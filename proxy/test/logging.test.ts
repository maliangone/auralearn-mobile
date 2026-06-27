import { describe, it, expect } from "vitest";
import { createLogger } from "../src/lib/logger.js";

describe("logger redaction", () => {
  it("drops non-allowlisted keys (content cannot be smuggled in)", () => {
    const lines: string[] = [];
    const log = createLogger({}, (l) => lines.push(l));
    // @ts-expect-error — deliberately passing a content-bearing field the type forbids.
    log.info("msg", { problem: "SECRET PROBLEM TEXT", userId: "u1" });
    const obj = JSON.parse(lines[0]) as Record<string, unknown>;
    expect(obj).not.toHaveProperty("problem");
    expect(obj.userId).toBe("u1");
    expect(lines[0]).not.toContain("SECRET PROBLEM TEXT");
  });

  it("redacts base64-looking blobs even in allowlisted string fields", () => {
    const lines: string[] = [];
    const log = createLogger({}, (l) => lines.push(l));
    const blob = "QUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVowMTIzNDU2Nzg5YWJjZGVmZ2hpamtsbW4=";
    log.info("x", { userId: blob });
    expect(lines[0]).not.toContain(blob);
    expect(lines[0]).toContain("[redacted:blob]");
  });

  it("truncates over-long strings in allowlisted fields", () => {
    const lines: string[] = [];
    const log = createLogger({}, (l) => lines.push(l));
    log.info("x", { code: "a".repeat(500) });
    expect(lines[0]).toContain("[redacted:too-long]");
  });

  it("child loggers inherit base metadata", () => {
    const lines: string[] = [];
    const log = createLogger({ reqId: "r1" }, (l) => lines.push(l));
    log.child({ userId: "u9" }).info("hi");
    const obj = JSON.parse(lines[0]) as Record<string, unknown>;
    expect(obj.reqId).toBe("r1");
    expect(obj.userId).toBe("u9");
  });
});
