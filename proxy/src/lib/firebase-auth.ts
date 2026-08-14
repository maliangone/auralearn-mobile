/**
 * Firebase ID-token verification (Phase 3) — the app account identity.
 *
 * The Flutter client signs in with Google/Apple through Firebase Auth and sends
 * the Firebase ID token as the `Authorization: Bearer` credential on every
 * /solve, /chat, and /billing call. This module verifies that token with
 * firebase-admin and returns the Firebase uid as the userId.
 *
 * Identity only — the token carries NO plan; entitlement is resolved
 * server-side (RevenueCat + Firestore), so a client cannot self-upgrade.
 *
 * When Firebase is NOT configured (no credentials + no FIREBASE_PROJECT_ID
 * env), verification is disabled and every real-ID-token request fails with a
 * clear reason; dev falls back to DEV_AUTH_TOKEN and the legacy HS256 JWT
 * (kept for local tooling). Production MUST configure Firebase.
 */

import { createHash } from "node:crypto";
import { initializeApp, type App } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { parseBearer, verifyHs256Jwt, type AuthResult } from "./auth.js";

export type { AuthOk, AuthErr, AuthResult } from "./auth.js";

export interface FirebaseAuthConfig {
  /** Firebase project id; empty => Firebase verification disabled. */
  firebaseProjectId: string;
  /** Legacy HS256 shared secret (dev/tooling). Empty => disabled. */
  accountsJwtSecret: string;
  /** Dev fallback token. Empty => no dev fallback. */
  devAuthToken: string;
}

/** Stable, content-free userId derived from a dev token (dev fallback only). */
export function userIdFromDevToken(token: string): string {
  return "u_" + createHash("sha256").update(token).digest("hex").slice(0, 16);
}

/** Lazily-initialized firebase-admin app (ADC on Cloud Run). */
let firebaseApp: App | undefined;
let firebaseInitFailed = false;

/**
 * Initializes firebase-admin from Application Default Credentials. On Cloud
 * Run the runtime service account is used; locally FIREBASE_CREDENTIALS_PATH
 * (path to a service-account JSON) or GOOGLE_APPLICATION_CREDENTIALS work.
 * Call once at boot; idempotent. Returns the app (also via [getFirebaseApp]).
 */
export function initFirebase(projectId: string): App | undefined {
  if (firebaseApp || firebaseInitFailed || projectId === "") return firebaseApp;
  try {
    firebaseApp = initializeApp({ projectId });
  } catch (err) {
    firebaseInitFailed = true;
    // Never crash boot over Firebase; real-token requests will fail clearly.
    // eslint-disable-next-line no-console
    console.error("[firebase-auth] initialization failed:", err);
  }
  return firebaseApp;
}

/** The initialized firebase-admin app, or undefined when not configured. */
export function getFirebaseApp(): App | undefined {
  return firebaseApp;
}

/**
 * Verify an Authorization header. Order:
 *   1. Dev fallback (LOCAL DEV ONLY) — exact or `<devToken>:<label>`.
 *   2. Firebase ID token (production path) — firebase-admin verifyIdToken.
 *   3. Legacy HS256 account JWT (dev/tooling compatibility).
 */
export async function verifyAuth(
  authorizationHeader: string | undefined,
  config: FirebaseAuthConfig,
): Promise<AuthResult> {
  const token = parseBearer(authorizationHeader);
  if (!token) {
    return { ok: false, reason: "missing or malformed Authorization header" };
  }

  // 1. Dev fallback (LOCAL DEV ONLY).
  const devToken = config.devAuthToken;
  if (devToken !== "") {
    if (token === devToken || token.startsWith(devToken + ":")) {
      return { ok: true, userId: userIdFromDevToken(token) };
    }
  }

  // 2. Firebase ID token (production).
  if (firebaseApp) {
    try {
      const decoded = await getAuth(firebaseApp).verifyIdToken(token);
      const sub = decoded.sub ?? decoded.uid;
      if (!sub) {
        return { ok: false, reason: "Firebase token missing sub/uid" };
      }
      return { ok: true, userId: sub };
    } catch {
      // Invalid/expired/revoked Firebase token. Do NOT fall through to the
      // legacy HS256 path with a Firebase token string — fail closed here
      // unless the legacy secret is configured for local tooling.
      if (config.accountsJwtSecret === "") {
        return { ok: false, reason: "invalid Firebase ID token" };
      }
    }
  } else if (config.accountsJwtSecret === "") {
    return { ok: false, reason: "invalid token" };
  }

  // 3. Legacy HS256 account JWT (dev/tooling compatibility).
  if (config.accountsJwtSecret === "") {
    return { ok: false, reason: "invalid token" };
  }
  const verified = verifyHs256Jwt(token, config.accountsJwtSecret);
  if (!verified.ok || !verified.payload) {
    return { ok: false, reason: verified.reason ?? "invalid token" };
  }
  const sub = verified.payload.sub;
  if (typeof sub !== "string" || sub.trim() === "") {
    return { ok: false, reason: "JWT missing sub claim" };
  }
  return { ok: true, userId: sub };
}
