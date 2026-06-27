# AuraLearn LLM Proxy (Phase A0 + Phase C)

A **stateless** Node + TypeScript proxy that forwards K-12 tutor solve/chat
requests to the Anthropic Messages API. It is the **only holder of the LLM
vendor key** — the key never ships in the Flutter client binary.

Phase C adds: real account-JWT auth, a server-authoritative **entitlement store**,
IAP **receipt validation + anti-replay binding**, **authoritative model routing**
(the plan comes from the server, never the client), and optional **doc-context**
(context-stuffing) on `/solve` + `/chat`.

## Invariants (do not violate)

- **No key in the client / no key in git.** The Anthropic key is read from
  `ANTHROPIC_API_KEY` at runtime, injected from the host secrets manager
  (Fly.io secrets / Render env-group / Cloud Run Secret Manager). `.env` is
  gitignored. A `gitleaks` config (`.gitleaks.toml`) is wired as a CI/release
  gate that fails the build on any detected `sk-`/Anthropic key.
- **No user content stored or logged.** The proxy is stateless: it forwards the
  image + prompt to Anthropic, streams the answer back, and keeps nothing. Logs
  contain metadata only (`userId`, `model`, `plan`, event type, counters,
  timings, error codes) — never image bytes, problem text, or answer text. A
  test asserts this (`test/solve.test.ts`, `test/logging.test.ts`).
- **Plan is server-authoritative, never client-trusted.** The auth token carries
  identity only (`sub` → userId). The model/tier is resolved from the
  entitlement store; a client-sent `plan` is ignored for routing. Free users are
  abuse-capped (default 3/day); metering records are `{ userId, model, count, day }`
  — no content.
- **One receipt = one account.** IAP receipts are bound unique-per-entitlement;
  a receipt already bound to another account is rejected (`409`).
- **Tutor prompt lives server-side** (`src/prompts/tutor.ts`) and is hardened
  against image-borne prompt injection. Doc-`context` is treated as untrusted
  REFERENCE data, never instructions, and capped to `MAX_CONTEXT_CHARS`.

## Run

```bash
cd proxy
npm install

# Local dev (loads env from your shell; copy .env.example -> .env for convenience).
ANTHROPIC_API_KEY=sk-ant-...your-key... npm run dev      # tsx watch
# or production-style:
npm run build && ANTHROPIC_API_KEY=sk-ant-... npm start

# Tests (mocked Anthropic client — NO real API calls, NO key needed):
npm test
```

> The repo does NOT ship a `.env`. Create one locally if you like (it is
> gitignored), or export the vars inline. **Never commit a real key.**

## Phase A Step 0 gate — `verify-models`

Before shipping `/solve` to production you MUST run the Step-0 model-verify gate.
It calls the Anthropic **Models API** to confirm each configured model exists and
supports image input, and reports max input/output tokens. It **requires the real
key** and is intentionally not run in CI:

```bash
ANTHROPIC_API_KEY=sk-ant-... npm run verify-models
```

It prints a clear `PASS`/`FAIL` per tier and an overall verdict (exit code 0 on
pass). Record the results in the ADR "resolved model-ID verdict" field.

## Environment variables

| Var | Purpose | Default |
| --- | --- | --- |
| `ANTHROPIC_API_KEY` | **Secret.** Runtime-injected. Server refuses to start without it. | — |
| `MODEL_FREE` | Free-tier model (vision). | `claude-haiku-4-5-20251001` |
| `MODEL_PAID_STD` | Paid standard model. | `claude-sonnet-4-6` |
| `MODEL_PAID_PRO` | Paid pro model. | `claude-opus-4-8` |
| `PORT` | HTTP port. | `8787` |
| `REDIS_URL` | If set, use the Redis metering + persistent entitlement stores (multi-instance). Blank = in-memory (single instance). | blank |
| `FREE_DAILY_QUOTA` | Per-user daily question cap (abuse guard; applies to the **free** tier). | `3` |
| `ACCOUNTS_JWT_SECRET` | **Secret.** HS256 shared secret to verify account JWTs. Token conveys identity only (`sub` → userId), never the plan. | — |
| `DEV_AUTH_TOKEN` | Dev fallback bearer token (**LOCAL DEV ONLY**). Leave blank in prod. | `dev-local-token` |
| `APPLE_IAP_SHARED_SECRET` | **Secret.** Apple App Store Server API cred. Absent → mock verifier. | — |
| `APPLE_IAP_ISSUER_ID` | Apple App Store Connect issuer id. Absent → mock verifier. | — |
| `GOOGLE_PLAY_SA_JSON` | **Secret.** Google Play Developer API service-account JSON. Absent → mock verifier. | — |
| `MAX_CONTEXT_CHARS` | Max chars of doc-`context` stuffed as REFERENCE material (truncated past this). | `12000` |

Model IDs come from the official Claude reference and are kept in **env, not
hardcoded in logic**. Pricing is NOT encoded anywhere — confirm at Step 0.

### Model-ID / vision confirmation (claude-api reference)

Resolved against the official Claude API reference (Phase A Step 0 inputs):

- `claude-haiku-4-5-20251001` — Haiku 4.5, vision-capable, 200K context.
- `claude-sonnet-4-6` — Sonnet 4.6, vision, 1M context.
- `claude-opus-4-8` — Opus 4.8, vision, 1M context.

All three accept base64 `image` content blocks (`media_type: image/jpeg`) and
support Messages API streaming. The runtime `verify-models` gate must still PASS
against the live Models API before production (it asserts exact
`max_input_tokens` and the `image_input` capability per tier).

## Auth (Phase C — real account JWT)

`Authorization: Bearer <token>`. Two accepted forms, checked in this order:

1. **Dev fallback (LOCAL DEV ONLY).** If `DEV_AUTH_TOKEN` is set and the bearer
   equals it (or `<DEV_AUTH_TOKEN>:<label>` for multiple test users), it is
   accepted WITHOUT JWT verification and mapped to a content-free `userId` (a
   hash). **Leave `DEV_AUTH_TOKEN` blank in production** so only real JWTs pass.
2. **Account JWT (HS256).** Otherwise the bearer is verified as an HS256 JWT
   signed with `ACCOUNTS_JWT_SECRET` (signature checked locally, constant-time).
   `exp`/`nbf` are enforced (±30s skew). The `userId` is taken from the `sub`
   claim.

**Identity only.** The token carries *who the user is*, never their plan/tier.
The plan is always resolved server-side from the entitlement store, so a client
cannot self-upgrade by minting a richer claim. Verification is dependency-free
(`node:crypto` HMAC-SHA256) — see `src/lib/auth.ts`. `signHs256Jwt` is exported
for tests/tooling to mint tokens; the account service is the real signer.

Missing / malformed / tampered / expired / wrong-secret / `sub`-less tokens →
`unauthorized`.

## Entitlement-authoritative model routing

The model is resolved from the server-side **EntitlementStore**
(`src/lib/entitlement.ts`), NOT from the request body:

- `getEntitlement(userId)` → `{ plan: 'free'|'paid', tier: 'free'|'std'|'pro', expiresAt? }`
  (default `{ plan:'free', tier:'free' }`; an expired paid entitlement falls back
  to free).
- Routing (`resolveModelFromEntitlement`): tier `free` → `MODEL_FREE`,
  `std` → `MODEL_PAID_STD`, `pro` → `MODEL_PAID_PRO`.
- `/solve` + `/chat` still **accept** a client-sent `plan` for backwards
  compatibility but **ignore it for routing**. A free-entitled user whose request
  claims `plan:'paid'` is still served `MODEL_FREE`.
- Metering quota is keyed to the **resolved** plan: free users are capped at
  `FREE_DAILY_QUOTA`; paid users are not abuse-capped here (entitlement is the
  real gate).

In-memory store for single-instance/dev/tests; a documented
`PersistentEntitlementStore` (Redis/SQL) stub for production. Content-free schema:
`entitlement:{userId}` and a UNIQUE `receipt:{receiptId} → userId`.

## Billing / IAP (`/billing/*`) — JSON, auth required

### `POST /billing/validate`

Body: `{ "platform": "apple"|"google", "receipt"|"purchaseToken", "productId" }`.

1. Verifies the receipt behind a mockable `ReceiptVerifier`
   (`src/lib/receipt-verifier.ts`): Apple App Store Server API + Google Play
   Developer API. The REAL store call needs your credentials (`APPLE_IAP_*` /
   `GOOGLE_PLAY_SA_JSON`); **absent → a deterministic mock** (also used by tests).
2. Derives a stable, content-free `receiptId` (Apple `originalTransactionId`,
   Google `purchaseToken`).
3. **Anti-replay / cross-account (Critic M3):** if that `receiptId` is already
   owned by a **different** user → **`409 receipt_already_bound`** (one purchase
   cannot entitle many accounts). The same owner re-presenting it is an idempotent
   restore (`200`). Otherwise the receipt is bound to this user and
   `setEntitlement(userId, { plan:'paid', tier: map(productId), expiresAt })` runs.
   `productId` containing `pro` → `pro` tier, else `std`.

Responses: `200 { ok, entitlement }`, `400 bad_request`, `401 unauthorized`,
`402 invalid_receipt`, `409 receipt_already_bound`.

### `GET /billing/status`

→ `{ entitlement }` for the authenticated user (defaults to free).

## Doc-context (context-stuffing)

`/solve` and `/chat` accept an optional `context` string (imported document text
or a selected chunk). It is included in the upstream user turn as **clearly-
delimited REFERENCE material** (`参考资料` / `<<<REFERENCE>>> … <<<END REFERENCE>>>`)
— as *data, never instructions*. The same injection hardening as image-borne text
applies: anything inside the fences that tries to change the tutor's behavior or
exfiltrate the system prompt is ignored. The context is truncated to
`MAX_CONTEXT_CHARS` (default 12000) and a truncation note is added when clipped.

## Endpoints

### `POST /solve` and `POST /chat` → `text/event-stream` (SSE)

Header: `Authorization: Bearer <jwt>`

Body:

```json
{ "images": ["<base64 jpeg>", "..."], "subject": "math", "context": "<doc text>" }
```

- `images`: base64 JPEG, long-edge ≤ 1568px, ≤ 3 images.
- `subject`: optional (`math` | `physics` | `chemistry`).
- `plan`: optional, **ACCEPTED but IGNORED for routing** — the model is resolved
  from the server-side entitlement (see "Entitlement-authoritative model routing").
- `context`: optional imported-document text (stuffed as REFERENCE, capped to
  `MAX_CONTEXT_CHARS`).
- `/chat` additionally accepts `"text": "<follow-up question>"`.

#### SSE event shapes (the Flutter client matches these exactly)

Each SSE frame is a single `data: <json>` line. Events arrive in this order:

1. **recognized** — FIRST. The vision model's read of the problem.
   ```json
   {"type":"recognized","problem":"Solve 2x + 3 = 11 for x"}
   ```
2. **step** — zero or more, streamed. `index` is 0-based and monotonic.
   ```json
   {"type":"step","index":0,"content":"1. Subtract 3 from both sides: 2x = 8."}
   ```
3. **done** — LAST on success. `model` is the resolved upstream model id.
   ```json
   {"type":"done","conclusion":"x = 4","model":"claude-haiku-4-5-20251001","metered":true}
   ```
4. **error** — on quota or failure (replaces `done`).
   ```json
   {"type":"error","code":"quota_exceeded","message":"Daily question limit reached (3/day). Upgrade for more."}
   ```
   `code` is one of: `quota_exceeded`, `unauthorized`, `bad_request`,
   `upstream_error`, `internal_error`.

### `GET /healthz` → `{ "ok": true }`

## Metering semantics

- **Unit = per user-facing question.** One `/solve` invocation = one metered unit.
- **Atomic increment** (Critic-7): metering happens BEFORE streaming, in one
  check-and-increment step, so two concurrent solves at `limit-1` cannot both
  succeed.
- **Mid-stream abort = ONE question** (Critic M2): because the increment happens
  before streaming, a `/solve` that begins and then fails/aborts mid-stream is
  metered exactly once (no refund). This closes an abort-to-farm-free-tokens
  loophole.
- **Record schema:** `{ userId, model, count, day }` — never any content. The
  no-content inspection harness checks the store records, not just logs.

### Metering store implementations

- **In-memory** (default, single instance): atomic via Node's single-threaded
  event loop — the read+write happens synchronously within one tick.
- **Redis** (`REDIS_URL` set): a documented stub in `src/lib/metering.ts`. The
  production implementation uses an `EVAL` Lua script doing check-and-increment
  in one round-trip (so an over-limit user does not keep inflating the counter)
  plus a day-end `EXPIRE` TTL. Wire the live client in Phase A1.

## CI / secret-scanning gate

```bash
gitleaks detect --config .gitleaks.toml --no-git --source .   # local
gitleaks detect --config .gitleaks.toml --redact              # CI
```

The gate fails the build on any detected Anthropic/`sk-` key. `.env.example`,
this README, and the gitleaks config are allowlisted (they contain only
placeholders / format documentation).

## Credentials the user must supply (blocked on user infra)

- **Real Anthropic key + `verify-models` PASS** — required before production
  `/solve`. Cannot be run here (no key).
- **`ACCOUNTS_JWT_SECRET`** — the HS256 secret the accounts service signs JWTs
  with. Required in production (set `DEV_AUTH_TOKEN` blank there).
- **`APPLE_IAP_SHARED_SECRET` + `APPLE_IAP_ISSUER_ID`** — Apple App Store Server
  API credentials. Without them the Apple path uses the deterministic mock; the
  real `fetch` to the App Store Server API is a marked stub in
  `src/lib/receipt-verifier.ts`.
- **`GOOGLE_PLAY_SA_JSON`** — Google Play Developer API service-account JSON.
  Without it the Google path uses the mock; the real call is the matching stub.
- **Redis / DB** — `REDIS_URL` + a live client wired into `RedisMeteringStore`
  and `PersistentEntitlementStore` for multi-instance deployments.
- **Host secrets manager** — Fly.io/Render/Cloud Run secret injection for all
  secrets above (and key rotation + separate dev/prod keys).
