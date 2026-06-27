/**
 * EntitlementStore (Phase C) — server-authoritative subscription state.
 *
 * INVARIANTS:
 *  - Content-free. Stores only identity-keyed entitlement + receipt bindings.
 *    Never any problem/answer/image content.
 *  - AUTHORITATIVE for plan/tier routing. The client's auth token conveys
 *    identity only; the plan is ALWAYS resolved from this store, never trusted
 *    from the request body (see lib/router.ts / solve-handler.ts).
 *  - Receipt binding is unique-per-entitlement (Critic M3): a stable `receiptId`
 *    (Apple originalTransactionId / Google purchaseToken) is bound to exactly one
 *    userId. A second user presenting the same receiptId is rejected upstream
 *    (routes/billing.ts) with 409 receipt_already_bound.
 *
 * Default entitlement (no record) = free / free tier.
 */

import type { Plan } from "../config.js";

/** Tier label that selects the concrete model within a plan. */
export type Tier = "free" | "std" | "pro";

export interface Entitlement {
  plan: Plan;
  tier: Tier;
  /** Epoch millis when the entitlement expires (paid only). Absent => no expiry. */
  expiresAt?: number;
}

/** The implicit entitlement for a user with no record. */
export const DEFAULT_ENTITLEMENT: Entitlement = { plan: "free", tier: "free" };

export interface EntitlementStore {
  /** Resolve a user's entitlement. Returns DEFAULT_ENTITLEMENT when unknown. */
  getEntitlement(userId: string): Promise<Entitlement>;
  /** Set/replace a user's entitlement. */
  setEntitlement(userId: string, ent: Entitlement): Promise<void>;
  /**
   * Bind a receipt to a user. Idempotent for the SAME owner; the caller is
   * responsible for the cross-account check via getReceiptOwner first.
   */
  bindReceipt(receiptId: string, userId: string): Promise<void>;
  /** Current owner of a receiptId, or undefined if unbound. */
  getReceiptOwner(receiptId: string): Promise<string | undefined>;
}

/**
 * In-memory implementation (single instance / dev / tests). Content-free.
 */
export class InMemoryEntitlementStore implements EntitlementStore {
  private readonly entitlements = new Map<string, Entitlement>();
  private readonly receiptOwners = new Map<string, string>();

  async getEntitlement(userId: string): Promise<Entitlement> {
    const ent = this.entitlements.get(userId);
    if (!ent) return { ...DEFAULT_ENTITLEMENT };
    // Expired paid entitlement falls back to free.
    if (ent.plan === "paid" && typeof ent.expiresAt === "number" && Date.now() > ent.expiresAt) {
      return { ...DEFAULT_ENTITLEMENT };
    }
    return { ...ent };
  }

  async setEntitlement(userId: string, ent: Entitlement): Promise<void> {
    this.entitlements.set(userId, { ...ent });
  }

  async bindReceipt(receiptId: string, userId: string): Promise<void> {
    this.receiptOwners.set(receiptId, userId);
  }

  async getReceiptOwner(receiptId: string): Promise<string | undefined> {
    return this.receiptOwners.get(receiptId);
  }
}

/**
 * Persistent store (DOCUMENTED STUB for production — Redis / SQL).
 *
 * Schema (content-free):
 *   entitlement:{userId} -> JSON { plan, tier, expiresAt }
 *   receipt:{receiptId}  -> userId   (UNIQUE — enforces one receipt = one account)
 *
 * Binding MUST be atomic to fully close the cross-account race: use Redis
 * `SET receipt:{id} {userId} NX` (set-if-absent) and treat a failed NX as
 * "already bound" — then compare the existing owner. In SQL, a UNIQUE constraint
 * on receiptId + an upsert achieves the same. The route layer does a
 * getReceiptOwner check first; the NX/UNIQUE guard is the last-writer safety net.
 *
 * Not wired to a live client here (no REDIS_URL/db in this lane); implement the
 * four methods against your client in production.
 */
export class PersistentEntitlementStore implements EntitlementStore {
  constructor(private readonly _connectionUrl: string) {}

  private fail(method: string): never {
    throw new Error(
      `PersistentEntitlementStore.${method} is a documented stub. Wire it to your ` +
        `Redis/SQL client (see schema in lib/entitlement.ts). Connection was: ${this._connectionUrl}`,
    );
  }

  async getEntitlement(_userId: string): Promise<Entitlement> {
    this.fail("getEntitlement");
  }
  async setEntitlement(_userId: string, _ent: Entitlement): Promise<void> {
    this.fail("setEntitlement");
  }
  async bindReceipt(_receiptId: string, _userId: string): Promise<void> {
    this.fail("bindReceipt");
  }
  async getReceiptOwner(_receiptId: string): Promise<string | undefined> {
    this.fail("getReceiptOwner");
  }
}

/** Factory: persistent store when a connection URL is configured, else in-memory. */
export function createEntitlementStore(connectionUrl: string | undefined): EntitlementStore {
  if (connectionUrl) {
    return new PersistentEntitlementStore(connectionUrl);
  }
  return new InMemoryEntitlementStore();
}
