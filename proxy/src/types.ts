/**
 * Wire contract types shared by /solve and /chat.
 *
 * These mirror the streaming contract in `.omc/handoffs/team-plan.md` EXACTLY so
 * the Flutter client (W2) can match them 1:1. Any change here is a contract change.
 */

import type { Plan } from "./config.js";

/** Request body for POST /solve and POST /chat. */
export interface SolveRequestBody {
  /** base64-encoded JPEG images (long-edge <= 1568px, <= 3 images). */
  images: string[];
  /** Optional subject hint, e.g. "math" | "physics" | "chemistry". */
  subject?: string;
  /**
   * OPTIONAL client-declared plan. ACCEPTED but NOT TRUSTED: the model is always
   * routed from the server-side entitlement (Phase C). Kept for compatibility.
   */
  plan?: Plan;
  /** Optional free-text follow-up question (used by /chat; /solve may ignore). */
  text?: string;
  /**
   * Optional imported-document text or selected chunk. Stuffed into the upstream
   * request as clearly-delimited REFERENCE material (NOT instructions), capped to
   * MAX_CONTEXT_CHARS server-side.
   */
  context?: string;
}

/**
 * SSE event union emitted on the stream, in this order:
 *   recognized -> step* -> done
 * or, on quota/other failure:
 *   error
 *
 * Each event is serialized as a single SSE `data:` line of JSON.
 */
export type SolveEvent =
  | RecognizedEvent
  | StepEvent
  | DoneEvent
  | ErrorEvent;

/** FIRST event: the vision model's read of the problem (read-accuracy surface). */
export interface RecognizedEvent {
  type: "recognized";
  /** The transcribed problem statement as the model read it from the image(s). */
  problem: string;
}

/** Streamed reasoning steps (思路 -> 步骤). `index` is 0-based and monotonic. */
export interface StepEvent {
  type: "step";
  index: number;
  content: string;
}

/** LAST success event: the conclusion + which model served it. */
export interface DoneEvent {
  type: "done";
  conclusion: string;
  model: string;
  /** Always true: a started /solve counts as exactly ONE metered question. */
  metered: true;
}

/** Error event (e.g. quota). On quota: code = "quota_exceeded". */
export interface ErrorEvent {
  type: "error";
  code: ErrorCode;
  message: string;
}

export type ErrorCode =
  | "quota_exceeded"
  | "unauthorized"
  | "bad_request"
  | "upstream_error"
  | "internal_error"
  /** The resolved tier model is text-only but the request carried images. */
  | "model_no_vision";
