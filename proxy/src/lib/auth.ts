/**
 * Auth — Phase C: real account-JWT verification.
 *
 * The account service (ACCOUNTS_URL) issues an HS256 JWT signed with a shared
 * secret (ACCOUNTS_JWT_SECRET). This proxy verifies the signature locally and
 * extracts the userId from the `sub` claim.
 *
 * IDENTITY ONLY: the token conveys *who* the user is — never their plan. The
 * plan/entitlement is resolved server-side from the EntitlementStore so a client
 * cannot self-upgrade by minting a token with a richer claim.
 *
 * Dev fallback: if DEV_AUTH_TOKEN is configured and the presented bearer equals
 * it (or `<DEV_AUTH_TOKEN>:<label>`), it is accepted WITHOUT JWT verification and
 * mapped to a stable content-free userId. LOCAL DEV ONLY (documented in README);
 * leave DEV_AUTH_TOKEN unset in production.
 *
 * No third-party JWT dependency: HS256 verify is a single HMAC-SHA256 + a
 * constant-time compare via Node's crypto.
 */

import { createHash, createHmac, timingSafeEqual } from "node:crypto";

export interface AuthOk {
  ok: true;
  userId: string;
}

export interface AuthErr {
  ok: false;
  reason: string;
}

export type AuthResult = AuthOk | AuthErr;

export interface VerifyAuthConfig {
  /** HS256 shared secret. Empty => JWT verification disabled (dev token only). */
  accountsJwtSecret: string;
  /** Dev fallback token. Empty => no dev fallback. */
  devAuthToken: string;
  /** Clock, injectable for tests. Defaults to Date.now (ms). */
  now?: () => number;
}

/** Extract the bearer token from an Authorization header value. */
export function parseBearer(headerValue: string | undefined): string | undefined {
  if (!headerValue) return undefined;
  const m = /^Bearer\s+(.+)$/i.exec(headerValue.trim());
  return m ? m[1].trim() : undefined;
}

/** Stable, content-free userId derived from a dev token (dev fallback only). */
function userIdFromDevToken(token: string): string {
  return "u_" + createHash("sha256").update(token).digest("hex").slice(0, 16);
}

/** base64url decode -> Buffer. */
function b64urlToBuffer(input: string): Buffer {
  const pad = input.length % 4 === 0 ? "" : "=".repeat(4 - (input.length % 4));
  const b64 = input.replace(/-/g, "+").replace(/_/g, "/") + pad;
  return Buffer.from(b64, "base64");
}

/** base64url encode a Buffer (no padding). */
function bufferToB64url(buf: Buffer): string {
  return buf.toString("base64").replace(/=+$/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

interface JwtVerifyResult {
  ok: boolean;
  reason?: string;
  payload?: Record<string, unknown>;
}

/**
 * Verify an HS256 JWT against `secret`. Checks: 3 segments, alg=HS256, signature
 * (constant-time), and `exp`/`nbf` if present. Returns the decoded payload.
 *
 * Exported for unit testing.
 */
export function verifyHs256Jwt(
  token: string,
  secret: string,
  nowMs: number = Date.now(),
): JwtVerifyResult {
  const parts = token.split(".");
  if (parts.length !== 3) return { ok: false, reason: "malformed JWT" };
  const [headerB64, payloadB64, signatureB64] = parts;

  let header: Record<string, unknown>;
  let payload: Record<string, unknown>;
  try {
    header = JSON.parse(b64urlToBuffer(headerB64).toString("utf8")) as Record<string, unknown>;
    payload = JSON.parse(b64urlToBuffer(payloadB64).toString("utf8")) as Record<string, unknown>;
  } catch {
    return { ok: false, reason: "undecodable JWT segments" };
  }

  if (header.alg !== "HS256") {
    return { ok: false, reason: `unsupported alg: ${String(header.alg)}` };
  }

  // Recompute and compare the signature in constant time.
  const expected = createHmac("sha256", secret).update(`${headerB64}.${payloadB64}`).digest();
  const provided = b64urlToBuffer(signatureB64);
  if (expected.length !== provided.length || !timingSafeEqual(expected, provided)) {
    return { ok: false, reason: "bad signature" };
  }

  // Time-based claims (seconds since epoch).
  const nowSec = Math.floor(nowMs / 1000);
  const SKEW = 30; // small clock-skew tolerance
  if (typeof payload.exp === "number" && nowSec > payload.exp + SKEW) {
    return { ok: false, reason: "token expired" };
  }
  if (typeof payload.nbf === "number" && nowSec + SKEW < payload.nbf) {
    return { ok: false, reason: "token not yet valid" };
  }

  return { ok: true, payload };
}

/**
 * Helper for tests/dev tooling: sign an HS256 JWT. NOT used by the request path
 * (the account service signs tokens), but lives here so tests can mint valid and
 * tampered tokens without a third-party dependency.
 */
export function signHs256Jwt(
  payload: Record<string, unknown>,
  secret: string,
  header: Record<string, unknown> = { alg: "HS256", typ: "JWT" },
): string {
  const h = bufferToB64url(Buffer.from(JSON.stringify(header), "utf8"));
  const p = bufferToB64url(Buffer.from(JSON.stringify(payload), "utf8"));
  const sig = createHmac("sha256", secret).update(`${h}.${p}`).digest();
  return `${h}.${p}.${bufferToB64url(sig)}`;
}

/**
 * Authenticate a request.
 *
 * Order:
 *   1. Dev fallback (if configured) — local dev convenience.
 *   2. Real account-JWT verification (HS256, signature-local). `sub` -> userId.
 *
 * Returns a content-free userId on success; otherwise an `unauthorized` reason.
 */
export function verifyAuth(
  authorizationHeader: string | undefined,
  config: VerifyAuthConfig,
): AuthResult {
  const token = parseBearer(authorizationHeader);
  if (!token) {
    return { ok: false, reason: "missing or malformed Authorization header" };
  }

  // 1. Dev fallback (LOCAL DEV ONLY) — exact match or "<devToken>:<label>".
  const devToken = config.devAuthToken;
  if (devToken !== "") {
    if (token === devToken || token.startsWith(devToken + ":")) {
      return { ok: true, userId: userIdFromDevToken(token) };
    }
  }

  // 2. Real account JWT.
  if (config.accountsJwtSecret === "") {
    return { ok: false, reason: "invalid token" };
  }
  const nowMs = config.now ? config.now() : Date.now();
  const verified = verifyHs256Jwt(token, config.accountsJwtSecret, nowMs);
  if (!verified.ok || !verified.payload) {
    return { ok: false, reason: verified.reason ?? "invalid token" };
  }
  const sub = verified.payload.sub;
  if (typeof sub !== "string" || sub.trim() === "") {
    return { ok: false, reason: "JWT missing sub claim" };
  }
  return { ok: true, userId: sub };
}
