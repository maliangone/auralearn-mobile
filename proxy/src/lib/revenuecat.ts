/**
 * RevenueCat REST client (Phase 3) — the purchase authority.
 *
 * The proxy queries RevenueCat itself (`GET /v1/subscribers/{appUserId}`);
 * clients NEVER send receipts. The Firebase uid IS the RevenueCat appUserID
 * (the Flutter app calls Purchases.logIn(uid) on sign-in), so one lookup
 * resolves the account's entitlement directly.
 *
 * `fetchFn` is injectable for tests; missing REVENUECAT_API_KEY => lookups
 * return a deterministic "not subscribed" (dev mode), never a crash.
 */

import type { Tier } from "./entitlement.js";

export interface RevenueCatSubscriber {
  plan: "free" | "paid";
  tier: Tier;
  /** Epoch millis when the entitlement expires (paid). Absent for free. */
  expiresAt?: number;
}

export interface RevenueCatClient {
  /** Resolve the 'pro' entitlement for an appUserID. 404 => not subscribed. */
  getSubscriber(appUserId: string): Promise<RevenueCatSubscriber>;
}

export const REVENUECAT_ENTITLEMENT_ID = "pro";

export class RevenueCatRestClient implements RevenueCatClient {
  constructor(
    private readonly apiKey: string,
    private readonly fetchFn: typeof fetch = fetch,
  ) {}

  async getSubscriber(appUserId: string): Promise<RevenueCatSubscriber> {
    if (this.apiKey === "") {
      return { plan: "free", tier: "free" };
    }

    const res = await this.fetchFn(
      `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}`,
      {
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
          Accept: "application/json",
        },
      },
    );

    if (res.status === 404) {
      // Unknown subscriber => never subscribed (or no active entitlement).
      return { plan: "free", tier: "free" };
    }
    if (!res.ok) {
      throw new Error(`RevenueCat API error ${res.status}`);
    }

    const json = (await res.json()) as {
      subscriber?: {
        entitlements?: Record<
          string,
          {
            expires_date?: string | null;
            product_identifier?: string;
          }
        >;
      };
    };
    const ent = json.subscriber?.entitlements?.[REVENUECAT_ENTITLEMENT_ID];
    if (!ent) {
      return { plan: "free", tier: "free" };
    }

    const expiresDate = ent.expires_date;
    const expiresAt = expiresDate ? Date.parse(expiresDate) : undefined;
    // An entitlement with a past expiry is inactive.
    if (typeof expiresAt === "number" && Date.now() > expiresAt) {
      return { plan: "free", tier: "free" };
    }

    const productId = ent.product_identifier ?? "";
    return {
      plan: "paid",
      tier: productId.includes("pro") ? "pro" : "std",
      ...(typeof expiresAt === "number" ? { expiresAt } : {}),
    };
  }
}
