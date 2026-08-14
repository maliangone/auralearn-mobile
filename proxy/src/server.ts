/**
 * Server entrypoint. Wires real deps (per-provider model clients, Firestore
 * stores, RevenueCat, Firebase auth, logger) and listens. Vendor keys are read
 * from env at runtime — never committed.
 */

import { getFirestore, type Firestore } from "firebase-admin/firestore";
import { loadConfig, type Provider, type TierConfig } from "./config.js";
import { buildApp } from "./app.js";
import { AnthropicTutorModel } from "./lib/anthropic.js";
import { OpenAiCompatibleTutorModel } from "./lib/openai-compatible.js";
import {
  createMeteringStore,
  type MeteringStore,
} from "./lib/metering.js";
import { FirestoreMeteringStore } from "./lib/firestore-metering.js";
import {
  createEntitlementStore,
  type EntitlementStore,
} from "./lib/entitlement.js";
import { FirestoreEntitlementStore } from "./lib/firestore-entitlement.js";
import { RevenueCatRestClient } from "./lib/revenuecat.js";
import { initFirebase } from "./lib/firebase-auth.js";
import { createLogger } from "./lib/logger.js";

/** Providers actually used by at least one tier. */
function usedProviders(config: ReturnType<typeof loadConfig>): Set<Provider> {
  const tiers: TierConfig[] = [
    config.models.free,
    config.models.paidStd,
    config.models.paidPro,
  ];
  return new Set(tiers.map((t) => t.provider));
}

async function main(): Promise<void> {
  const config = loadConfig();
  const logger = createLogger({ route: "boot" });

  // Boot guard: every provider referenced by a tier must have a key. Keys are
  // never logged — only which provider is missing.
  for (const provider of usedProviders(config)) {
    if (!config.providers[provider].apiKey) {
      logger.error(`${provider.toUpperCase()}_API_KEY is not set; refusing to start`, {
        code: "internal_error",
      });
      process.exit(1);
    }
  }

  if (!config.accountsJwtSecret && !config.devAuthToken && !config.firebaseProjectId) {
    logger.error(
      "no auth configured (set FIREBASE_PROJECT_ID, ACCOUNTS_JWT_SECRET, or DEV_AUTH_TOKEN)",
      { code: "internal_error" },
    );
    process.exit(1);
  }

  // Firebase: auth (ID-token verification) + Firestore (metering/entitlement).
  // When FIREBASE_PROJECT_ID is unset (dev/test) the in-memory stores apply and
  // real-ID-token auth is disabled — dev token / legacy JWT still work.
  let firestoreDb: Firestore | undefined;
  let metering: MeteringStore;
  let entitlement: EntitlementStore;
  if (config.firebaseProjectId) {
    const fbApp = initFirebase(config.firebaseProjectId);
    if (fbApp) {
      try {
        firestoreDb = getFirestore(fbApp);
        metering = new FirestoreMeteringStore(firestoreDb);
        entitlement = new FirestoreEntitlementStore(firestoreDb);
        logger.info("Firestore stores wired", {});
      } catch (err) {
        logger.error("Firestore initialization failed — falling back to in-memory", {
          code: "internal_error",
        });
        // eslint-disable-next-line no-console
        console.error(err);
        metering = createMeteringStore();
        entitlement = createEntitlementStore();
      }
    } else {
      logger.error("Firebase initialization failed — falling back to in-memory", {
        code: "internal_error",
      });
      metering = createMeteringStore();
      entitlement = createEntitlementStore();
    }
  } else {
    metering = createMeteringStore();
    entitlement = createEntitlementStore();
  }

  // One model client per provider family; tiers share base URL + key.
  const anthropic = new AnthropicTutorModel(config.providers.anthropic.apiKey);
  const openAi = new OpenAiCompatibleTutorModel({
    apiKey: config.providers.openai.apiKey,
    baseUrl: config.providers.openai.baseUrl,
  });
  const revenuecat = new RevenueCatRestClient(config.revenuecat.apiKey);

  const app = buildApp({
    config,
    model: anthropic,
    openAiModel: usedProviders(config).has("openai") ? openAi : undefined,
    metering,
    entitlement,
    revenuecat,
    db: firestoreDb,
    logger,
  });

  try {
    await app.listen({ port: config.port, host: "0.0.0.0" });
    logger.info("proxy listening", { status: config.port });
  } catch (err) {
    logger.error("failed to start", { code: "internal_error" });
    // eslint-disable-next-line no-console
    console.error(err);
    process.exit(1);
  }
}

main();
