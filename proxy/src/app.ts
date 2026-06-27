/**
 * Fastify app factory. Kept separate from server.ts so tests can build an app
 * with injected deps (a mocked TutorModel) and NO network.
 */

import Fastify, { type FastifyInstance } from "fastify";
import type { AppConfig } from "./config.js";
import type { TutorModel } from "./lib/anthropic.js";
import type { MeteringStore } from "./lib/metering.js";
import type { EntitlementStore } from "./lib/entitlement.js";
import type { ReceiptVerifier } from "./lib/receipt-verifier.js";
import type { Logger } from "./lib/logger.js";
import { registerSolveRoutes } from "./routes/solve.js";
import { registerBillingRoutes } from "./routes/billing.js";

export interface BuildAppDeps {
  config: AppConfig;
  model: TutorModel;
  metering: MeteringStore;
  entitlement: EntitlementStore;
  receiptVerifier: ReceiptVerifier;
  logger: Logger;
}

export function buildApp(deps: BuildAppDeps): FastifyInstance {
  const app = Fastify({
    // We do our own redacting logger; disable Fastify's request/response logging
    // so it can never accidentally log bodies (image bytes / problem text).
    logger: false,
    bodyLimit: 8 * 1024 * 1024, // 8 MB: up to 3 base64 images.
  });

  app.get("/healthz", async () => ({ ok: true }));

  registerSolveRoutes(app, deps);
  registerBillingRoutes(app, {
    config: deps.config,
    entitlement: deps.entitlement,
    receiptVerifier: deps.receiptVerifier,
    logger: deps.logger,
  });

  return app;
}
