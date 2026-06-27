import { describe, it, expect } from "vitest";
import { buildTestApp } from "./helpers.js";

const DEV = "dev-local-token";
const ALICE = `Bearer ${DEV}:alice`;
const BOB = `Bearer ${DEV}:bob`;

describe("POST /billing/validate + GET /billing/status (mock verifier)", () => {
  it("requires auth", async () => {
    const { app } = buildTestApp();
    const res = await app.inject({
      method: "POST",
      url: "/billing/validate",
      payload: { platform: "apple", receipt: "good-receipt", productId: "sub_std" },
    });
    expect(res.statusCode).toBe(401);
  });

  it("validates an Apple receipt -> entitlement becomes paid, and status reflects it", async () => {
    const { app, entitlement } = buildTestApp();

    const res = await app.inject({
      method: "POST",
      url: "/billing/validate",
      headers: { authorization: ALICE },
      payload: { platform: "apple", receipt: "apple-good-1", productId: "sub_pro" },
    });
    expect(res.statusCode).toBe(200);
    const body = res.json() as { ok: boolean; entitlement: { plan: string; tier: string } };
    expect(body.ok).toBe(true);
    expect(body.entitlement.plan).toBe("paid");
    expect(body.entitlement.tier).toBe("pro"); // productId contains "pro"

    // status endpoint reflects the entitlement
    const status = await app.inject({
      method: "GET",
      url: "/billing/status",
      headers: { authorization: ALICE },
    });
    expect(status.statusCode).toBe(200);
    const sBody = status.json() as { entitlement: { plan: string } };
    expect(sBody.entitlement.plan).toBe("paid");

    // entitlement actually persisted server-side under alice's userId
    const aliceId = (await entitlement.getReceiptOwner("apple:apple-good-1"))!;
    expect(aliceId).toBeDefined();
    const ent = await entitlement.getEntitlement(aliceId);
    expect(ent.plan).toBe("paid");
  });

  it("validates a Google purchaseToken -> paid std for a non-pro product", async () => {
    const { app } = buildTestApp();
    const res = await app.inject({
      method: "POST",
      url: "/billing/validate",
      headers: { authorization: ALICE },
      payload: { platform: "google", purchaseToken: "tok-123", productId: "sub_monthly" },
    });
    expect(res.statusCode).toBe(200);
    expect((res.json() as { entitlement: { tier: string } }).entitlement.tier).toBe("std");
  });

  it("rejects an invalid receipt with 402", async () => {
    const { app } = buildTestApp();
    const res = await app.inject({
      method: "POST",
      url: "/billing/validate",
      headers: { authorization: ALICE },
      payload: { platform: "apple", receipt: "this-is-invalid", productId: "sub_std" },
    });
    expect(res.statusCode).toBe(402);
    expect((res.json() as { code: string }).code).toBe("invalid_receipt");
  });

  it("rejects a bad platform / missing productId with 400", async () => {
    const { app } = buildTestApp();
    const r1 = await app.inject({
      method: "POST",
      url: "/billing/validate",
      headers: { authorization: ALICE },
      payload: { platform: "windows", receipt: "x", productId: "p" },
    });
    expect(r1.statusCode).toBe(400);

    const r2 = await app.inject({
      method: "POST",
      url: "/billing/validate",
      headers: { authorization: ALICE },
      payload: { platform: "apple", receipt: "x" },
    });
    expect(r2.statusCode).toBe(400);
  });

  it("ANTI-REPLAY: the same receipt under a DIFFERENT account -> 409 receipt_already_bound", async () => {
    const { app } = buildTestApp();
    const receipt = "shared-receipt-xyz";

    // Alice binds it first.
    const first = await app.inject({
      method: "POST",
      url: "/billing/validate",
      headers: { authorization: ALICE },
      payload: { platform: "apple", receipt, productId: "sub_std" },
    });
    expect(first.statusCode).toBe(200);

    // Bob presents the SAME receipt -> rejected.
    const second = await app.inject({
      method: "POST",
      url: "/billing/validate",
      headers: { authorization: BOB },
      payload: { platform: "apple", receipt, productId: "sub_std" },
    });
    expect(second.statusCode).toBe(409);
    expect((second.json() as { code: string }).code).toBe("receipt_already_bound");

    // Bob stays free.
    const bobStatus = await app.inject({
      method: "GET",
      url: "/billing/status",
      headers: { authorization: BOB },
    });
    expect((bobStatus.json() as { entitlement: { plan: string } }).entitlement.plan).toBe("free");
  });

  it("RESTORE: the same owner re-presenting the same receipt is idempotent (200)", async () => {
    const { app } = buildTestApp();
    const receipt = "alice-restore-receipt";
    const payload = { platform: "apple", receipt, productId: "sub_std" };

    const first = await app.inject({
      method: "POST",
      url: "/billing/validate",
      headers: { authorization: ALICE },
      payload,
    });
    const second = await app.inject({
      method: "POST",
      url: "/billing/validate",
      headers: { authorization: ALICE },
      payload,
    });
    expect(first.statusCode).toBe(200);
    expect(second.statusCode).toBe(200);
  });

  it("status defaults to free for a user who never purchased", async () => {
    const { app } = buildTestApp();
    const res = await app.inject({
      method: "GET",
      url: "/billing/status",
      headers: { authorization: BOB },
    });
    expect(res.statusCode).toBe(200);
    expect((res.json() as { entitlement: { plan: string } }).entitlement.plan).toBe("free");
  });
});
