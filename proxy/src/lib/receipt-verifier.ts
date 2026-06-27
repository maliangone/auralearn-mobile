/**
 * IAP receipt verification (Phase C).
 *
 * The route layer (routes/billing.ts) depends ONLY on the `ReceiptVerifier`
 * interface so tests inject a deterministic mock with NO network.
 *
 * Two real backends:
 *  - Apple: App Store Server API (verify a transaction; the stable id is
 *    `originalTransactionId`).
 *  - Google: Google Play Developer API (purchases.products/subscriptions.get; the
 *    stable id is the `purchaseToken`).
 *
 * The REAL verification call needs the user's store credentials, so it is guarded
 * behind env (APPLE_IAP_*, GOOGLE_PLAY_SA_JSON). When credentials are absent we
 * fall back to a deterministic mock (also used in tests). This file implements the
 * STRUCTURE + parsing + receiptId derivation; the network call itself is a clearly
 * marked stub the user wires with their credentials.
 */

export type Platform = "apple" | "google";

export interface ReceiptVerifyRequest {
  platform: Platform;
  /** Apple StoreKit receipt / signed transaction (base64 or JWS). */
  receipt?: string;
  /** Google Play purchase token. */
  purchaseToken?: string;
  /** The product the client claims was purchased. */
  productId: string;
}

export interface ReceiptVerifyOk {
  ok: true;
  /**
   * Stable, content-free id that uniquely identifies the purchase across
   * restores: Apple `originalTransactionId`, Google `purchaseToken`.
   */
  receiptId: string;
  productId: string;
  /** Epoch millis the entitlement expires (subscriptions), if known. */
  expiresAt?: number;
}

export interface ReceiptVerifyErr {
  ok: false;
  /** Machine code: "invalid_receipt" | "verifier_unavailable" | "bad_request". */
  code: "invalid_receipt" | "verifier_unavailable" | "bad_request";
  message: string;
}

export type ReceiptVerifyResult = ReceiptVerifyOk | ReceiptVerifyErr;

export interface ReceiptVerifier {
  verify(req: ReceiptVerifyRequest): Promise<ReceiptVerifyResult>;
}

/** 30 days in ms — the mock's default subscription window. */
const THIRTY_DAYS_MS = 30 * 24 * 60 * 60 * 1000;

/**
 * Deterministic mock verifier (tests + when store creds are absent).
 *
 * Rules (deterministic, no network):
 *  - A receipt/token that contains the literal substring "invalid" is rejected.
 *  - Otherwise it is accepted; the receiptId is derived deterministically from the
 *    platform-appropriate field (Apple: receipt; Google: purchaseToken), so the
 *    SAME receipt always yields the SAME receiptId (this is what powers the
 *    anti-replay / cross-account test).
 *  - expiresAt = now + 30d (a stable, content-free window).
 */
export class MockReceiptVerifier implements ReceiptVerifier {
  constructor(private readonly now: () => number = Date.now) {}

  async verify(req: ReceiptVerifyRequest): Promise<ReceiptVerifyResult> {
    const raw = req.platform === "apple" ? req.receipt : req.purchaseToken;
    if (!raw || raw.trim() === "") {
      return {
        ok: false,
        code: "bad_request",
        message:
          req.platform === "apple"
            ? "apple receipt is required"
            : "google purchaseToken is required",
      };
    }
    if (raw.toLowerCase().includes("invalid")) {
      return { ok: false, code: "invalid_receipt", message: "receipt failed verification" };
    }
    // Apple's stable id is originalTransactionId; for the mock we treat the
    // receipt string itself as that stable id. Google's stable id IS the token.
    const receiptId = `${req.platform}:${raw}`;
    return {
      ok: true,
      receiptId,
      productId: req.productId,
      expiresAt: this.now() + THIRTY_DAYS_MS,
    };
  }
}

/**
 * Real verifier (DOCUMENTED STUB). Selects Apple/Google and, when credentials are
 * present, performs the store call; otherwise delegates to the mock.
 *
 * The network call is intentionally NOT implemented in this lane (it needs the
 * user's store credentials). The structure, credential gating, and receiptId
 * derivation are real; wire the two `fetch` calls marked below in production.
 */
export class StoreReceiptVerifier implements ReceiptVerifier {
  private readonly mock: MockReceiptVerifier;

  constructor(
    private readonly creds: {
      appleSharedSecret: string;
      appleIssuerId: string;
      googlePlaySaJson: string;
    },
    now: () => number = Date.now,
  ) {
    this.mock = new MockReceiptVerifier(now);
  }

  async verify(req: ReceiptVerifyRequest): Promise<ReceiptVerifyResult> {
    if (req.platform === "apple") return this.verifyApple(req);
    if (req.platform === "google") return this.verifyGoogle(req);
    return { ok: false, code: "bad_request", message: `unknown platform: ${String(req.platform)}` };
  }

  private async verifyApple(req: ReceiptVerifyRequest): Promise<ReceiptVerifyResult> {
    const hasCreds = this.creds.appleSharedSecret !== "" && this.creds.appleIssuerId !== "";
    if (!hasCreds) {
      // No credentials -> deterministic mock (documented fallback).
      return this.mock.verify(req);
    }
    // --- PRODUCTION STUB ---------------------------------------------------
    // Wire the Apple App Store Server API here:
    //   POST https://api.storekit.itunes.apple.com/inApps/v1/.../{txId}
    //   sign a JWT with appleIssuerId + key; parse the signed transaction; the
    //   stable id is `originalTransactionId`; expiresAt from `expiresDate`.
    //   On success: { ok: true, receiptId: `apple:${originalTransactionId}`, ... }
    //   On failure: { ok: false, code: "invalid_receipt", ... }
    // -----------------------------------------------------------------------
    throw new Error(
      "StoreReceiptVerifier.verifyApple is a documented stub: wire the App Store " +
        "Server API call with your APPLE_IAP_* credentials.",
    );
  }

  private async verifyGoogle(req: ReceiptVerifyRequest): Promise<ReceiptVerifyResult> {
    const hasCreds = this.creds.googlePlaySaJson !== "";
    if (!hasCreds) {
      return this.mock.verify(req);
    }
    // --- PRODUCTION STUB ---------------------------------------------------
    // Wire the Google Play Developer API here:
    //   GET androidpublisher/v3/applications/{pkg}/purchases/.../{purchaseToken}
    //   authenticate with the service-account JSON (GOOGLE_PLAY_SA_JSON); the
    //   stable id IS the purchaseToken; expiresAt from `expiryTimeMillis`.
    //   On success: { ok: true, receiptId: `google:${purchaseToken}`, ... }
    // -----------------------------------------------------------------------
    throw new Error(
      "StoreReceiptVerifier.verifyGoogle is a documented stub: wire the Google " +
        "Play Developer API call with your GOOGLE_PLAY_SA_JSON credentials.",
    );
  }
}

/**
 * Factory: use the real store verifier when ANY store credential is present,
 * otherwise the deterministic mock. The store verifier itself falls back to the
 * mock per-platform when that platform's creds are missing — so a deploy with
 * only Apple creds still mock-verifies Google in dev.
 */
export function createReceiptVerifier(
  creds: { appleSharedSecret: string; appleIssuerId: string; googlePlaySaJson: string },
  now: () => number = Date.now,
): ReceiptVerifier {
  const anyCreds =
    creds.appleSharedSecret !== "" || creds.appleIssuerId !== "" || creds.googlePlaySaJson !== "";
  return anyCreds ? new StoreReceiptVerifier(creds, now) : new MockReceiptVerifier(now);
}

/** Map a productId to a tier. Conservative: explicit pro ids -> pro, else std. */
export function productIdToTier(productId: string): "std" | "pro" {
  return /pro/i.test(productId) ? "pro" : "std";
}
