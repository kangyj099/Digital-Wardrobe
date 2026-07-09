## Stage 5 — Design Tokens

### 1. Definition

This stage defines only the **role structure** of design tokens. Actual values (hex, px, font names, etc.) remain placeholders pending the Brand Guide stage. Based on Material 3's role-based token structure, incorporating this project's existing constraints (avoid black/white, dark mode support, limited fixed colors, 3-level density, etc. from Stages 3/4).

### 2. Rules

**T1. Color Roles (Material 3 based, values undefined)**

- `Primary` / `OnPrimary`
- `Secondary` / `OnSecondary` (maps to Accent role)
- `Surface` / `OnSurface`
- `Background` / `OnBackground`
- `Error` / `OnError` (used for destructive-action confirmation, linked to I6)
- Each role has both Light/Dark sets (dark mode principle, Stage 1 P6)
- Values undefined — to be filled by Brand Guide output

**T2. Neutral/Gray Scale Role**

- Defines only a stepped scale role (`Gray50`–`Gray900`, exact step count TBD in Brand Guide)
- Per the avoid-black/white principle (Stage 1 P6), pure `#000000`/`#FFFFFF` are prohibited — this is fixed here as a **constraint rule**, not a value

**T3. Semantic State Color Roles**

- `Disabled` (I4 disabled indication), `Warning` (I6 cascade warning), `Success/Info` (toasts, etc.)
- Roles only, values undefined

**T4. Typography Roles**

- `DisplayLarge/Medium/Small`, `TitleLarge/Medium/Small`, `BodyLarge/Medium/Small`, `LabelLarge/Medium/Small` (Material 3 type scale roles adopted as-is)
- Font family values undefined — the "few fixed fonts" principle (Stage 1 P6) is reflected structurally only: a rule limiting the project to a **maximum of 2 font families** (1 body + optionally 1 emphasis) is fixed now
- To support Dynamic Type (Stage 4 A5), each role must be based on a **scalable unit**, not a fixed px value (exact unit TBD)

**T5. Spacing Scale Role**

- Defines only stepped role names (`Spacing.xxs`–`Spacing.xl`), actual multiplier/base value undefined
- Structural rules like L5 (reserved space for overlay coverage) and L2 (overlay header) will reference this scale

**T6. Density Token (linked to L4)**

- `Density.min / Density.mid / Density.max` — the mapping point where Stage 3 L4's "3-level structure only" gets actual column-count values
- Values (column counts) undefined — only role names fixed here

**T7. Elevation/Overlay Token (linked to L2, L6)**

- `Elevation.overlayHeader`, `Elevation.overlayCanvas`, etc. — roles representing the visual layering order for L2 (overlay header) and L6 (non-displacing secondary region over fixed canvas)
- Values (z-index/blur degree) undefined

**T8. Motion Token (linked to A7)**

- `Motion.standard`, `Motion.reduced` — the point where Stage 4 A7 (reduced motion option) reflects system settings
- Duration/easing values undefined

### 3. AI Constraints

- Do not generate actual values (hex, px, font names) at this stage — pending Brand Guide output
- Do not finalize pure black/white as actual Neutral scale values (only the constraint rule is fixed, T2)
- Do not design more than 2 font families (T4)
- Do not decide concrete numeric values for Density/Elevation/Motion roles at this stage — deferred to Component Strategy or Brand Guide
- Do not invent new color/typography role concepts outside the Material 3 role system (no-redefinition principle)
