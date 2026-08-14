/**
 * Minimal SSE serialization for the SolveEvent stream.
 *
 * Each event is emitted as one `data: <json>\n\n` frame. The client parses each
 * data line as JSON (the SolveEvent union in types.ts).
 */

import type { SolveEvent } from "../types.js";

/** Serialize one SolveEvent into an SSE frame. */
export function formatSseEvent(event: SolveEvent): string {
  return `data: ${JSON.stringify(event)}\n\n`;
}

/** SSE response headers. */
export const SSE_HEADERS: Record<string, string> = {
  "content-type": "text/event-stream; charset=utf-8",
  "cache-control": "no-cache, no-transform",
  connection: "keep-alive",
  "x-accel-buffering": "no",
};
