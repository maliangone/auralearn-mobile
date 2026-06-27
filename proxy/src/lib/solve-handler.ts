/**
 * Core solve/chat pipeline — transport-agnostic so it is directly unit-testable
 * AND drivable by the Fastify route.
 *
 * Responsibilities, in order:
 *   1. Validate the request body (images count/shape, plan).
 *   2. Resolve the upstream model from the plan (router; env-driven).
 *   3. Meter FIRST (atomic increment) — a started solve = ONE question even if
 *      aborted mid-stream (Critic M2). On quota deny -> emit error, no LLM call.
 *   4. Stream the tutor model; parse the stream into ordered SolveEvents:
 *        recognized (FIRST) -> step* -> done (LAST).
 *   5. Log metadata only (no content). Errors -> error event.
 *
 * It NEVER logs image bytes or problem/answer text.
 */

import type { AppConfig, Plan } from "../config.js";
import type { SolveEvent } from "../types.js";
import type { TutorModel } from "./anthropic.js";
import type { MeteringStore } from "./metering.js";
import type { Logger } from "./logger.js";
import type { EntitlementStore } from "./entitlement.js";
import { resolveModelFromEntitlement } from "./router.js";
import { todayUtc } from "./metering.js";
import {
  TUTOR_SYSTEM_PROMPT,
  TUTOR_PROMPT_VERSION,
  buildUserFraming,
  buildContextBlock,
} from "../prompts/tutor.js";

const MAX_IMAGES = 3;
const MAX_TOKENS = 2048;

export interface SolveDeps {
  config: AppConfig;
  model: TutorModel;
  metering: MeteringStore;
  entitlement: EntitlementStore;
  logger: Logger;
}

export interface SolveInput {
  userId: string;
  /**
   * Client-declared plan. ACCEPTED but NOT TRUSTED for routing — the model is
   * always resolved from the server-side EntitlementStore. Kept only for the log
   * line / backwards compatibility.
   */
  plan?: Plan;
  images: string[];
  subject?: string;
  /** Optional follow-up text (used by /chat). */
  text?: string;
  /**
   * Optional imported-document text / selected chunk. Stuffed into the upstream
   * request as clearly-delimited REFERENCE material (NOT instructions), capped to
   * config.maxContextChars.
   */
  context?: string;
}

/** A sink that receives ordered SolveEvents. */
export type Emit = (event: SolveEvent) => void | Promise<void>;

interface ValidationError {
  message: string;
}

function validate(input: SolveInput): ValidationError | undefined {
  // `plan` is accepted but NOT trusted for routing (entitlement is authoritative).
  // We still reject an explicitly malformed value to keep the contract honest.
  if (input.plan !== undefined && input.plan !== "free" && input.plan !== "paid") {
    return { message: "plan, if provided, must be 'free' or 'paid'" };
  }
  if (!Array.isArray(input.images)) {
    return { message: "images must be an array of base64 strings" };
  }
  if (input.images.length === 0 && !input.text) {
    return { message: "at least one image or text is required" };
  }
  if (input.images.length > MAX_IMAGES) {
    return { message: `at most ${MAX_IMAGES} images are allowed` };
  }
  for (const img of input.images) {
    if (typeof img !== "string" || img.length === 0) {
      return { message: "each image must be a non-empty base64 string" };
    }
  }
  return undefined;
}

/**
 * Parse a streaming tutor text into ordered SolveEvents.
 *
 * The model is asked (in the user framing) to start with a `RECOGNIZED: ...` line
 * and then number its steps. We parse incrementally:
 *   - Everything up to the first newline after "RECOGNIZED:" becomes the
 *     `recognized` event (emitted FIRST).
 *   - Subsequent content is split into steps on blank lines / numbered markers and
 *     streamed as `step` events.
 *   - The final accumulated tail becomes the `conclusion` in `done`.
 *
 * This parser is deliberately tolerant: if the model never emits "RECOGNIZED:",
 * we still emit a recognized event (best-effort first line) so the contract
 * ordering (recognized first, done last) always holds.
 */
class StreamParser {
  private buffer = "";
  private recognizedEmitted = false;
  private stepIndex = 0;
  private full = "";

  constructor(private readonly emit: Emit) {}

  async push(text: string): Promise<void> {
    this.full += text;
    this.buffer += text;

    if (!this.recognizedEmitted) {
      // Wait until we have a full first line (or a clear RECOGNIZED line).
      const newlineIdx = this.buffer.indexOf("\n");
      if (newlineIdx === -1) return; // need more
      const firstLine = this.buffer.slice(0, newlineIdx).trim();
      const rest = this.buffer.slice(newlineIdx + 1);
      const problem = firstLine.replace(/^RECOGNIZED:\s*/i, "").trim();
      await this.emit({ type: "recognized", problem: problem || "(problem read pending)" });
      this.recognizedEmitted = true;
      this.buffer = rest;
    }

    // Emit complete step segments. A segment ends at a blank line boundary.
    await this.flushSteps(false);
  }

  private async flushSteps(final: boolean): Promise<void> {
    // Split on double-newline boundaries; keep the last partial in the buffer
    // unless this is the final flush.
    const parts = this.buffer.split(/\n\s*\n/);
    const completeUpTo = final ? parts.length : parts.length - 1;
    for (let i = 0; i < completeUpTo; i++) {
      const segment = parts[i].trim();
      if (segment.length === 0) continue;
      await this.emit({ type: "step", index: this.stepIndex++, content: segment });
    }
    this.buffer = final ? "" : parts[parts.length - 1] ?? "";
  }

  /** Finish: ensure recognized emitted, flush remaining steps, return conclusion. */
  async finish(): Promise<string> {
    if (!this.recognizedEmitted) {
      const firstLine = (this.full.split("\n")[0] ?? "").replace(/^RECOGNIZED:\s*/i, "").trim();
      await this.emit({ type: "recognized", problem: firstLine || "(problem read unavailable)" });
      this.recognizedEmitted = true;
    }
    // The final remaining buffer is the conclusion-ish tail; flush prior steps.
    const tail = this.buffer.trim();
    this.buffer = "";
    // Flush any complete steps left, treating everything as final.
    if (tail.length > 0) {
      // Heuristic: a 结论/Conclusion segment, otherwise just the tail, becomes the
      // conclusion. We do NOT emit it as a step.
    }
    return tail.length > 0 ? tail : "See steps above.";
  }
}

/**
 * Run the solve/chat pipeline. Returns true if the question was metered (a
 * stream began), false if it was denied/invalid before any LLM call.
 */
export async function runSolve(
  deps: SolveDeps,
  input: SolveInput,
  emit: Emit,
  opts: { reqId?: string; route?: string } = {},
): Promise<{ metered: boolean }> {
  const { config, model, metering, entitlement, logger } = deps;

  // 1. Validate (before touching the entitlement store / metering).
  const invalid = validate(input);
  if (invalid) {
    logger
      .child({ reqId: opts.reqId, route: opts.route, userId: input.userId })
      .warn("request rejected: invalid", { code: "bad_request", event: "validate" });
    await emit({ type: "error", code: "bad_request", message: invalid.message });
    return { metered: false };
  }

  // 2. AUTHORITATIVE routing: resolve the model from the server-side entitlement.
  //    The client-sent `plan` is IGNORED for routing.
  const ent = await entitlement.getEntitlement(input.userId);
  const resolvedModel = resolveModelFromEntitlement(config, ent);

  const log = logger.child({
    reqId: opts.reqId,
    route: opts.route,
    userId: input.userId,
    plan: ent.plan, // the RESOLVED plan, not the claimed one
    imageCount: input.images.length,
  });
  const startedAt = Date.now();

  // 3. Meter FIRST (atomic). A started solve = ONE question even if aborted.
  //    Quota is keyed to the resolved plan: free => FREE_DAILY_QUOTA; paid =>
  //    effectively unlimited in this lane (entitlement is the real gate).
  const day = todayUtc();
  const limit = ent.plan === "free" ? config.freeDailyQuota : Number.MAX_SAFE_INTEGER;
  const inc = await metering.incrementIfAllowed({
    userId: input.userId,
    model: resolvedModel,
    day,
    limit,
  });
  if (!inc.allowed) {
    log.info("quota exceeded", {
      code: "quota_exceeded",
      event: "meter",
      model: resolvedModel,
      used: inc.used,
      limit: inc.limit,
    });
    await emit({
      type: "error",
      code: "quota_exceeded",
      message: `Daily question limit reached (${inc.limit}/day). Upgrade for more.`,
    });
    return { metered: false };
  }
  log.info("metered question", {
    event: "meter",
    model: resolvedModel,
    used: inc.used,
    limit: inc.limit,
    promptVersion: TUTOR_PROMPT_VERSION,
  });

  // 4. Stream tutor model -> ordered SolveEvents
  const parser = new StreamParser(emit);
  try {
    // Build the user turn: framing + optional doc-context (as untrusted REFERENCE,
    // capped) + optional follow-up text.
    let userText = buildUserFraming(input.subject);
    if (typeof input.context === "string" && input.context.length > 0) {
      const cap = config.maxContextChars;
      const truncated = input.context.length > cap;
      const safeContext = truncated ? input.context.slice(0, cap) : input.context;
      userText += `\n\n${buildContextBlock(safeContext, truncated)}`;
      log.info("doc-context attached", {
        event: "context",
        // metadata only — never the context text itself
        used: safeContext.length,
        limit: cap,
      });
    }
    if (input.text) {
      userText += `\n\nFollow-up: ${input.text}`;
    }
    const chunks = model.streamTutor({
      model: resolvedModel,
      system: TUTOR_SYSTEM_PROMPT,
      userText,
      images: input.images,
      maxTokens: MAX_TOKENS,
    });
    for await (const chunk of chunks) {
      await parser.push(chunk.text);
    }
    const conclusion = await parser.finish();
    await emit({ type: "done", conclusion, model: resolvedModel, metered: true });
    log.info("solve complete", {
      event: "done",
      model: resolvedModel,
      durationMs: Date.now() - startedAt,
    });
    return { metered: true };
  } catch (err) {
    // The question was already metered (stream began / attempted). Emit an error
    // event but do NOT refund — a started solve is metered once (Critic M2).
    log.error("upstream error during stream", {
      event: "error",
      code: "upstream_error",
      model: resolvedModel,
      durationMs: Date.now() - startedAt,
    });
    await emit({
      type: "error",
      code: "upstream_error",
      message: "The tutor service failed mid-answer. Please try again.",
    });
    return { metered: true };
  }
}
