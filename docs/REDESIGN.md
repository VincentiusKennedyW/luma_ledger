# Version 1.1 UI redesign

Requested style: modern white and green, using the ui-styling skill while retaining Flutter, GetX, and local SQLite.

The dashboard now has a compact mint balance summary, quick expense/income/transfer actions, period totals, and recent activity. A center Add button sits inside bottom navigation. The activity list aligns amounts to the right, groups dates, and moves category/wallet/review/type filtering into a sheet. Reports prioritize totals and cash flow, with full category rankings and exact monthly values. Transaction entry has an icon category picker, optional notes, and a persistent save action. Budgets come first on Plan; wallets and schedules remain directly accessible below. Onboarding, settings, import/export, dialogs, and secondary screens share the same tokens and Inter typeface.

No database migration is needed. Accounting models, CSV parsing, and SQL storage are byte-for-byte unchanged. Default currency remains IDR. The release uses the same private Android signing identity as 1.0, with versionCode 2 and versionName 1.1.0. Back up important ledgers before installing any update.

Inter is bundled locally under the SIL Open Font License; see assets/fonts/OFL.txt. No runtime font downloads are required. Demo screenshots contain fictional records. Personal CSV data and release signing files are excluded from the source archive and app package.
