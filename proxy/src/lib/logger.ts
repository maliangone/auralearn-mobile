/**
 * Structured logging with REDACTION.
 *
 * INVARIANT (architecture acceptance bar): logs NEVER contain user content —
 * no image bytes, no problem text, no answer text. Only metadata may be logged
 * (userId, model, plan, event type, counters, timings, error codes).
 *
 * To make this enforceable AND testable, all log output goes through `log()`,
 * which (a) only accepts an allowlisted set of metadata fields and (b) runs a
 * defensive scrubber that strips anything resembling content (base64 blobs,
 * long free-text). A test asserts no content leaks (test/logging.test.ts).
 */

export type LogLevel = "debug" | "info" | "warn" | "error";

/** Allowlisted metadata fields. Anything else is dropped before serialization. */
export interface LogMeta {
  reqId?: string;
  userId?: string;
  plan?: string;
  model?: string;
  provider?: string;
  route?: string;
  event?: string;
  code?: string;
  durationMs?: number;
  imageCount?: number;
  used?: number;
  limit?: number;
  status?: number;
  promptVersion?: string;
}

const ALLOWED_KEYS: ReadonlySet<keyof LogMeta> = new Set<keyof LogMeta>([
  "reqId",
  "userId",
  "plan",
  "model",
  "provider",
  "route",
  "event",
  "code",
  "durationMs",
  "imageCount",
  "used",
  "limit",
  "status",
  "promptVersion",
]);

/**
 * Defensive scrubber: even within allowlisted string fields, refuse to emit
 * values that look like content (base64 image blobs or long free text).
 */
function scrubValue(value: unknown): unknown {
  if (typeof value !== "string") return value;
  // Long strings are never legitimate metadata — truncate hard.
  if (value.length > 120) return "[redacted:too-long]";
  // base64-ish blobs (image bytes) — redact even if short-ish.
  if (/^[A-Za-z0-9+/=]{64,}$/.test(value)) return "[redacted:blob]";
  return value;
}

export interface Logger {
  child(meta: LogMeta): Logger;
  debug(message: string, meta?: LogMeta): void;
  info(message: string, meta?: LogMeta): void;
  warn(message: string, meta?: LogMeta): void;
  error(message: string, meta?: LogMeta): void;
}

type Sink = (line: string) => void;

function buildLine(level: LogLevel, message: string, meta: LogMeta): string {
  const clean: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(meta)) {
    if (!ALLOWED_KEYS.has(k as keyof LogMeta)) continue; // drop unknown keys
    if (v === undefined) continue;
    clean[k] = scrubValue(v);
  }
  // message itself is developer-authored, but scrub it too for safety.
  const safeMessage = typeof message === "string" && message.length <= 200
    ? message
    : "[redacted:message-too-long]";
  return JSON.stringify({
    ts: new Date().toISOString(),
    level,
    msg: safeMessage,
    ...clean,
  });
}

export function createLogger(baseMeta: LogMeta = {}, sink: Sink = (l) => console.log(l)): Logger {
  const emit = (level: LogLevel, message: string, meta?: LogMeta) => {
    sink(buildLine(level, message, { ...baseMeta, ...(meta ?? {}) }));
  };
  return {
    child(meta: LogMeta): Logger {
      return createLogger({ ...baseMeta, ...meta }, sink);
    },
    debug: (m, meta) => emit("debug", m, meta),
    info: (m, meta) => emit("info", m, meta),
    warn: (m, meta) => emit("warn", m, meta),
    error: (m, meta) => emit("error", m, meta),
  };
}
