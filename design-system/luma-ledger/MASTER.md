# Luma 1.1 — white & green

## Design direction

A clean daily ledger should make money readable before it asks for attention. White is the canvas; emerald identifies actions and meaningful state. Pale mint gives the recorded balance a distinct home without turning the screen into an oversized promotional card. Borders, spacing, and type establish the rest of the hierarchy.

Inter creates a consistent voice across Android and iOS. Tabular figures make changing amounts easier to compare, while restrained sizes keep useful records in view. The largest type belongs to money. Supporting copy is short, and detailed explanations live in disclosures where they can be read when needed.

The interface uses compact, repeatable shapes: rounded inputs, low-profile buttons, lightly bordered panels, and soft square category icons. The small radius differences express hierarchy without making each component look unrelated. Green variations distinguish chart series; labels, signed amounts, and exact values carry meaning independently of color.

Navigation keeps four destinations and puts the primary add action in the center. It occupies its own touch target without floating over transaction content. Quick actions choose the transaction type before opening the form. Activity presents a search field, three common type choices, and a sheet for advanced filters. Forms lead with amount and description, then wallet, category, and date; notes are optional, and Save stays visible.

The ui-styling skill's semantic tokens, composable components, mobile-first spacing, and accessible control principles are implemented in native Flutter widgets. GetX and SQLite remain the application stack. Screenshots from the iPhone simulator are the reference compositions; they use fictional demo data.

## Tokens

| Role | Light | Dark |
|---|---|---|
| Canvas | #FFFFFF | #111A15 |
| Panel | #FFFFFF | #1A2820 |
| Primary | #087A50 | #75D6A5 |
| Soft primary | #EAF8F0 | #213C2D |
| Text | #17251E | #F2F7F3 |
| Secondary text | #66736B | #ACBDB0 |
| Border | #E5ECE7 | #344D3E |
| Quiet surface | #F5F8F6 | #16231B |

20 px phone gutters; 760 px content maximum. Spacing primarily 4/8/12/16/20/24. Card radius 18–22; inputs 12; primary button 13; category avatar 14. Controls have at least 48 px touch targets; primary actions 52 px. Main amount 34 px, page title 22 px, section title 16 px, body 13–15 px, metadata 11 px. OS text scaling stays enabled. Large text stacks information and changes navigation labels to semantic icon controls.

Contrast ratios: main text on white 15.91:1; secondary text 4.97:1; white on emerald 5.37:1; emerald on mint 4.91:1. Secondary text on the quiet surface is 4.64:1. Color is never the only indication of transaction type, budget status, selection, or chart values.

## Interaction rules

- Always offer a labeled, semantic Add transaction action in navigation.
- Keep amounts aligned at the right of activity rows; stack at large text sizes.
- Keep advanced filters in a scrollable sheet with a live matching-record count and Reset.
- Category selection uses a scrollable icon grid, switching to one column for enlarged text.
- Save stays available at the bottom of the entry screen. Preserve validation, unsaved-change confirmation, duplication, and delete/undo.
- Chart month taps open exact month totals and an explicit transaction drill-down.
- Retain all category rankings in full reports; the dashboard summarizes the top three.
- Honor reduced motion and native focus, keyboard, back, and screen-reader behavior.
- Light is the default for new installs. An existing explicit appearance preference remains respected.
