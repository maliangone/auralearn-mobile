# AuraLearn LLM Proxy (Phase A0 + Phase C)

A **stateless** Node + TypeScript proxy that forwards K-12 tutor solve/chat
requests to a per-tier upstream model — Anthropic Messages API or any
OpenAI-compatible chat-completions host (OpenAI `gpt-5.6-luna`, DeepSeek,
custom endpoints). It is the **only holder of the LLM vendor keys** — keys
never ship in the Flutter client binary.

Phase 3 adds: Firebase Auth (ID-token verification) + Firestore persistence, a
RevenueCat-authoritative **entitlement store** (sync + webhook), **authoritative
model routing** (the plan comes from the server, never the client), and optional
**doc-context** (context-stuffing) on `/solve` + `/chat`.

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
| `ANTHROPIC_API_KEY` | **Secret.** Runtime-injected. Required only if a tier uses the anthropic provider. | — |
| `ANTHROPIC_BASE_URL` | Anthropic API base URL. | `https://api.anthropic.com` |
| `OPENAI_API_KEY` | **Secret.** Runtime-injected. Required only if a tier uses the openai provider. | — |
| `OPENAI_BASE_URL` | OpenAI-compatible base URL (OpenAI, DeepSeek, any chat-completions host). | `https://api.openai.com/v1` |
| `{FREE\|STD\|PRO}_PROVIDER` | Per-tier provider: `anthropic` \| `openai`. | `openai` (or `anthropic` if the legacy `MODEL_*` var is set) |
| `{FREE\|STD\|PRO}_MODEL` | Per-tier model id. | `gpt-5.6-luna` (openai) / legacy Claude ids (anthropic) |
| `{FREE\|STD\|PRO}_REASONING_EFFORT` | OpenAI-compatible `reasoning_effort` (none/low/medium/high/xhigh/max). Empty = omit. | `max` on api.openai.com; empty elsewhere |
| `{FREE\|STD\|PRO}_SUPPORTS_VISION` | `true`/`false`. Images on a text-only tier are rejected with `model_no_vision` (before metering). | inferred (deepseek base URL => false) |
| `PORT` | HTTP port. | `8787` |
| `FIREBASE_PROJECT_ID` | Firebase project id — enables Firebase ID-token verification + Firestore persistence (production). Blank = in-memory stores, dev/legacy auth only. | blank |
| `REVENUECAT_API_KEY` | **Secret.** RevenueCat REST API key for `/billing/sync` lookups. Blank = "not subscribed" (dev-safe). | — |
| `REVENUECAT_WEBHOOK_SECRET` / `REVENUECAT_WEBHOOK_HMAC_SECRET` | **Secrets.** Webhook auth (static + HMAC). Blank = webhook always 401. | — |
| `FREE_DAILY_QUOTA` | Per-user daily question cap (abuse guard; applies to the **free** tier). | `3` |
| `ACCOUNTS_JWT_SECRET` | **Secret.** HS256 shared secret to verify account JWTs. Token conveys identity only (`sub` → userId), never the plan. | — |
| `DEV_AUTH_TOKEN` | Dev fallback bearer token (**LOCAL DEV ONLY**). Leave blank in prod. | `dev-local-token` |
| `MAX_CONTEXT_CHARS` | Max chars of doc-`context` stuffed as REFERENCE material (truncated past this). | `12000` |

Model IDs come from the official vendor references and are kept in **env, not
hardcoded in logic**. Pricing is NOT encoded anywhere — confirm at Step 0.

### Model routing (provider-agnostic)

Each tier resolves to `{ provider, model, reasoningEffort, supportsVision }`
(`src/config.ts`). The **default stack is OpenAI `gpt-5.6-luna` with
`reasoning_effort=max`** for all three tiers — it is vision-capable and cheap.
The legacy `MODEL_FREE` / `MODEL_PAID_STD` / `MODEL_PAID_PRO` envs remain
supported and select the Anthropic provider (Haiku 4.5 / Sonnet 4.6 /
Opus 4.8, all vision). DeepSeek is available as a **text-only lane**
(`{tier}_PROVIDER=openai` + `OPENAI_BASE_URL=https://api.deepseek.com` +
`{tier}_MODEL=deepseek-chat`): its official API does not accept images, so
photo requests on that tier are rejected with `model_no_vision` **before
metering** (no quota cost).

The `verify-models` gate (below) must still PASS against the live endpoints
before production.

### Model-ID / vision confirmation (claude-api reference)

Resolved against the official Claude API reference (Phase A Step 0 inputs):

- `claude-haiku-4-5-20251001` — Haiku 4.5, vision-capable, 200K context.
- `claude-sonnet-4-6` — Sonnet 4.6, vision, 1M context.
- `claude-opus-4-8` — Opus 4.8, vision, 1M context.

All three accept base64 `image` content blocks (`media_type: image/jpeg`) and
support Messages API streaming. `gpt-5.6-luna` accepts `image_url` content
parts (data URLs), supports `reasoning_effort` up to `max`, ~1M context, and
is the default photo-solving lane. DeepSeek's official chat API is text-only
(no `image_url` support) — text follow-ups only.

## Auth (Phase 3 — Firebase ID token)

`Authorization: Bearer <token>`. Accepted forms, checked in this order:

1. **Dev fallback (LOCAL DEV ONLY).** If `DEV_AUTH_TOKEN` is set and the bearer
   equals it (or `<DEV_AUTH_TOKEN>:<label>` for multiple test users), it is
   accepted WITHOUT verification and mapped to a content-free `userId` (a
   hash). **Leave `DEV_AUTH_TOKEN` blank in production** so only real ID tokens
   pass.
2. **Firebase ID token (production).** When `FIREBASE_PROJECT_ID` is set, the
   bearer is verified via firebase-admin `verifyIdToken` — the Flutter client
   signs in with Google/Apple through Firebase Auth and sends this token. The
   Firebase uid (`sub`) is the `userId` every route keys on, and is also the
   RevenueCat appUserID (the client calls `Purchases.logIn(uid)`).
3. **Legacy HS256 JWT (dev/tooling).** `ACCOUNTS_JWT_SECRET` verification is
   kept for local tooling compatibility (`src/lib/auth.ts`).

**Identity only.** The token carries *who the user is*, never their plan/tier.
The plan is always resolved server-side (RevenueCat + Firestore), so a client
cannot self-upgrade by minting a richer claim.

Missing / malformed / tampered / expired / revoked tokens → `unauthorized`.

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

## Billing / subscriptions (`/billing/*`, `/webhook/revenuecat`) — JSON, auth required

RevenueCat is the purchase authority (Phase 3). Receipts NEVER reach this
proxy: the store SDK hands them to RevenueCat, and this service either
pulls (`/billing/sync`) or receives pushes (webhook).

### `POST /billing/sync`

Body: `{}` — the client sends nothing; the server queries
`GET https://api.revenuecat.com/v1/subscribers/{uid}` itself and persists the
`pro` entitlement (plan/tier/expiry) into the entitlement store. The Firebase
uid IS the RevenueCat appUserID (the app calls `Purchases.logIn(uid)`).

Responses: `200 { ok, plan, tier, expiresAt }`, `401 unauthorized`,
`502 upstream_error` (RevenueCat unreachable).

### `GET /billing/status`

→ `{ plan, tier, expiresAt }` for the authenticated user (defaults to free).

### `POST /webhook/revenuecat`

Push channel for renewals/expirations. Dual auth: a static
`Authorization: Bearer <REVENUECAT_WEBHOOK_SECRET>` AND an
`X-RevenueCat-Webhook-Signature` HMAC-SHA256 (`t=...,v1=...`, 300s window).

- Grant events (INITIAL_PURCHASE / RENEWAL / UNCANCELLATION / PRODUCT_CHANGE /
  SUBSCRIPTION_EXTENDED) persist `plan=paid` + expiry; revoke events
  (EXPIRATION / BILLING_ISSUE) persist `plan=free`.
- Idempotent + out-of-order safe: event ids are recorded in Firestore
  (`revenuecatWebhookEvents/{eventId}`) inside the same transaction that writes
  `users/{uid}`; events older than the user's last-applied
  `subscriptionEventAtMs` are dropped.
- `$RCAnonymousID` app user ids are resolved from `aliases` to the real
  Firebase uid.

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
   `upstream_error`, `internal_error`, `model_no_vision` (the resolved tier
   model is text-only and the request carried images — emitted BEFORE
   metering, so no quota is consumed).

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

- **In-memory** (default, dev/test): atomic via Node's single-threaded event
  loop — the read+write happens synchronously within one tick.
- **Firestore** (`FIREBASE_PROJECT_ID` set, production): the daily counter
  lives on `users/{uid}`; the check-and-increment runs in a Firestore
  transaction (serialized on the user document), so N concurrent solves at
  limit-1 yield exactly one allowed result. Restarts keep the counters.

## Cloud Run deployment (Phase 3)

`Dockerfile` + `deploy.sh` deploy the proxy to Cloud Run (region
asia-southeast1, 512Mi/1CPU, min 0 / max 3, timeout 300s for long streams,
`--allow-unauthenticated` — every route verifies auth at the application
layer). ADC gives the runtime service account Firestore + Firebase Auth
access.

```bash
# One-time: create secrets (never committed anywhere)
gcloud secrets create ANTHROPIC_API_KEY --data-file=- <<< "sk-ant-..."
gcloud secrets create OPENAI_API_KEY --data-file=- <<< "sk-..."
gcloud secrets create REVENUECAT_API_KEY --data-file=- <<< "sk_..."
gcloud secrets create REVENUECAT_WEBHOOK_SECRET --data-file=- <<< "<random>"
gcloud secrets create REVENUECAT_WEBHOOK_HMAC_SECRET --data-file=- <<< "<random>"

FIREBASE_PROJECT_ID=your-firebase-project-id ./deploy.sh
```

Then point the Flutter client at the service URL:
`flutter run --dart-define=PROXY_URL=https://<service>-...run.app` and add the
Firebase + RevenueCat dart-defines (see the client README/SETUP).

## CI / secret-scanning gate

```bash
gitleaks detect --config .gitleaks.toml --no-git --source .   # local
gitleaks detect --config .gitleaks.toml --redact              # CI
```

The gate fails the build on any detected Anthropic/`sk-` key. `.env.example`,
this README, and the gitleaks config are allowlisted (they contain only
placeholders / format documentation).

## Credentials the user must supply (blocked on user infra)

- **Real provider keys + `verify-models` PASS** — `ANTHROPIC_API_KEY` /
  `OPENAI_API_KEY` for the tiers actually configured. Required before
  production `/solve` (dev can run on `DEV_AUTH_TOKEN` + in-memory stores).
- **`FIREBASE_PROJECT_ID` + Firebase project** — enables Firebase ID-token
  verification and Firestore persistence. Without it the proxy runs
  in-memory (dev only; restart loses metering/entitlement).
- **`REVENUECAT_API_KEY` + webhook secrets** — subscription sync + webhook
  auth. Without them `/billing/sync` reports "not subscribed" (dev-safe).
- **gcloud project** — Cloud Run + Secret Manager for the production deploy
  (key rotation + separate dev/prod keys per the M1 lifecycle).
