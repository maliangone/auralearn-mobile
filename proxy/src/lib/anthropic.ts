/**
 * Anthropic upstream abstraction.
 *
 * The route depends ONLY on the `TutorModel` interface, so tests inject a fake
 * that streams canned chunks with NO network. The real implementation wraps the
 * official @anthropic-ai/sdk Messages streaming API with vision (base64 image
 * blocks) per the claude-api reference.
 *
 * Model IDs come from config/env — never hardcoded here.
 */

import Anthropic from "@anthropic-ai/sdk";

/** A single text chunk streamed from the model. */
export interface TextChunk {
  text: string;
}

export interface TutorStreamArgs {
  model: string;
  system: string;
  /** Pre-built user-turn framing (text). */
  userText: string;
  /** base64-encoded JPEG images. */
  images: string[];
  /** Cap on output tokens. */
  maxTokens: number;
}

/**
 * The narrow capability the route needs: stream tutor text chunks for a request.
 * Implementations MUST yield text deltas in order and complete the async iterator
 * when the model is done.
 */
export interface TutorModel {
  streamTutor(args: TutorStreamArgs): AsyncIterable<TextChunk>;
}

/** Real implementation backed by the Anthropic Messages streaming API + vision. */
export class AnthropicTutorModel implements TutorModel {
  private readonly client: Anthropic;

  constructor(apiKey: string) {
    this.client = new Anthropic({ apiKey });
  }

  async *streamTutor(args: TutorStreamArgs): AsyncIterable<TextChunk> {
    const { model, system, userText, images, maxTokens } = args;

    // Build vision content: image blocks (base64 JPEG) followed by the text framing.
    const content: Anthropic.MessageParam["content"] = [
      ...images.map(
        (data): Anthropic.ImageBlockParam => ({
          type: "image",
          source: { type: "base64", media_type: "image/jpeg", data },
        }),
      ),
      { type: "text", text: userText },
    ];

    const stream = this.client.messages.stream({
      model,
      max_tokens: maxTokens,
      system,
      messages: [{ role: "user", content }],
    });

    for await (const event of stream) {
      if (
        event.type === "content_block_delta" &&
        event.delta.type === "text_delta"
      ) {
        yield { text: event.delta.text };
      }
    }
  }
}
