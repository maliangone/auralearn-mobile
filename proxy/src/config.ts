/**
 * Centralized, env-driven configuration.
 *
 * INVARIANTS:
 *  - Model IDs are read from env (MODEL_FREE / MODEL_PAID_STD / MODEL_PAID_PRO),
 *    never hardcoded in routing logic (see lib/router.ts). They were resolved at
 *    Phase A Step 0 against the official Claude reference; do NOT invent pricing.
 *  - The Anthropic key is read from env only and is NEVER logged.
 */

export type Plan = "free" | "paid";

/** Plan -> tier label used by the router. A0 default plan is "free". */
export interface AppConfig {
  port: number;
  anthropicApiKey: string;
  models: {
    free: string;
    paidStd: string;
    paidPro: string;
  };
  redisUrl: string | undefined;
  freeDailyQuota: number;
  /**
   * Phase C real auth: HS256 shared secret used to verify account JWTs.
   * The JWT conveys IDENTITY ONLY (userId from `sub`) — never the plan.
   * Empty string => account-JWT verification is disabled (dev token only).
   */
  accountsJwtSecret: string;
  /**
   * Optional dev fallback token (LOCAL DEV ONLY). If set and presented, it is
   * accepted without JWT verification and mapped to a stable content-free userId.
   * Documented in README; do NOT enable in production.
   */
  devAuthToken: string;
  /** IAP receipt-verifier credentials (Phase C). Absent => deterministic mock. */
  iap: {
    appleSharedSecret: string;
    appleIssuerId: string;
    googlePlaySaJson: string;
  };
  /**
   * Max characters of caller-supplied doc `context` stuffed into the upstream
   * request as REFERENCE material (truncated past this; never as instructions).
   */
  maxContextChars: number;
}

function intEnv(name: string, fallback: number): number {
  const raw = process.env[name];
  if (raw === undefined || raw.trim() === "") return fallback;
  const n = Number.parseInt(raw, 10);
  if (Number.isNaN(n) || n < 0) {
    throw new Error(`Invalid integer for env ${name}: ${JSON.stringify(raw)}`);
  }
  return n;
}

export function loadConfig(env: NodeJS.ProcessEnv = process.env): AppConfig {
  return {
    port: intEnv("PORT", 8787),
    anthropicApiKey: env.ANTHROPIC_API_KEY ?? "",
    models: {
      free: env.MODEL_FREE ?? "claude-haiku-4-5-20251001",
      paidStd: env.MODEL_PAID_STD ?? "claude-sonnet-4-6",
      paidPro: env.MODEL_PAID_PRO ?? "claude-opus-4-8",
    },
    redisUrl: env.REDIS_URL && env.REDIS_URL.trim() !== "" ? env.REDIS_URL : undefined,
    freeDailyQuota: intEnv("FREE_DAILY_QUOTA", 3),
    accountsJwtSecret: env.ACCOUNTS_JWT_SECRET ?? "",
    devAuthToken: env.DEV_AUTH_TOKEN ?? "dev-local-token",
    iap: {
      appleSharedSecret: env.APPLE_IAP_SHARED_SECRET ?? "",
      appleIssuerId: env.APPLE_IAP_ISSUER_ID ?? "",
      googlePlaySaJson: env.GOOGLE_PLAY_SA_JSON ?? "",
    },
    maxContextChars: intEnv("MAX_CONTEXT_CHARS", 12000),
  };
}
