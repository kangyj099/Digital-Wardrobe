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

Justification against this app's actual constraints:

- **Anonymous Auth today** (`00_MVP.md` §6): every install gets a Firebase Auth `uid` immediately, before any account exists. There is never a "no uid yet" moment to design around, so nesting under `users/{uid}` has no bootstrapping problem.
- **"Easy future account linking"** (`00_MVP.md` §6, §8 Post-Launch checklist): linking an anonymous account to a real one (`linkWithCredential`) keeps the same `uid`. Subcollection paths need zero migration when that happens — the path key never changes.
- **Security rules are structurally safer**: `match /users/{uid}/{document=**} { allow read, write: if request.auth.uid == uid; }` scopes access by construction. A flat-collection + `userId` field design instead requires every query to remember `where('userId', isEqualTo: uid)` and every rule to check `resource.data.userId == request.auth.uid` — a single missed filter is a cross-user data leak. Subcollections make that class of mistake structurally harder to make.
- **Single-device-at-a-time usage in practice**: there is no current need for cross-user queries. If the Phase-3-maybe lightweight community layer (public/private, follow, likes — `00_MVP.md` §1) ever ships, Firestore's collection-group queries (`collectionGroup('clothingItems')`) still allow reading across all users' subcollections without flattening anything — so this choice does not foreclose that hypothetical future.
- **Offline cache behavior**: Firestore's offline persistence caches per query, not by collection nesting depth. Subcollections and flat top-level collections behave identically here, so this axis doesn't favor either option.

**Trade-off acknowledged**: flat top-level + `userId` would be simpler *if* this app ever needed a single global query across all users' data (e.g., an admin dashboard querying "every ClothingItem using material X, across all users"). No such need is in scope today, and collection-group queries cover the realistic version of it anyway.

**Review: challenge this first if you disagree** — see Open Question #1.

---

## 2. `users/{uid}` — User profile

| Field | Firestore type | Nullable | Notes |
|---|---|---|---|
| *(doc ID)* | — | — | Firebase Auth `uid`; not duplicated as a field |
| `email` | string | yes | `null` while anonymous; populated only if/when account-linking ships (`00_MVP.md` §8, not MVP-scoped) |
| `createdAt` | Timestamp | no | account creation time |
| `lastActiveAt` | Timestamp | no | 최근 접속 시각 — 앱 실행/재개(또는 재로그인)마다 갱신. `createdAt`과 별개 필드(계정 생성 시각 vs 최근 사용 시각). 사용자 스키마 리뷰(2026-08-03)로 추가 — 향후 외부 이메일 로그인 연동 시에도 그대로 유지 |

Kept minimal, mirroring `00_MVP.md` §5's own draft (`id`/`email`/`created_at`) plus `lastActiveAt` added per direct user review. No dedicated `User` Dart model exists in `lib/models/` yet, so nothing beyond this is invented.

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
| `wornDate` | Timestamp | no | |
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

---

## 6. Soft-delete / Trash

**No persisted Trash collection.** `TrashEntry` (`lib/models/trash_entry.dart`) is a client-side **derived read model**, not a Firestore document — `trashEntriesProvider` (`lib/providers/trash_providers.dart`) watches all three domain collections live and filters. The Firestore-native equivalent keeps the same shape: the client queries each of the three subcollections with `where('isDeleted', '==', true)` and computes `daysUntilPurge` client-side from `deletedAt` (retention window: 15 days — currently the `_trashRetentionDays` constant in `trash_providers.dart`; this would move to a shared config location at implementation time, not duplicated here).

**Composite indexes implied**: any server-side query combining `isDeleted` equality with another filter or sort — e.g. the closet grid's `isDeleted==false` + `category`/`season` equality + `createdAt`/`wearCount` sort (`lib/providers/closet_providers.dart`) — will need a Firestore composite index once these move off the current client-side Riverpod filtering. **Exact index set is deferred to implementation time; not blocking this decision doc** (per task scope).

**Purge**: `purgeExpiredTrash()` today runs once at app startup, imperative, before `runApp()`, hard-deleting anything past the 15-day window. This same one-shot-at-launch, client-side pattern can carry over directly to Firestore — no server cron / Cloud Function is required for this MVP's scope (solo-dev, personal-use-first, `00_MVP.md` §1).

---

## 7. `wearCount` aggregation

**Revised 2026-08-03 — decision changed from a Firestore transaction to a non-transactional `WriteBatch` with `FieldValue.increment()`, specifically because of the offline-first/local-first requirement introduced in §11.** The original client-side-transaction design (still visible in this document's history) does not work offline: `runTransaction()` requires a live round-trip to the server to guarantee it's reading the latest committed state before writing, so it simply fails (or blocks indefinitely) with no network — which would silently break wear-count updates for any StyleLog created while offline, exactly the scenario §11 requires to work.

**Revised decision**: still client-side (not a Cloud Function — same solo-dev/no-deploy-pipeline justification as before, `00_MVP.md` §1), but using a `WriteBatch` instead of a transaction: the client reads the StyleLog's previous `wornItemIds` from the **local cache** (available offline — reflects the last known state including any not-yet-synced pending writes), diffs it against the new list, then batches the StyleLog write together with `FieldValue.increment(+1)`/`(-1)` calls on the affected `ClothingItem.wearCount` docs. A `WriteBatch` — unlike a transaction — never reads from the server; it only queues a set of writes to apply atomically once they reach it, so it queues and works normally while offline, same as any other Firestore write.

This is not just an offline workaround — it's arguably *more* correct for a personal, potentially-multi-device app than the transaction version was: `FieldValue.increment()` is a server-side atomic operation, so if the same `ClothingItem` gets worn in two StyleLogs created on two different offline devices before either syncs, both devices' independent `+1`s still net out correctly once both reach the server (no lost update) — a naive read-then-write would not have that property, and neither would a transaction that ran fully offline even if it could (there'd be nothing live to transact against).

Confirmed via `lib/providers/style_log_providers.dart` and `lib/providers/closet_providers.dart`: **no wear-count recompute exists anywhere in the current provider layer** — `00_MVP.md` §4.1's "auto-updated" rule is not yet implemented; mock data hardcodes `wearCount` values directly. This document is the first place this aggregation is actually designed.

**When it fires**: any StyleLog write that changes `wornItemIds` membership — create (initial list), edit (list changes), soft-delete (full de-credit), restore (re-credit), purge (permanent, already de-credited at soft-delete time so no further action needed) — matching the events `00_MVP.md` §4.1 already enumerates ("+1 when linked ... -1 when unlinked or Style Log deleted").

Open question flagged (#4 below): the `wornItemIds` **array itself** (as opposed to the `wearCount` number) is still a plain last-write-wins field — if two offline devices both edit the same StyleLog's worn-item list before syncing, whichever write reaches the server last simply overwrites the array, silently discarding the other edit's list changes (the wear-count *side effect* of each edit still applies correctly per the paragraph above, but the array content itself isn't merge-safe). Not designed further here; revisit if multi-device concurrent editing becomes a real usage pattern (currently single-device-at-a-time per existing project constraints).

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

**Requirement (user, 2026-08-03)**: the app should be usable as a local app with no server connection, and sync data to the server whenever internet connectivity is available. This is a cross-cutting requirement, not specific to any one collection — it's addressed here rather than repeated per section.

**What Firestore already gives for this, mostly for free**: the client SDK's offline persistence (on by default on mobile) caches reads and queues writes locally, replaying the queue once connectivity returns — the app can read and write normally while offline, for any of the collections in this document, with no schema changes needed for that baseline behavior. Combined with Anonymous Auth (`00_MVP.md` §6), this already gets the app most of the way to "usable without a server."

**Real gaps this requirement exposes, that do need explicit design:**

1. **`wearCount`'s aggregation design (§7) did not actually work offline as originally written** — this review round caught it: Firestore transactions require live connectivity and fail without it. Revised in §7 to a non-transactional `WriteBatch` + `FieldValue.increment()`, which does queue and work offline. This is the one place this requirement changed an already-made decision, not just added a new one.
2. **Cloud Storage (images) does not get the same automatic offline queue that Firestore documents do.** Firestore's offline persistence covers `users/{uid}/...` documents; it does not cover Cloud Storage uploads (`imagePath`/`coverImagePath` targets, §8) — an upload attempted while offline simply fails at the SDK level, it doesn't auto-queue and retry the way a Firestore write does. Taking a clothing photo while offline needs its own client-side handling (e.g., save the file locally first, mark it pending, retry the Storage upload when connectivity returns) — this is real work, not covered by "Firestore is offline-capable." **Not designed further here** (it's an implementation-stage concern, arguably Logic/Feature not Data/Architecture), but flagged so it isn't assumed to be free. See Open Question #13.
3. **Anonymous Auth itself needs one network round-trip, on the very first app launch, to obtain a `uid`** — after that, the SDK caches the credential and works offline indefinitely, including across app restarts. Whether the very first launch (a device that has *never* touched the network even once) also needs to work is an open scope question — see Open Question #14; this document assumes "one-time online setup, then offline-capable after" unless told otherwise, since that's what Firestore + Anonymous Auth support without extra architecture.
4. **Multi-device conflict resolution stays last-write-wins** for any field that isn't a simple counter (i.e., everything except `wearCount`, per §7's revised design) — e.g. two offline devices editing the same Composition's `items[]` will have one edit silently overwrite the other on sync, whichever reaches the server last. Not a new problem this requirement created (it's inherent to Firestore's default conflict model), but worth naming explicitly now that offline multi-session editing is an explicit goal rather than an edge case. Not designed further here — revisit if genuinely concurrent multi-device editing (not just "used on two devices at different times") becomes a real usage pattern.

---

## Open Questions for Review

1. **[Biggest call]** Collection topology — user-scoped subcollections (`users/{uid}/...`) chosen over flat top-level collections + `userId` field. Full justification in §1. Challenge this first if you disagree with the choice.
2. `ClothingItem` currently has only one `imagePath` field (background-removed). `00_MVP.md` §4.1/§6 implies the pre-removal original image should also be retained (for the "manual masking fallback if offline" case), but no such field exists in `lib/models/clothing_item.dart` yet. §8 proposes a Storage path convention for this in advance, but does not add the field itself — the current Dart model stays the source of truth for field shapes.
3. `00_MVP.md` §5's stale draft data model includes `last_worn_date` (auto-aggregated alongside wear count), but no `lastWorn`/`lastWornDate` field exists anywhere in the current codebase. Should this schema pre-declare it now (cheap — the same transaction that updates `wearCount` in §7 could set it), or wait until a future task actually adds the Dart field? This document leaves it out for now, per the source-of-truth discipline.
4. `wearCount` aggregation (§7, revised 2026-08-03) is a client-side `WriteBatch` + `FieldValue.increment()`, not a Cloud Function — justified by the solo-dev/no-deploy-pipeline reasoning there, and required to work offline (§11). The `wearCount` number itself is safe under concurrent offline edits (increments net out correctly); the `wornItemIds` **array** that drives it is not (§11 point 4, last-write-wins) — revisit if multi-device concurrent editing becomes a real usage pattern (currently single-device-at-a-time).
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
14. **Does "usable without server connection" (§11) need to cover a device's very first launch** (zero prior connectivity, so Anonymous Auth has never obtained a `uid`), or is "one-time online setup, then offline-capable indefinitely after" acceptable? This document assumes the latter, since that's what Firestore + Anonymous Auth support without extra architecture — if the former is actually required, a separate local-identity/local-DB layer (independent of Firebase, reconciled to a real `uid` on first successful connection) would be needed, which is a materially bigger addition than anything else in this document. Needs an explicit answer before implementation starts.
