import { describe, it, expect } from "vitest";
import {
  verifyAuth,
  parseBearer,
  signHs256Jwt,
  verifyHs256Jwt,
} from "../src/lib/auth.js";

const SECRET = "test-accounts-secret";
const DEV = "dev-local-token";

function bearer(token: string): string {
  return `Bearer ${token}`;
}

describe("parseBearer", () => {
  it("parses a bearer token", () => {
    expect(parseBearer("Bearer abc")).toBe("abc");
    expect(parseBearer("bearer  abc ")).toBe("abc");
    expect(parseBearer(undefined)).toBeUndefined();
    expect(parseBearer("Basic xyz")).toBeUndefined();
  });
});

describe("account-JWT auth (HS256)", () => {
  it("accepts a valid token and extracts userId from sub", () => {
    const token = signHs256Jwt({ sub: "user-42", iat: 1000 }, SECRET);
    const r = verifyAuth(bearer(token), { accountsJwtSecret: SECRET, devAuthToken: "" });
    expect(r.ok).toBe(true);
    if (r.ok) expect(r.userId).toBe("user-42");
  });

  it("rejects a tampered token (payload changed, signature stale)", () => {
    const token = signHs256Jwt({ sub: "user-42" }, SECRET);
    const parts = token.split(".");
    // Re-sign nothing; just swap the payload to a forged "admin" sub.
    const forgedPayload = Buffer.from(JSON.stringify({ sub: "admin" }), "utf8")
      .toString("base64")
      .replace(/=+$/g, "")
      .replace(/\+/g, "-")
      .replace(/\//g, "_");
    const tampered = `${parts[0]}.${forgedPayload}.${parts[2]}`;
    const r = verifyAuth(bearer(tampered), { accountsJwtSecret: SECRET, devAuthToken: "" });
    expect(r.ok).toBe(false);
  });

  it("rejects a token signed with the wrong secret", () => {
    const token = signHs256Jwt({ sub: "user-42" }, "the-wrong-secret");
    const r = verifyAuth(bearer(token), { accountsJwtSecret: SECRET, devAuthToken: "" });
    expect(r.ok).toBe(false);
  });

  it("rejects an expired token", () => {
    const nowMs = 2_000_000_000_000; // fixed clock
    // exp 1 hour in the PAST relative to the injected clock.
    const expSec = Math.floor(nowMs / 1000) - 3600;
    const token = signHs256Jwt({ sub: "user-42", exp: expSec }, SECRET);
    const r = verifyAuth(bearer(token), {
      accountsJwtSecret: SECRET,
      devAuthToken: "",
      now: () => nowMs,
    });
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.reason).toMatch(/expired/);
  });

  it("accepts a not-yet-expired token", () => {
    const nowMs = 2_000_000_000_000;
    const expSec = Math.floor(nowMs / 1000) + 3600;
    const token = signHs256Jwt({ sub: "user-7", exp: expSec }, SECRET);
    const r = verifyAuth(bearer(token), {
      accountsJwtSecret: SECRET,
      devAuthToken: "",
      now: () => nowMs,
    });
    expect(r.ok).toBe(true);
    if (r.ok) expect(r.userId).toBe("user-7");
  });

  it("rejects a missing Authorization header", () => {
    expect(verifyAuth(undefined, { accountsJwtSecret: SECRET, devAuthToken: "" }).ok).toBe(false);
  });

  it("rejects a non-JWT garbage token", () => {
    expect(
      verifyAuth(bearer("not-a-jwt"), { accountsJwtSecret: SECRET, devAuthToken: "" }).ok,
    ).toBe(false);
  });

  it("rejects a valid-signature token that lacks a sub claim", () => {
    const token = signHs256Jwt({ iat: 1 }, SECRET);
    const r = verifyAuth(bearer(token), { accountsJwtSecret: SECRET, devAuthToken: "" });
    expect(r.ok).toBe(false);
  });

  it("verifyHs256Jwt rejects a non-HS256 alg", () => {
    const token = signHs256Jwt({ sub: "x" }, SECRET, { alg: "none", typ: "JWT" });
    expect(verifyHs256Jwt(token, SECRET).ok).toBe(false);
  });
});

describe("dev fallback token (LOCAL DEV ONLY)", () => {
  it("accepts the configured dev token and yields a content-free userId", () => {
    const r = verifyAuth(bearer(DEV), { accountsJwtSecret: SECRET, devAuthToken: DEV });
    expect(r.ok).toBe(true);
    if (r.ok) expect(r.userId).toMatch(/^u_/);
  });

  it("maps distinct '<devToken>:<label>' tokens to distinct, content-free userIds", () => {
    const cfg = { accountsJwtSecret: SECRET, devAuthToken: DEV };
    const a = verifyAuth(bearer(`${DEV}:alice`), cfg);
    const b = verifyAuth(bearer(`${DEV}:bob`), cfg);
    expect(a.ok && b.ok).toBe(true);
    if (a.ok && b.ok) {
      expect(a.userId).not.toBe(b.userId);
      expect(a.userId).not.toContain("alice"); // hashed, never the raw token
    }
  });

  it("does NOT accept the dev token when devAuthToken is unset (prod posture)", () => {
    const r = verifyAuth(bearer(DEV), { accountsJwtSecret: SECRET, devAuthToken: "" });
    expect(r.ok).toBe(false);
  });

  it("rejects everything when neither JWT secret nor dev token is configured", () => {
    expect(verifyAuth(bearer("anything"), { accountsJwtSecret: "", devAuthToken: "" }).ok).toBe(
      false,
    );
  });
});
