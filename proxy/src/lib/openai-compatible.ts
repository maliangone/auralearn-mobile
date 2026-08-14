/**
 * OpenAI-compatible upstream abstraction (chat completions, streaming).
 *
 * Covers OpenAI (gpt-5.6-luna etc.), DeepSeek, and any host speaking the chat
 * completions wire format. No SDK — a fetch + SSE line parser keeps the proxy
 * dependency-light, and `fetchFn` is injectable for tests.
 *
 * Images travel as `image_url` content parts with `data:image/jpeg;base64,...`
 * data URLs. Text-only hosts (DeepSeek chat) reject such requests; the
 * solve-handler guards that earlier via TierConfig.supportsVision.
 *
 * `reasoning_effort` (when set) is forwarded verbatim — hosts that do not know
 * the field reject the request, so per-tier config must stay host-appropriate.
 */

import type { TextChunk, TutorModel, TutorStreamArgs } from "./anthropic.js";

export interface OpenAiCompatibleOptions {
  apiKey: string;
  baseUrl: string;
  /** Injectable for tests; defaults to global fetch. */
  fetchFn?: typeof fetch;
}

interface ChatDeltaPayload {
  choices?: Array<{ delta?: { content?: unknown } }>;
  error?: unknown;
}

export class OpenAiCompatibleTutorModel implements TutorModel {
  private readonly apiKey: string;
  private readonly baseUrl: string;
  private readonly fetchFn: typeof fetch;

  constructor(opts: OpenAiCompatibleOptions) {
    this.apiKey = opts.apiKey;
    this.baseUrl = opts.baseUrl.replace(/\/+$/, ""); // never double-slash
    this.fetchFn = opts.fetchFn ?? fetch;
  }

  async *streamTutor(args: TutorStreamArgs): AsyncIterable<TextChunk> {
    const { model, system, userText, images, maxTokens, reasoningEffort } = args;

    const userContent: Array<Record<string, unknown>> = [
      ...images.map((data) => ({
        type: "image_url",
        image_url: { url: `data:image/jpeg;base64,${data}` },
      })),
      { type: "text", text: userText },
    ];

    const body: Record<string, unknown> = {
      model,
      max_tokens: maxTokens,
      stream: true,
      messages: [
        { role: "system", content: system },
        { role: "user", content: userContent },
      ],
    };
    if (reasoningEffort && reasoningEffort !== "") {
      body["reasoning_effort"] = reasoningEffort;
    }

    let response: Response;
    try {
      response = await this.fetchFn(`${this.baseUrl}/chat/completions`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
          "Content-Type": "application/json",
          Accept: "text/event-stream",
        },
        body: JSON.stringify(body),
      });
    } catch (err) {
      throw new Error(
        `openai-compatible upstream unreachable: ${err instanceof Error ? err.message : String(err)}`,
      );
    }

    if (!response.ok || !response.body) {
      const bodyText = await response.text().catch(() => "");
      throw new Error(
        `openai-compatible upstream error ${response.status}: ${truncateForError(bodyText)}`,
      );
    }

    const decoder = new TextDecoder();
    let buffer = "";
    for await (const chunk of response.body as unknown as AsyncIterable<Uint8Array>) {
      buffer += decoder.decode(chunk, { stream: true });
      // SSE frames are newline-delimited `data:` lines.
      const lines = buffer.split("\n");
      buffer = lines.pop() ?? ""; // keep the last partial line
      for (const raw of lines) {
        const line = raw.trim();
        if (line === "" || !line.startsWith("data:")) continue;
        const payload = line.slice("data:".length).trim();
        if (payload === "" || payload === "[DONE]") continue;
        const json = parseJsonOrNull<ChatDeltaPayload>(payload);
        if (!json) continue; // skip malformed frames rather than aborting
        if (json.error !== undefined) {
          throw new Error(`openai-compatible stream error: ${JSON.stringify(json.error)}`);
        }
        const delta = json.choices?.[0]?.delta?.content;
        if (typeof delta === "string" && delta.length > 0) {
          yield { text: delta };
        }
      }
    }
  }
}

/** Errors must never echo request bodies; a short structured excerpt is fine. */
function truncateForError(text: string): string {
  try {
    const json = JSON.parse(text) as { error?: { message?: string } };
    return json.error?.message ?? "no error detail";
  } catch {
    return text.slice(0, 200);
  }
}

function parseJsonOrNull<T>(text: string): T | null {
  try {
    return JSON.parse(text) as T;
  } catch {
    return null;
  }
}
