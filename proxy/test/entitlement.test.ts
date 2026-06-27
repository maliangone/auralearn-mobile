import { describe, it, expect } from "vitest";
import {
  InMemoryEntitlementStore,
  DEFAULT_ENTITLEMENT,
} from "../src/lib/entitlement.js";

describe("InMemoryEntitlementStore", () => {
  it("defaults unknown users to free / free tier", async () => {
    const store = new InMemoryEntitlementStore();
    const ent = await store.getEntitlement("nobody");
    expect(ent).toEqual(DEFAULT_ENTITLEMENT);
    expect(ent.plan).toBe("free");
    expect(ent.tier).toBe("free");
  });

  it("stores and returns a paid entitlement", async () => {
    const store = new InMemoryEntitlementStore();
    const expiresAt = Date.now() + 1_000_000;
    await store.setEntitlement("u1", { plan: "paid", tier: "pro", expiresAt });
    const ent = await store.getEntitlement("u1");
    expect(ent.plan).toBe("paid");
    expect(ent.tier).toBe("pro");
    expect(ent.expiresAt).toBe(expiresAt);
  });

  it("treats an expired paid entitlement as free", async () => {
    const store = new InMemoryEntitlementStore();
    await store.setEntitlement("u2", { plan: "paid", tier: "std", expiresAt: Date.now() - 1 });
    const ent = await store.getEntitlement("u2");
    expect(ent.plan).toBe("free");
  });

  it("binds a receipt to one owner and reports the owner", async () => {
    const store = new InMemoryEntitlementStore();
    expect(await store.getReceiptOwner("r1")).toBeUndefined();
    await store.bindReceipt("r1", "owner-a");
    expect(await store.getReceiptOwner("r1")).toBe("owner-a");
  });

  it("is content-free: stored records are entitlement + receipt-owner only", async () => {
    const store = new InMemoryEntitlementStore();
    await store.setEntitlement("u", { plan: "paid", tier: "std" });
    const ent = await store.getEntitlement("u");
    expect(Object.keys(ent).sort()).toEqual(["plan", "tier"]);
  });
});
