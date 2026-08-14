/**
 * Firestore-backed entitlement store (Phase 3) — server-authoritative
 * subscription state, port of the yijing app's `users/{uid}` tier pattern.
 *
 * INVARIANTS (same as EntitlementStore):
 *  - Content-free: `users/{uid}` carries only plan/tier/expiry timestamps;
 *    `receipts/{receiptId}` carries only the owning uid.
 *  - AUTHORITATIVE for plan/tier routing (client tokens carry identity only).
 *  - Receipt binding is unique-per-entitlement (Critic M3): the binding is a
 *    transaction with `tx.create`, so a second account presenting an already-
 *    bound receipt FAILS atomically (no check-then-act race).
 *
 * RevenueCat is the upstream purchase authority; this store persists its
 * verdicts (sync + webhook) so routing never depends on a live RC round-trip.
 */

import type { Firestore } from "firebase-admin/firestore";
import type { Entitlement } from "./entitlement.js";
import {
  DEFAULT_ENTITLEMENT,
  type EntitlementStore,
} from "./entitlement.js";

export class FirestoreEntitlementStore implements EntitlementStore {
  constructor(private readonly db: Firestore) {}

  private userDoc(userId: string) {
    return this.db.collection("users").doc(userId);
  }

  private receiptDoc(receiptId: string) {
    return this.db.collection("receipts").doc(receiptId);
  }

  async getEntitlement(userId: string): Promise<Entitlement> {
    const snap = await this.userDoc(userId).get();
    const data = snap.data() ?? {};
    const plan = data["plan"] === "paid" ? "paid" : "free";
    const tier = data["tier"] as Entitlement["tier"] | undefined;
    const subExpiry = data["subExpiry"] as number | undefined;
    const ent: Entitlement = {
      plan,
      tier: plan === "free" ? "free" : tier ?? "std",
      ...(typeof subExpiry === "number" ? { expiresAt: subExpiry } : {}),
    };
    // Expired paid entitlement falls back to free.
    if (ent.plan === "paid" && typeof ent.expiresAt === "number" && Date.now() > ent.expiresAt) {
      return { ...DEFAULT_ENTITLEMENT };
    }
    return ent;
  }

  async setEntitlement(userId: string, ent: Entitlement): Promise<void> {
    await this.userDoc(userId).set(
      {
        plan: ent.plan,
        tier: ent.tier,
        ...(typeof ent.expiresAt === "number" ? { subExpiry: ent.expiresAt } : {}),
        subscriptionUpdatedAt: new Date().toISOString(),
      },
      { merge: true },
    );
  }

  async bindReceipt(receiptId: string, userId: string): Promise<void> {
    await this.db.runTransaction(async (tx) => {
      // `create` fails the whole transaction if the receipt is already bound —
      // the atomic uniqueness guard (a second account re-presenting the same
      // receiptId never overwrites the first binding).
      tx.create(this.receiptDoc(receiptId), { owner: userId });
    });
  }

  async getReceiptOwner(receiptId: string): Promise<string | undefined> {
    const snap = await this.receiptDoc(receiptId).get();
    return (snap.data()?.["owner"] as string | undefined);
  }
}
