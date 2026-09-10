---
name: "Luma Ledger"
description: "Pocket almanac: warm paper, calendar-led money, and exact recorded amounts."
colors:
  indigo: "#4056A1"
  indigo-wash: "#E6EAF8"
  rust: "#AD5238"
  income-green: "#276955"
  category-lavender: "#75679D"
  paper: "#F7F5F0"
  surface: "#FFFEFB"
  soft-surface: "#F0EFEA"
  ink: "#242938"
  muted: "#616471"
  rule: "#DCDDDC"
  outline: "#7B7F8C"
  error: "#B33535"
  dark-indigo: "#B5C5FF"
  dark-indigo-wash: "#303C67"
  dark-rust: "#FFB59E"
  dark-income-green: "#8BD5BB"
  dark-paper: "#191C26"
  dark-surface: "#222634"
  dark-soft-surface: "#282D3B"
  dark-ink: "#F1F0EA"
  dark-muted: "#B8BDCB"
  dark-rule: "#424858"
  dark-error: "#FFB4AB"
typography:
  display:
    fontFamily: "Inter"
    fontSize: "34px"
    fontWeight: 600
    lineHeight: 1.15
    letterSpacing: "-1px"
  headline:
    fontFamily: "Inter"
    fontSize: "26px"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "-0.8px"
  title-large:
    fontFamily: "Inter"
    fontSize: "22px"
    fontWeight: 600
    letterSpacing: "-0.5px"
  title-medium:
    fontFamily: "Inter"
    fontSize: "16px"
    fontWeight: 600
    letterSpacing: "-0.25px"
  title-small:
    fontFamily: "Inter"
    fontSize: "14px"
    fontWeight: 600
  body-large:
    fontFamily: "Inter"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.45
  body:
    fontFamily: "Inter"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.5
  body-small:
    fontFamily: "Inter"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1.45
  label-large:
    fontFamily: "Inter"
    fontSize: "13px"
    fontWeight: 600
  label:
    fontFamily: "Inter"
    fontSize: "12px"
    fontWeight: 500
  label-small:
    fontFamily: "Inter"
    fontSize: "10px"
    fontWeight: 600
    letterSpacing: "0.7px"
rounded:
  chart-bar: "2px"
  progress: "5px"
  row: "8px"
  chip: "10px"
  field: "12px"
  button: "13px"
  panel: "14px"
  fab: "16px"
  dialog: "22px"
  sheet-top: "24px"
spacing:
  step-4: "4px"
  step-6: "6px"
  step-8: "8px"
  step-10: "10px"
  step-12: "12px"
  step-14: "14px"
  step-16: "16px"
  step-20: "20px"
  step-22: "22px"
  step-24: "24px"
components:
  button-primary:
    backgroundColor: "{colors.indigo}"
    textColor: "{colors.surface}"
    rounded: "{rounded.button}"
  button-outlined:
    textColor: "{colors.indigo}"
    typography: "{typography.label-large}"
    rounded: "{rounded.field}"
  button-text:
    textColor: "{colors.indigo}"
  input:
    backgroundColor: "{colors.soft-surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.field}"
    padding: "15px 16px"
  navigation:
    backgroundColor: "{colors.paper}"
    typography: "{typography.label}"
  chip-selected:
    backgroundColor: "{colors.indigo-wash}"
    typography: "{typography.label}"
    rounded: "{rounded.chip}"
    padding: "8px"
  panel:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.panel}"
    padding: "{spacing.step-20}"
  calendar-band:
    backgroundColor: "{colors.indigo-wash}"
    textColor: "{colors.indigo}"
    typography: "{typography.title-medium}"
    rounded: "{rounded.panel}"
    padding: "8px 4px"
---

# Design System: Luma Ledger

## Overview

**Creative North Star: "Pocket almanac"**

Luma Ledger reads money as a calendar: years open into months, and months into dated entries. Warm paper, deep ink, indigo selection bands and a rust spending trace make an everyday ledger feel calm and legible. Open financial rows carry the information; restrained containers gather forms, budgets and supporting tasks.

This is an Android-first Flutter interface with Material 3 controls, also supporting iPhone. The same hierarchy survives dark appearance, larger system text and expanded screens. The wallet-and-coin app mark remains the identity asset; no simulated paper texture or additional illustration is part of this implemented world.

**Key Characteristics:**

- Calendar bands orient the reader before financial detail.
- One Inter family with tabular amounts and restrained weight changes.
- Open rows, fine rules and flat tonal surfaces.
- Semantic color and plain language preserve financial distinctions.
- System text scaling, native controls and reduced motion remain part of the design.

This post-build record replaces the historical visual authority of `design-system/luma-ledger/MASTER.md`. Ground truth is `lib/ui/theme.dart`, `lib/main.dart`, `lib/ui/components.dart`, `lib/ui/insights.dart`, `lib/ui/entry_form.dart` and `lib/ui/planning.dart`. The surface contract remains in `.impeccable/surfaces/lib-ui-insights-dart.md`; product scope remains in `PRODUCT.md`. The finish review records a ship disposition over 13 native captures and sampled source, with no material fixes. This document does not expand that review into a physical-device or screen-reader certification.

## Colors

A warm neutral ground holds cool calendar selection and a restrained warm spending accent. Frontmatter values are normative; names below describe their application. Historical Dart constant names such as `forest` and `mint` now resolve to indigo and its wash; they do not describe a second palette.

### Primary

- **Indigo / Indigo wash:** primary actions, selection, calendar bands and invested-contribution report rows. The wash groups context without introducing elevation.
- **Dark indigo / Dark indigo wash:** the corresponding semantic primary and container roles in dark appearance. Primary button text uses dark paper; text on the dark calendar band uses dark ink.

### Secondary

- **Rust / Dark rust:** spending bars, expense totals in financial rows and expense-category progress.
- **Income green / Dark income green:** income in report rows and the semantic tertiary role. Entry-list income uses primary indigo, as implemented; color meanings must always travel with labels.
- **Category lavender:** investment category identity; category colors are supplementary, not a substitute for transaction-kind labels.
- **Error / Dark error:** validation feedback and over-budget states.

### Neutral

- **Paper / Dark paper:** the scaffold, app bar and navigation ground.
- **Surface / Dark surface:** cards, dialogs and sheets.
- **Soft surface / Dark soft surface:** filled fields, quiet controls and upcoming-date chart shading.
- **Ink / Dark ink:** primary text. **Muted / Dark muted:** supporting labels and explanatory text.
- **Rule / Dark rule:** card outlines, dividers and chart baselines. **Outline:** light-mode stronger outlines; dark mode uses dark muted for that role.

**The Calendar Ink Rule.** Use indigo for selection and primary action, rust for spending traces, and green for income in report rows. Keep the text label with the color.

Flutter's seeded ColorScheme supplies unoverridden Material roles. Do not infer an exact secondary-container palette from these explicit tokens. Sidecar tonal ramps are synthesized swatch explorations, not additional application colors.

## Typography

**Display and body font:** bundled Inter. All authored theme text enables tabular figures. Native Flutter resolves platform fallback for unavailable glyphs; no alternate display face is prescribed.

The hierarchy favors practical numerals and modest heading steps. The frontmatter uses portable CSS `px` notation for the nominal Flutter logical font sizes; native text remains subject to the system text scaler. Explicit line-height multipliers and tracking are recorded only where set in source. Unspecified values inherit Flutter/Material text behavior.

### Hierarchy

- **Display:** the dominant amount and amount entry, using `display` / Flutter `displaySmall`.
- **Headline:** intermediate large totals, using `headline` / `headlineMedium`.
- **Title large / medium / small:** section and component hierarchy. Emphasized financial values use title large; ordinary row values use title medium.
- **Body large / body / body small:** prose, row labels and supporting explanations. Body small uses the muted semantic role.
- **Label large / label / label small:** compact controls and small annotations. The existence of label small is not a prescription for uppercase eyebrow headings.

The app bar uses the title-large size and weight with separately authored tracking of −0.7 logical pixels. Filled buttons use 14/600, outlined buttons 13/600, and text buttons 12/600. These native control overrides do not imply a new global type family or line-height scale.

**The Exact Amount Rule.** Use tabular Inter figures for money and preserve the full formatted amount; allow layout to reflow before sacrificing financial meaning.

## Layout

Pages scroll in a single reading column. `PageBody` has 24 logical pixels of horizontal padding, 12 at the top, and 104 at the bottom to leave room for persistent controls. Its content is centered at a maximum width of 860 logical pixels. Repeated gaps use the frontmatter spacing steps; forms commonly separate fields by 12 or 20, and section headings use 22 above and 10 below. These are observed values, not a forced mathematical grid.

At a viewport width of 720 logical pixels or wider, the four-destination bottom navigation becomes a left rail with a fine divider, and Add moves to the rail. Page content keeps its reading order and width constraint. The standard theme app bar is 64 high; the main shell overrides it to 76, or 144 when the text-scale factor exceeds 1.4.

Above text scale 1.4, section actions and financial rows reflow, entry amounts move below their descriptions, entry category selection becomes one column, and navigation labels hide while destination tooltips remain. Financial rows also stack below 290 logical pixels of available width. The supporting stat grid becomes one column above text scale 1.5. These are per-component adaptations, not global breakpoints to apply blindly.

The main scaffold and entry form preserve safe areas. Entry Save sits in a bottom safe-area region with horizontal 20, top 10 and bottom 12 padding; form content scrolls independently. Expanded rails can scroll on short screens. Keep Android-sized controls: authored button and icon-button minimum dimensions start at 48 logical pixels; filled buttons have a minimum height of 52.

## Elevation & Depth

The authored page chrome, cards and FAB use no shadow at rest. Paper, surface, selection wash, thin outlines and whitespace express grouping. Cards carry a one-logical-pixel outline; the chart has a one-logical-pixel baseline. This is a flat interface, not a simulation of a physical paper object. Dialog and bottom-sheet elevation and Material state layers are inherited; there is no custom shadow vocabulary to invent for them.

**The Flat Paper Rule.** Use tonal surfaces and fine rules for authored separation. App bars, cards, bottom navigation and the Add action have zero configured elevation.

## Shapes

Use restrained rounded rectangles: fields and outlined buttons share the field radius, filled buttons have their own button radius, and panels/calendar bands share the panel radius. Chips are tighter, while the Add action is slightly softer. Dialogs and sheet top corners are larger native interruption surfaces. Use the exact role values in frontmatter rather than rounding every surface identically.

Financial rows use a small radius only for their InkWell feedback; they remain visually open. Category avatars are 44-square with the panel radius, a category-color fill at 10% opacity, and a 22-pixel Material icon. Dark-mode avatar icons use primary color. Chart bars use the chart-bar radius; progress rails use the progress radius unless overridden by the 8-high budget indicator, which uses an 8-pixel radius.

## Components

### Buttons

Calm, readable native actions. Filled buttons use primary/on-primary and the button radius, with a 48×52 minimum size. Outlined buttons use a fine outline and the field radius, with a 48×48 minimum. Text buttons and icon buttons also have 48×48 minima; icon buttons use 21-pixel icons unless locally overridden. The Add FAB is flat, uses primary/on-primary and the FAB radius, and has a 28-pixel plus icon.

Pressed, hovered, focused and disabled button treatments inherit Material 3 unless explicitly overridden. Do not convert the minimum dimensions into fixed heights. Entry Save disables while saving, exchanges its icon for an 18-square progress indicator, and reports its saving state in text. Successful save triggers light native haptic feedback.

### Chips

Compact category/type choices use soft surface at rest and primary container when selected, with no border and no checkmark by default. Theme padding is 8 in both axes and text uses the label role. Entry-type chips override that padding to horizontal 2 and vertical 6. Keep the native selection and touch-target behavior; no authored hover color is specified.

### Cards / Containers

Panels gather budgets, wallet management and empty states. They use the surface role, panel radius, one-pixel rule outline and default 20 padding with no elevation. Supporting panels may use horizontal 16 and vertical 4. Planning's current-month summary uses the primary-container fill and the same radius; report financial rows remain unboxed.

### Inputs / Fields

Fields use soft-surface fill, the field radius, and 15 vertical by 16 horizontal content padding. Their ordinary outline is a fine rule; focus changes it to primary at 1.5 pixels. Labels are Inter 13/400 and hints 14/400 in muted text. Helper and error messages can occupy up to three lines. Error/disabled styling beyond the semantic error color remains Material behavior.

The amount field uses display text on primary container with 22 padding and an always-floating currency label. Other text fields, dates, dropdowns and category sheets retain native form semantics. Do not replace labels with placeholder-only instructions.

### Navigation

Overview, Activity, Insights and Plan are four peer destinations. Native Material icons and a pale indigo indicator orient the selected destination on the paper ground. Bottom-navigation text uses the label role; icon and state colors otherwise follow Material defaults. The rail explicitly sets selected icons to primary. Preserve native state feedback and system back behavior rather than adding authored page choreography.

### Calendar band

A quiet indigo wash makes the active month or year unmistakable. The panel radius and padding of 8 vertical / 4 horizontal wrap previous, center period-picker and next controls. The centered title-medium label uses on-primary-container. Forward movement disables when it would enter a future period; the previous control respects the recorded lower date limit.

The period label uses AnimatedSwitcher’s fade over 180ms; the incoming curve is `Curves.easeOutCubic`, while other switcher behavior is inherited. Totals update immediately. `MediaQuery.disableAnimationsOf` makes the duration zero. App routes use native transitions, or no transition when system animations are disabled. No other authored global duration is prescribed.

### Financial rows and spending chart

Open rows place the label and exact amount together, with 14 vertical padding and a chevron only when tappable. Emphasized rows use larger amounts; financial meaning remains in words. Monthly/yearly breakdowns lead into contributing entries while retaining report context on return.

Spending charts show the whole selected period in a 124-high plotting region, with zero baseline, shared scale within that plot and tick labels outside it. Bars take 64% of their bucket width with 18% side insets; positive values scale against the largest bucket with 6 pixels of headroom. Upcoming buckets use soft-surface shading and an explicit legend. The semantic chart description points to exact values in the dated breakdown. Decorative chart motion is absent.

The schema-2 sidecar contains eight self-contained HTML/CSS previews of representative native components. They resolve Flutter-only tokens to literal CSS and translate logical pixels 1:1 for illustration. Browser interaction feedback, fallbacks and layout mechanics are explicitly preview conventions, not production Flutter implementations or approved native hover values.

## Do's and Don'ts

### Do:

- **Do** keep calendar context visible when opening monthly or daily detail.
- **Do** use the theme’s semantic colors so dark appearance retains the same roles.
- **Do** keep exact amounts, missing records, partial periods and upcoming dates explicit.
- **Do** allow system text scaling and reflow rows and controls at their implemented thresholds.
- **Do** preserve native Material interaction feedback, safe areas, route transitions and reduced-motion handling.
- **Do** retain the wallet-and-coin mark; use real Material icons for application controls.

### Don't:

- **Don't** turn every report value into a tinted metric card; keep the implemented open-row hierarchy.
- **Don't** introduce paper grain, bevels, decorative gradients or hard offset shadows into the flat material language.
- **Don't** animate money totals with counting or rolling digits; the authored transition belongs to the period label.
- **Don't** encode financial meaning only through color or confuse invested contributions with investment returns.
- **Don't** treat synthesized sidecar ramps, web focus rings or browser line-height defaults as native theme tokens.

Not canonized: unused historical color constants, inferred Material defaults, and synthesized preview behavior are not new native rules. The bounded finish review found no material visual defects to carry forward or repair.
