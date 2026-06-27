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

/**
 * Redis-backed store (DOCUMENTED STUB for Phase A1/production).
 *
 * Why a Lua script and not a bare INCR: we need a single atomic round-trip that
 * (1) reads the counter, (2) denies if it is already >= limit (WITHOUT
 * incrementing — otherwise an over-limit user keeps inflating the counter), and
 * (3) increments + sets a TTL to the end of the UTC day otherwise. A bare
 * `INCR then compare` would over-count denied requests and would need two
 * round-trips. The Lua script runs atomically server-side:
 *
 *   -- KEYS[1] = "meter:{userId}:{day}"
 *   -- ARGV[1] = limit, ARGV[2] = ttlSeconds
 *   local current = tonumber(redis.call('GET', KEYS[1]) or '0')
 *   if current >= tonumber(ARGV[1]) then
 *     return {0, current}            -- denied, not incremented
 *   end
 *   local next = redis.call('INCR', KEYS[1])
 *   if next == 1 then
 *     redis.call('EXPIRE', KEYS[1], tonumber(ARGV[2]))
 *   end
 *   return {1, next}                 -- allowed, post-increment value
 *
 * The model is stored separately (or encoded in a parallel key) — the metering
 * record MUST stay { userId, model, count, day } with NO content.
 *
 * This stub is intentionally NOT wired to a live client in A0 (REDIS_URL blank →
 * server uses InMemoryMeteringStore). Implement `incrementIfAllowed` against your
 * Redis client (ioredis/node-redis) using EVAL with the script above in Phase A1.
 */
export class RedisMeteringStore implements MeteringStore {
  // The concrete redis client type is intentionally left as unknown to avoid a
  // hard dependency in A0. Wire it in Phase A1.
  constructor(private readonly _redisUrl: string) {}

  async incrementIfAllowed(_args: {
    userId: string;
    model: string;
    day: string;
    limit: number;
  }): Promise<IncrementResult> {
    throw new Error(
      "RedisMeteringStore is a documented stub (Phase A1). Wire EVAL of the Lua " +
        "check-and-increment script described in lib/metering.ts. REDIS_URL was: " +
        this._redisUrl,
    );
  }

  async peek(_userId: string, _day: string): Promise<MeteringRecord | undefined> {
    throw new Error("RedisMeteringStore.peek is a documented stub (Phase A1).");
  }
}

/** Factory: choose the store based on whether REDIS_URL is configured. */
export function createMeteringStore(redisUrl: string | undefined): MeteringStore {
  if (redisUrl) {
    return new RedisMeteringStore(redisUrl);
  }
  return new InMemoryMeteringStore();
}
