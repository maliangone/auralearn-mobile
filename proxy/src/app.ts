/**
 * Fastify app factory. Kept separate from server.ts so tests can build an app
 * with injected deps (mocked TutorModel / stores / RevenueCat) and NO network.
 */

import Fastify, { type FastifyInstance } from "fastify";
import type { Firestore } from "firebase-admin/firestore";
import type { AppConfig } from "./config.js";
import type { TutorModel } from "./lib/anthropic.js";
import type { MeteringStore } from "./lib/metering.js";
import type { EntitlementStore } from "./lib/entitlement.js";
import type { RevenueCatClient } from "./lib/revenuecat.js";
import type { Logger } from "./lib/logger.js";
import { registerSolveRoutes } from "./routes/solve.js";
import { registerBillingRoutes } from "./routes/billing.js";
import { registerWebhookRoutes } from "./routes/webhook.js";

export interface BuildAppDeps {
  config: AppConfig;
  model: TutorModel;
  /** OpenAI-compatible upstream — used when a tier resolves to provider "openai". */
  openAiModel?: TutorModel;
  metering: MeteringStore;
  entitlement: EntitlementStore;
  revenuecat: RevenueCatClient;
  /** Firestore for webhook idempotency records; undefined => dev/test fallback. */
  db?: Firestore;
  logger: Logger;
}

export function buildApp(deps: BuildAppDeps): FastifyInstance {
  const app = Fastify({
    // We do our own redacting logger; disable Fastify's request/response logging
    // so it can never accidentally log bodies (image bytes / problem text).
    logger: false,
    bodyLimit: 8 * 1024 * 1024, // 8 MB: up to 3 base64 images.
  });

  const auth = {
    firebaseProjectId: deps.config.firebaseProjectId,
    accountsJwtSecret: deps.config.accountsJwtSecret,
    devAuthToken: deps.config.devAuthToken,
  };

  app.get("/healthz", async () => ({ ok: true }));

  registerSolveRoutes(app, {
    config: deps.config,
    model: deps.model,
    openAiModel: deps.openAiModel,
    metering: deps.metering,
    entitlement: deps.entitlement,
    auth,
    logger: deps.logger,
  });
  registerBillingRoutes(app, {
    config: deps.config,
    entitlement: deps.entitlement,
    revenuecat: deps.revenuecat,
    auth,
    logger: deps.logger,
  });
  registerWebhookRoutes(app, {
    entitlement: deps.entitlement,
    db: deps.db,
    webhookSecret: deps.config.revenuecat.webhookSecret,
    webhookHmacSecret: deps.config.revenuecat.webhookHmacSecret,
    logger: deps.logger,
  });

  return app;
}
