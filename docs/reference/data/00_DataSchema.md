# Firestore Data Model & Schema Design

Decision-stage design document. Covers whole-app Firestore/Cloud Storage schema for the four core domains (User/ClothingItem/Composition/StyleLog). No implementation code (Dart, security rules, indexes) is written here — those are implementation-stage work.

**Source of truth split:**
- Field shapes → current `lib/models/*.dart` (not `00_MVP.md` §5, which is a stale early draft this document supersedes for that purpose).
- Closed-vocabulary values → `lib/models/enums.dart`. This document never restates an enum's value list in prose; it only names which enum a field maps to, per the project's hardcoding-principle skill (`engineering-principles`).

Non-goals: no Phase 2/3 features are introduced (composition calendar, hotspot layers, recommendations/feed, custom groups stay excluded per `00_MVP.md` §2).

---

## 1. Collection Topology — biggest open architectural call

**Decision: user-scoped subcollections**, not flat top-level collections with a `userId` field.

```
users/{uid}                                  (profile doc)
users/{uid}/clothingItems/{itemId}
users/{uid}/compositions/{compositionId}
users/{uid}/styleLogs/{styleLogId}
```

**Revised 2026-08-04 — the first two bullets below originally cited Anonymous Auth, which §11 later replaced entirely.** §11 confirms zero Firebase Auth calls (including Anonymous Auth) before the user explicitly links a social account; pre-link, the app uses a fixed local placeholder path segment (`unlinked_local`) instead of a real `uid`. This doesn't weaken the topology conclusion — if anything it reinforces it: because the placeholder scope already has the exact same `users/{scope}/...` shape as a real `uid` would, the identical code paths and query shapes work before and after linking, with only the path segment changing (§11.2's migration is a bulk document copy to a new path prefix, not an Auth-level `linkWithCredential()` call as originally described here). Justification, updated:

- **A `uid`-shaped scope exists from the very first launch, real or placeholder** — pre-link, `unlinked_local` fills the same structural role a real `uid` would; there is never a "no scope yet" moment to design around, so nesting under `users/{scope}` has no bootstrapping problem regardless of link status (§11).
- **Linking migrates cleanly without changing topology**: linking swaps the local placeholder scope for a real `uid` via a one-time bulk document copy (§11.2) — the *documents move*, but the *shape they move into* (`users/{uid}/...`) is identical to what they already had (`users/{placeholder}/...`). Subcollection paths need zero structural change when that happens, only the path segment's value.
- **Security rules are structurally safer**: `match /users/{uid}/{document=**} { allow read, write: if request.auth.uid == uid; }` scopes access by construction. A flat-collection + `userId` field design instead requires every query to remember `where('userId', isEqualTo: uid)` and every rule to check `resource.data.userId == request.auth.uid` — a single missed filter is a cross-user data leak. Subcollections make that class of mistake structurally harder to make.
- **Single-device-at-a-time usage in practice**: there is no current need for cross-user queries. If the Phase-3-maybe lightweight community layer (public/private, follow, likes — `00_MVP.md` §1) ever ships, Firestore's collection-group queries (`collectionGroup('clothingItems')`) still allow reading across all users' subcollections without flattening anything — so this choice does not foreclose that hypothetical future.
- **Offline cache behavior**: Firestore's offline persistence caches per query, not by collection nesting depth. Subcollections and flat top-level collections behave identically here, so this axis doesn't favor either option.

**Trade-off acknowledged**: flat top-level + `userId` would be simpler *if* this app ever needed a single global query across all users' data (e.g., an admin dashboard querying "every ClothingItem using material X, across all users"). No such need is in scope today, and collection-group queries cover the realistic version of it anyway.

**Review: challenge this first if you disagree** — see Open Question #1.

---

## 2. `users/{uid}` — User profile

| Field | Firestore type | Nullable | Notes |
|---|---|---|---|
| *(doc ID)* | — | — | Real Firebase Auth `uid` **once linked** — before that, this doc doesn't exist on the server at all, see §11 |
| `email` | string | yes | sourced from the linked social provider's profile (not manually typed) — `null` until linked, see §11 for the auth model |
| `authProvider` | string | yes | which social provider was used to link — candidate value list not finalized, see Open Question #15. **Not yet in code** (no `User` Dart model exists yet at all) |
| `createdAt` | Timestamp | no | account creation time — for a linked user, this is link time, not local-first-use time (that's `acquiredAt`-equivalent for the whole account, tracked locally, not in this doc since it's pre-link and never reaches Firestore) |
| `lastActiveAt` | Timestamp | no | 최근 접속 시각 — 앱 실행/재개(또는 재로그인)마다 갱신, **오프라인이어도 갱신됨**(로컬 이벤트). `createdAt`과 별개 필드(계정 생성 시각 vs 최근 사용 시각). 사용자 스키마 리뷰(2026-08-03)로 추가 |
| `lastSyncedAt` | Timestamp | yes | 마지막으로 서버와 동기화가 실제로 완료된 시각 — `lastActiveAt`과 달리 **온라인 상태에서만 갱신됨**(§11 링크 이후, `enableNetwork()` 상태에서 pending write가 전부 서버에 반영된 시점). 링크 직후 최초 동기화 전까지 `null`. 클라이언트가 `waitForPendingWrites()` 완료 시점에 이 필드를 갱신하는 방식 제안. 멀티기기 사용 시 기기마다 각자 이 값을 덮어써서 마지막으로 동기화한 기기 기준이 됨(현재 단일기기 전제라 더 설계하지 않음). 사용자 스키마 리뷰(2026-08-03)로 추가 |

Kept minimal, mirroring `00_MVP.md` §5's own draft (`id`/`email`/`created_at`) plus `lastActiveAt`/`lastSyncedAt`/`authProvider` added per direct user review. No dedicated `User` Dart model exists in `lib/models/` yet, so nothing beyond this is invented. **This entire document (`users/{uid}`) only exists once a user has linked an account** — see §11 for what happens before that point.

**Deliberately not included yet** (see Open Question #10): fields tied to a not-yet-defined monetization/billing model — e.g. `closetSlotLimit`(이용 가능한 최대 옷장 칸 수) or `bgRemovalCreditsRemaining`(이미지 배경 자동 제거 잔여 시도 횟수). Flagged by the user during review (2026-08-03) as likely-needed once a billing tier structure exists, but not added now since that structure isn't decided yet.

---

## 3. `users/{uid}/clothingItems/{itemId}`

Source of truth for shape: `lib/models/clothing_item.dart`.

| Field | Firestore type | Nullable | Notes |
|---|---|---|---|
| `name` | string | no | |
| `category` | string | yes | enum-name string → `ClothingCategory` (`lib/models/enums.dart`) |
| `color` | string | yes | enum-name string → `ClothingColor` — **proposed enum, not yet in `enums.dart`**, see Open Question #11. Reverses this document's earlier note that `color` was confirmed free text; user review (2026-08-03) decided it should be closed like `category`/`season`/`material` |
| `season` | string | yes | → `Season` enum |
| `material` | string | yes | → `ClothingMaterial` enum (~18 perception-based values; rationale in `docs/history/Decision.md`) |
| `hasGraphic` | boolean | yes | 그래픽(그림·로고·프린트) 유무 — AI 자동 태깅 대상이라 미태깅 상태를 표현하려 nullable. **Not yet in `lib/models/clothing_item.dart`**, see Open Question #12 |
| `hasPattern` | boolean | yes | 패턴(줄무늬·체크 등 반복 텍스타일 패턴) 유무 — `hasGraphic`과 독립(한 옷에 둘 다 있을 수 있음). **Not yet in `lib/models/clothing_item.dart`**, see Open Question #12 |
| `imagePath` | string | no | Cloud Storage path — background-removed image, see §8 |
| `createdAt` | Timestamp | no | 앱에 등록(입력)한 시각 — 실제 구매/획득 시각과 다를 수 있음, 그 구분은 `acquiredAt` 참고 |
| `acquiredAt` | Timestamp | yes | 실제 습득(구매 등)일 — 오래된 옷을 나중에 등록하는 경우 `createdAt`과 달라질 수 있어 별도 필드. 모르거나 안 적을 수 있어 nullable. **Not yet in `lib/models/clothing_item.dart`**, added per user review (2026-08-03) |
| `location` | string | no (default `''`) | free-text location memo |
| `memo` | string | no (default `''`) | |
| `wearCount` | number (int) | no (default `0`) | auto-aggregated, see §6 |
| `isIncomplete` | boolean | no (default `false`) | Editor Draft marker, see §9 |
| `isDeleted` | boolean | no (default `false`) | soft-delete flag, see §5 |
| `deletedAt` | Timestamp | yes | set together with `isDeleted:true`; cleared on restore |
| `analysisMetadata` | map | yes | 추천 알고리즘용 사진 분석 결과 컨테이너 — **내부 구조는 아직 미정**(추천 알고리즘 설계 시점에 결정, 지금 억지로 필드를 구체화하지 않음). MVP 초안(`00_MVP.md` §5)의 `internal_tags` 개념을 일반화한 것 — 사용자에게 노출되지 않는 내부용 데이터. See §12 |
| `analysisModelVersion` | string | yes | 이 `analysisMetadata`를 생성한 분석 모델의 버전 식별자. `null` = 아직 한 번도 분석 안 됨. 앱의 "현재 목표 버전"(아이템별 값 아닌 전역 설정)과 비교해 재분석 필요 여부 판단, see §12 |
| `analyzedAt` | Timestamp | yes | 마지막 분석 완료 시각. 재분석 여부 판단 자체엔 `analysisModelVersion` 비교만으로 충분(이 필드는 판단에 필수는 아님) — 디버깅/UI 표시용으로 유지, 다른 타임스탬프 필드들과 일관성 유지 |

**Required vs. optional input (2026-08-03 user review)**: the Nullable column above is the only distinction this document models — it reflects storage-level optionality, not which fields a UI form forces the user to fill in before saving. Whether an entry screen additionally *requires* a nullable field (e.g. always asking for `color` even though it's nullable at the DB level) is an implementation-stage UI/form-validation decision, intentionally left unmodeled here.

**Deliberately not included** (see Open Questions #2, #3, #5): `originalImagePath` (pre-background-removal image), `lastWornDate`, and `00_MVP.md` §4.1's remaining richer auto-tagging fields (`moodTags`, `internalTags`, `brand`/`purchasePlace`/`price`) — none of these exist in `lib/models/clothing_item.dart` today, so per the source-of-truth rule above they are left out rather than pre-declared. (`hasGraphic` was in this list until the 2026-08-03 review decided to split it into `hasGraphic`/`hasPattern`, added to the table above instead.)

---

## 4. `users/{uid}/compositions/{compositionId}`

Source of truth for shape: `lib/models/composition.dart`.

| Field | Firestore type | Nullable | Notes |
|---|---|---|---|
| `name` | string | no | max 40 chars is a UI-level constraint (`00_MVP.md` §5), not enforced by the schema itself |
| `items` | array&lt;map&gt; | no | embedded `CompositionItemPlacement` list — item reference **and** artboard position/scale/rotation/z-order together in one map, see below |
| `createdAt` | Timestamp | no | |
| `season` | string | yes | → `Season` enum |
| `weather` | string | yes | → `Weather` enum |
| `tags` | array&lt;string&gt; | yes (default `[]`) | free-text, user-entered tags — **not** a closed vocabulary (unlike `season`/`weather`). Added per user review (2026-08-03). **Not yet in `lib/models/composition.dart`** |
| `coverImagePath` | string | yes | Cloud Storage path only — the image bytes themselves live in Storage, never in this Firestore document, see §8 |
| `backgroundColor` | string | yes | enum-name string → `ArtboardBackgroundColor` (`lib/widgets/interactive_artboard/artboard_background_color.dart`; MVP-scoped: `docs/reference/plan/03_화면별UX명세서/02_코디 (가상 조합).md:36` specs the artboard's background-color swatch control, white/gray/black only). **Not yet in `lib/models/composition.dart`** — currently local/ephemeral widget state only, see Open Question #9 |
| `isIncomplete` | boolean | no (default `false`) | |
| `isDeleted` | boolean | no (default `false`) | |
| `deletedAt` | Timestamp | yes | |

**`items` embedded array** — each element:

```
{ clothingItemId: string, x: number, y: number, scale: number, rotation: number, zIndex: number }
```

- Cap of **≤15 items per composition** is already confirmed (`docs/history/Decision.md`, "코디 아이템 개수 상한 15개") — the embedded array-of-maps approach is fine at that cardinality.
- **Firestore's ~1 MiB per-document size ceiling is a non-issue here, stated explicitly so nobody re-derives it**: 15 items × a generous ~200 bytes/item (five numeric fields + one ID string, including field-name overhead) ≈ 3 KB — several hundred times under the ceiling.

---

## 5. `users/{uid}/styleLogs/{styleLogId}`

Source of truth for shape: `lib/models/style_log.dart`.

| Field | Firestore type | Nullable | Notes |
|---|---|---|---|
| `coverImagePath` | string | no | Cloud Storage path, see §8 |
| `createdAt` | Timestamp | no | 이 스타일일지를 앱에 등록(작성)한 시각 — 실제 착용일과 다를 수 있어 별도 필드. `wornDate`와의 구분은 `ClothingItem.createdAt`/`acquiredAt` 패턴과 동일. **Not yet in `lib/models/style_log.dart`**, added per user review (2026-08-04) |
| `wornDate` | Timestamp | yes | 실제로 착용한 날짜 — **2026-08-04 리뷰로 nullable로 변경**(기존엔 필수였음). 오래된 사진을 등록하며 정확한 날짜를 모르거나 비워둘 수 있는 경우 지원. **UI 영향**: 스타일일지 메인 화면은 날짜순 정렬/그룹핑을 전제하므로(`00_MVP.md` §4.3 "Sorted by date", 진행 중인 필터 UI 스펙), `wornDate`가 null인 항목의 정렬 위치(맨 끝? 별도 그룹?)는 구현 단계에서 정해야 함 — see Open Question #17 |
| `linkedCompositionId` | string | yes | references `compositions/{id}` within the same user scope |
| `wornItemIds` | array&lt;string&gt; | no (default `[]`) | list of `clothingItems/{id}` references — replaced an earlier, fragile image-path-string-matching approach (`docs/history/TechnicalDebt.md`, 2026-07-29 entry) |
| `season` | string | yes | → `Season` enum |
| `weather` | string | yes | → `Weather` enum |
| `location` | string | no (default `''`) | |
| `isIncomplete` | boolean | no (default `false`) | |
| `isDeleted` | boolean | no (default `false`) | |
| `deletedAt` | Timestamp | yes | |

Note: `00_MVP.md` §4.3's "additional images (#3 onward, reorderable)" concept was superseded — the worn-item images shown in the UI are resolved by dereferencing `wornItemIds` against the existing `ClothingItem.imagePath` values, not stored as separate StyleLog-owned photos. No `additionalImagePaths`-equivalent field exists in the current model, so none is defined here.

No separate `StyleLogItem` join collection: `wornItemIds` is a simple embedded array of ID strings, which fully replaces the N:N join table in `00_MVP.md` §5's stale draft.

**Confirmed (user, 2026-08-04) — `TrashEntry.createdAt` must use the new `StyleLog.createdAt`, not `wornDate`.** Trash displays both "제작일"(creation date) and "삭제까지 남은 날짜"(days until purge) per item. `lib/models/trash_entry.dart`'s doc comment shows `TrashEntry.createdAt` currently maps from `StyleLog.wornDate` (StyleLog had no `createdAt` of its own before this review). With `wornDate` now nullable, that mapping must switch to the new `StyleLog.createdAt` — otherwise a StyleLog with no recorded worn date would show a blank "제작일" in Trash. Confirmed direction; the actual `trash_providers.dart` code change is Implementation-stage, tracked in `docs/work/BACKLOG.md` rather than re-litigated here (was Open Question #18, now resolved).

---

## 6. Soft-delete / Trash

**No persisted Trash collection.** `TrashEntry` (`lib/models/trash_entry.dart`) is a client-side **derived read model**, not a Firestore document — `trashEntriesProvider` (`lib/providers/trash_providers.dart`) watches all three domain collections live and filters. The Firestore-native equivalent keeps the same shape: the client queries each of the three subcollections with `where('isDeleted', '==', true)` and computes `daysUntilPurge` client-side from `deletedAt` (retention window: 15 days — currently the `_trashRetentionDays` constant in `trash_providers.dart`; this would move to a shared config location at implementation time, not duplicated here).

**Composite indexes implied**: any server-side query combining `isDeleted` equality with another filter or sort — e.g. the closet grid's `isDeleted==false` + `category`/`season` equality + `createdAt`/`wearCount` sort (`lib/providers/closet_providers.dart`) — will need a Firestore composite index once these move off the current client-side Riverpod filtering. **Exact index set is deferred to implementation time; not blocking this decision doc** (per task scope).

**Purge**: `purgeExpiredTrash()` today runs once at app startup, imperative, before `runApp()`, hard-deleting anything past the 15-day window. This same one-shot-at-launch, client-side pattern can carry over directly to Firestore — no server cron / Cloud Function is required for this MVP's scope (solo-dev, personal-use-first, `00_MVP.md` §1).

---

## 7. `wearCount` aggregation

**Revised 2026-08-03 — decision changed from a Firestore transaction to a non-transactional `WriteBatch` with `FieldValue.increment()`, specifically because of the offline-first/local-first requirement introduced in §11.** The original client-side-transaction design (still visible in this document's history) does not work offline: `runTransaction()` requires a live round-trip to the server to guarantee it's reading the latest committed state before writing, so it simply fails (or blocks indefinitely) with no network — which would silently break wear-count updates for any StyleLog created while offline, exactly the scenario §11 requires to work.

**Revised decision**: still client-side (not a Cloud Function — same solo-dev/no-deploy-pipeline justification as before, `00_MVP.md` §1), but using a `WriteBatch` instead of a transaction: the client reads the StyleLog's previous `wornItemIds` from the **local cache** (available offline — reflects the last known state including any not-yet-synced pending writes), diffs it against the new list, then batches the StyleLog write together with `FieldValue.increment(+1)`/`(-1)` calls on the affected `ClothingItem.wearCount` docs. A `WriteBatch` — unlike a transaction — never reads from the server; it only queues a set of writes to apply atomically once they reach it, so it queues and works normally while offline, same as any other Firestore write.

This is not just an offline workaround — it's arguably *more* correct for a personal, potentially-multi-device app than the transaction version was **for the non-overlapping case**: `FieldValue.increment()` is a server-side atomic operation, so if the same `ClothingItem` gets worn in two StyleLogs created on two different offline devices before either syncs, both devices' independent `+1`s still net out correctly once both reach the server (no lost update) — a naive read-then-write would not have that property, and neither would a transaction that ran fully offline even if it could (there'd be nothing live to transact against).

**Revised 2026-08-04 — narrowing the "safe" claim above, per round-2 Review (P1)**: that safety only holds when the concurrent edits touch *different* StyleLogs. If two offline devices edit the **same** StyleLog's `wornItemIds` concurrently, each device computes its `+1`/`-1` diff against its own stale local-cache baseline of that document — not a live server read (this is exactly why the design moved off transactions; a transaction would have retried against fresh state, but only works online). When both `WriteBatch`es eventually sync, the StyleLog document itself still resolves via ordinary last-write-wins (whichever batch's StyleLog write lands last wins the whole document), while *both* devices' independent `wearCount` increments have already been applied. The two are no longer guaranteed consistent with each other: a `ClothingItem` counted as `+1` by the losing device's diff can end up with an incremented `wearCount` even though the final, surviving `wornItemIds` array no longer includes it — a real counter *drift*, not merely the array "losing" an edit as the previous wording implied. Confirmed via Development Review (round 2): worth restating precisely rather than leaving the impression that only the array is at risk while the counter stays trustworthy.

Confirmed via `lib/providers/style_log_providers.dart` and `lib/providers/closet_providers.dart`: **no wear-count recompute exists anywhere in the current provider layer** — `00_MVP.md` §4.1's "auto-updated" rule is not yet implemented; mock data hardcodes `wearCount` values directly. This document is the first place this aggregation is actually designed.

**When it fires**: any StyleLog write that changes `wornItemIds` membership — create (initial list), edit (list changes), soft-delete (full de-credit), restore (re-credit), purge (permanent, already de-credited at soft-delete time so no further action needed) — matching the events `00_MVP.md` §4.1 already enumerates ("+1 when linked ... -1 when unlinked or Style Log deleted").

Open question flagged (#4 below, revised): both the `wornItemIds` **array** and, in the same-StyleLog-concurrent-edit case, the `wearCount` **number** it drives can end up inconsistent — not just the array in isolation. Not designed further here; revisit if multi-device concurrent editing becomes a real usage pattern (currently single-device-at-a-time per existing project constraints, which is exactly the case this gap doesn't occur in).

---

## 8. Image storage (Cloud Storage)

| Source field | Storage path convention | Notes |
|---|---|---|
| `ClothingItem.imagePath` | `users/{uid}/clothingItems/{itemId}/processed.jpg` | background-removed image (Remove.bg output, `00_MVP.md` §4.1) — matches the single-field shape in `lib/models/clothing_item.dart` today |
| *(no current field)* | `users/{uid}/clothingItems/{itemId}/original.jpg` | proposed convention **if/when** an original-image field is added (see Open Question #2) — not added to §3's field table since it isn't in the current Dart model |
| `StyleLog.coverImagePath` | `users/{uid}/styleLogs/{logId}/cover.jpg` | |
| `StyleLog.wornItemIds` | *(no Storage path of its own)* | ID references only, resolved at read time against the referenced `ClothingItem.imagePath` — no image duplication |
| `Composition.coverImagePath` | *(no independent upload, by current design)* | expected to always be a copy of one of the composition's own item images' Storage path — see Open Question #8 |
| `Composition.items[].clothingItemId` | *(no Storage path)* | ID reference only |

---

## 9. Export / Import file format

`00_MVP.md` §6 lists "Firestore offline cache + manual export/import files" as the offline/backup story. Proposed shape (confirming no conflict with this schema, not a full spec): one JSON file per user snapshot, structurally mirroring the collections above —

```
{ user: {...}, clothingItems: [...], compositions: [...], styleLogs: [...] }
```

— with Firestore `Timestamp` fields serialized as ISO-8601 strings, and enum fields kept as the same enum-name strings used in Firestore (so `enums.dart` remains the single source of truth for round-tripping, rather than a separate export-specific vocabulary being invented). Referenced images are exported as relative file paths alongside the JSON (e.g., packaged in a zip), reusing the Storage-path convention from §8 rather than a separate export layout. Full export/import spec (versioning, partial-import conflict handling, etc.) is out of scope for this decision doc.

---

## 10. Editor Draft / `isIncomplete`

`isIncomplete` itself already exists as a persisted field on all three domain docs (§3/§4/§5), used today only as a plain boolean marker on the *committed Record* — that part maps directly onto Firestore with no changes needed, since it's just an ordinary field.

**This is not a greenfield question, though — a prior decision already committed to a concrete design.** `docs/history/Decision.md`'s "[Decision] Editor 저장 모델 전환 — Record Real-time Save + Editor Draft/Commit/Cancel" entry (2026-07-15) settled the Record-vs-Draft split: general field edits keep saving straight to the Record as today, but dedicated Editor screens (Add Clothing, Composition editor) instead write to a separate, domain-specific Draft object (`ClothingItemDraft`/`CompositionDraft`/`StyleLogDraft`) that only gets folded into the Record on Commit (✔) and is discarded on Cancel (✕) — giving true edit-rollback, which the old "always-save" policy couldn't. That entry explicitly anticipates Firestore: *"향후 Firestore에서도 별도 컬렉션(`editor_drafts`, `{recordType, recordId}` 키)으로 갈 것이므로 지금부터 그 경계를 맞춘다"* — i.e., a dedicated `editor_drafts` collection, keyed by a compound `{recordType, recordId}` key, separate from the three Record collections (§3/§4/§5).

**Reconciling with §1's topology decision:** read literally, "별도 컬렉션" (a dedicated collection) named simply `editor_drafts` reads as a single flat, top-level collection — which would be a different shape than §1's user-scoped-subcollection topology for every other domain in this document. However, the 2026-07-15 entry was written purely in terms of today's single-process, in-memory Riverpod architecture (there is no multi-tenant Firestore in the picture yet at that point in the project) — it names a *future* Firestore collection only in passing, and never actually weighs the multi-user security/isolation question §1 is about. Its real, load-bearing commitment is the **compound `{recordType, recordId}` key** and the **Draft/Record separation**, not a considered choice between flat-top-level vs. user-scoped nesting.

Reading it that way, nesting under `users/{uid}` doesn't conflict with what was actually decided — it just adds the same outer uid-scope layer every other domain collection in this document already has, while keeping the `{recordType, recordId}` compound key exactly as specified. This document's proposal, following that reading: **`users/{uid}/editorDrafts/{recordType}_{recordId}`** (document ID = the compound key joined with an underscore; `recordType` and `recordId` also stored as separate fields on the doc for queryability) — consistent with §1, and a straightforward refinement rather than a rejection of the 2026-07-15 decision.

**This reconciliation is itself a judgment call, not a settled fact** — see Open Question #7, flagged explicitly for Review/PM/user to confirm or override, since it depends on reading the prior decision's silence on multi-tenancy as non-binding on that specific point, rather than as a deliberate choice of flat topology that this document would then be overriding without permission.

---

## 11. Offline & Local-First Operation

**Confirmed architecture (user, 2026-08-03, final): the app is fully usable offline from the very first launch — zero network required, ever, unless and until the user explicitly links a social account.** This is a bigger commitment than "Firestore has offline persistence" — it means no Firebase Auth call of any kind happens before linking, not even Anonymous Auth's one-time `signInAnonymously()` round-trip. This section is cross-cutting (applies to every collection in this document, not just one), so it lives here rather than being repeated per section.

### 11.1 Before linking: local placeholder scope, no network ever

- The app never calls any Firebase Auth method before the user chooses to link an account. There is no "anonymous uid" phase at all.
- Instead, at first launch, the app uses a **fixed local placeholder scope, `unlinked_local`**, in place of a real `uid` — i.e. all reads/writes go to `users/unlinked_local/clothingItems/...` etc., using the exact same collection paths and field shapes as every other section of this document (nothing about the per-collection schemas changes; only the path segment is a placeholder instead of a real Auth `uid`). **Naming note (revised 2026-08-04, round-2 Audit P1)**: the original proposal used `__unlinked_local__` (double-underscore prefix/suffix) — Firestore reserves document/field IDs matching the pattern `__.*__` for internal use, so that literal name would likely have been rejected or misbehaved the moment implementation started. Renamed to `unlinked_local` (no leading/trailing double underscore) throughout this document; verify against Firestore's current documented ID restrictions before implementation as a final sanity check.
- `Firestore.instance.disableNetwork()` is engaged at app start and stays on for the entire pre-link lifetime — this isn't just "no login," it's an explicit guarantee that nothing leaves the device, verified structurally (the SDK physically won't attempt any server call) rather than relying on there simply being no credential to sync with.
- Firestore's local persistence cache is the local database here — no separate local DB engine (SQLite/Hive/etc.) is needed. It's a real, full-featured on-device store (SQLite-backed under the hood) that supports every read/write/query this document's schemas need, indefinitely, with no time limit and no functional degradation. Set `Settings(cacheSizeBytes: CACHE_SIZE_UNLIMITED)` so the default LRU cache eviction (sized for "a cache," not "the only copy of the data") never discards anything — this app's Firestore documents are lightweight (no image bytes in them, see §8), so this has no meaningful storage-size downside.
- **The one thing that is *not* covered by "Firestore's local cache is enough"**: Cloud Storage (images) has no equivalent local-first behavior at all — see 11.3.

### 11.2 Linking: migrating placeholder-scoped data to a real `uid`

The user is considering social login only (no email/password) — candidate providers Google / Naver / Kakao / GitHub, list not finalized (see Open Question #15). Whichever set is chosen, linking follows the same procedure:

1. User initiates a social sign-in flow. Firebase Auth exchanges the provider's token for a real Firebase `uid` (this is the first network call the app ever makes, and it's user-initiated, not automatic/ambient — connecting to Wi-Fi alone does not trigger this).
2. The app reads every document currently cached locally under `users/unlinked_local/...` (still a pure local read, no network needed for this step) and re-writes each one under `users/{realUid}/...` — same collections, same field shapes, just a different path prefix. This is a bulk copy for every field **except** the image-path fields — see step 3.
3. **Revised 2026-08-04 (round-2 Audit P1) — image fields need reconciliation, not a plain copy.** Per §11.3, pre-link image files live in local on-device storage with `imagePath`/`coverImagePath`-equivalent fields pointing at local file paths, not Cloud Storage paths. A literal "bulk copy, not a transformation" (as step 2 originally claimed for every field) can't be true for these specific fields: linking must also (a) upload each locally-stored image to its real Cloud Storage destination (§8's path convention, now finally reachable since a real `uid` exists) and (b) rewrite the corresponding path field to the new Storage path as part of the same migration, not leave it pointing at a local file path that may not even exist on a future device. This is distinct from Open Question #13 (the ongoing *steady-state* offline-upload-queue problem) — this is a one-time *migration-time* reconciliation step. Not designed further here (Implementation-stage), but the doc must not read as if step 2's "bulk copy" covers these fields too — see Open Question #19.
4. Once the document copy (and image reconciliation) completes, the local `users/unlinked_local/...` documents (and any now-uploaded local image files) are deleted (cleanup — nothing should be left behind pointing at the placeholder scope).
5. `Firestore.instance.enableNetwork()` is called, and the newly `{realUid}`-scoped writes sync to the cloud normally from this point on, per the rest of this document's design (§1 topology, §7 wearCount batching, etc. — nothing about those designs changes; they simply start actually reaching a server instead of only existing locally).

This is why §2's `authProvider`/`email` fields are only ever populated **after** linking — the `users/{uid}` document, and the `uid` itself, do not exist on the server at all before that point.

### 11.3 The one real gap: Cloud Storage has no local-first equivalent

Cloud Storage (images) does not get the same automatic offline queue that Firestore documents do, before *or* after linking — an upload attempted without a live connection simply fails at the SDK level, it doesn't queue and retry the way a Firestore write does. For this architecture to be genuinely complete offline (not just "the text data is fine"), photos need their own handling regardless of link status: save the captured image to local on-device file storage immediately (so `imagePath`-equivalent fields can point at a local file path and display correctly offline right away), and queue the actual Cloud Storage upload for whenever a connection becomes available (which, pre-link, means never — uploads only really start happening post-link, once `enableNetwork()` is on and there's an actual cloud destination to upload *to*). **Not designed further here** — this is Implementation-stage work (Logic/Feature, not Data/Architecture), but it's load-bearing for the "genuinely complete offline" claim, not an optional nice-to-have. See Open Question #13 (steady-state) and Open Question #19 (the distinct migration-time version of this problem, §11.2 step 3).

### 11.4 Residual items, unchanged by this confirmation

- **`wearCount`'s aggregation (§7)** already uses a non-transactional `WriteBatch` + `FieldValue.increment()` rather than a Firestore transaction — this was revised earlier in this same review round specifically because transactions require live connectivity, which is even more clearly disqualifying now that "no network ever, pre-link" is the confirmed baseline rather than an occasional edge case.
- **Multi-device conflict resolution stays last-write-wins** for any field that isn't a simple counter (i.e., everything except `wearCount`) — e.g. two devices editing the same Composition's `items[]` before either has synced will have one edit silently overwrite the other once both eventually reach the server. Not designed further here — revisit if genuinely concurrent multi-device editing becomes a real usage pattern (currently single-device-at-a-time per existing project constraints); note that pre-link, "multi-device" isn't really meaningful anyway since each device's `unlinked_local` scope is entirely separate until/unless the *same* device later links (linking two different devices' local data into one account, if that's ever wanted, is a distinct future feature — merging two placeholder scopes into one real `uid` — not designed here).

---

## 12. `ClothingItem` analysis metadata & model versioning

**Requirement (user, 2026-08-04)**: `ClothingItem` needs a container for photo-analysis metadata destined for a future clothing-recommendation algorithm. The analysis model may be replaced later, and some items may never get analyzed (offline at capture time, API failure, etc.) — so the schema needs to track *which model version* produced the stored metadata and *whether/when* analysis happened, so the client can decide when to (re-)analyze once connectivity is available.

**Decided now vs. deferred**: this section designs the **versioning/tracking envelope** (§3's `analysisMetadata`/`analysisModelVersion`/`analyzedAt` fields) — that part doesn't depend on knowing what the future recommendation algorithm actually needs. The **internal shape of `analysisMetadata` itself is deliberately not designed here** — pre-defining specific sub-fields before the recommendation algorithm exists would be speculative, the same reasoning this document has applied throughout (e.g. §3's "deliberately not included" fields). Revisit this the moment that algorithm's actual input requirements are known.

**How re-analysis is triggered**: the client compares an item's stored `analysisModelVersion` against the app's current target model version (a single global constant/config value, not stored per-item) — a mismatch (or `null`, meaning never analyzed) means the item is due for (re-)analysis. No stored "needs reanalysis" boolean is needed; it's fully derivable from that comparison, the same "derive, don't duplicate" pattern §6 already uses for `TrashEntry`.

**This is independent of §11's link-gating.** §11 governs whether *Firestore/Cloud Storage* sync is allowed (gated on explicit account linking). Photo analysis is a call to an external AI service (Claude Vision, per `00_MVP.md` §4.1, same as the existing `category`/`color`/`season`/`material`/`hasGraphic`/`hasPattern` auto-tagging already in this document) — it only needs general internet connectivity, not a linked Firebase account. A fully local, never-linked user can still get their clothes analyzed whenever their device happens to have Wi-Fi; the resulting `analysisMetadata` just stays in the local `users/unlinked_local/...` scope like everything else until/unless they later link.

---

## Open Questions for Review

1. **[Biggest call]** Collection topology — user-scoped subcollections (`users/{uid}/...`) chosen over flat top-level collections + `userId` field. Full justification in §1. Challenge this first if you disagree with the choice.
2. `ClothingItem` currently has only one `imagePath` field (background-removed). `00_MVP.md` §4.1/§6 implies the pre-removal original image should also be retained (for the "manual masking fallback if offline" case), but no such field exists in `lib/models/clothing_item.dart` yet. §8 proposes a Storage path convention for this in advance, but does not add the field itself — the current Dart model stays the source of truth for field shapes.
3. `00_MVP.md` §5's stale draft data model includes `last_worn_date` (auto-aggregated alongside wear count), but no `lastWorn`/`lastWornDate` field exists anywhere in the current codebase. Should this schema pre-declare it now (cheap — the same transaction that updates `wearCount` in §7 could set it), or wait until a future task actually adds the Dart field? This document leaves it out for now, per the source-of-truth discipline.
4. `wearCount` aggregation (§7, revised 2026-08-03) is a client-side `WriteBatch` + `FieldValue.increment()`, not a Cloud Function — justified by the solo-dev/no-deploy-pipeline reasoning there, and required to work offline (§11). **Revised 2026-08-04 (round-2 Review, P1)**: the `wearCount` number is only safe under concurrent offline edits to *different* StyleLogs (increments net out correctly there); for concurrent offline edits to the *same* StyleLog, both the `wornItemIds` **array** (last-write-wins, §11 point 4) and the `wearCount` **number** it drives can end up inconsistent with each other — see §7 for the full mechanism. Not designed further here — revisit if multi-device concurrent editing becomes a real usage pattern (currently single-device-at-a-time, which is exactly the case this gap doesn't occur in).
5. `00_MVP.md` §4.1's remaining richer auto-tagging fields (`moodTags`, `internalTags`, `brand`/`purchasePlace`/`price`) are described in the MVP doc but don't exist in `lib/models/clothing_item.dart` yet. They're intentionally left out of §3's field table to stay consistent with "Dart models are the current source of truth" — not because they were overlooked. (`hasGraphic` was originally grouped with these but was decided and split into `hasGraphic`/`hasPattern` on 2026-08-03 — see Open Question #12.)
6. Composite indexes for combined filters (`isDeleted` + season/category/wearCount sort, etc., §6) are explicitly deferred to implementation time, not designed in this document.
7. Editor Draft persistence topology (§10): `docs/history/Decision.md`'s 2026-07-15 "Editor 저장 모델 전환" entry already committed to a dedicated `editor_drafts` collection keyed by `{recordType, recordId}`, separate from the Record collections (§3/§4/§5) — this predates and was made independently of §1's user-scoped-subcollection topology decision in this document. §10 proposes reading that prior decision as silent-on-multi-tenancy (not a considered flat-topology choice) and nesting it as `users/{uid}/editorDrafts/{recordType}_{recordId}` for consistency with §1, while keeping the prior decision's compound key intact. **This reading is a judgment call, not confirmed** — Review/PM/user should explicitly weigh in on whether that's a fair interpretation of the 2026-07-15 decision, or whether it should instead stay a literal flat `editor_drafts` collection as originally worded (in which case §1's topology decision would need an explicit carve-out for this one collection).
8. `Composition.coverImagePath` semantics (§8): currently assumed to always duplicate an existing composition-item's `ClothingItem.imagePath` Storage path (no independent upload), since the picker UI that would let a user upload a genuinely distinct cover image doesn't exist yet (`docs/history/Decision.md` notes the "field만 먼저" pattern — value-picking UI not built). Revisit if that Editor UI ships with real upload capability.
9. `Composition.backgroundColor` (§4) — the artboard background-color swatch control is real, current MVP scope (`docs/reference/plan/03_화면별UX명세서/02_코디 (가상 조합).md:36`) and already implemented as a closed-vocabulary enum, `ArtboardBackgroundColor` (`lib/widgets/interactive_artboard/artboard_background_color.dart`), but it is currently local/ephemeral widget state only — `lib/models/composition.dart` has no persisted field for it yet. This document proposes the Firestore field now (string, nullable, mapping to that enum) in advance of the Dart model catching up, same pattern as Open Question #2's `originalImagePath`.
10. **User billing/quota fields (§2)** — during schema review (2026-08-03) the user flagged that once a monetization model is defined, `users/{uid}` will likely need fields such as a max-closet-slot limit and/or a remaining-background-removal-attempts counter. Neither is added now since the billing tier structure itself doesn't exist yet — this is a placeholder for future work, not a design decision to make today. When a billing model is defined, revisit this doc to add the concrete field(s) (naming, type, and whether it's a hard quota enforced by security rules or a soft client-side-checked counter).
11. **`ClothingItem.color` closed-vocabulary list (§3)** — user review (2026-08-03) decided `color` should become closed like `category`/`season`/`material`, reversing this document's earlier "free text" note. No such list exists in the codebase yet, so this document proposes one (PM proposal, pending user sign-off on the exact set):

   `white`(화이트) · `ivory`(아이보리) · `beige`(베이지) · `gray`(그레이) · `black`(블랙) · `brown`(브라운) · `red`(레드) · `orange`(오렌지) · `yellow`(옐로우) · `green`(그린) · `blue`(블루) · `navy`(네이비) · `purple`(퍼플) · `pink`(핑크) · `khaki`(카키) · `multi`(멀티/혼합)

   16 values — comparable in size to `ClothingMaterial`'s 18, ordered neutrals → chromatic → catch-all, `multi` covering genuinely multi-colored items with no dominant color (distinct from `hasPattern`/`hasGraphic`, which describe surface design, not color count). **This is a code-level change, not just a doc update**: it requires adding a `ClothingColor` enum to `lib/models/enums.dart` and changing `ClothingItem.color`'s Dart type from `String?` to `ClothingColor?` (Logic/Feature × Implementation, per `Workflow_Project.md` §12.1 — needs its own Worker/Development Review pass, separate from this Decision-stage document, plus a follow-up to re-tag any existing mock data). Track as a BACKLOG.md item once this doc round is done.
12. **`ClothingItem.hasGraphic`/`hasPattern` (§3)** — user review (2026-08-03) decided to split `00_MVP.md` §4.1's single 3-way "graphic presence (plain/pattern/print)" auto-tag field into two independent booleans: `hasGraphic`(그래픽/프린트 유무) and `hasPattern`(패턴 유무). This is a real MVP-spec change (not just a schema addition) since the original spec's field was a mutually-exclusive 3-state choice — an item can now be flagged with both, which the original 3-way field couldn't represent. `00_MVP.md` §4.1 has been updated to match. Like `color` above, adding the actual `hasGraphic`/`hasPattern` fields to `lib/models/clothing_item.dart` is Implementation-stage code work outside this document's scope — track as a BACKLOG.md item.
13. **Cloud Storage offline upload queue (§11)** — unlike Firestore documents, image uploads (`imagePath`/`coverImagePath`/etc., §8) have no automatic offline queue in the Firebase SDK; an upload attempted offline simply fails rather than queuing for retry. Needs its own client-side pending-upload handling at implementation time (e.g. save locally + retry on reconnect). Not designed further in this Decision-stage document — flagged so it isn't assumed to be free just because Firestore's offline behavior is.
14. ~~Does "usable without server connection" need to cover a device's very first launch?~~ **Resolved (2026-08-03, final): yes** — confirmed architecture is zero-network-ever pre-link, using a fixed local placeholder scope (`users/unlinked_local/...`) with `disableNetwork()`, migrated to a real `uid` only when the user explicitly links a social account. No Anonymous Auth phase at all — see §11 for the full design. This turned out not to need a separate local-DB engine either: Firestore's own local persistence cache serves as the local database, pointed at the placeholder path instead of a real `uid`.
15. **Social login provider set (§2 `authProvider`)** — user is considering Google / Naver / Kakao / GitHub as of 2026-08-03, explicitly not finalized ("더 줄일 수도 있음" — the list may shrink). No email/password option under consideration. This document proposes the field now (nullable string, candidate enum values above) so §11's linking flow has somewhere to record which provider was used, but the exact final provider set is Implementation-stage work to confirm before `authProvider` is added as a real Dart enum.
16. **`ClothingItem.analysisMetadata` internal shape (§12)** — deliberately undesigned. The versioning envelope (`analysisMetadata`/`analysisModelVersion`/`analyzedAt`) is confirmed, but what actually goes inside `analysisMetadata` depends entirely on the not-yet-designed clothing-recommendation algorithm. Revisit when that algorithm's input requirements are known — do not pre-populate sub-fields speculatively.
17. **StyleLog list sorting/grouping with a nullable `wornDate` (§5)** — the Style Log main screen sorts/groups by date (`00_MVP.md` §4.3, in-progress filter UI spec). Now that `wornDate` can be `null`, the UI needs an explicit rule for where those items land (sort to the end? a separate "날짜 없음" group?). Not designed here — Implementation-stage UI decision, needs an answer before the sort/filter UI work in `docs/work/BACKLOG.md`'s "Current" section lands.
18. ~~`TrashEntry.createdAt` mapping needs to move off `StyleLog.wornDate`?~~ **Resolved (2026-08-04): yes, confirmed by user.** `TrashEntry.createdAt` (Trash popup's "제작일" display, alongside "삭제까지 남은 날짜") must switch from `StyleLog.wornDate` to the new `StyleLog.createdAt` — see §5. Actual `trash_providers.dart` code change is Implementation-stage, tracked in `docs/work/BACKLOG.md`.
19. **Migration-time image reconciliation (§11.2 step 3)** — found by round-2 Audit (P1). Linking's document migration can't be a pure field-for-field bulk copy for image-path fields specifically: pre-link they point at local file paths (§11.3), post-link they must point at real Cloud Storage paths (§8) with the actual bytes uploaded. §11.2 now acknowledges this needs its own step, but the mechanism itself (upload ordering, failure/retry handling mid-migration, what the field should read while an image is uploading) is not designed here — Implementation-stage, distinct from Open Question #13's steady-state (post-migration, ongoing) version of the offline-upload-queue problem.
