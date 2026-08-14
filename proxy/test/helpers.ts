import type { FastifyInstance } from "fastify";
import type { TutorModel, TextChunk, TutorStreamArgs } from "../src/lib/anthropic.js";
import { createLogger, type Logger } from "../src/lib/logger.js";
import { loadConfig, type AppConfig } from "../src/config.js";
import { buildApp } from "../src/app.js";
import { InMemoryMeteringStore, type MeteringStore } from "../src/lib/metering.js";
import {
  InMemoryEntitlementStore,
  type EntitlementStore,
} from "../src/lib/entitlement.js";
import type { RevenueCatClient, RevenueCatSubscriber } from "../src/lib/revenuecat.js";

/** A fake TutorModel that streams canned chunks — NO network, NO real API. */
export class FakeTutorModel implements TutorModel {
  public lastArgs: TutorStreamArgs | undefined;

  constructor(private readonly chunks: string[]) {}

  async *streamTutor(args: TutorStreamArgs): AsyncIterable<TextChunk> {
    this.lastArgs = args;
    for (const text of this.chunks) {
      yield { text };
    }
  }
}

/** A TutorModel that throws mid-stream, to test the upstream_error path. */
export class FailingTutorModel implements TutorModel {
  // eslint-disable-next-line require-yield
  async *streamTutor(): AsyncIterable<TextChunk> {
    yield { text: "RECOGNIZED: a problem\n\n" };
    throw new Error("simulated upstream failure");
  }
}

/** A deterministic RevenueCat client — records lookups, returns a fixed verdict. */
export class FakeRevenueCat implements RevenueCatClient {
  public queriedIds: string[] = [];
  /** Mutable so tests can flip the verdict between calls. */
  public verdict: RevenueCatSubscriber = { plan: "free", tier: "free" };

  constructor(verdict?: RevenueCatSubscriber) {
    if (verdict) this.verdict = verdict;
  }

  async getSubscriber(appUserId: string): Promise<RevenueCatSubscriber> {
    this.queriedIds.push(appUserId);
    return { ...this.verdict };
  }
}

/** A logger that captures every emitted line for inspection. */
export function captureLogger(): { logger: Logger; lines: string[] } {
  const lines: string[] = [];
  const logger = createLogger({}, (l) => lines.push(l));
  return { logger, lines };
}

export function testConfig(overrides: Partial<AppConfig> = {}): AppConfig {
  const base = loadConfig({
    ANTHROPIC_API_KEY: "test-key-not-used",
    MODEL_FREE: "claude-haiku-4-5-20251001",
    MODEL_PAID_STD: "claude-sonnet-4-6",
    MODEL_PAID_PRO: "claude-opus-4-8",
    PORT: "0",
    FREE_DAILY_QUOTA: "3",
    ACCOUNTS_JWT_SECRET: "test-accounts-secret",
    DEV_AUTH_TOKEN: "dev-local-token",
    MAX_CONTEXT_CHARS: "12000",
  } as NodeJS.ProcessEnv);
  return { ...base, ...overrides };
}

export interface TestApp {
  app: FastifyInstance;
  config: AppConfig;
  metering: MeteringStore;
  entitlement: EntitlementStore;
  revenuecat: FakeRevenueCat;
  lines: string[];
}

/**
 * Build the full Fastify app with in-memory stores + a deterministic mock
 * RevenueCat client and a captured logger. NO network. Returns the stores so
 * tests can seed and inspect them via `app.inject`.
 */
export function buildTestApp(overrides: Partial<AppConfig> = {}): TestApp {
  const config = testConfig(overrides);
  const { logger, lines } = captureLogger();
  const metering = new InMemoryMeteringStore();
  const entitlement = new InMemoryEntitlementStore();
  const revenuecat = new FakeRevenueCat();
  const model = new FakeTutorModel(["RECOGNIZED: x\n\n结论: y."]);
  const app = buildApp({
    config,
    model,
    metering,
    entitlement,
    revenuecat,
    logger,
  });
  return { app, config, metering, entitlement, revenuecat, lines };
}
