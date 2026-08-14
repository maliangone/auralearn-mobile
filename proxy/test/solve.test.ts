import { describe, it, expect } from "vitest";
import { runSolve } from "../src/lib/solve-handler.js";
import { InMemoryMeteringStore } from "../src/lib/metering.js";
import { InMemoryEntitlementStore, type Entitlement } from "../src/lib/entitlement.js";
import type { SolveEvent } from "../src/types.js";
import type { AppConfig } from "../src/config.js";
import type { TutorModel } from "../src/lib/anthropic.js";
import { FakeTutorModel, FailingTutorModel, captureLogger, testConfig } from "./helpers.js";

const SECRET_PROBLEM = "Solve 2x + 3 = 11 for x";
const SECRET_ANSWER = "x equals 4";

function cannedTutorChunks(): string[] {
  // Simulates the model's structured reply, split into stream chunks.
  return [
    `RECOGNIZED: ${SECRET_PROBLEM}\n\n`,
    "思路: Isolate x by undoing the operations in reverse order.\n\n",
    "1. Subtract 3 from both sides: 2x = 8.\n\n",
    "2. Divide both sides by 2: x = 4.\n\n",
    `结论: ${SECRET_ANSWER}.`,
  ];
}

async function collect(
  model: FakeTutorModel | FailingTutorModel,
  opts: {
    /** Client-claimed plan in the request body (NOT trusted for routing). */
    plan?: "free" | "paid";
    userId?: string;
    quota?: number;
    /** Server-side entitlement (authoritative). Default: free. */
    entitlement?: Entitlement;
    /** Optional doc-context to stuff. */
    context?: string;
    /** OpenAI-compatible upstream model (used when a tier resolves to openai). */
    openAiModel?: TutorModel;
    /** Config overrides (e.g. text-only tier for the model_no_vision path). */
    config?: Partial<AppConfig>;
  } = {},
): Promise<{ events: SolveEvent[]; lines: string[]; metered: boolean; model: FakeTutorModel | FailingTutorModel }> {
  const { logger, lines } = captureLogger();
  const config = testConfig({
    ...(opts.quota !== undefined ? { freeDailyQuota: opts.quota } : {}),
    ...(opts.config ?? {}),
  });
  const metering = new InMemoryMeteringStore();
  const entitlementStore = new InMemoryEntitlementStore();
  const userId = opts.userId ?? "user-1";
  if (opts.entitlement) {
    await entitlementStore.setEntitlement(userId, opts.entitlement);
  }
  const events: SolveEvent[] = [];

  const { metered } = await runSolve(
    { config, model, openAiModel: opts.openAiModel, metering, entitlement: entitlementStore, logger },
    {
      userId,
      plan: opts.plan ?? "free",
      images: ["ZmFrZS1iYXNlNjQtaW1hZ2UtYnl0ZXM="],
      subject: "math",
      context: opts.context,
    },
    (e) => {
      events.push(e);
    },
    { reqId: "req-test", route: "/solve" },
  );

  return { events, lines, metered, model };
}

describe("/solve pipeline (mocked Anthropic client)", () => {
  it("emits recognized FIRST and done LAST, with steps in between, in order", async () => {
    const { events, metered } = await collect(new FakeTutorModel(cannedTutorChunks()));

    expect(metered).toBe(true);
    expect(events.length).toBeGreaterThanOrEqual(3);

    // recognized is first
    expect(events[0].type).toBe("recognized");
    // done is last
    expect(events[events.length - 1].type).toBe("done");

    // everything between is steps
    const middle = events.slice(1, -1);
    expect(middle.every((e) => e.type === "step")).toBe(true);

    // step indices are monotonic from 0
    const stepIndices = middle.map((e) => (e.type === "step" ? e.index : -1));
    expect(stepIndices).toEqual(stepIndices.map((_, i) => i));

    // done carries the resolved free-tier model + metered:true
    const done = events[events.length - 1];
    if (done.type === "done") {
      expect(done.model).toBe("claude-haiku-4-5-20251001");
      expect(done.metered).toBe(true);
    }

    // recognized carries the transcribed problem
    const recognized = events[0];
    if (recognized.type === "recognized") {
      expect(recognized.problem).toContain("2x + 3");
    }
  });

  it("routes a paid-entitled user to the standard paid model", async () => {
    const model = new FakeTutorModel(cannedTutorChunks());
    const { events } = await collect(model, {
      entitlement: { plan: "paid", tier: "std" },
    });
    const done = events[events.length - 1];
    expect(done.type).toBe("done");
    if (done.type === "done") expect(done.model).toBe("claude-sonnet-4-6");
    expect(model.lastArgs?.model).toBe("claude-sonnet-4-6");
  });

  it("routes a pro-entitled user to the pro paid model", async () => {
    const model = new FakeTutorModel(cannedTutorChunks());
    const { events } = await collect(model, {
      entitlement: { plan: "paid", tier: "pro" },
    });
    const done = events[events.length - 1];
    if (done.type === "done") expect(done.model).toBe("claude-opus-4-8");
    expect(model.lastArgs?.model).toBe("claude-opus-4-8");
  });

  it("IGNORES a client-sent plan:'paid' for routing — free entitlement still routes to MODEL_FREE", async () => {
    // The request body LIES (claims paid); the entitlement store says free.
    const model = new FakeTutorModel(cannedTutorChunks());
    const { events } = await collect(model, {
      plan: "paid", // untrusted client claim
      entitlement: { plan: "free", tier: "free" },
    });
    const done = events[events.length - 1];
    expect(done.type).toBe("done");
    if (done.type === "done") expect(done.model).toBe("claude-haiku-4-5-20251001");
    // The model actually handed to the (mocked) Anthropic client is the FREE model.
    expect(model.lastArgs?.model).toBe("claude-haiku-4-5-20251001");
  });

  it("stuffs doc-context as delimited REFERENCE and truncates past the cap", async () => {
    const longContext = "C".repeat(20000); // well past the 12000 cap
    const model = new FakeTutorModel(cannedTutorChunks());
    const { model: m } = await collect(model, { context: longContext });
    const sent = (m as FakeTutorModel).lastArgs?.userText ?? "";
    // Delimited as reference material, not instructions.
    expect(sent).toContain("REFERENCE MATERIAL");
    expect(sent).toContain("<<<REFERENCE>>>");
    expect(sent).toContain("<<<END REFERENCE>>>");
    // Truncated: only `maxContextChars` (12000) of the context made it through,
    // and a truncation note is present.
    const cCount = (sent.match(/C/g) ?? []).length;
    expect(cCount).toBeLessThanOrEqual(12000 + 50); // allow a few stray C's from framing
    expect(cCount).toBeGreaterThan(11000);
    expect(sent.toLowerCase()).toContain("truncated");
  });

  it("does not truncate short doc-context and adds no truncation note", async () => {
    const shortContext = "Reference: the quadratic formula is x = (-b ± sqrt(b^2-4ac)) / 2a.";
    const model = new FakeTutorModel(cannedTutorChunks());
    const { model: m } = await collect(model, { context: shortContext });
    const sent = (m as FakeTutorModel).lastArgs?.userText ?? "";
    expect(sent).toContain(shortContext);
    expect(sent.toLowerCase()).not.toContain("was truncated");
  });

  it("routes an openai tier to the openAiModel with the tier's model id", async () => {
    const anthropicModel = new FakeTutorModel(cannedTutorChunks());
    const openAiModel = new FakeTutorModel(cannedTutorChunks());
    const { events } = await collect(anthropicModel, {
      openAiModel,
      config: {
        models: {
          ...testConfig().models,
          free: {
            provider: "openai",
            model: "gpt-5.6-luna",
            reasoningEffort: "max",
            supportsVision: true,
          },
        },
      },
    });

    // The default anthropic model was NOT called.
    expect(anthropicModel.lastArgs).toBeUndefined();
    // The openai model got the tier model + reasoning effort.
    expect(openAiModel.lastArgs?.model).toBe("gpt-5.6-luna");
    expect(openAiModel.lastArgs?.reasoningEffort).toBe("max");
    const done = events[events.length - 1];
    if (done.type === "done") expect(done.model).toBe("gpt-5.6-luna");
  });

  it("rejects images on a text-only tier with model_no_vision BEFORE metering", async () => {
    const textOnlyTier = {
      provider: "openai" as const,
      model: "deepseek-chat",
      reasoningEffort: "",
      supportsVision: false,
    };
    const model = new FakeTutorModel(cannedTutorChunks());
    const openAiModel = new FakeTutorModel(cannedTutorChunks());
    const { events, metered } = await collect(model, {
      openAiModel,
      config: {
        models: {
          ...testConfig().models,
          free: textOnlyTier,
        },
      },
    });

    expect(metered).toBe(false);
    expect(events).toHaveLength(1);
    expect(events[0].type).toBe("error");
    if (events[0].type === "error") expect(events[0].code).toBe("model_no_vision");
    // Neither upstream model was called.
    expect(model.lastArgs).toBeUndefined();
    expect(openAiModel.lastArgs).toBeUndefined();
  });

  it("blocks with quota_exceeded once the daily limit is reached, and makes NO LLM call after", async () => {
    const config = testConfig({ freeDailyQuota: 1 });
    const metering = new InMemoryMeteringStore();
    const entitlement = new InMemoryEntitlementStore();
    const model = new FakeTutorModel(cannedTutorChunks());
    const { logger } = captureLogger();

    const deps = { config, model, metering, entitlement, logger };
    const input = {
      userId: "quota-user",
      plan: "free" as const,
      images: ["YQ=="],
      subject: "math",
    };

    // First call: allowed.
    const first: SolveEvent[] = [];
    await runSolve(deps, input, (e) => {
      first.push(e);
    });
    expect(first[0].type).toBe("recognized");

    // Second call: blocked. The fake model should NOT be invoked again.
    model.lastArgs = undefined;
    const second: SolveEvent[] = [];
    const r2 = await runSolve(deps, input, (e) => {
      second.push(e);
    });

    expect(r2.metered).toBe(false);
    expect(second).toHaveLength(1);
    expect(second[0].type).toBe("error");
    if (second[0].type === "error") expect(second[0].code).toBe("quota_exceeded");
    expect(model.lastArgs).toBeUndefined(); // no LLM call on the blocked request
  });

  it("on mid-stream upstream failure, still counts as exactly ONE metered question", async () => {
    const config = testConfig({ freeDailyQuota: 5 });
    const metering = new InMemoryMeteringStore();
    const entitlement = new InMemoryEntitlementStore();
    const { logger } = captureLogger();
    const events: SolveEvent[] = [];

    const r = await runSolve(
      { config, model: new FailingTutorModel(), metering, entitlement, logger },
      { userId: "abort-user", plan: "free", images: ["YQ=="] },
      (e) => {
        events.push(e);
      },
    );

    expect(r.metered).toBe(true);
    // recognized emitted before failure, then an error event.
    expect(events.some((e) => e.type === "recognized")).toBe(true);
    expect(events[events.length - 1].type).toBe("error");

    // Exactly one decrement happened.
    const rec = await metering.peek("abort-user", new Date().toISOString().slice(0, 10));
    expect(rec?.count).toBe(1);
  });

  it("rejects more than 3 images without calling the model", async () => {
    const config = testConfig();
    const metering = new InMemoryMeteringStore();
    const entitlement = new InMemoryEntitlementStore();
    const model = new FakeTutorModel(cannedTutorChunks());
    const { logger } = captureLogger();
    const events: SolveEvent[] = [];

    const r = await runSolve(
      { config, model, metering, entitlement, logger },
      { userId: "u", plan: "free", images: ["a", "b", "c", "d"] },
      (e) => {
        events.push(e);
      },
    );

    expect(r.metered).toBe(false);
    expect(events).toHaveLength(1);
    expect(events[0].type).toBe("error");
    expect(model.lastArgs).toBeUndefined();
  });
});

describe("no-content-logged invariant", () => {
  it("logs contain NO image bytes, problem text, or answer text", async () => {
    const { lines } = await collect(new FakeTutorModel(cannedTutorChunks()));

    expect(lines.length).toBeGreaterThan(0);
    const joined = lines.join("\n");

    // The problem statement and answer must never appear in logs.
    expect(joined).not.toContain(SECRET_PROBLEM);
    expect(joined).not.toContain(SECRET_ANSWER);
    expect(joined).not.toContain("2x + 3");
    // The base64 image bytes must never appear in logs.
    expect(joined).not.toContain("ZmFrZS1iYXNlNjQtaW1hZ2UtYnl0ZXM=");

    // Every line must be valid JSON metadata only (no surprise fields).
    for (const line of lines) {
      const obj = JSON.parse(line) as Record<string, unknown>;
      expect(obj).toHaveProperty("ts");
      expect(obj).toHaveProperty("level");
      expect(obj).toHaveProperty("msg");
      // No content-bearing keys.
      expect(obj).not.toHaveProperty("images");
      expect(obj).not.toHaveProperty("problem");
      expect(obj).not.toHaveProperty("conclusion");
      expect(obj).not.toHaveProperty("text");
    }
  });
});
