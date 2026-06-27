/**
 * Billing / IAP routes (Phase C) — plain JSON (NOT SSE).
 *
 *   POST /billing/validate  -> verify a store receipt, bind it, grant entitlement.
 *   GET  /billing/status    -> the authed user's current entitlement.
 *
 * Anti-replay / cross-account (Critic M3): a receipt is bound to exactly one
 * userId. If the derived receiptId is already owned by a DIFFERENT user, the
 * request is rejected with 409 receipt_already_bound — one purchase cannot
 * entitle many accounts. Re-presenting the SAME receipt by its OWNER is idempotent
 * (a restore).
 *
 * All responses are content-free metadata. The store credentials needed for REAL
 * verification are guarded behind env; absent => deterministic mock (documented).
 */

import type { FastifyInstance, FastifyReply, FastifyRequest } from "fastify";
import type { AppConfig } from "../config.js";
import type { EntitlementStore, Entitlement } from "../lib/entitlement.js";
import type { Logger } from "../lib/logger.js";
import type {
  ReceiptVerifier,
  ReceiptVerifyRequest,
  Platform,
} from "../lib/receipt-verifier.js";
import { verifyAuth } from "../lib/auth.js";
import { productIdToTier } from "../lib/receipt-verifier.js";

export interface BillingRouteDeps {
  config: AppConfig;
  entitlement: EntitlementStore;
  receiptVerifier: ReceiptVerifier;
  logger: Logger;
}

interface ValidateBody {
  platform?: string;
  receipt?: string;
  purchaseToken?: string;
  productId?: string;
}

function authOf(deps: BillingRouteDeps, request: FastifyRequest) {
  return verifyAuth(request.headers["authorization"], {
    accountsJwtSecret: deps.config.accountsJwtSecret,
    devAuthToken: deps.config.devAuthToken,
  });
}

async function handleValidate(
  deps: BillingRouteDeps,
  request: FastifyRequest,
  reply: FastifyReply,
): Promise<void> {
  const reqId = (request.id as string) ?? undefined;
  const auth = authOf(deps, request);
  if (!auth.ok) {
    deps.logger.info("billing auth failed", {
      reqId,
      route: "/billing/validate",
      code: "unauthorized",
      event: "auth",
    });
    await reply.code(401).send({ code: "unauthorized", message: "Authentication required." });
    return;
  }
  const log = deps.logger.child({ reqId, route: "/billing/validate", userId: auth.userId });

  const body = (request.body ?? {}) as ValidateBody;
  const platform = body.platform;
  if (platform !== "apple" && platform !== "google") {
    await reply
      .code(400)
      .send({ code: "bad_request", message: "platform must be 'apple' or 'google'" });
    return;
  }
  if (typeof body.productId !== "string" || body.productId.trim() === "") {
    await reply.code(400).send({ code: "bad_request", message: "productId is required" });
    return;
  }

  const verifyReq: ReceiptVerifyRequest = {
    platform: platform as Platform,
    receipt: typeof body.receipt === "string" ? body.receipt : undefined,
    purchaseToken: typeof body.purchaseToken === "string" ? body.purchaseToken : undefined,
    productId: body.productId,
  };

  const result = await deps.receiptVerifier.verify(verifyReq);
  if (!result.ok) {
    const status = result.code === "bad_request" ? 400 : 402;
    log.info("receipt rejected", { event: "billing", code: result.code, status });
    await reply.code(status).send({ code: result.code, message: result.message });
    return;
  }

  // Anti-replay / cross-account binding.
  const existingOwner = await deps.entitlement.getReceiptOwner(result.receiptId);
  if (existingOwner !== undefined && existingOwner !== auth.userId) {
    log.warn("receipt already bound to another account", {
      event: "billing",
      code: "receipt_already_bound",
      status: 409,
    });
    await reply.code(409).send({
      code: "receipt_already_bound",
      message: "This purchase is already linked to a different account.",
    });
    return;
  }

  // Bind (idempotent for the same owner) and grant entitlement.
  await deps.entitlement.bindReceipt(result.receiptId, auth.userId);
  const entitlement: Entitlement = {
    plan: "paid",
    tier: productIdToTier(result.productId),
    expiresAt: result.expiresAt,
  };
  await deps.entitlement.setEntitlement(auth.userId, entitlement);

  log.info("entitlement granted", { event: "billing", status: 200 });
  await reply.code(200).send({
    ok: true,
    entitlement,
  });
}

async function handleStatus(
  deps: BillingRouteDeps,
  request: FastifyRequest,
  reply: FastifyReply,
): Promise<void> {
  const reqId = (request.id as string) ?? undefined;
  const auth = authOf(deps, request);
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
  await reply.code(200).send({ entitlement: ent });
}

export function registerBillingRoutes(app: FastifyInstance, deps: BillingRouteDeps): void {
  app.post("/billing/validate", (req, reply) => handleValidate(deps, req, reply));
  app.get("/billing/status", (req, reply) => handleStatus(deps, req, reply));
}
