/**
 * Model router — env-driven (Critic 6b), provider-agnostic.
 *
 * The plan->model MAP is wired here. The per-user plan LOOKUP is server-side:
 * the route applies the resolved Entitlement (default plan "free").
 *
 * Pricing is NOT encoded here — only the env model IDs. Do not hardcode.
 */

import type { AppConfig, TierConfig } from "../config.js";
import type { Entitlement, Tier } from "./entitlement.js";

/**
 * AUTHORITATIVE model routing. The model is resolved from the server-side
 * Entitlement — NOT from any client-sent `plan`.
 *
 *   tier "free" -> config.models.free
 *   tier "std"  -> config.models.paidStd
 *   tier "pro"  -> config.models.paidPro
 *
 * (A paid plan with a stale/unknown tier defaults to the std paid tier.)
 */
export function resolveProviderFromEntitlement(
  config: AppConfig,
  ent: Entitlement,
): TierConfig {
  if (ent.plan === "free") return config.models.free;
  return tierToPaidTier(config, ent.tier);
}

function tierToPaidTier(config: AppConfig, tier: Tier): TierConfig {
  if (tier === "pro") return config.models.paidPro;
  // "std" or, defensively, "free" tier on a paid plan -> standard paid tier.
  return config.models.paidStd;
}
