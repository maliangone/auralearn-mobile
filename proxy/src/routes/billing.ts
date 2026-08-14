/**
 * Billing routes (Phase 3, RevenueCat-authoritative) — plain JSON (NOT SSE).
 *
 *   POST /billing/sync  -> the server queries RevenueCat itself for this
 *                          account's entitlement and persists it. The client
 *                          sends an EMPTY body — it never sends receipts.
 *   GET  /billing/status -> the authed user's persisted entitlement.
 *
 * The RevenueCat webhook (routes/webhook.ts) is the push channel for
 * renewals/expirations; /billing/sync is the pull channel after a fresh
 * purchase. All responses are content-free metadata.
 */

import type { FastifyInstance, FastifyReply, FastifyRequest } from "fastify";
import type { AppConfig } from "../config.js";
import type { EntitlementStore } from "../lib/entitlement.js";
import type { Logger } from "../lib/logger.js";
import type { RevenueCatClient } from "../lib/revenuecat.js";
import type { FirebaseAuthConfig } from "../lib/firebase-auth.js";
import { verifyAuth } from "../lib/firebase-auth.js";

export interface BillingRouteDeps {
  config: AppConfig;
  entitlement: EntitlementStore;
  revenuecat: RevenueCatClient;
  /** Auth config mirroring the solve routes (Firebase ID token / dev / legacy). */
  auth: FirebaseAuthConfig;
  logger: Logger;
}

async function authOf(
  deps: BillingRouteDeps,
  request: FastifyRequest,
): Promise<{ ok: true; userId: string } | { ok: false }> {
  return verifyAuth(request.headers["authorization"], deps.auth);
}

async function handleSync(
  deps: BillingRouteDeps,
  request: FastifyRequest,
  reply: FastifyReply,
): Promise<void> {
  const reqId = (request.id as string) ?? undefined;
  const auth = await authOf(deps, request);
  if (!auth.ok) {
    deps.logger.info("billing auth failed", {
      reqId,
      route: "/billing/sync",
      code: "unauthorized",
      event: "auth",
    });
    await reply.code(401).send({ code: "unauthorized", message: "Authentication required." });
    return;
  }
  const log = deps.logger.child({ reqId, route: "/billing/sync", userId: auth.userId });

  // The body is intentionally ignored: the client cannot assert its own
  // entitlement — the server only trusts its own RevenueCat lookup.
  let subscriber;
  try {
    subscriber = await deps.revenuecat.getSubscriber(auth.userId);
  } catch (err) {
    log.error("revenuecat lookup failed", { event: "billing", code: "upstream_error" });
    await reply.code(502).send({
      code: "upstream_error",
      message: "Could not reach the subscription service. Try again.",
    });
    return;
  }

  const entitlement = {
    plan: subscriber.plan,
    tier: subscriber.tier,
    ...(typeof subscriber.expiresAt === "number"
      ? { expiresAt: subscriber.expiresAt }
      : {}),
  };
  await deps.entitlement.setEntitlement(auth.userId, entitlement);

  log.info("entitlement synced", {
    event: "billing",
    plan: entitlement.plan,
    status: 200,
  });
  // Client contract: { plan, tier, expiresAt } at the TOP level (the billing
  // datasource parses these fields directly).
  await reply.code(200).send({ ok: true, ...entitlement });
}

async function handleStatus(
  deps: BillingRouteDeps,
  request: FastifyRequest,
  reply: FastifyReply,
): Promise<void> {
  const reqId = (request.id as string) ?? undefined;
  const auth = await authOf(deps, request);
  if (!auth.ok) {
    await reply.code(401).send({ code: "unauthorized", message: "Authentication required." });
    return;
  }
  const ent = await deps.entitlement.getEntitlement(auth.userId);
  deps.logger.info("billing status", {
    reqId,
    route: "/billing/status",
    userId: auth.userId,
    plan: ent.plan,
    event: "billing",
    status: 200,
  });
  // Client contract: { plan, tier, expiresAt } at the TOP level.
  await reply.code(200).send({ ...ent });
}

export function registerBillingRoutes(app: FastifyInstance, deps: BillingRouteDeps): void {
  app.post("/billing/sync", (req, reply) => handleSync(deps, req, reply));
  app.get("/billing/status", (req, reply) => handleStatus(deps, req, reply));
}
