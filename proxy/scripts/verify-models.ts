/**
 * Phase A Step 0 GATE — verify-models.
 *
 * RUNNABLE script: given ANTHROPIC_API_KEY, it calls the Anthropic Models API to
 * assert each configured model (MODEL_FREE / MODEL_PAID_STD / MODEL_PAID_PRO)
 * exists and supports IMAGE INPUT, and reports max input tokens + max output
 * tokens. Prints a clear PASS/FAIL per model and an overall verdict.
 *
 * This REQUIRES the user's real key. DO NOT run it in CI without a key. It must
 * PASS before production (records the resolved model-ID + per-tier vision verdict
 * for the ADR Step-0 field).
 *
 * Usage:
 *   ANTHROPIC_API_KEY=sk-ant-... npm run verify-models
 */

import Anthropic from "@anthropic-ai/sdk";
import { loadConfig } from "../src/config.js";

interface ModelVerdict {
  label: string;
  id: string;
  exists: boolean;
  imageInput: boolean | "unknown";
  maxInputTokens: number | undefined;
  maxOutputTokens: number | undefined;
  error?: string;
}

function readImageCapability(model: unknown): boolean | "unknown" {
  // The Models API returns a `capabilities` tree with leaves `{ supported: bool }`.
  // image_input may be absent on older API versions -> "unknown".
  const caps = (model as { capabilities?: Record<string, unknown> }).capabilities;
  if (!caps || typeof caps !== "object") return "unknown";
  const img = (caps as Record<string, { supported?: boolean }>)["image_input"];
  if (!img || typeof img.supported !== "boolean") return "unknown";
  return img.supported;
}

async function checkModel(client: Anthropic, label: string, id: string): Promise<ModelVerdict> {
  try {
    const model = await client.models.retrieve(id);
    const m = model as unknown as {
      id: string;
      max_input_tokens?: number;
      max_tokens?: number;
    };
    return {
      label,
      id,
      exists: true,
      imageInput: readImageCapability(model),
      maxInputTokens: m.max_input_tokens,
      maxOutputTokens: m.max_tokens,
    };
  } catch (err) {
    return {
      label,
      id,
      exists: false,
      imageInput: "unknown",
      maxInputTokens: undefined,
      maxOutputTokens: undefined,
      error: err instanceof Error ? err.message : String(err),
    };
  }
}

function printVerdict(v: ModelVerdict): boolean {
  // A model passes the Step-0 gate if it exists AND image input is supported
  // (or unknown — older API versions don't expose the capability tree, in which
  // case the operator must confirm vision manually; we surface that as WARN).
  const visionOk = v.imageInput === true;
  const visionUnknown = v.imageInput === "unknown";
  const pass = v.exists && (visionOk || visionUnknown);

  const status = !v.exists ? "FAIL" : visionOk ? "PASS" : visionUnknown ? "WARN" : "FAIL";
  console.log(`\n[${status}] ${v.label} = ${v.id}`);
  if (!v.exists) {
    console.log(`  - model does NOT exist / not retrievable: ${v.error ?? "unknown error"}`);
    return false;
  }
  console.log(`  - exists: yes`);
  console.log(
    `  - image input: ${
      visionOk ? "SUPPORTED" : visionUnknown ? "UNKNOWN (confirm manually)" : "NOT supported"
    }`,
  );
  console.log(`  - max input tokens: ${v.maxInputTokens ?? "unknown"}`);
  console.log(`  - max output tokens: ${v.maxOutputTokens ?? "unknown"}`);
  if (visionUnknown) {
    console.log(`  - NOTE: capabilities tree absent; manually confirm vision before prod.`);
  }
  if (v.imageInput === false) {
    console.log(`  - GATE FAILURE: this tier requires vision (all tiers are vision-mandated).`);
  }
  return pass;
}

async function main(): Promise<void> {
  const config = loadConfig();
  if (!config.anthropicApiKey) {
    console.error(
      "verify-models: ANTHROPIC_API_KEY is required. This script needs the real " +
        "key and must PASS before production. Aborting.",
    );
    process.exit(2);
  }

  const client = new Anthropic({ apiKey: config.anthropicApiKey });

  console.log("AuraLearn proxy — Phase A Step 0 model verification");
  console.log("Configured model IDs (from env):");
  console.log(`  free     = ${config.models.free}`);
  console.log(`  paid std = ${config.models.paidStd}`);
  console.log(`  paid pro = ${config.models.paidPro}`);

  const verdicts = await Promise.all([
    checkModel(client, "free (Haiku 4.5)", config.models.free),
    checkModel(client, "paid std (Sonnet 4.6)", config.models.paidStd),
    checkModel(client, "paid pro (Opus 4.8)", config.models.paidPro),
  ]);

  let allPass = true;
  for (const v of verdicts) {
    const ok = printVerdict(v);
    allPass = allPass && ok;
  }

  console.log("\n========================================");
  if (allPass) {
    console.log("OVERALL: PASS — all configured models exist and are vision-capable (or pending manual confirm).");
    console.log("Record these results in the ADR Step-0 'resolved model-ID verdict' field.");
    process.exit(0);
  } else {
    console.log("OVERALL: FAIL — at least one model is missing or lacks vision. Do NOT ship proxy /solve.");
    process.exit(1);
  }
}

main().catch((err) => {
  console.error("verify-models crashed:", err);
  process.exit(3);
});
