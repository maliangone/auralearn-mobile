import { describe, it, expect } from "vitest";
import { buildTestApp } from "./helpers.js";
import type { SolveEvent } from "../src/types.js";

const ALICE = "Bearer dev-local-token:alice";

/** Parse an SSE body ("data: {...}\n\n" frames) into SolveEvents. */
function parseSse(body: string): SolveEvent[] {
  return body
    .split("\n\n")
    .map((f) => f.trim())
    .filter((f) => f.startsWith("data:"))
    .map((f) => JSON.parse(f.slice("data:".length).trim()) as SolveEvent);
}

describe("/solve route — authoritative routing end-to-end", () => {
  it("ignores a client-claimed plan:'paid' and routes a free user to MODEL_FREE", async () => {
    const { app } = buildTestApp();
    const res = await app.inject({
      method: "POST",
      url: "/solve",
      headers: { authorization: ALICE },
      // The client LIES: claims paid. Entitlement store has no record => free.
      payload: { images: ["YQ=="], subject: "math", plan: "paid" },
    });
    expect(res.statusCode).toBe(200);
    const events = parseSse(res.body);
    const done = events.find((e) => e.type === "done");
    expect(done).toBeDefined();
    if (done && done.type === "done") {
      expect(done.model).toBe("claude-haiku-4-5-20251001"); // MODEL_FREE
    }
  });

  it("routes a paid-entitled user (RevenueCat verdict paid) to the paid model", async () => {
    const { app, revenuecat } = buildTestApp();
    // Grant alice a paid std entitlement through the real billing path:
    // RevenueCat says subscribed -> /billing/sync persists it -> /solve routes.
    revenuecat.verdict = {
      plan: "paid",
      tier: "std",
      expiresAt: Date.now() + 86_400_000,
    };
    await app.inject({
      method: "POST",
      url: "/billing/sync",
      headers: { authorization: ALICE },
      payload: {},
    });

    const res = await app.inject({
      method: "POST",
      url: "/solve",
      headers: { authorization: ALICE },
      payload: { images: ["YQ=="], subject: "math" },
    });
    const events = parseSse(res.body);
    const done = events.find((e) => e.type === "done");
    if (done && done.type === "done") {
      expect(done.model).toBe("claude-sonnet-4-6"); // MODEL_PAID_STD
    }
  });

  it("returns an SSE unauthorized error when the token is missing", async () => {
    const { app } = buildTestApp();
    const res = await app.inject({
      method: "POST",
      url: "/solve",
      payload: { images: ["YQ=="] },
    });
    const events = parseSse(res.body);
    expect(events[0].type).toBe("error");
    if (events[0].type === "error") expect(events[0].code).toBe("unauthorized");
  });
});
