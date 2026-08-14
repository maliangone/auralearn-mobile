/**
 * Centralized, env-driven configuration.
 *
 * INVARIANTS:
 *  - Per-tier model routing (free/std/pro) is env-driven and provider-agnostic:
 *    each tier resolves to { provider, model, reasoningEffort, supportsVision }
 *    plus global per-provider { baseUrl, apiKey }. Model IDs are never hardcoded
 *    in routing logic (see lib/router.ts). Do NOT invent pricing.
 *  - Vendor keys are read from env only and are NEVER logged.
 *  - Backward compat: the legacy MODEL_FREE / MODEL_PAID_STD / MODEL_PAID_PRO
 *    envs select the anthropic provider with those model IDs. Absent those,
 *    the default stack is OpenAI gpt-5.6-luna (vision, reasoning max) — the
 *    photo-solving lane — and DeepSeek is available as a text-only lane via
 *    explicit per-tier env.
 */

export type Plan = "free" | "paid";

/** Upstream vendor families the proxy can stream from. */
export type Provider = "anthropic" | "openai";

/** Global connection settings for one vendor family. */
export interface ProviderSettings {
  baseUrl: string;
  apiKey: string;
}

/** Per-tier routing target. */
export interface TierConfig {
  provider: Provider;
  model: string;
  /**
   * OpenAI-compatible `reasoning_effort` (none/low/medium/high/xhigh/max);
   * "" = omit the field. Anthropic tiers ignore it.
   */
  reasoningEffort: string;
  /**
   * false = known text-only model (e.g. deepseek-chat). /solve requests with
   * images are rejected with `model_no_vision` BEFORE metering; text-only
   * `/chat` requests still work.
   */
  supportsVision: boolean;
}

/** Plan -> tier label used by the router. A0 default plan is "free". */
export interface AppConfig {
  port: number;
  /** Per-vendor connection settings (keys NEVER logged). */
  providers: Record<Provider, ProviderSettings>;
  models: {
    free: TierConfig;
    paidStd: TierConfig;
    paidPro: TierConfig;
  };
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
  /** Firebase (Phase 3): project id; empty => Firebase verification disabled. */
  firebaseProjectId: string;
  /** RevenueCat (Phase 3): API + webhook credentials. Absent => dev mocks. */
  revenuecat: {
    apiKey: string;
    webhookSecret: string;
    webhookHmacSecret: string;
  };
  /**
   * Max characters of caller-supplied doc `context` stuffed into the upstream
   * request as REFERENCE material (truncated past this; never as instructions).
   */
  maxContextChars: number;
}

function intEnv(env: NodeJS.ProcessEnv, name: string, fallback: number): number {
  const raw = env[name];
  if (raw === undefined || raw.trim() === "") return fallback;
  const n = Number.parseInt(raw, 10);
  if (Number.isNaN(n) || n < 0) {
    throw new Error(`Invalid integer for env ${name}: ${JSON.stringify(raw)}`);
  }
  return n;
}

function strEnv(env: NodeJS.ProcessEnv, name: string, fallback: string): string {
  const raw = env[name];
  if (raw === undefined || raw.trim() === "") return fallback;
  return raw;
}

const LEGACY_MODELS: Record<"free" | "paidStd" | "paidPro", string> = {
  free: "MODEL_FREE",
  paidStd: "MODEL_PAID_STD",
  paidPro: "MODEL_PAID_PRO",
};

const TIER_PREFIXES: Record<"free" | "paidStd" | "paidPro", string> = {
  free: "FREE",
  paidStd: "STD",
  paidPro: "PRO",
};

const ANTHROPIC_DEFAULT_MODELS: Record<"free" | "paidStd" | "paidPro", string> = {
  free: "claude-haiku-4-5-20251001",
  paidStd: "claude-sonnet-4-6",
  paidPro: "claude-opus-4-8",
};

const OPENAI_DEFAULT_MODEL = "gpt-5.6-luna";

/** Default OpenAI base URL whose models support `reasoning_effort: "max"`. */
const DEFAULT_OPENAI_BASE_URL = "https://api.openai.com/v1";

function inferSupportsVision(provider: Provider, baseUrl: string): boolean {
  if (provider === "anthropic") return true;
  // DeepSeek's official chat API is text-only; anything else is assumed to
  // support images (the operator can pin it explicitly via *_SUPPORTS_VISION).
  return !baseUrl.includes("deepseek");
}

/**
 * Resolve one tier from env. Legacy MODEL_* vars select the anthropic provider
 * (backward compat); without them the default stack is OpenAI.
 */
function loadTierConfig(
  env: NodeJS.ProcessEnv,
  tier: "free" | "paidStd" | "paidPro",
  providers: Record<Provider, ProviderSettings>,
): TierConfig {
  const p = TIER_PREFIXES[tier];
  const legacyModel = env[LEGACY_MODELS[tier]];
  const providerRaw = strEnv(env, `${p}_PROVIDER`, "");
  const provider: Provider =
    providerRaw === "anthropic" || providerRaw === "openai"
      ? providerRaw
      : legacyModel
        ? "anthropic"
        : "openai";

  const baseUrl = providers[provider].baseUrl;
  const model = strEnv(
    env, `${p}_MODEL`,
    legacyModel ?? (provider === "anthropic" ? ANTHROPIC_DEFAULT_MODELS[tier] : OPENAI_DEFAULT_MODEL),
  );

  // reasoning_effort defaults to "max" only on the official OpenAI endpoint
  // (gpt-5.6-luna supports it); other OpenAI-compatible hosts may not, so they
  // must opt in explicitly.
  const reasoningDefault =
    provider === "openai" && baseUrl === DEFAULT_OPENAI_BASE_URL ? "max" : "";
  const reasoningEffort = strEnv(env, `${p}_REASONING_EFFORT`, reasoningDefault);

  const visionRaw = strEnv(env, `${p}_SUPPORTS_VISION`, "");
  const supportsVision =
    visionRaw === "true" || visionRaw === "false"
      ? visionRaw === "true"
      : inferSupportsVision(provider, baseUrl);

  return { provider, model, reasoningEffort, supportsVision };
}

export function loadConfig(env: NodeJS.ProcessEnv = process.env): AppConfig {
  const providers: Record<Provider, ProviderSettings> = {
    anthropic: {
      baseUrl: strEnv(env, "ANTHROPIC_BASE_URL", "https://api.anthropic.com"),
      apiKey: env.ANTHROPIC_API_KEY ?? "",
    },
    openai: {
      baseUrl: strEnv(env, "OPENAI_BASE_URL", DEFAULT_OPENAI_BASE_URL),
      apiKey: env.OPENAI_API_KEY ?? "",
    },
  };

  return {
    port: intEnv(env, "PORT", 8787),
    providers,
    models: {
      free: loadTierConfig(env, "free", providers),
      paidStd: loadTierConfig(env, "paidStd", providers),
      paidPro: loadTierConfig(env, "paidPro", providers),
    },
    freeDailyQuota: intEnv(env, "FREE_DAILY_QUOTA", 3),
    accountsJwtSecret: env.ACCOUNTS_JWT_SECRET ?? "",
    devAuthToken: env.DEV_AUTH_TOKEN ?? "dev-local-token",
    firebaseProjectId: env.FIREBASE_PROJECT_ID ?? "",
    revenuecat: {
      apiKey: env.REVENUECAT_API_KEY ?? "",
      webhookSecret: env.REVENUECAT_WEBHOOK_SECRET ?? "",
      webhookHmacSecret: env.REVENUECAT_WEBHOOK_HMAC_SECRET ?? "",
    },
    maxContextChars: intEnv(env, "MAX_CONTEXT_CHARS", 12000),
  };
}
