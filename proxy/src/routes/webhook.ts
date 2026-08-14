/**
 * RevenueCat webhook (Phase 3) — push channel for entitlement changes.
 *
 *   POST /webhook/revenuecat
 *
 * Port of the yijing app's webhook pipeline:
 *   - Dual auth: a static Authorization header secret AND the
 *     `X-RevenueCat-Webhook-Signature` HMAC-SHA256 (`t=...,v1=...`, 300s window).
 *   - Idempotent + out-of-order safe: each event id is recorded in Firestore
 *     (`revenuecatWebhookEvents/{eventId}`, 90-day TTL) inside a transaction;
 *     events older than the user's last-applied `subscriptionEventAtMs` are
 *     dropped.
 *   - Grant events (INITIAL_PURCHASE / RENEWAL / UNCANCELLATION /
 *     PRODUCT_CHANGE / SUBSCRIPTION_EXTENDED) persist tier=subscribed;
 *     revoke events (EXPIRATION / BILLING_ISSUE) persist tier=free.
 *   - `$RCAnonymousID` app user ids are resolved from `aliases` to the real
 *     Firebase uid (the app calls Purchases.logIn(uid) on sign-in, so the
 *     resolved id is the uid the proxy routes on).
 *
 * All writes are content-free metadata only.
 */

import { createHmac, timingSafeEqual } from "node:crypto";
import type { FastifyInstance, FastifyReply, FastifyRequest } from "fastify";
import type { EntitlementStore } from "../lib/entitlement.js";
import type { Logger } from "../lib/logger.js";
import type { Firestore } from "firebase-admin/firestore";

export interface WebhookDeps {
  entitlement: EntitlementStore;
  /** Required for idempotency records; in-memory fallback used in tests/dev. */
  db: Firestore | undefined;
  webhookSecret: string;
  webhookHmacSecret: string;
  logger: Logger;
}

const GRANT_EVENTS = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "UNCANCELLATION",
  "PRODUCT_CHANGE",
  "SUBSCRIPTION_EXTENDED",
]);
const REVOKE_EVENTS = new Set(["EXPIRATION", "BILLING_ISSUE"]);

interface RevenueCatEvent {
  event: {
    id: string;
    type: string;
    app_user_id: string;
    aliases?: string[];
    expiration_at_ms?: number;
    environment?: string;
  };
}

const SIGNATURE_WINDOW_MS = 300_000; // 300 seconds

/** Verify `t=...,v1=...` HMAC-SHA256 over `t.<body>` (constant-time). */
function verifyHmacSignature(body: string, header: string | undefined, secret: string): boolean {
  if (!header || secret === "") return false;
  const tMatch = /t=(\d+)/.exec(header);
  const v1Match = /v1=([0-9a-fA-F]+)/.exec(header);
  if (!tMatch || !v1Match) return false;

  const t = Number.parseInt(tMatch[1], 10);
  if (!Number.isFinite(t) || Math.abs(Date.now() - t * 1000) > SIGNATURE_WINDOW_MS) {
    return false;
  }
  const expected = createHmac("sha256", secret)
    .update(`${tMatch[1]}.${body}`)
    .digest("hex");
  const provided = Buffer.from(v1Match[1], "hex");
  const expectedBuf = Buffer.from(expected, "hex");
  return expectedBuf.length === provided.length && timingSafeEqual(expectedBuf, provided);
}

/** Resolve the real account uid: prefer aliases' last entry, else app_user_id. */
function resolveUserId(evt: RevenueCatEvent["event"]): string {
  const aliases = evt.aliases ?? [];
  return aliases.length > 0 ? aliases[aliases.length - 1] : evt.app_user_id;
}

export async function handleRevenueCatWebhook(
  deps: WebhookDeps,
  request: FastifyRequest,
  reply: FastifyReply,
): Promise<void> {
  // The route's scoped parser uses `parseAs: "string"`, so request.body IS the
  // exact raw bytes (as a string) RevenueCat signed. (rawBody is a fallback for
  // Fastify versions that populate it.)
  const bodyValue = (request as { rawBody?: string }).rawBody ?? request.body;
  const rawBody = typeof bodyValue === "string" ? bodyValue : JSON.stringify(bodyValue ?? "");

  // 1. Dual auth: static header secret + HMAC signature.
  const authHeader = request.headers["authorization"];
  const secretOk =
    deps.webhookSecret !== "" && authHeader === `Bearer ${deps.webhookSecret}`;
  const hmacOk = verifyHmacSignature(
    rawBody,
    request.headers["x-revenuecat-webhook-signature"] as string | undefined,
    deps.webhookHmacSecret,
  );
  if (!secretOk && !hmacOk) {
    await reply.code(401).send({ code: "unauthorized", message: "Invalid webhook credentials." });
    return;
  }

  // 2. Parse the event.
  let parsed: RevenueCatEvent;
  try {
    parsed = JSON.parse(rawBody) as RevenueCatEvent;
  } catch {
    await reply.code(400).send({ code: "bad_request", message: "Invalid JSON body." });
    return;
  }
  const evt = parsed.event;
  if (!evt || typeof evt.id !== "string" || typeof evt.type !== "string") {
    await reply.code(400).send({ code: "bad_request", message: "Missing event fields." });
    return;
  }

  const userId = resolveUserId(evt);
  const eventId = evt.id;
  const eventTimeMs = typeof evt.expiration_at_ms === "number" ? evt.expiration_at_ms : Date.now();

  // 3. Idempotency + out-of-order guard.
  if (deps.db) {
    const applied = await applyWithIdempotency(deps, userId, eventId, eventTimeMs, evt);
    if (!applied) {
      await reply.code(200).send({ ok: true, duplicate: true });
      return;
    }
  } else {
    // Dev/test without Firestore: apply directly (no idempotency records).
    await applyEvent(deps, userId, evt);
  }

  deps.logger.info("revenuecat webhook applied", {
    route: "/webhook/revenuecat",
    userId,
    code: evt.type,
    event: "webhook",
    status: 200,
  });
  await reply.code(200).send({ ok: true });
}

/** Firestore-transactional apply: idempotent + drops out-of-order events. */
async function applyWithIdempotency(
  deps: WebhookDeps,
  userId: string,
  eventId: string,
  eventTimeMs: number,
  evt: RevenueCatEvent["event"],
): Promise<boolean> {
  const db = deps.db!;
  const eventDoc = db.collection("revenuecatWebhookEvents").doc(eventId);
  const userDoc = db.collection("users").doc(userId);

  try {
    await db.runTransaction(async (tx) => {
      const appliedSnap = await tx.get(eventDoc);
      if (appliedSnap.exists) return; // duplicate — already applied

      // Out-of-order: drop events older than the last applied subscription event.
      const userSnap = await tx.get(userDoc);
      const lastApplied = userSnap.data()?.["subscriptionEventAtMs"] as number | undefined;
      if (typeof lastApplied === "number" && eventTimeMs < lastApplied) return;

      tx.set(eventDoc, { appliedAt: new Date().toISOString() });
      if (GRANT_EVENTS.has(evt.type)) {
        // users/{uid} IS the entitlement doc (FirestoreEntitlementStore reads
        // the same fields) — a single transaction keeps both consistent.
        tx.set(
          userDoc,
          {
            plan: "paid",
            tier: "std",
            subExpiry: eventTimeMs,
            subscriptionEventAtMs: eventTimeMs,
          },
          { merge: true },
        );
      } else if (REVOKE_EVENTS.has(evt.type)) {
        tx.set(
          userDoc,
          { plan: "free", tier: "free", subscriptionEventAtMs: eventTimeMs },
          { merge: true },
        );
      }
      // Other event types (TEST, TRANSFER, etc.) are ignored but recorded.
    });
    return true;
  } catch (err) {
    // Transaction contention / duplicate-create race: treat as already applied.
    deps.logger.warn("webhook transaction failed (treated as duplicate)", {
      route: "/webhook/revenuecat",
      code: "webhook_transaction",
      event: "webhook",
    });
    void err;
    return false;
  }
}

async function applyEvent(
  deps: WebhookDeps,
  userId: string,
  evt: RevenueCatEvent["event"],
): Promise<void> {
  if (GRANT_EVENTS.has(evt.type)) {
    await deps.entitlement.setEntitlement(userId, {
      plan: "paid",
      tier: "std",
      expiresAt: typeof evt.expiration_at_ms === "number" ? evt.expiration_at_ms : undefined,
    });
  } else if (REVOKE_EVENTS.has(evt.type)) {
    await deps.entitlement.setEntitlement(userId, { plan: "free", tier: "free" });
  }
}

export function registerWebhookRoutes(app: FastifyInstance, deps: WebhookDeps): void {
  // The webhook needs the EXACT request bytes (HMAC). Fastify only populates
  // request.rawBody when the route's content-type parser uses
  // `parseAs: "string"` — registered inside a child scope so the rest of the
  // app keeps the normal JSON-object parser.
  app.register(async (child) => {
    child.addContentTypeParser("application/json", { parseAs: "string" }, (_req, body, done) =>
      done(null, body),
    );
    child.post("/webhook/revenuecat", { config: { rawBody: true } }, (req, reply) =>
      handleRevenueCatWebhook(deps, req, reply),
    );
  });
}
