import { describe, it, expect } from "vitest";
import { TUTOR_SYSTEM_PROMPT, buildUserFraming } from "../src/prompts/tutor.js";

describe("tutor system prompt (server-owned)", () => {
  it("enforces the 思路 → 步骤 → 结论 teach-don't-tell structure", () => {
    expect(TUTOR_SYSTEM_PROMPT).toContain("思路");
    expect(TUTOR_SYSTEM_PROMPT).toContain("步骤");
    expect(TUTOR_SYSTEM_PROMPT).toContain("结论");
    expect(TUTOR_SYSTEM_PROMPT).toMatch(/TEACH, DON'T TELL/i);
  });

  it("scopes to K-12 math / physics / chemistry", () => {
    expect(TUTOR_SYSTEM_PROMPT).toMatch(/K-12/);
    expect(TUTOR_SYSTEM_PROMPT.toLowerCase()).toContain("math");
    expect(TUTOR_SYSTEM_PROMPT.toLowerCase()).toContain("physics");
    expect(TUTOR_SYSTEM_PROMPT.toLowerCase()).toContain("chemistry");
  });

  it("is hardened against image-borne prompt injection", () => {
    // Must explicitly tell the model that in-image instructions are untrusted.
    expect(TUTOR_SYSTEM_PROMPT.toLowerCase()).toContain("ignore previous instructions");
    expect(TUTOR_SYSTEM_PROMPT.toLowerCase()).toContain("never reveal");
    expect(TUTOR_SYSTEM_PROMPT.toLowerCase()).toMatch(/problem content/);
  });

  it("user framing asks for a RECOGNIZED transcription first and threads the subject", () => {
    const f = buildUserFraming("physics");
    expect(f).toContain("RECOGNIZED:");
    expect(f).toContain("physics");
    const noSubject = buildUserFraming();
    expect(noSubject).toMatch(/Identify the subject/i);
  });
});
