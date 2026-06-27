import { describe, it, expect } from "vitest";
import {
  MockReceiptVerifier,
  createReceiptVerifier,
  productIdToTier,
} from "../src/lib/receipt-verifier.js";

describe("MockReceiptVerifier", () => {
  it("accepts a good Apple receipt and derives a stable receiptId", async () => {
    const v = new MockReceiptVerifier(() => 1000);
    const r = await v.verify({ platform: "apple", receipt: "abc", productId: "sub_std" });
    expect(r.ok).toBe(true);
    if (r.ok) {
      expect(r.receiptId).toBe("apple:abc");
      expect(r.expiresAt).toBeGreaterThan(1000);
    }
  });

  it("derives the SAME receiptId for the same receipt (anti-replay foundation)", async () => {
    const v = new MockReceiptVerifier();
    const a = await v.verify({ platform: "google", purchaseToken: "tok", productId: "p" });
    const b = await v.verify({ platform: "google", purchaseToken: "tok", productId: "p" });
    expect(a.ok && b.ok).toBe(true);
    if (a.ok && b.ok) expect(a.receiptId).toBe(b.receiptId);
  });

  it("rejects a receipt containing 'invalid'", async () => {
    const v = new MockReceiptVerifier();
    const r = await v.verify({ platform: "apple", receipt: "INVALID-x", productId: "p" });
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.code).toBe("invalid_receipt");
  });

  it("rejects a missing receipt/token with bad_request", async () => {
    const v = new MockReceiptVerifier();
    const a = await v.verify({ platform: "apple", productId: "p" });
    const b = await v.verify({ platform: "google", productId: "p" });
    expect(a.ok).toBe(false);
    expect(b.ok).toBe(false);
  });
});

describe("productIdToTier", () => {
  it("maps pro products to pro and others to std", () => {
    expect(productIdToTier("sub_pro_yearly")).toBe("pro");
    expect(productIdToTier("auralearn.pro")).toBe("pro");
    expect(productIdToTier("sub_std")).toBe("std");
    expect(productIdToTier("monthly")).toBe("std");
  });
});

describe("createReceiptVerifier", () => {
  it("returns the mock verifier when no store credentials are configured", async () => {
    const v = createReceiptVerifier({
      appleSharedSecret: "",
      appleIssuerId: "",
      googlePlaySaJson: "",
    });
    // It behaves like the mock (no network, deterministic).
    const r = await v.verify({ platform: "apple", receipt: "x", productId: "p" });
    expect(r.ok).toBe(true);
  });
});
