import { describe, it, expect } from "vitest";
import { loadConfig } from "../src/config.js";

const base = {
  ANTHROPIC_API_KEY: "sk-ant-test",
  OPENAI_API_KEY: "sk-openai-test",
  PORT: "0",
  ACCOUNTS_JWT_SECRET: "secret",
} as NodeJS.ProcessEnv;

describe("loadConfig — provider-agnostic tiers", () => {
  it("defaults to the OpenAI gpt-5.6-luna stack with reasoning max", () => {
    const config = loadConfig({ ...base });
    expect(config.models.free).toMatchObject({
      provider: "openai",
      model: "gpt-5.6-luna",
      reasoningEffort: "max",
      supportsVision: true,
    });
    expect(config.models.paidStd.model).toBe("gpt-5.6-luna");
    expect(config.models.paidPro.model).toBe("gpt-5.6-luna");
  });

  it("legacy MODEL_* envs select the anthropic provider (backward compat)", () => {
    const config = loadConfig({
      ...base,
      MODEL_FREE: "claude-haiku-4-5-20251001",
      MODEL_PAID_STD: "claude-sonnet-4-6",
      MODEL_PAID_PRO: "claude-opus-4-8",
    });
    expect(config.models.free).toMatchObject({
      provider: "anthropic",
      model: "claude-haiku-4-5-20251001",
      reasoningEffort: "",
      supportsVision: true,
    });
  });

  it("per-tier overrides win over defaults; deepseek base URL infers text-only", () => {
    const config = loadConfig({
      ...base,
      OPENAI_BASE_URL: "https://api.deepseek.com",
      STD_MODEL: "deepseek-chat",
    });
    expect(config.models.free).toMatchObject({
      provider: "openai",
      model: "gpt-5.6-luna",
      supportsVision: false, // deepseek base URL => text-only, even for the free tier
      reasoningEffort: "", // non-openai.com host does not default to max
    });
    expect(config.models.paidStd.model).toBe("deepseek-chat");
  });

  it("explicit *_SUPPORTS_VISION overrides inference", () => {
    const config = loadConfig({
      ...base,
      OPENAI_BASE_URL: "https://api.deepseek.com",
      STD_MODEL: "deepseek-chat",
      STD_SUPPORTS_VISION: "true",
    });
    expect(config.models.paidStd.supportsVision).toBe(true);
  });

  it("per-tier provider switch is honored", () => {
    const config = loadConfig({
      ...base,
      FREE_PROVIDER: "anthropic",
      FREE_MODEL: "claude-haiku-4-5-20251001",
    });
    expect(config.models.free).toMatchObject({
      provider: "anthropic",
      model: "claude-haiku-4-5-20251001",
    });
    // Other tiers stay on the openai default.
    expect(config.models.paidStd.provider).toBe("openai");
  });
});
