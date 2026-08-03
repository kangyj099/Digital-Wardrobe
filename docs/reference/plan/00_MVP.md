1. Overview

Service Name: Digital Closet (working title)
One-line definition: A mobile closet app where you take photos of clothing items, and AI automatically organizes them. It also lets you record outfits you’ve actually worn so you can revisit them later.

Target users

People who are interested in fashion
People with many clothes who often forget what they own
People who find closet organization tedious
People who feel like they have many clothes but “nothing to wear”

Development background: Built by the developer for personal real-world use first, with plans to later release it for general users

Key differentiators

A Style Log feature that records real worn outfits (ref. Today’s House Stories) — unlike typical closet apps (e.g., ACloset) that focus on “clothing-to-clothing combinations / AI recommendations,” this focuses on “the relationship between clothing and the user.”
Location memo to help users physically find clothes in their real closet — an area not addressed by competing services
PSD-like editable compositions: While competitor apps (e.g., ACloset) flatten outfit compositions into static PNG images that cannot be edited afterward, this app preserves the underlying layout data so outfits can be freely re-edited anytime, and each clothing item inside a composition image is tappable and linked to its item detail
(After Phase 3 review) If community features are added, they will be lightweight only:
public/private settings, follow, likes — no comments or messaging, intended as a reference-level social layer only
2. MVP Scope Definition
Feature	Included in MVP	Notes
Clothing archiving (AI background removal + auto-tagging)	✅ Included	Core pain-point solving feature; AI automation applied from the start
View/filter by tags	✅ Included	Switch by season/type/color, includes location memo
Composition (virtual outfit creation, editable)	✅ Included	Re-integrated into MVP since storing layout data + linking items on tap is not technically difficult even without hotspot layers
Style Log (real outfit records)	✅ Included	Linked with compositions/clothing items; calendar UI excluded
Clothing-based history of past compositions and style logs	✅ Included	
Automatic wear count updates	✅ Included	Aggregated automatically whenever clothing items are linked in style logs
Composition calendar	❌ Phase 2	
Today’s House-style hotspot layer over real photos (tagging clothing positions in real images)	❌ Phase 2	Detecting clothing positions in real photos is significantly harder than composition canvas implementation
Composition reference feature, style log memo (1000 chars), guided walkthrough panel	❌ Phase 2	Supporting features
Recommendations, feed/follow system	❌ Phase 3	Requires sufficient data scale or user base
Color theme/layout customization, tablet/foldable/landscape support	❌ Phase 3	Supporting features
Custom groups (folders) for compositions/style logs	❌ Phase 2–3	Requires full folder CRUD + ownership UI; currently filters by date/weather/season are sufficient, may be added later as convenience feature

MVP core loop: Add clothing (auto-organization) → browse closet / check location → create compositions / log outfits → review past outfit history per item

3. Core User Stories
When a new clothing item is purchased, a single photo is taken; the background is removed, type/color tags are automatically assigned, and it is added to the closet.
When deciding what to wear today, the user combines clothes in the closet on a canvas like stickers to preview outfits.
When looking for a clothing item, the user can find it immediately using a location memo such as “basket in the 3rd closet compartment.”
When the user records what they actually wore today in the Style Log, the clothing items in the photo are linked to closet items.
When tapping a specific clothing item, the user can see at a glance how it was styled in the past and when it was worn.
When tapping a clothing item inside a composition image, the user is navigated directly to that item’s detail page.
4. Feature Specifications
4.1 Clothing Archiving

Input: Clothing photo (camera capture or gallery selection)

Processing flow

Upload image → Remove.bg API for background removal
Background-removed image → Claude Vision API generates tags (returned as structured JSON)
Auto-generated tags include primary tags (type, color, etc.) that the user can view/edit
Internal classification metadata tags are hidden (not editable)
Basic fields (type/color/size/season/location/memo) are filled; additional info such as brand/purchase place/price can be added via an [Add Info] button

Viewing

Gallery grid view (default, pinch zoom adjusts tile size)
Tap tag → list of clothing items with same tag
Filter switch buttons (season/type/color, etc.)
Text search (includes memo field)

Auto-tagging fields (to be returned via Claude Vision prompt design)

Clothing type (tops/bottoms/outerwear/shoes/accessories, detailed categories)
Color (1–2 dominant colors)
Presence of graphics and pattern, as two independent flags rather than a single plain/pattern/print choice (revised 2026-08-03: an item can have both a printed graphic and a repeating textile pattern at once, which the original mutually-exclusive 3-way field couldn't represent) — `hasGraphic` (graphic/logo/print present) and `hasPattern` (repeating textile pattern, e.g. stripes/checks/florals, present)
Mood (minimal/casual/formal, etc.) — may have low accuracy; requires validation in Phase 1.5
Material (perception-based fabric feel, closed set of ~18 values — e.g. cotton/denim/knit/leather, not fiber-composition percentages; added to support future outfit-recommendation analysis of frequently-worn combinations) — same low-accuracy caveat as Mood; requires validation in Phase 1.5. Full value list: see `ClothingItem.material` / `kClothingMaterials` in the app's data model.

Additional rules

Wear count / last worn date are automatically updated when linked with Style Logs
Deletion requires confirmation + temporary Trash system
4.2 Composition (Virtual Outfit Creation)

Core concept: Create outfits by placing clothing images on a background sheet like a “dress-up game.” Instead of flattening the result into a static image, the layout data (position/scale/rotation/render order) is preserved so it can be re-edited anytime.

Editing features

Select clothing from closet and place it on an artboard (default 1:1)
Move, rotate, resize, change render order (z-index)
When overlapping, tapping ambiguous areas shows a popup for clarification → highlights item in bottom list
Dragging outside the artboard triggers deletion (trash icon appears)

Viewing

Composition detail shows list of used items (horizontal scroll), linked style logs
Editable tags: season/weather/category
4.3 Style Log

Input: Outfit photos (full body or partial), multiple images per card supported

Card structure:
Cover image (fixed #1) → Composition slot (fixed #2 — shows linked composition or +placeholder if not linked) → Additional images (#3 onward, reorderable)

Processing flow

Select photos (+ → [Add 1 card / split across multiple cards])
User manually links clothing items in photos to closet items (or AI-assisted matching — under review in Phase 1.5)
Seasonal tags are automatically inferred from the capture date; date/location are auto-filled from photo metadata (editable)

Viewing

In clothing item detail page: view history of “compositions and style logs that included this item”
Sorted by date
5. Data Model (Draft)
User
- id
- email (nullable — supports local anonymous usage)
- created_at

ClothingItem
- id
- user_id (FK)
- image_url (background-removed version)
- original_image_url
- category (primary tag, user-editable)
- color (primary tag, user-editable)
- has_graphic (primary tag, user-editable)
- mood_tags (primary tag, user-editable)
- material (primary tag, user-editable, closed vocabulary of ~18 perception-based values — see §4.1 Auto-tagging fields)
- internal_tags (private metadata for algorithms)
- size, season, location, memo
- brand, purchase_place, price (optional, shown via [Add Info])
- wear_count (auto-aggregated — +1 when linked to StyleLogItem, -1 when unlinked or Style Log deleted)
- last_worn_date (auto-aggregated)
- is_deleted (Trash state)
- created_at

Composition (virtual outfit)
- id
- user_id (FK)
- name (max 40 chars, auto-generated timestamp if not provided)
- background_color (canvas background color)
- items: [
    { clothing_item_id, x, y, scale, rotation, z_index }
  ]
- season, weather, mood_tags
- is_deleted (Trash state)
- created_at, updated_at

StyleLog (style log)
- id
- user_id (FK)
- cover_image_url (fixed primary image #1)
- linked_composition_id (nullable, fixed slot #2)
- additional_images: [ordered image URL array] (#3 onward)
- worn_date, location, inferred_season
- is_deleted (Trash state)
- created_at

StyleLogItem (N:N link between StyleLog and ClothingItem)
- id
- style_log_id (FK)
- clothing_item_id (FK)
6. Technical Stack Decisions

(to be revisited during design/implementation)

Area	Choice	Reason
Data storage	Firebase (Firestore + Cloud Storage), local-first — revised 2026-08-03: no Anonymous Auth at all; app runs fully offline from first launch using a local placeholder scope, cloud sync/backup only begins once the user explicitly links a social account (Google/Naver/Kakao/GitHub candidates, TBD)	Zero network required until the user opts in; avoids an Anonymous-Auth phase that would need its own later migration. Full design: `docs/reference/architecture/00_DataSchema.md` §11
Background removal	Remove.bg API	No need to operate own model; fallback to manual masking if offline
Auto-tagging	Claude API (Vision)	Image input → structured JSON tags; no separate classification model required
Client	Flutter (Dart) — Android/iOS dual support	Single codebase ensures feature parity; go_router supports navigation stack requirements
Composition canvas	Custom implementation using Flutter GestureDetector + Matrix4	Requires custom implementation due to lack of suitable off-the-shelf packages supporting move/rotate/scale/z-index
Image loading/caching	cached_network_image	Required for performance/thermal management via thumbnail caching
Offline/backup	Firestore offline cache (as the primary local database pre-link, not just a fallback) + manual export/import files	Full offline usage is the default mode, not a degraded fallback — see `00_DataSchema.md` §11
Development environment	Windows + Flutter SDK	Android via local emulator; iOS builds/signing via Codemagic (cloud macOS) → TestFlight for device testing
7. Screen List (Draft)
Closet Main (group view) / Closet list (grid view)
Clothing item detail (tags, location/memo, composition & style log history)
Add clothing (capture/upload → AI processing → tag review/edit)
Composition Main (group view) / Composition Detail (artboard viewer)
Composition editor (artboard editing)
Style Log Main (gallery)
Add Style Log (capture/upload, single/multi-card option)
Style Log viewer (cover image → composition → additional images swipe, worn item list)
Settings (startup screen selection, etc.) / Trash — unified view for clothing/compositions/style logs with filter chips and restore options

Navigation
Top header: “tap title → dropdown (Closet / Composition / Style Log)” for category switching
Back navigation is conditionally shown only when a navigation stack exists. Planned implementation using Flutter go_router

Screen transition flow diagrams (user flow diagrams) and hi-fi UI mockups will be handled separately in the next phase
— detailed screen-by-screen specs will be referenced in a separate “Screen UX Specification” document

8. Post-Launch Checklist (Post-MVP Phase)
 Social login linking flow (Google/Naver/Kakao/GitHub candidates — no Anonymous Auth phase, see `00_DataSchema.md` §11 for the local-placeholder-to-real-uid migration this login flow must perform)
 Onboarding flow (empty closet UX, first item upload guidance)
 Privacy policy / Terms of service (required for Play Store)
 Camera/storage permission explanation UX
 Multi-device / low-end device testing, dark mode/accessibility review
 AI API cost monitoring and usage limits
 Monetization strategy (free vs premium model)