---
name: flutter-ui-reference
description: Curated, Flutter-only UI/UX reference distilled from the ui-ux-pro-max plugin — 52 Flutter widget/state/layout/navigation/testing guidelines, a stack-agnostic UX Quick Reference (accessibility, touch, performance, layout, typography/color, animation, forms, navigation), a mobile App-UI checklist, and a small curated color-palette/font-pairing reference set for a fashion/wardrobe app. Invoke before or while making UI/UX implementation decisions in this Flutter app (Layer=UI/Screen, Stage=Implementation/Frontend) — building or reviewing widgets, screens, navigation, theming, animation, forms, or accessibility — instead of loading the full multi-stack ui-ux-pro-max skill.
---

# Flutter UI Reference

This is a project-local, Flutter-scoped extract of the globally-installed `ui-ux-pro-max` plugin skill. That skill covers 10 frontend stacks (React, Vue, SwiftUI, Flutter, etc.) plus a Python CLI/CSV search tool this project doesn't use — most of its ~700 lines are irrelevant here. This file keeps only the Flutter-relevant and stack-agnostic-but-useful content as plain reference text (no CLI, no search tool).

**License notice (source material reuse):** The guideline content below (Flutter rows, Quick Reference, Common Rules, checklist, color/typography rows) is extracted from `ui-ux-pro-max-skill` (https://github.com/nextlevelbuilder/ui-ux-pro-max-skill), licensed under MIT:

> MIT License
>
> Copyright (c) 2024 Next Level Builder
>
> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to deal
> in the Software without restriction, including without limitation the rights
> to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
> copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all
> copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
> SOFTWARE.

---

## 1. Flutter-Specific Guidelines

52 concrete Flutter guidelines, grouped by category. Format: **Guideline** (Severity) — Do: `good`. Don't: `bad`.

### Widgets

- **Use StatelessWidget when possible** (Medium) — Do: `class MyWidget extends StatelessWidget` for static UI. Don't: use `StatefulWidget` for everything.
- **Keep widgets small** (Medium) — Do: extract widgets into smaller pieces, e.g. `Column(children: [Header(), Content()])`. Don't: write 500+ line build methods.
- **Use const constructors** (High) — Do: `const Text('Hello')` when possible. Don't: `Text('Hello')` for literals.
- **Prefer composition over inheritance** (Medium) — Do: compose via children, e.g. `Container(child: MyContent())`. Don't: `class MyContainer extends Container`.

### State

- **Use setState correctly** (Medium) — Do: `setState(() { _counter++; })` for UI-only changes. Don't: put complex business logic inside `setState`.
- **Avoid setState in build** (High) — Do: call `setState` only in callbacks (`onPressed: () => setState(() {})`). Don't: call `setState` inside `build()`.
- **Use state management for complex apps** (Medium) — Do: Provider/Riverpod/BLoC for shared state (`Provider.of<MyState>(context)`). Don't: global `setState` calls.
- **Prefer Riverpod or Provider** (Medium) — Do: `ref.watch(myProvider)` for new projects. Don't: hand-roll `InheritedWidget`.
- **Dispose resources** (High) — Do: override `dispose()` and call `controller.dispose()`. Don't: leave subscriptions running (memory leak).

### Layout

- **Use Column and Row** (Medium) — Do: `Column(children: [Text(), Button()])` for linear layouts. Don't: `Stack` for a simple vertical list.
- **Use Expanded and Flexible** (Medium) — Do: `Expanded(child: Container())` to fill space. Don't: fixed sizes (`Container(width: 200)`) inside a `Row`.
- **Use SizedBox for spacing** (Low) — Do: `SizedBox(height: 16)`. Don't: `Container(height: 16)` just for spacing.
- **Use LayoutBuilder for responsive** (Medium) — Do: `LayoutBuilder(builder: (context, constraints) {})`. Don't: hardcode `Container(width: 375)`.
- **Avoid deep nesting** (Medium) — Do: extract deeply nested widgets into methods/classes. Don't: `Column(Row(Column(Row(...))))` 10+ levels deep.

### Lists

- **Use ListView.builder** (High) — Do: `ListView.builder(itemCount: 100, itemBuilder: ...)` for long lists. Don't: `ListView(children: items.map(...).toList())` for large lists.
- **Provide itemExtent when known** (Medium) — Do: `ListView.builder(itemExtent: 50)` to skip measurement. Don't: omit `itemExtent` for uniform-height lists.
- **Use keys for stateful items** (High) — Do: `ListTile(key: ValueKey(item.id))`. Don't: omit keys on dynamic list items.
- **Use SliverList for custom scroll** (Medium) — Do: `CustomScrollView(slivers: [SliverList()])`. Don't: nest `ListView` inside `ListView`.

### Navigation

- **Use Navigator 2.0 or GoRouter** (Medium) — Do: `GoRouter(routes: [...])` for declarative routing. Don't: `Navigator.push` everywhere in complex apps.
- **Use named routes** (Low) — Do: `Navigator.pushNamed(context, '/home')`. Don't: anonymous `Navigator.push(context, MaterialPageRoute())`.
- **Handle back button with PopScope** (High) — Do: `PopScope(canPop: false, onPopInvoked: (didPop) => ...)` for Android predictive back (Android 14+). Don't: use the deprecated `WillPopScope`.
- **Pass typed arguments** (Medium) — Do: `MyRoute(id: '123')` typed route arguments. Don't: pass a raw `arguments: {'id': '123'}` map.

### Async

- **Use FutureBuilder** (Medium) — Do: `FutureBuilder(future: fetchData())`. Don't: `fetchData().then((d) => setState())`.
- **Use StreamBuilder** (Medium) — Do: `StreamBuilder(stream: myStream)`. Don't: `stream.listen` manually in `initState`.
- **Handle loading and error states** (High) — Do: check `if (snapshot.connectionState == ConnectionState.waiting)`. Don't: show only the success state with no loading indicator.
- **Cancel subscriptions** (High) — Do: `subscription.cancel()` in `dispose`. Don't: leave stream subscriptions uncancelled (memory leak).

### Theming

- **Use ThemeData** (Medium) — Do: `Theme.of(context).primaryColor` for consistent theming. Don't: hardcode `Color(0xFF123456)` everywhere.
- **Use ColorScheme** (Medium) — Do: `colorScheme: ColorScheme.fromSeed()` (Material 3). Don't: set individual properties like `primaryColor: Colors.blue`.
- **Access theme via context** (Medium) — Do: `Theme.of(context).textTheme.bodyLarge`. Don't: hardcode `TextStyle(fontSize: 16)`.
- **Support dark mode** (Medium) — Do: `MaterialApp(theme: light, darkTheme: dark)`. Don't: ship light theme only.

### Animation

- **Use implicit animations for simple cases** (Low) — Do: `AnimatedContainer`/`AnimatedOpacity`. Don't: use a full `AnimationController` for a simple fade.
- **Use AnimationController for complex animations** (Medium) — Do: `AnimationController(vsync: this)` for fine-grained control. Don't: force implicit widgets to do staggered sequences.
- **Dispose AnimationControllers** (High) — Do: `controller.dispose()` in `dispose()`. Don't: leave controllers undisposed (memory leak).
- **Use Hero for shared-element transitions** (Low) — Do: `Hero(tag: 'image', child: Image())`. Don't: hand-roll a custom shared-element animation.

### Forms

- **Use Form widget** (Medium) — Do: `Form(key: _formKey, child: ...)`. Don't: validate `TextField`s individually with no `Form`.
- **Use TextEditingController** (Medium) — Do: `final controller = TextEditingController();` to control text input. Don't: drive every field through `onChanged: (v) => setState()`.
- **Validate on submit** (High) — Do: `if (_formKey.currentState!.validate())`. Don't: submit without validation.
- **Dispose controllers** (High) — Do: `controller.dispose()` in `dispose()`. Don't: leave `TextEditingController`s undisposed.

### Performance

- **Use const widgets** (High) — Do: `const Icon(Icons.add)` to reduce rebuilds. Don't: `Icon(Icons.add)` for a static literal.
- **Avoid rebuilding the entire tree** (High) — Do: isolate the changing widget, e.g. wrap only it in a `Consumer`. Don't: call `setState` on the root widget.
- **Use RepaintBoundary** (Medium) — Do: `RepaintBoundary(child: AnimatedWidget())` to isolate repaints. Don't: let a full-screen repaint happen for a small animation.
- **Profile with DevTools** (Medium) — Do: measure with the Flutter DevTools performance tab before optimizing. Don't: guess at performance and optimize blind.

### Accessibility

- **Use Semantics widget** (High) — Do: `Semantics(label: 'Submit button')`. Don't: leave a bare `GestureDetector` without semantics.
- **Support large fonts** (High) — Do: use `Theme.of(context).textTheme` (respects `MediaQuery` text scaling). Don't: hardcode `TextStyle(fontSize: 14)`.
- **Test with screen readers** (High) — Do: test regularly with TalkBack/VoiceOver. Don't: skip screen-reader testing.

### Testing

- **Use widget tests** (Medium) — Do: `testWidgets('...', (tester) async {})` for UI behavior. Don't: rely on `test()` unit tests alone for UI.
- **Use integration tests** (Medium) — Do: `IntegrationTestWidgetsFlutterBinding` via the `integration_test` package for full-app testing. Don't: rely on manual E2E testing only.
- **Mock dependencies** (Medium) — Do: `when(mock.method()).thenReturn()` (Mockito/mocktail) to isolate tests. Don't: hit real APIs/dependencies in tests.

### Platform

- **Use Platform checks** (Medium) — Do: `if (Platform.isIOS) {}` for platform-specific code. Don't: hardcode iOS-only behavior for all platforms.
- **Use kIsWeb for web** (Medium) — Do: `if (kIsWeb) {}`. Don't: try `Platform.isWeb` (doesn't exist).

### Packages

- **Use pub.dev packages** (Medium) — Do: prefer popular maintained packages, e.g. `cached_network_image`. Don't: write a custom image-cache implementation.
- **Check package quality before adding** (Medium) — Do: check pub points/popularity (100+ pub points). Don't: add unmaintained packages without review.

---

## 2. Stack-Agnostic Quick Reference

Compact principle bullets, independent of framework. Priority order (see also `.claude/skills/flutter-implementation-conventions/SKILL.md` for this project's own Flutter conventions, which take precedence where they overlap).

### 2.1 Accessibility (CRITICAL)

- `color-contrast` - Minimum 4.5:1 ratio for normal text (large text 3:1)
- `focus-states` - Visible focus rings on interactive elements (2–4px)
- `alt-text` - Descriptive alt text for meaningful images
- `aria-labels` - Label for icon-only buttons; `accessibilityLabel`/`Semantics(label:)` in Flutter
- `keyboard-nav` - Tab order matches visual order; full keyboard support
- `form-labels` - Pair every input with a visible label
- `skip-links` - Skip to main content for keyboard users
- `heading-hierarchy` - Sequential h1→h6, no level skip
- `color-not-only` - Don't convey info by color alone (add icon/text)
- `dynamic-type` - Support system text scaling; avoid truncation as text grows
- `reduced-motion` - Respect reduced-motion preference; simplify/disable animations when requested
- `voiceover-sr` - Meaningful accessibility labels/hints; logical reading order for screen readers
- `escape-routes` - Provide cancel/back in modals and multi-step flows
- `keyboard-shortcuts` - Preserve system/a11y shortcuts; offer alternatives for drag-and-drop

### 2.2 Touch & Interaction (CRITICAL)

- `touch-target-size` - Min 44×44pt (iOS) / 48×48dp (Android); extend hit area if needed
- `touch-spacing` - Minimum 8px/8dp gap between touch targets
- `hover-vs-tap` - Use tap for primary interactions; don't rely on hover alone
- `loading-buttons` - Disable button during async operations; show spinner/progress
- `error-feedback` - Clear error messages near the problem
- `gesture-conflicts` - Avoid horizontal swipe on main content; prefer vertical scroll
- `standard-gestures` - Use platform standard gestures consistently; don't redefine them
- `system-gestures` - Don't block system gestures (back swipe, gesture bar, etc.)
- `press-feedback` - Visual feedback on press (ripple/highlight)
- `haptic-feedback` - Use haptics for confirmations and important actions; avoid overuse
- `gesture-alternative` - Don't rely on gesture-only interactions; always provide visible controls for critical actions
- `safe-area-awareness` - Keep primary touch targets away from notch, gesture bar, and screen edges
- `no-precision-required` - Avoid requiring pixel-perfect taps on small icons or thin edges
- `swipe-clarity` - Swipe actions must show clear affordance or hint (chevron, label, tutorial)
- `drag-threshold` - Use a movement threshold before starting drag to avoid accidental drags

### 2.3 Performance (HIGH)

- `image-optimization` - Use responsive/appropriately-sized images, lazy-load non-critical assets
- `image-dimension` - Reserve width/height or aspect ratio to prevent layout shift
- `lazy-loading` - Lazy-load non-hero components/routes
- `bundle-splitting` - Split code by route/feature to reduce initial load
- `reduce-reflows` - Avoid frequent layout reads/writes; batch them
- `content-jumping` - Reserve space for async content to avoid layout jumps
- `virtualize-lists` - Virtualize lists with 50+ items (`ListView.builder` etc.) for memory/scroll performance
- `main-thread-budget` - Keep per-frame work under ~16ms for 60fps; move heavy tasks off the main thread
- `progressive-loading` - Use skeleton/shimmer instead of long blocking spinners for >1s operations
- `input-latency` - Keep input latency under ~100ms for taps/scrolls
- `tap-feedback-speed` - Provide visual feedback within 100ms of tap
- `debounce-throttle` - Debounce/throttle high-frequency events (scroll, resize, search input)
- `offline-support` - Provide offline state messaging and a basic fallback
- `network-fallback` - Offer degraded modes for slow networks (lower-res images, fewer animations)

### 2.4 Style Selection (HIGH)

- `style-match` - Match style to product type
- `consistency` - Use the same style across all screens
- `no-emoji-icons` - Use vector icons, not emojis
- `color-palette-from-product` - Choose palette informed by product/industry conventions
- `effects-match-style` - Shadows, blur, radius aligned with chosen style
- `platform-adaptive` - Respect platform idioms (iOS vs Android): navigation, controls, typography, motion
- `state-clarity` - Make hover/pressed/disabled states visually distinct while staying on-style
- `elevation-consistent` - Use a consistent elevation/shadow scale for cards, sheets, modals
- `dark-mode-pairing` - Design light/dark variants together to keep brand, contrast, and style consistent
- `icon-style-consistent` - Use one icon set/visual language (stroke width, corner radius) across the product
- `system-controls` - Prefer native/system controls over fully custom ones; customize only when branding requires it
- `blur-purpose` - Use blur to indicate background dismissal (modals, sheets), not as decoration
- `primary-action` - Each screen should have only one primary CTA; secondary actions visually subordinate

### 2.5 Layout & Responsive (HIGH)

- `mobile-first` - Design mobile-first, then scale up to tablet
- `breakpoint-consistency` - Use systematic breakpoints
- `readable-font-size` - Minimum 16px body text on mobile
- `line-length-control` - Mobile 35–60 chars per line
- `horizontal-scroll` - No horizontal scroll on mobile unless intentional (carousels)
- `spacing-scale` - Use a 4pt/8dp incremental spacing system
- `touch-density` - Keep component spacing comfortable for touch: not cramped, not causing mis-taps
- `container-width` - Consistent max content width per device class
- `z-index-management` - Define a layered elevation/z-order scale
- `fixed-element-offset` - Fixed navbar/bottom bar must reserve safe padding for underlying content
- `scroll-behavior` - Avoid nested scroll regions that interfere with the main scroll experience
- `orientation-support` - Keep layout readable and operable in landscape mode
- `content-priority` - Show core content first on mobile; fold or hide secondary content
- `visual-hierarchy` - Establish hierarchy via size, spacing, contrast — not color alone

### 2.6 Typography & Color (MEDIUM)

- `line-height` - Use 1.5–1.75 for body text
- `line-length` - Limit to 65–75 characters per line
- `font-pairing` - Match heading/body font personalities
- `font-scale` - Consistent type scale (e.g. 12 14 16 18 24 32)
- `contrast-readability` - Darker text on light backgrounds
- `text-styles-system` - Use a platform type-role system (display, headline, title, body, label)
- `weight-hierarchy` - Use font-weight to reinforce hierarchy: bold headings (600–700), regular body (400), medium labels (500)
- `color-semantic` - Define semantic color tokens (primary, secondary, error, surface) not raw hex in widgets
- `color-dark-mode` - Dark mode uses desaturated/lighter tonal variants, not inverted colors; test contrast separately
- `color-accessible-pairs` - Foreground/background pairs must meet 4.5:1 (AA) or 7:1 (AAA)
- `color-not-decorative-only` - Functional color (error red, success green) must include icon/text
- `truncation-strategy` - Prefer wrapping over truncation; when truncating, provide full text via tooltip/expand
- `number-tabular` - Use tabular/monospaced figures for data columns, prices, and timers to prevent layout shift
- `whitespace-balance` - Use whitespace intentionally to group related items and separate sections

### 2.7 Animation (MEDIUM)

- `duration-timing` - Use 150–300ms for micro-interactions; complex transitions ≤400ms; avoid >500ms
- `transform-performance` - Animate transform/opacity only; avoid animating width/height/position directly
- `loading-states` - Show skeleton or progress indicator when loading exceeds 300ms
- `excessive-motion` - Animate 1–2 key elements per view max
- `easing` - Use ease-out for entering, ease-in for exiting; avoid linear for UI transitions
- `motion-meaning` - Every animation must express a cause-effect relationship, not just be decorative
- `state-transition` - State changes (hover/active/expanded/collapsed/modal) should animate smoothly, not snap
- `continuity` - Screen transitions should maintain spatial continuity (shared element, directional slide)
- `spring-physics` - Prefer spring/physics-based curves over linear for a natural feel
- `exit-faster-than-enter` - Exit animations shorter than enter (~60–70% of enter duration)
- `stagger-sequence` - Stagger list/grid item entrance by 30–50ms per item
- `shared-element-transition` - Use shared-element/hero transitions for visual continuity between screens
- `interruptible` - Animations must be interruptible; a tap/gesture cancels in-progress animation immediately
- `no-blocking-animation` - Never block user input during an animation; UI must stay interactive
- `scale-feedback` - Subtle scale (0.95–1.05) on press for tappable cards/buttons; restore on release
- `motion-consistency` - Unify duration/easing tokens globally; all animations share the same rhythm
- `modal-motion` - Modals/sheets should animate from their trigger source for spatial context
- `navigation-direction` - Forward navigation animates left/up; backward animates right/down, consistently
- `layout-shift-avoid` - Animations must not cause layout reflow; use transform for position changes

### 2.8 Forms & Feedback (MEDIUM)

- `input-labels` - Visible label per input (not placeholder-only)
- `error-placement` - Show error below the related field
- `submit-feedback` - Loading then success/error state on submit
- `required-indicators` - Mark required fields
- `empty-states` - Helpful message and action when no content
- `toast-dismiss` - Auto-dismiss toasts in 3–5s
- `confirmation-dialogs` - Confirm before destructive actions
- `input-helper-text` - Provide persistent helper text below complex inputs, not just placeholder
- `disabled-states` - Disabled elements use reduced opacity + no tap action + semantic disabled state
- `progressive-disclosure` - Reveal complex options progressively; don't overwhelm users upfront
- `inline-validation` - Validate on blur (not keystroke); show error only after user finishes input
- `input-type-keyboard` - Use semantic keyboard types (email, tel, number) to trigger the correct mobile keyboard
- `password-toggle` - Provide show/hide toggle for password fields
- `undo-support` - Allow undo for destructive or bulk actions (e.g. "Undo delete" toast)
- `success-feedback` - Confirm completed actions with brief visual feedback (checkmark, toast, color flash)
- `error-recovery` - Error messages must include a clear recovery path (retry, edit, help link)
- `multi-step-progress` - Multi-step flows show a step indicator or progress bar; allow back navigation
- `form-autosave` - Long forms should auto-save drafts to prevent data loss on accidental dismissal
- `sheet-dismiss-confirm` - Confirm before dismissing a sheet/modal with unsaved changes
- `error-clarity` - Error messages must state cause + how to fix, not just "Invalid input"
- `field-grouping` - Group related fields logically
- `read-only-distinction` - Read-only state should be visually and semantically different from disabled
- `focus-management` - After a submit error, auto-focus the first invalid field
- `error-summary` - For multiple errors, show a summary with anchors to each field
- `touch-friendly-input` - Mobile input height ≥44px to meet touch target requirements
- `destructive-emphasis` - Destructive actions use semantic danger color and are visually separated from primary actions
- `toast-accessibility` - Toasts must not steal focus; announce via a live/polite region
- `contrast-feedback` - Error and success state colors must meet 4.5:1 contrast ratio
- `timeout-feedback` - Request timeout must show clear feedback with a retry option

### 2.9 Navigation Patterns (HIGH)

- `bottom-nav-limit` - Bottom navigation max 5 items; use labels with icons
- `drawer-usage` - Use drawer/sidebar for secondary navigation, not primary actions
- `back-behavior` - Back navigation must be predictable and consistent; preserve scroll/state
- `deep-linking` - All key screens must be reachable via deep link for sharing/notifications
- `tab-bar-ios` - iOS: use bottom Tab Bar for top-level navigation
- `nav-label-icon` - Navigation items must have both icon and text label; icon-only nav harms discoverability
- `nav-state-active` - Current location must be visually highlighted (color, weight, indicator) in navigation
- `nav-hierarchy` - Primary nav (tabs/bottom bar) vs secondary nav (drawer/settings) must be clearly separated
- `modal-escape` - Modals and sheets must offer a clear close/dismiss affordance; swipe-down to dismiss on mobile
- `search-accessible` - Search must be easily reachable; provide recent/suggested queries
- `state-preservation` - Navigating back must restore previous scroll position, filter state, and input (see this project's P7 in `00_DesignPrinciples.md`)
- `gesture-nav-support` - Support system gesture navigation (swipe-back, predictive back) without conflict
- `tab-badge` - Use badges on nav items sparingly to indicate unread/pending; clear after user visits
- `overflow-menu` - When actions exceed available space, use overflow/more menu instead of cramming
- `bottom-nav-top-level` - Bottom nav is for top-level screens only; never nest sub-navigation inside it
- `back-stack-integrity` - Never silently reset the navigation stack or unexpectedly jump to home
- `navigation-consistency` - Navigation placement must stay the same across all pages; don't change by page type
- `avoid-mixed-patterns` - Don't mix Tab + Sidebar + Bottom Nav at the same hierarchy level
- `modal-vs-navigation` - Modals must not be used for primary navigation flows; they break the user's path
- `focus-on-route-change` - After a page transition, move focus to the main content region for screen reader users
- `persistent-nav` - Core navigation must remain reachable from deep pages; don't hide it entirely in sub-flows
- `destructive-nav-separation` - Dangerous actions (delete account, logout) must be visually/spatially separated from normal nav items
- `empty-nav-state` - When a nav destination is unavailable, explain why instead of silently hiding it

*(Charts & Data — LOW priority — omitted here as not currently relevant to this app; see the original plugin skill if a data-viz screen is added later.)*

---

## 3. Mobile App-UI Common Rules & Pre-Delivery Checklist

Scope: App UI (iOS/Android/Flutter), not desktop-web interaction patterns.

### 3.1 Icons & Visual Elements

| Rule | Standard | Avoid |
|------|----------|--------|
| No emoji as structural icons | Vector-based icons (scalable, themeable) | Emojis for navigation/settings/system controls |
| Vector-only assets | SVG or platform vector icons | Raster PNG icons that blur/pixelate |
| Stable interaction states | Color/opacity/elevation transitions without shifting layout bounds | Layout-shifting transforms that jitter surrounding content |
| Correct brand logos | Official brand assets, correct spacing/color/clear space | Guessing logo paths, unofficial recoloring |
| Consistent icon sizing | Icon sizes as design tokens (icon-sm/md/lg) | Arbitrary mixed values (20/24/28pt) |
| Stroke consistency | One stroke width per visual layer | Mixing thick/thin strokes arbitrarily |
| Filled vs outline discipline | One icon style per hierarchy level | Mixing filled and outline at the same level |
| Touch target minimum | ≥44×44pt interactive area (expand hit area if icon is smaller) | Small icons with no expanded tap area |
| Icon alignment | Align to text baseline, consistent padding | Misaligned icons, inconsistent spacing |
| Icon contrast | WCAG 4.5:1 (small)/3:1 (large glyphs) | Low-contrast icons that blend into background |

### 3.2 Interaction (App)

| Rule | Do | Don't |
|------|----|-----|
| Tap feedback | Clear pressed feedback (ripple/opacity/elevation) within 80–150ms | No visual response on tap |
| Animation timing | Micro-interactions ~150–300ms, platform-native easing | Instant transitions or slow animations (>500ms) |
| Accessibility focus | Screen reader focus order matches visual order, descriptive labels | Unlabeled controls, confusing focus traversal |
| Disabled state clarity | Disabled semantics, reduced emphasis, no tap action | Controls that look tappable but do nothing |
| Touch target minimum | ≥44×44pt (iOS) / ≥48×48dp (Android), expand hit area for small icons | Tiny tap targets or icon-only hit areas without padding |
| Gesture conflict prevention | One primary gesture per region | Overlapping gestures causing accidental actions |
| Semantic native controls | Prefer native primitives with proper accessibility roles | Generic containers used as primary controls without semantics |

### 3.3 Light/Dark Mode Contrast

| Rule | Do | Don't |
|------|----|-----|
| Surface readability (light) | Cards/surfaces clearly separated from background | Overly transparent surfaces that blur hierarchy |
| Text contrast (light) | Body text ≥4.5:1 against light surfaces | Low-contrast gray body text |
| Text contrast (dark) | Primary text ≥4.5:1, secondary text ≥3:1 on dark surfaces | Dark-mode text that blends into background |
| Border/divider visibility | Separators visible in both themes | Theme-specific borders disappearing in one mode |
| State contrast parity | Pressed/focused/disabled states equally distinguishable in both themes | Defining interaction states for one theme only |
| Token-driven theming | Semantic color tokens mapped per theme | Hardcoded per-screen hex values |
| Scrim/modal legibility | Scrim strong enough to isolate foreground (typically 40–60% black) | Weak scrim that leaves background visually competing |

### 3.4 Layout & Spacing

| Rule | Do | Don't |
|------|----|-----|
| Safe-area compliance | Respect top/bottom safe areas for fixed headers, tab bars, CTA bars | Fixed UI under notch, status bar, or gesture area |
| System bar clearance | Spacing for status/nav bars and gesture home indicator | Tappable content colliding with OS chrome |
| Consistent content width | Predictable content width per device class | Mixing arbitrary widths between screens |
| 8dp spacing rhythm | Consistent 4/8dp spacing system | Random spacing increments |
| Readable text measure | Readable long-form text on large devices | Full-width long text on tablets |
| Section spacing hierarchy | Clear vertical rhythm tiers (e.g. 16/24/32/48) by hierarchy | Similar UI levels with inconsistent spacing |
| Adaptive gutters | Increase horizontal insets on larger widths/landscape | Same narrow gutter on all sizes/orientations |
| Scroll/fixed coexistence | Bottom/top content insets so lists aren't hidden behind fixed bars | Scroll content obscured by sticky headers/footers |

### 3.5 Pre-Delivery Checklist

**Visual Quality**
- [ ] No emojis used as icons
- [ ] All icons come from a consistent icon family and style
- [ ] Official brand assets used with correct proportions and clear space
- [ ] Pressed-state visuals don't shift layout bounds or cause jitter
- [ ] Semantic theme tokens used consistently (no ad-hoc per-screen hardcoded colors)

**Interaction**
- [ ] All tappable elements provide clear pressed feedback
- [ ] Touch targets meet minimum size (≥44×44pt iOS, ≥48×48dp Android)
- [ ] Micro-interaction timing stays in the 150–300ms range with native-feeling easing
- [ ] Disabled states are visually clear and non-interactive
- [ ] Screen reader focus order matches visual order, interactive labels are descriptive
- [ ] Gesture regions avoid nested/conflicting interactions

**Light/Dark Mode**
- [ ] Primary text contrast ≥4.5:1 in both themes
- [ ] Secondary text contrast ≥3:1 in both themes
- [ ] Dividers/borders and interaction states distinguishable in both modes
- [ ] Modal/drawer scrim opacity strong enough to preserve foreground legibility
- [ ] Both themes tested before delivery (not inferred from a single theme)

**Layout**
- [ ] Safe areas respected for headers, tab bars, bottom CTA bars
- [ ] Scroll content not hidden behind fixed/sticky bars
- [ ] Verified on small phone, large phone, and tablet (portrait + landscape)
- [ ] Horizontal insets/gutters adapt correctly by device size and orientation
- [ ] 4/8dp spacing rhythm maintained across component/section/page levels
- [ ] Long-form text measure remains readable on larger devices

**Accessibility**
- [ ] All meaningful images/icons have accessibility labels
- [ ] Form fields have labels, hints, and clear error messages
- [ ] Color is not the only indicator
- [ ] Reduced motion and dynamic text size supported without layout breakage
- [ ] Accessibility traits/roles/states (selected, disabled, expanded) announced correctly

---

## 4. Reference-Only Color & Typography Picks

**This section is inspiration/reference material, not this project's design tokens.** `docs/reference/design/` remains the actual source of truth for Digital Wardrobe's brand colors, type scale, and tokens. The rows below are a small curated subset (out of the plugin's 160 palettes / 74 font pairings) of entries plausibly relevant to a fashion/wardrobe/lifestyle mobile app — kept for occasional inspiration, not for direct hardcoding.

### 4.1 Color Palettes (curated, 8 of 160)

| Product Type | Primary | Secondary | Accent | Background | Notes |
|---|---|---|---|---|---|
| Wardrobe & Outfit Planner | #BE185D | #EC4899 | #D97706 | #FDF2F8 | Fashion rose + gold accent — closest direct match to this app's category |
| E-commerce Luxury | #1C1917 | #44403C | #A16207 | #FAFAF9 | Premium dark + gold accent |
| Beauty/Spa/Wellness Service | #EC4899 | #F9A8D4 | #8B5CF6 | #FDF2F8 | Soft pink + lavender luxury |
| Luxury/Premium Brand | #1C1917 | #44403C | #A16207 | #FAFAF9 | Premium black + gold accent |
| Magazine/Blog | #18181B | #3F3F46 | #EC4899 | #FAFAFA | Editorial black + accent pink |
| Photography Studio | #18181B | #27272A | #F8FAFC | #000000 | Pure black + white contrast |
| Portfolio/Personal | #18181B | #3F3F46 | #2563EB | #FAFAFA | Monochrome + blue accent |
| Home Decoration & Interior Design | #78716C | #A8A29E | #D97706 | #FAF5F2 | Interior warm grey + gold accent |

### 4.2 Font Pairings (curated, 7 of 57)

| Pairing | Heading Font | Body Font | Mood/Keywords | Best For |
|---|---|---|---|---|
| Classic Elegant | Playfair Display | Inter | elegant, luxury, sophisticated, editorial | Luxury brands, fashion, spa, beauty, editorial |
| Luxury Serif | Cormorant | Montserrat | luxury, high-end, fashion, refined | Fashion brands, luxury e-commerce, jewelry |
| Fashion Forward | Syne | Manrope | fashion, avant-garde, creative, bold, edgy | Fashion brands, creative agencies, art galleries |
| Magazine Style | Libre Bodoni | Public Sans | magazine, editorial, publishing, refined | Magazines, online publications, editorial content |
| Luxury Minimalist | Bodoni Moda | Jost | luxury, minimalist, high-end, refined | Luxury minimalist brands, high-end fashion |
| Minimalist Monochrome Editorial | Playfair Display | Source Serif 4 | monochrome, editorial, austere, high contrast | Luxury fashion mobile apps, editorial publications, portfolio apps |
| Minimal Swiss | Inter | Inter | minimal, clean, functional, neutral | Dashboards, functional/utility UI text within an otherwise-branded app |
