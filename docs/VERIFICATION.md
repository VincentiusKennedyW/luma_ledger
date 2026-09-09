# Luma 1.1 verification

- Flutter 3.35.6 / Dart 3.9.2; static analysis passes with no issues.
- 32 portable tests pass: 14 domain tests and 18 responsive layout configurations.
- Layout coverage: 375×812, 844×390 landscape, and 768×1024; light and dark; text scaling 1.0×, 2.0×, and 3.2×; reduced motion. Covers navigation, dashboard, activity, reports, budgets, entry, onboarding, settings, import, export, wallets, and recurring schedules. Missed scroll targets are treated as failures.
- Native iPhone 16 Pro simulator integration passes: actual SQLite storage, import deduplication, ledger isolation, transfers, recurring posting, rollback, backup restore and reopen; UI transaction entry, quick income entry, category-picker opening, filter/reset actions, and navigation.
- Eleven native screenshots were captured. Dashboard, activity, reports, budgets, entry, category picker, filter sheet, settings, import and dark appearance were visually inspected; label wrapping and amount alignment were corrected from that review.
- Accounting models, SQL storage and CSV importer match their pre-redesign SHA-256 hashes exactly. This redesign needs no database migration. Existing CSV/domain regressions continue to pass.
- Contrast: primary text on white 15.91:1; secondary text 4.97:1; primary button text 5.37:1; green text on mint 4.91:1.
- Inter is bundled locally under SIL OFL. No personal CSV, database, source-specific financial baselines, or release signing secrets are distributed.

Physical device testing and app-store publication have not been performed. iPhone distribution still requires Apple signing/provisioning.

Android release 1.1.0 (version code 2) built successfully. APK signature verified using v2; certificate SHA-256 e06ae8175fd1c31942668653b8a1ea2f60e040c9c6f3d24c72898a7c57537c65 matches the previous release. Package app.lumaledger.luma_ledger, minimum Android API 24, target API 36.
