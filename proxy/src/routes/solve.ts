/**
 * POST /solve and POST /chat -> text/event-stream (SSE).
 *
 * Both share the same pipeline (solve-handler). /chat additionally accepts a
 * `text` follow-up. Auth is verified up front; on auth failure we still respond
 * with an SSE error event (so the client's single SSE consumer handles it).
 */

import type { FastifyInstance, FastifyReply, FastifyRequest } from "fastify";
import type { AppConfig } from "../config.js";
import type { TutorModel } from "../lib/anthropic.js";
import type { MeteringStore } from "../lib/metering.js";
import type { EntitlementStore } from "../lib/entitlement.js";
import type { Logger } from "../lib/logger.js";
import type { SolveRequestBody, SolveEvent } from "../types.js";
import { verifyAuth } from "../lib/auth.js";
import { runSolve } from "../lib/solve-handler.js";
import { formatSseEvent, SSE_HEADERS } from "../lib/sse.js";

export interface RouteDeps {
  config: AppConfig;
  model: TutorModel;
  metering: MeteringStore;
  entitlement: EntitlementStore;
  logger: Logger;
}

function beginSse(reply: FastifyReply): (event: SolveEvent) => void {
  reply.raw.writeHead(200, SSE_HEADERS);
  return (event: SolveEvent) => {
    reply.raw.write(formatSseEvent(event));
  };
}

async function handle(
  deps: RouteDeps,
  route: "/solve" | "/chat",
  request: FastifyRequest,
  reply: FastifyReply,
): Promise<void> {
  const reqId = (request.id as string) ?? undefined;
  const auth = verifyAuth(request.headers["authorization"], {
    accountsJwtSecret: deps.config.accountsJwtSecret,
    devAuthToken: deps.config.devAuthToken,
  });

  const emit = beginSse(reply);

  if (!auth.ok) {
    emit({ type: "error", code: "unauthorized", message: "Authentication required." });
    deps.logger.info("auth failed", { reqId, route, code: "unauthorized", event: "auth" });
    reply.raw.end();
    return;
  }

  const body = (request.body ?? {}) as Partial<SolveRequestBody>;
  await runSolve(
    deps,
    {
      userId: auth.userId,
      // `plan` is accepted but IGNORED for routing (entitlement is authoritative).
      plan: body.plan === "free" || body.plan === "paid" ? body.plan : undefined,
      images: Array.isArray(body.images) ? body.images : [],
      subject: typeof body.subject === "string" ? body.subject : undefined,
      text: typeof body.text === "string" ? body.text : undefined,
      context: typeof body.context === "string" ? body.context : undefined,
    },
    emit,
    { reqId, route },
  );

  reply.raw.end();
}

export function registerSolveRoutes(app: FastifyInstance, deps: RouteDeps): void {
  app.post("/solve", (req, reply) => handle(deps, "/solve", req, reply));
  app.post("/chat", (req, reply) => handle(deps, "/chat", req, reply));
}
