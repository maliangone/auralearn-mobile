/**
 * Metering = ABUSE / RATE GUARD ONLY (Architect-12). This is NOT entitlement
 * enforcement — real entitlement is server-authoritative in Phase C.
 *
 * Rules:
 *  - Per-user, per-day counter. Default limit 3/day (FREE_DAILY_QUOTA).
 *  - Increment is ATOMIC (Critic-7): check-and-increment in one step so two
 *    concurrent /solve calls at limit-1 cannot both succeed.
 *  - Metered unit = per user-facing QUESTION (one /solve invocation = one unit).
 *  - A /solve that BEGINS streaming is metered as exactly ONE question even if
 *    aborted mid-stream (Critic M2) — so the route increments BEFORE streaming.
 *  - Record schema carries NO user content: { userId, model, count, day } only.
 *
 * `day` is a UTC date key (YYYY-MM-DD). Reset is implicit: a new day = new key.
 */

/** A single metering record. MUST contain no user content. */
export interface MeteringRecord {
  userId: string;
  model: string;
  count: number;
  day: string;
}

export interface IncrementResult {
  /** True if this question is allowed (count was at or below limit after increment). */
  allowed: boolean;
  /** The count for this user/day AFTER attempting the increment. */
  used: number;
  /** The limit that applied. */
  limit: number;
}

export interface MeteringStore {
  /**
   * Atomically: read the user's count for `day`, and if it is < limit, increment
   * by 1 and allow; otherwise do NOT increment and deny. Returns the post-state.
   *
   * Atomicity is what closes the abuse hole: N concurrent calls at limit-1 must
   * yield exactly one `allowed: true`.
   */
  incrementIfAllowed(args: {
    userId: string;
    model: string;
    day: string;
    limit: number;
  }): Promise<IncrementResult>;

  /** Inspect a record (for the no-content harness / debugging). */
  peek(userId: string, day: string): Promise<MeteringRecord | undefined>;
}

/** UTC day key, e.g. "2026-06-26". */
export function todayUtc(now: Date = new Date()): string {
  return now.toISOString().slice(0, 10);
}

/**
 * In-memory store.
 *
 * Atomicity model: Node runs one JS callback to completion without interleaving
 * (single-threaded event loop). `incrementIfAllowed` does its read+write
 * SYNCHRONOUSLY within one tick (the returned Promise is resolved from already-
 * computed values), so no `await` splits the check from the write. Two concurrent
 * callers are therefore serialized by the event loop and cannot both read the
 * same pre-increment value. Suitable for a single-instance deployment / tests.
 *
 * For multi-instance, use the Redis store (atomic across processes via INCR/Lua).
 */
export class InMemoryMeteringStore implements MeteringStore {
  // key = `${userId}|${day}` -> record
  private readonly map = new Map<string, MeteringRecord>();

  async incrementIfAllowed(args: {
    userId: string;
    model: string;
    day: string;
    limit: number;
  }): Promise<IncrementResult> {
    const { userId, model, day, limit } = args;
    const key = `${userId}|${day}`;
    // --- BEGIN critical section (synchronous, no await) ---
    const existing = this.map.get(key);
    const current = existing?.count ?? 0;
    if (current >= limit) {
      return { allowed: false, used: current, limit };
    }
    const next = current + 1;
    this.map.set(key, { userId, model, count: next, day });
    // --- END critical section ---
    return { allowed: true, used: next, limit };
  }

  async peek(userId: string, day: string): Promise<MeteringRecord | undefined> {
    return this.map.get(`${userId}|${day}`);
  }
}

/** Factory: in-memory store (dev/test). Production wires FirestoreMeteringStore. */
export function createMeteringStore(): MeteringStore {
  return new InMemoryMeteringStore();
}
