import { createHmac } from "node:crypto";
import { describe, it, expect } from "vitest";
import { buildTestApp } from "./helpers.js";
import type { Entitlement } from "../src/lib/entitlement.js";

const DEV = "dev-local-token";
const ALICE = `Bearer ${DEV}:alice`;
const BOB = `Bearer ${DEV}:bob`;

describe("POST /billing/sync + GET /billing/status (RevenueCat-authoritative)", () => {
  it("requires auth", async () => {
    const { app } = buildTestApp();
    const res = await app.inject({ method: "POST", url: "/billing/sync", payload: {} });
    expect(res.statusCode).toBe(401);
  });

  it("sync queries RevenueCat for the account uid and persists paid", async () => {
    const { app } = buildTestApp();

    const res = await app.inject({
      method: "POST",
      url: "/billing/sync",
      headers: { authorization: ALICE },
      payload: {}, // client sends NOTHING — server only trusts its own RC lookup
    });
    // Default FakeRevenueCat verdict is free.
    expect(res.statusCode).toBe(200);
    const body = res.json() as { ok: boolean; plan: string };
    expect(body.ok).toBe(true);
    expect(body.plan).toBe("free");

    // A paid verdict (RC says subscribed) persists paid + std tier.
    const { app: paidApp, revenuecat } = buildTestApp();
    revenuecat.verdict = {
      plan: "paid",
      tier: "std",
      expiresAt: Date.now() + 86_400_000,
    };
    const paidRes = await paidApp.inject({
      method: "POST",
      url: "/billing/sync",
      headers: { authorization: ALICE },
      payload: {},
    });
    expect(paidRes.statusCode).toBe(200);
    const paidBody = paidRes.json() as { ok: boolean; plan: string; tier: string };
    expect(paidBody.ok).toBe(true);
    expect(paidBody.plan).toBe("paid");
    expect(paidBody.tier).toBe("std");

    // The entitlement was queried by uid (dev token hash) and persisted.
    expect(revenuecat.queriedIds.length).toBeGreaterThan(0);
    const status = await paidApp.inject({
      method: "GET",
      url: "/billing/status",
      headers: { authorization: ALICE },
    });
    const sBody = status.json() as { plan: string };
    expect(sBody.plan).toBe("paid");
  });

  it("sync is per-account: bob's status stays free when alice goes paid", async () => {
    const { app, revenuecat } = buildTestApp();
    revenuecat.verdict = {
      plan: "paid",
      tier: "pro",
      expiresAt: Date.now() + 86_400_000,
    };
    await app.inject({
      method: "POST",
      url: "/billing/sync",
      headers: { authorization: ALICE },
      payload: {},
    });
    const bobStatus = await app.inject({
      method: "GET",
      url: "/billing/status",
      headers: { authorization: BOB },
    });
    expect((bobStatus.json() as { plan: string }).plan).toBe("free");
  });

  it("502 when the RevenueCat lookup throws", async () => {
    const { app, revenuecat } = buildTestApp();
    revenuecat.getSubscriber = () => Promise.reject(new Error("rc down"));
    const res = await app.inject({
      method: "POST",
      url: "/billing/sync",
      headers: { authorization: ALICE },
      payload: {},
    });
    expect(res.statusCode).toBe(502);
  });
});

describe("RevenueCat webhook", () => {
  const goodEvent = (over: Record<string, unknown> = {}) => ({
    event: {
      id: "EVENT-1",
      type: "INITIAL_PURCHASE",
      app_user_id: "firebase-uid-1",
      expiration_at_ms: Date.now() + 30 * 86_400_000,
      ...over,
    },
  });

  function hmacSignature(body: string, secret: string, t = Math.floor(Date.now() / 1000)): string {
    const v1 = createHmac("sha256", secret).update(`${t}.${body}`).digest("hex");
    return `t=${t},v1=${v1}`;
  }

  it("rejects missing credentials", async () => {
    const { app } = buildTestApp();
    const res = await app.inject({
      method: "POST",
      url: "/webhook/revenuecat",
      payload: goodEvent(),
    });
    expect(res.statusCode).toBe(401);
  });

  it("applies a grant event with a valid HMAC signature", async () => {
    const { app, entitlement } = buildTestApp({
      revenuecat: {
        apiKey: "",
        webhookSecret: "",
        webhookHmacSecret: "hmac-test-secret",
      },
    });
    const body = JSON.stringify(goodEvent());
    const res = await app.inject({
      method: "POST",
      url: "/webhook/revenuecat",
      headers: {
        "content-type": "application/json",
        "x-revenuecat-webhook-signature": hmacSignature(body, "hmac-test-secret"),
      },
      payload: body,
    });
    expect(res.statusCode).toBe(200);

    const ent = await entitlement.getEntitlement("firebase-uid-1");
    expect(ent.plan).toBe("paid");
    expect(ent.expiresAt).toBeDefined();
  });

  it("applies a revoke (EXPIRATION) event -> back to free", async () => {
    const { app, entitlement } = buildTestApp({
      revenuecat: {
        apiKey: "",
        webhookSecret: "",
        webhookHmacSecret: "hmac-test-secret",
      },
    });
    await entitlement.setEntitlement("firebase-uid-2", {
      plan: "paid",
      tier: "std",
      expiresAt: Date.now() + 86_400_000,
    } as Entitlement);

    const body = JSON.stringify(
      goodEvent({ id: "EVENT-2", type: "EXPIRATION", app_user_id: "firebase-uid-2" }),
    );
    const res = await app.inject({
      method: "POST",
      url: "/webhook/revenuecat",
      headers: {
        "content-type": "application/json",
        "x-revenuecat-webhook-signature": hmacSignature(body, "hmac-test-secret"),
      },
      payload: body,
    });
    expect(res.statusCode).toBe(200);
    expect((await entitlement.getEntitlement("firebase-uid-2")).plan).toBe("free");
  });

  it("resolves the real uid from aliases ($RCAnonymousID)", async () => {
    const { app, entitlement } = buildTestApp({
      revenuecat: {
        apiKey: "",
        webhookSecret: "",
        webhookHmacSecret: "hmac-test-secret",
      },
    });
    const body = JSON.stringify(
      goodEvent({
        id: "EVENT-3",
        app_user_id: "$RCAnonymousID:abc123",
        aliases: ["$RCAnonymousID:abc123", "firebase-uid-real"],
      }),
    );
    const res = await app.inject({
      method: "POST",
      url: "/webhook/revenuecat",
      headers: {
        "content-type": "application/json",
        "x-revenuecat-webhook-signature": hmacSignature(body, "hmac-test-secret"),
      },
      payload: body,
    });
    expect(res.statusCode).toBe(200);
    expect((await entitlement.getEntitlement("firebase-uid-real")).plan).toBe("paid");
  });

  it("rejects a tampered signature", async () => {
    const { app } = buildTestApp({
      revenuecat: {
        apiKey: "",
        webhookSecret: "",
        webhookHmacSecret: "hmac-test-secret",
      },
    });
    const body = JSON.stringify(goodEvent());
    const res = await app.inject({
      method: "POST",
      url: "/webhook/revenuecat",
      headers: {
        "content-type": "application/json",
        "x-revenuecat-webhook-signature": hmacSignature(body, "wrong-secret"),
      },
      payload: body,
    });
    expect(res.statusCode).toBe(401);
  });
});
