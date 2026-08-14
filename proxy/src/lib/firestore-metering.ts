/**
 * Firestore-backed metering store (Phase 3) — port of the yijing app's
 * quota-ledger pattern (server-authoritative counters via Admin SDK).
 *
 * Every counter lives on the user's own document `users/{uid}` — the client
 * NEVER touches Firestore directly (rules deny all client access); only the
 * Admin SDK writes. The record carries NO user content:
 * `{ dailyCount, dailyDay, dailyModel }` metadata only.
 *
 * Atomicity: Firestore transactions serialize on the user document, so N
 * concurrent /solve calls at limit-1 yield exactly ONE allowed result
 * (Critic-7). The transaction re-runs up to 5 times on contention.
 */

import type { Firestore } from "firebase-admin/firestore";
import type { IncrementResult, MeteringStore, MeteringRecord } from "./metering.js";

export class FirestoreMeteringStore implements MeteringStore {
  constructor(private readonly db: Firestore) {}

  private docRef(userId: string) {
    return this.db.collection("users").doc(userId);
  }

  async incrementIfAllowed(args: {
    userId: string;
    model: string;
    day: string;
    limit: number;
  }): Promise<IncrementResult> {
    const { userId, model, day, limit } = args;
    const ref = this.docRef(userId);

    // One transaction = one atomic check-and-increment on the user document.
    const result = await this.db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const data = snap.data() ?? {};
      const current = data["dailyDay"] === day ? (data["dailyCount"] as number) ?? 0 : 0;
      if (current >= limit) {
        // Denied WITHOUT incrementing — an over-limit user must not inflate
        // the counter (mirrors the Redis Lua script's semantics).
        return { allowed: false, used: current, limit } as IncrementResult;
      }
      const next = current + 1;
      tx.set(
        ref,
        {
          dailyCount: next,
          dailyDay: day,
          dailyModel: model,
          dailyUpdatedAt: new Date().toISOString(),
        },
        { merge: true },
      );
      return { allowed: true, used: next, limit } as IncrementResult;
    });
    return result;
  }

  async peek(userId: string, day: string): Promise<MeteringRecord | undefined> {
    const snap = await this.docRef(userId).get();
    const data = snap.data() ?? {};
    if (data["dailyDay"] !== day) return undefined;
    return {
      userId,
      model: (data["dailyModel"] as string) ?? "",
      count: (data["dailyCount"] as number) ?? 0,
      day,
    };
  }
}
