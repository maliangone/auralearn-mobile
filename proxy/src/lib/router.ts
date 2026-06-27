/**
 * Model router — env-driven (Critic 6b).
 *
 * The plan->model MAP is wired here in Phase A0. The per-user plan LOOKUP is
 * deferred to Phase C: in A0 the route applies a default plan ("free") unless the
 * request body / a benchmark override says otherwise, so paid-tier model IDs can
 * be benchmarked before entitlement ships.
 *
 * Pricing is NOT encoded here — only the env model IDs. Do not hardcode.
 */

import type { AppConfig } from "../config.js";
import type { Entitlement, Tier } from "./entitlement.js";

/**
 * AUTHORITATIVE model routing (Phase C). The model is resolved from the
 * server-side Entitlement — NOT from any client-sent `plan`.
 *
 *   tier "free" -> MODEL_FREE
 *   tier "std"  -> MODEL_PAID_STD
 *   tier "pro"  -> MODEL_PAID_PRO
 *
 * (A paid plan with a stale/unknown tier defaults to the std paid model.)
 */
export function resolveModelFromEntitlement(config: AppConfig, ent: Entitlement): string {
  if (ent.plan === "free") return config.models.free;
  return tierToPaidModel(config, ent.tier);
}

function tierToPaidModel(config: AppConfig, tier: Tier): string {
  if (tier === "pro") return config.models.paidPro;
  // "std" or, defensively, "free" tier on a paid plan -> standard paid model.
  return config.models.paidStd;
}
