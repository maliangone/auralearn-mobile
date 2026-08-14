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

/** Factory: in-memory store (dev/test). Production wires FirestoreEntitlementStore. */
export function createEntitlementStore(): EntitlementStore {
  return new InMemoryEntitlementStore();
}
