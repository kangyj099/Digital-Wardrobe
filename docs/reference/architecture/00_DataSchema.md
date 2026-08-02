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

Kept minimal, mirroring `00_MVP.md` §5's own draft (`id`/`email`/`created_at`). No dedicated `User` Dart model exists in `lib/models/` yet, so nothing beyond this is invented.

---

## 3. `users/{uid}/clothingItems/{itemId}`

Source of truth for shape: `lib/models/clothing_item.dart`.

| Field | Firestore type | Nullable | Notes |
|---|---|---|---|
| `name` | string | no | |
| `category` | string | yes | enum-name string → `ClothingCategory` (`lib/models/enums.dart`) |
| `color` | string | yes | free text, **not** a closed vocabulary (confirmed: `lib/models/clothing_item.dart` types `color` as bare `String?`, while `category`/`season`/`material` are typed as their respective enums — `ClothingCategory?`/`Season?`/`ClothingMaterial?`) |
| `season` | string | yes | → `Season` enum |
| `material` | string | yes | → `ClothingMaterial` enum (~18 perception-based values; rationale in `docs/history/Decision.md`) |
| `imagePath` | string | no | Cloud Storage path — background-removed image, see §8 |
| `createdAt` | Timestamp | no | |
| `location` | string | no (default `''`) | free-text location memo |
| `memo` | string | no (default `''`) | |
| `wearCount` | number (int) | no (default `0`) | auto-aggregated, see §6 |
| `isIncomplete` | boolean | no (default `false`) | Editor Draft marker, see §9 |
| `isDeleted` | boolean | no (default `false`) | soft-delete flag, see §5 |
| `deletedAt` | Timestamp | yes | set together with `isDeleted:true`; cleared on restore |

**Deliberately not included** (see Open Questions #2, #3, #5): `originalImagePath` (pre-background-removal image), `lastWornDate`, and `00_MVP.md` §4.1's richer auto-tagging fields (`hasGraphic`, `moodTags`, `internalTags`, `brand`/`purchasePlace`/`price`) — none of these exist in `lib/models/clothing_item.dart` today, so per the source-of-truth rule above they are left out rather than pre-declared.

---

## 4. `users/{uid}/compositions/{compositionId}`

Source of truth for shape: `lib/models/composition.dart`.

| Field | Firestore type | Nullable | Notes |
|---|---|---|---|
| `name` | string | no | max 40 chars is a UI-level constraint (`00_MVP.md` §5), not enforced by the schema itself |
| `items` | array&lt;map&gt; | no | embedded `CompositionItemPlacement` list, see below |
| `createdAt` | Timestamp | no | |
| `season` | string | yes | → `Season` enum |
| `weather` | string | yes | → `Weather` enum |
| `coverImagePath` | string | yes | see §8 for value semantics |
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

**Decision: client-side Firestore transaction, triggered as part of the StyleLog write path — not a Cloud Function trigger.**

Justification: this is a solo-developer, personal-use-first app (`00_MVP.md` §1) with no existing Cloud Functions deployment pipeline. Introducing one adds an ongoing ops surface (billing tier, deploy step, cold-start latency) to maintain a low-volume, low-consistency-risk aggregate — a wear-count miscount from a rare dropped transaction is a cosmetic bug, not data loss. A client-side `runTransaction` that reads the StyleLog's previous `wornItemIds` set, diffs it against the new one, and issues `FieldValue.increment(+1)`/`(-1)` on the affected `ClothingItem.wearCount` docs is sufficient, and keeps the aggregation logic co-located with the write path that already owns this decision.

Confirmed via `lib/providers/style_log_providers.dart` and `lib/providers/closet_providers.dart`: **no wear-count recompute exists anywhere in the current provider layer** — `00_MVP.md` §4.1's "auto-updated" rule is not yet implemented; mock data hardcodes `wearCount` values directly. This document is the first place this aggregation is actually designed.

**When it fires**: any StyleLog write that changes `wornItemIds` membership — create (initial list), edit (list changes), soft-delete (full de-credit), restore (re-credit), purge (permanent, already de-credited at soft-delete time so no further action needed) — matching the events `00_MVP.md` §4.1 already enumerates ("+1 when linked ... -1 when unlinked or Style Log deleted").

Open question flagged (#4 below): whether client-only transactions stay safe enough if multi-device concurrent editing becomes a real usage pattern later. Current usage is single-device-at-a-time, so this is not designed for now.

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

`isIncomplete` already exists as a persisted field on all three domain docs (§3/§4/§5), used today only as a plain boolean marker — "Editor Draft 구현" (per-domain `draftsProvider`, Commit/Cancel flow) is an unstarted `docs/work/BACKLOG.md` item. This schema does **not** add a separate Drafts collection: today's "field-only" pattern (a normal document with `isIncomplete: true`) maps directly onto Firestore with no changes needed.

Open Question #7: if the eventual Draft feature needs draft-only fields that shouldn't round-trip through normal committed-document queries (e.g. autosave timestamps, partially invalid states), a separate `drafts` subcollection might become necessary at that time. Not designed now — speculative design ahead of that task starting is out of scope.

---

## Open Questions for Review

1. **[Biggest call]** Collection topology — user-scoped subcollections (`users/{uid}/...`) chosen over flat top-level collections + `userId` field. Full justification in §1. Challenge this first if you disagree with the choice.
2. `ClothingItem` currently has only one `imagePath` field (background-removed). `00_MVP.md` §4.1/§6 implies the pre-removal original image should also be retained (for the "manual masking fallback if offline" case), but no such field exists in `lib/models/clothing_item.dart` yet. §8 proposes a Storage path convention for this in advance, but does not add the field itself — the current Dart model stays the source of truth for field shapes.
3. `00_MVP.md` §5's stale draft data model includes `last_worn_date` (auto-aggregated alongside wear count), but no `lastWorn`/`lastWornDate` field exists anywhere in the current codebase. Should this schema pre-declare it now (cheap — the same transaction that updates `wearCount` in §7 could set it), or wait until a future task actually adds the Dart field? This document leaves it out for now, per the source-of-truth discipline.
4. `wearCount` aggregation (§7) is designed as a client-side Firestore transaction, not a Cloud Function — justified by the solo-dev/no-deploy-pipeline reasoning there. Revisit if multi-device concurrent editing becomes a real usage pattern (currently single-device-at-a-time).
5. `00_MVP.md` §4.1's richer auto-tagging fields (`hasGraphic`, `moodTags`, `internalTags`, `brand`/`purchasePlace`/`price`) are described in the MVP doc but don't exist in `lib/models/clothing_item.dart` yet. They're intentionally left out of §3's field table to stay consistent with "Dart models are the current source of truth" — not because they were overlooked.
6. Composite indexes for combined filters (`isDeleted` + season/category/wearCount sort, etc., §6) are explicitly deferred to implementation time, not designed in this document.
7. Editor Draft / `isIncomplete` persistence (§10): kept as today's field-only pattern with no dedicated Drafts collection. Whether a separate `drafts` subcollection becomes necessary is deferred until the "Editor Draft 구현" task actually starts.
8. `Composition.coverImagePath` semantics (§8): currently assumed to always duplicate an existing composition-item's `ClothingItem.imagePath` Storage path (no independent upload), since the picker UI that would let a user upload a genuinely distinct cover image doesn't exist yet (`docs/history/Decision.md` notes the "field만 먼저" pattern — value-picking UI not built). Revisit if that Editor UI ships with real upload capability.
9. `Composition.backgroundColor` (§4) — the artboard background-color swatch control is real, current MVP scope (`docs/reference/plan/03_화면별UX명세서/02_코디 (가상 조합).md:36`) and already implemented as a closed-vocabulary enum, `ArtboardBackgroundColor` (`lib/widgets/interactive_artboard/artboard_background_color.dart`), but it is currently local/ephemeral widget state only — `lib/models/composition.dart` has no persisted field for it yet. This document proposes the Firestore field now (string, nullable, mapping to that enum) in advance of the Dart model catching up, same pattern as Open Question #2's `originalImagePath`.
