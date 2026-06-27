/**
 * Server entrypoint. Wires real deps (Anthropic client, metering store, logger)
 * and listens. The Anthropic key is read from env at runtime — never committed.
 */

import { loadConfig } from "./config.js";
import { buildApp } from "./app.js";
import { AnthropicTutorModel } from "./lib/anthropic.js";
import { createMeteringStore } from "./lib/metering.js";
import { createEntitlementStore } from "./lib/entitlement.js";
import { createReceiptVerifier } from "./lib/receipt-verifier.js";
import { createLogger } from "./lib/logger.js";

async function main(): Promise<void> {
  const config = loadConfig();
  const logger = createLogger({ route: "boot" });

  if (!config.anthropicApiKey) {
    logger.error("ANTHROPIC_API_KEY is not set; refusing to start", { code: "internal_error" });
    process.exit(1);
  }

  if (!config.accountsJwtSecret && !config.devAuthToken) {
    logger.error("no auth configured (set ACCOUNTS_JWT_SECRET or DEV_AUTH_TOKEN)", {
      code: "internal_error",
    });
    process.exit(1);
  }

  const model = new AnthropicTutorModel(config.anthropicApiKey);
  const metering = createMeteringStore(config.redisUrl);
  // Entitlement uses the same connection seam as metering (Redis/db) in prod.
  const entitlement = createEntitlementStore(config.redisUrl);
  const receiptVerifier = createReceiptVerifier(config.iap);

  const app = buildApp({ config, model, metering, entitlement, receiptVerifier, logger });

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
