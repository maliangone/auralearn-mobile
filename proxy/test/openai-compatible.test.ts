import { describe, it, expect, vi, type Mock } from "vitest";
import { OpenAiCompatibleTutorModel } from "../src/lib/openai-compatible.js";
import type { TutorStreamArgs } from "../src/lib/anthropic.js";

/** Builds a Response whose body streams the given SSE lines. */
function sseResponse(lines: string[], status = 200): Response {
  const encoder = new TextEncoder();
  const stream = new ReadableStream<Uint8Array>({
    start(controller) {
      for (const line of lines) controller.enqueue(encoder.encode(line + "\n"));
      controller.close();
    },
  });
  return new Response(stream, {
    status,
    headers: { "content-type": "text/event-stream" },
  });
}

const args: TutorStreamArgs = {
  model: "gpt-5.6-luna",
  system: "You are a tutor.",
  userText: "Solve this.",
  images: ["ZmFrZS1iYXNlNjQtaW1hZ2U="],
  maxTokens: 2048,
};

async function collect(model: OpenAiCompatibleTutorModel): Promise<string[]> {
  const chunks: string[] = [];
  for await (const chunk of model.streamTutor(args)) {
    chunks.push(chunk.text);
  }
  return chunks;
}

describe("OpenAiCompatibleTutorModel", () => {
  it("streams delta content and stops at [DONE]", async () => {
    const fetchFn: Mock<typeof fetch> = vi.fn(
      async (_url: string | URL | Request, _init?: RequestInit) =>
        sseResponse([
          'data: {"choices":[{"delta":{"content":"Hello"}}]}',
          'data: {"choices":[{"delta":{"content":" world"}}]}',
          "data: [DONE]",
        ]),
    );
    const model = new OpenAiCompatibleTutorModel({
      apiKey: "sk-test",
      baseUrl: "https://api.openai.com/v1/",
      fetchFn,
    });

    expect(await collect(model)).toEqual(["Hello", " world"]);

    // Request shape: URL, auth header, image as data-URL part, no reasoning_effort.
    const [url, init] = fetchFn.mock.calls[0];
    expect(String(url)).toBe("https://api.openai.com/v1/chat/completions");
    const headers = init?.headers as Record<string, string>;
    expect(headers["Authorization"]).toBe("Bearer sk-test");
    const body = JSON.parse(init?.body as string) as Record<string, unknown>;
    expect(body["stream"]).toBe(true);
    expect(body["reasoning_effort"]).toBeUndefined();
    const userMsg = (body["messages"] as Array<Record<string, unknown>>)[1];
    const parts = userMsg["content"] as Array<Record<string, unknown>>;
    expect(parts[0]["type"]).toBe("image_url");
    const imageUrl = (parts[0] as { image_url: { url: string } }).image_url.url;
    expect(imageUrl).toBe("data:image/jpeg;base64,ZmFrZS1iYXNlNjQtaW1hZ2U=");
  });

  it("forwards reasoning_effort when set", async () => {
    const fetchFn: Mock<typeof fetch> = vi.fn(async () => sseResponse(["data: [DONE]"]));
    const model = new OpenAiCompatibleTutorModel({
      apiKey: "sk-test",
      baseUrl: "https://api.openai.com/v1",
      fetchFn,
    });
    await collect(model);
    const body = JSON.parse(fetchFn.mock.calls[0][1]?.body as string) as Record<string, unknown>;
    expect(body["reasoning_effort"]).toBeUndefined(); // args have none

    const model2 = new OpenAiCompatibleTutorModel({
      apiKey: "sk-test",
      baseUrl: "https://api.openai.com/v1",
      fetchFn,
    });
    const chunks: string[] = [];
    for await (const c of model2.streamTutor({ ...args, reasoningEffort: "max" })) {
      chunks.push(c.text);
    }
    const body2 = JSON.parse(
      fetchFn.mock.calls[1][1]?.body as string,
    ) as Record<string, unknown>;
    expect(body2["reasoning_effort"]).toBe("max");
  });

  it("throws on non-2xx with a redacted message", async () => {
    const fetchFn: Mock<typeof fetch> = vi.fn(async () =>
      new Response(JSON.stringify({ error: { message: "invalid key" } }), { status: 401 }),
    );
    const model = new OpenAiCompatibleTutorModel({
      apiKey: "bad",
      baseUrl: "https://api.openai.com/v1",
      fetchFn,
    });
    await expect(collect(model)).rejects.toThrow(/401/);
    await expect(collect(model)).rejects.toThrow(/invalid key/);
  });

  it("throws on an in-stream error frame", async () => {
    const fetchFn: Mock<typeof fetch> = vi.fn(async () =>
      sseResponse([
        'data: {"choices":[{"delta":{"content":"partial"}}]}',
        'data: {"error":{"message":"rate limited"}}',
      ]),
    );
    const model = new OpenAiCompatibleTutorModel({
      apiKey: "sk-test",
      baseUrl: "https://api.deepseek.com",
      fetchFn,
    });
    await expect(collect(model)).rejects.toThrow(/rate limited/);
  });
});
