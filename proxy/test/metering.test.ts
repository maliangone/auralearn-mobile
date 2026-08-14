import { describe, it, expect } from "vitest";
import { InMemoryMeteringStore, todayUtc } from "../src/lib/metering.js";

describe("InMemoryMeteringStore — atomic increment + quota block", () => {
  const day = todayUtc();

  it("allows up to the limit then blocks", async () => {
    const store = new InMemoryMeteringStore();
    const args = { userId: "u1", model: "m", day, limit: 3 };

    const r1 = await store.incrementIfAllowed(args);
    const r2 = await store.incrementIfAllowed(args);
    const r3 = await store.incrementIfAllowed(args);
    const r4 = await store.incrementIfAllowed(args);

    expect([r1.allowed, r2.allowed, r3.allowed]).toEqual([true, true, true]);
    expect([r1.used, r2.used, r3.used]).toEqual([1, 2, 3]);
    expect(r4.allowed).toBe(false);
    expect(r4.used).toBe(3); // denied request does NOT inflate the counter
    expect(r4.limit).toBe(3);
  });

  it("blocks at the limit under N concurrent calls — exactly one succeeds at limit-1", async () => {
    const store = new InMemoryMeteringStore();
    const args = { userId: "concurrent", model: "m", day, limit: 1 };

    // Fire N concurrent attempts at limit 1 -> exactly one must be allowed.
    const N = 20;
    const results = await Promise.all(
      Array.from({ length: N }, () => store.incrementIfAllowed(args)),
    );
    const allowedCount = results.filter((r) => r.allowed).length;
    expect(allowedCount).toBe(1);

    const rec = await store.peek("concurrent", day);
    expect(rec?.count).toBe(1); // counter never exceeds the limit
  });

  it("isolates users and days (no cross-talk)", async () => {
    const store = new InMemoryMeteringStore();
    await store.incrementIfAllowed({ userId: "a", model: "m", day, limit: 3 });
    await store.incrementIfAllowed({ userId: "a", model: "m", day, limit: 3 });
    const b = await store.incrementIfAllowed({ userId: "b", model: "m", day, limit: 3 });
    expect(b.used).toBe(1); // user b unaffected by user a

    const other = await store.incrementIfAllowed({
      userId: "a",
      model: "m",
      day: "2099-01-01",
      limit: 3,
    });
    expect(other.used).toBe(1); // new day resets implicitly
  });

  it("metering record schema carries no user content", async () => {
    const store = new InMemoryMeteringStore();
    await store.incrementIfAllowed({ userId: "u", model: "claude-x", day, limit: 3 });
    const rec = await store.peek("u", day);
    expect(rec).toBeDefined();
    expect(Object.keys(rec!).sort()).toEqual(["count", "day", "model", "userId"]);
  });
});
