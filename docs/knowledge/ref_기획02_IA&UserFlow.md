## Information Architecture (Screen Hierarchy)

**Top-level content categories (3):** Closet / Composition / Style Log
(Calendar is planned for Phase 2 and is excluded from the menu and IA.)

```text
[Top Header] Current top-level category ▾ (Tap → Dropdown: Closet / Composition / Style Log) | [bottom-left] ← Conditional Back navigation
├── Closet
│   ├── Closet Main (Category group view)
│   │   ├── Switch category criterion — Floating bar
│   │   ├── Tap category group → List view (gallery of items within the group)
│   │   └── + button → [Add Single Item / Add Multiple Items]
│   │                  (While viewing a category, the labels change to "[Add ... to this category]")
│   ├── Add Item (Capture/Upload → AI Processing → Review/Edit Tags)
│   └── Item Detail
│       ├── View/Edit Primary tags, Location/Memo
│       └── Composition & Style Log history (records where this item appears)
│
├── Composition (Virtual Outfit)
│   ├── Composition Main (Category group view, same specification as Closet)
│   │   ├── Switch category criterion — Floating bar
│   │   ├── Tap category group → List view
│   ├── Composition Detail (Artboard viewer, used clothing list at the bottom, linked Style Logs)
│   └── Composition Editor (Place clothing on the artboard, move/rotate/resize/change render order)
│
├── Style Log (Real Outfit Records)
│   ├── Style Log Main (Gallery)
│   ├── Add Style Log (+ → [Add 1 Card / Split Across Multiple Cards])
│   └── Style Log Viewer (Swipe through Cover Image → Composition → Additional Images, worn clothing list)
│
└── (Phase 2) Calendar — Currently excluded from the menu and IA

Additional:
Settings / Trash — Not included in the header dropdown; located within Settings.
```

**Design Notes**

* **Item Detail ↔ Composition Detail ↔ Style Log Viewer** are all interconnected with bidirectional navigation. This interconnected relationship is the core of the app's cross-feature integration.
* The top header does not use a separate menu (hamburger) icon. Instead, **the current top-level category name itself serves as the dropdown trigger.**

  * Tapping the title allows users to jump directly to Closet, Composition, or Style Log.
* Back navigation is displayed conditionally as a separate icon only when a navigation history (stack) exists.

  * The responsibilities of the header and the Back button are separated ("Back = one step back" vs. "Title = jump anywhere"), preventing overlapping or confusing navigation controls.

**Note:** The detailed definitions of category criteria are documented in **ref_Planning_Screen_UX_Specification**, under **"Sort Criteria Table by Category Criterion."**

**Note:** This document defines only the screen structure (IA), navigation relationships between screens, and navigation rules.

Each screen's UI, category criteria, and data model use separate documents as the Source of Truth.

---

## User Flows

### Flow A — Add a New Clothing Item

```text
Closet Main
→ [+ Add Button]
→ Capture / Select from Gallery
→ AI Processing
→ Review/Edit Tags
→ [Save]
→ Return to Closet Main (new item appears)
```

---

### Flow B — Find a Clothing Item (Check Physical Location)

```text
Closet Main
→ Tap Tag Filter
→ Select an item from the filtered list
→ Item Detail
→ Check Location Memo
```

---

### Flow C — Record a Style Log

```text
Style Log Main
→ [+ Add Button]
→ Capture / Select from Gallery
→ Link Clothing Items (select one or multiple items from Closet)
→ [Save]
```

---

### Flow D — Review Past Outfits for a Specific Clothing Item (Core Differentiating Feature)

```text
Closet Main
→ Select Clothing Item
→ Item Detail
→ Scroll to the "Composition History" section
→ Tap a Style Log thumbnail
→ Style Log Detail (full photos + other clothing worn that day)
→ (Back)
→ Return to Item Detail
[Navigation stack preserved; ideally the scroll position is also preserved]
```

---

### Flow E — Reverse Navigation from a Style Log

```text
Style Log Main
→ Select Style Log
→ Style Log Detail
→ Tap one of the linked clothing items
→ Navigate to Item Detail
→ (Back)
→ Return to Style Log Detail
[Navigation stack preserved]
```

---

## Back Navigation Stack Notes

Support deep navigation chains such as **Item Detail ↔ Style Log Detail**, where users continuously navigate between related records.

```text
Closet Main
→ Item A Detail
→ Style Log ① (from Composition History)
→ Item B Detail (linked from Style Log ①)
→ Style Log ② (from Item B's Composition History)
→ ...
```

Users can continue navigating indefinitely in this manner.

When pressing Back, the navigation stack should unwind in the exact reverse order:

```text
Style Log ②
→ Item B Detail
→ Style Log ①
→ Item A Detail
→ Closet Main
```

### Back Navigation Stack Reset Rule

**Selecting a category from the dropdown resets the navigation stack.**

When the user taps the top header title and selects a category (Closet / Composition / Style Log) from the dropdown, that category always opens at its root screen (its Main screen).
