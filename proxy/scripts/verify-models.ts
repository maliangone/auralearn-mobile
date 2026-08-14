/**
 * Phase A Step 0 GATE — verify-models (provider-agnostic).
 *
 * RUNNABLE script: for every configured tier it verifies the resolved model
 * exists on its provider and reports vision capability + token limits where
 * the provider exposes them:
 *   - anthropic: Models API (`client.models.retrieve`) -> capabilities tree.
 *   - openai:    GET {baseUrl}/models -> id membership. Vision is NOT exposed
 *                by that endpoint, so it is checked against the tier's own
 *                `*_SUPPORTS_VISION` config: a photo-solving tier flagged
 *                text-only FAILS the gate; a text-only lane (deepseek) passes
 *                existence-only with a WARN.
 *
 * This REQUIRES the user's real keys. DO NOT run it in CI without keys. It must
 * PASS before production (records the resolved model-ID + per-tier vision
 * verdict for the ADR Step-0 field).
 *
 * Usage:
 *   ANTHROPIC_API_KEY=... OPENAI_API_KEY=... npm run verify-models
 */

import Anthropic from "@anthropic-ai/sdk";
import { loadConfig, type TierConfig } from "../src/config.js";

interface ModelVerdict {
  label: string;
  provider: string;
  id: string;
  exists: boolean;
  imageInput: boolean | "unknown";
  maxInputTokens: number | undefined;
  maxOutputTokens: number | undefined;
  visionExpected: boolean;
  error?: string;
}

function readImageCapability(model: unknown): boolean | "unknown" {
  // The Anthropic Models API returns a `capabilities` tree with leaves
  // `{ supported: bool }`. image_input may be absent on older API versions.
  const caps = (model as { capabilities?: Record<string, unknown> }).capabilities;
  if (!caps || typeof caps !== "object") return "unknown";
  const img = (caps as Record<string, { supported?: boolean }>)["image_input"];
  if (!img || typeof img.supported !== "boolean") return "unknown";
  return img.supported;
}

async function checkAnthropic(
  apiKey: string,
  label: string,
  tier: TierConfig,
): Promise<ModelVerdict> {
  const client = new Anthropic({ apiKey });
  try {
    const model = await client.models.retrieve(tier.model);
    const m = model as unknown as {
      id: string;
      max_input_tokens?: number;
      max_tokens?: number;
    };
    return {
      label,
      provider: "anthropic",
      id: tier.model,
      exists: true,
      imageInput: readImageCapability(model),
      maxInputTokens: m.max_input_tokens,
      maxOutputTokens: m.max_tokens,
      visionExpected: tier.supportsVision,
    };
  } catch (err) {
    return {
      label,
      provider: "anthropic",
      id: tier.model,
      exists: false,
      imageInput: "unknown",
      maxInputTokens: undefined,
      maxOutputTokens: undefined,
      visionExpected: tier.supportsVision,
      error: err instanceof Error ? err.message : String(err),
    };
  }
}

async function checkOpenAi(
  apiKey: string,
  baseUrl: string,
  label: string,
  tier: TierConfig,
): Promise<ModelVerdict> {
  try {
    const res = await fetch(`${baseUrl.replace(/\/+$/, "")}/models`, {
      headers: { Authorization: `Bearer ${apiKey}` },
    });
    if (!res.ok) {
      return {
        label,
        provider: "openai",
        id: tier.model,
        exists: false,
        imageInput: "unknown",
        maxInputTokens: undefined,
        maxOutputTokens: undefined,
        visionExpected: tier.supportsVision,
        error: `models list returned HTTP ${res.status}`,
      };
    }
    const json = (await res.json()) as { data?: Array<{ id: string }> };
    const ids = new Set((json.data ?? []).map((m) => m.id));
    return {
      label,
      provider: "openai",
      id: tier.model,
      exists: ids.has(tier.model),
      // The /models endpoint does not expose vision; the tier's own config
      // is the authority (checked against visionExpected below).
      imageInput: "unknown",
      maxInputTokens: undefined,
      maxOutputTokens: undefined,
      visionExpected: tier.supportsVision,
    };
  } catch (err) {
    return {
      label,
      provider: "openai",
      id: tier.model,
      exists: false,
      imageInput: "unknown",
      maxInputTokens: undefined,
      maxOutputTokens: undefined,
      visionExpected: tier.supportsVision,
      error: err instanceof Error ? err.message : String(err),
    };
  }
}

function printVerdict(v: ModelVerdict): boolean {
  const visionOk = v.imageInput === true;
  const visionUnknown = v.imageInput === "unknown";
  const visionMismatch = visionOk === false && v.visionExpected;

  // Pass conditions:
  //  - exists, AND
  //  - (a) vision confirmed OK, or (b) vision unknown (manual confirm), or
  //    (c) vision not expected (deliberate text-only lane).
  const pass = v.exists && !visionMismatch;

  const status = !v.exists
    ? "FAIL"
    : visionMismatch
      ? "FAIL"
      : visionOk
        ? "PASS"
        : visionUnknown && v.visionExpected
          ? "WARN"
          : "PASS (text-only lane)";

  console.log(`\n[${status}] ${v.label} = ${v.id} (${v.provider})`);
  if (!v.exists) {
    console.log(`  - model does NOT exist / not retrievable: ${v.error ?? "unknown error"}`);
    return false;
  }
  console.log(`  - exists: yes`);
  if (v.visionExpected) {
    console.log(
      `  - image input: ${
        visionOk ? "SUPPORTED" : visionUnknown ? "UNKNOWN (confirm manually)" : "NOT supported"
      }`,
    );
    if (visionUnknown) {
      console.log(`  - NOTE: provider does not expose vision capability; confirm manually before prod.`);
    }
    if (visionMismatch) {
      console.log(`  - GATE FAILURE: this tier is vision-mandated but the model reports no image input.`);
    }
  } else {
    console.log(`  - image input: NOT expected (configured text-only lane)`);
  }
  if (v.maxInputTokens !== undefined) console.log(`  - max input tokens: ${v.maxInputTokens}`);
  if (v.maxOutputTokens !== undefined) console.log(`  - max output tokens: ${v.maxOutputTokens}`);
  return pass;
}

async function main(): Promise<void> {
  const config = loadConfig();

  console.log("AuraLearn proxy — model verification (per tier)");
  console.log("Configured tiers (from env):");
  for (const [label, tier] of Object.entries(config.models) as Array<[string, TierConfig]>) {
    console.log(
      `  ${label.padEnd(8)} = ${tier.model} (${tier.provider}, vision=${tier.supportsVision}, ` +
        `reasoningEffort=${tier.reasoningEffort || "-"})`,
    );
  }

  const verdicts: ModelVerdict[] = [];
  for (const [label, tier] of Object.entries(config.models) as Array<[string, TierConfig]>) {
    if (tier.provider === "anthropic") {
      if (!config.providers.anthropic.apiKey) {
        console.error(`\nverify-models: ANTHROPIC_API_KEY is required for tier ${label}.`);
        process.exit(2);
      }
      verdicts.push(await checkAnthropic(config.providers.anthropic.apiKey, label, tier));
    } else {
      if (!config.providers.openai.apiKey) {
        console.error(`\nverify-models: OPENAI_API_KEY is required for tier ${label}.`);
        process.exit(2);
      }
      verdicts.push(
        await checkOpenAi(
          config.providers.openai.apiKey,
          config.providers.openai.baseUrl,
          label,
          tier,
        ),
      );
    }
  }

  let allPass = true;
  for (const v of verdicts) {
    const ok = printVerdict(v);
    allPass = allPass && ok;
  }

  console.log("\n========================================");
  if (allPass) {
    console.log(
      "OVERALL: PASS — all configured tier models exist; vision either confirmed, " +
        "pending manual confirm, or deliberately text-only.",
    );
    console.log("Record these results in the ADR Step-0 'resolved model-ID verdict' field.");
    process.exit(0);
  } else {
    console.log("OVERALL: FAIL — at least one tier model is missing or lacks required vision.");
    process.exit(1);
  }
}

main().catch((err) => {
  console.error("verify-models crashed:", err);
  process.exit(3);
});
