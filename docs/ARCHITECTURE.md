# Architecture

`lib/core/models.dart` contains immutable money, entry, wallet, ledger, period and report models. It owns decimal validation, date boundaries and recurrence calculation. Display formatting uses `intl`; IDR renders without decimal digits when the value is integral.

`lib/data/database.dart` contains SQLite schema version 1, migrations entry point, local settings, foreign keys, transactional entry persistence, all-or-nothing import, recurring posting, and transactional backup restoration. Foreign keys are enabled at connection time. Date/category indexes support ledger retrieval; source fingerprints are unique within a ledger.

`lib/data/csv_import.dart` is an isolated, independently tested migration boundary. It converts legacy booleans into explicit entry types and never executes text from an imported document. The UI invokes parsing in an isolate, then presents counts and row errors before writing.

`lib/controllers/ledger_controller.dart` coordinates GetX reactive state and persistence. The database remains the source of truth. Each mutation awaits persistence and refreshes affected state; errors leave input available for retry. The controller owns date and filter state across navigation.

`lib/ui/` includes native Material screens, semantic theme tokens and reusable components. There are four top-level destinations: Overview, Activity, Insights and Plan. Named in-app routes cover import, export, transaction editing, wallets, recurring entries and settings. OS universal/app-link registration is not configured.

## Tables

| Table | Purpose |
|---|---|
| ledgers | Independent local books with fixed currency |
| wallets | Opening balances and wallet names, scoped to a ledger |
| categories | Normalized category names scoped to a ledger |
| entries | Dated positive amounts and explicit kinds; optional transfer destination/import fingerprint |
| budgets | Repeating calendar-month expense limits, per category or all expenses |
| recurring | Confirmable schedules with an anchor day and next due date |
| settings | Current ledger and appearance |

A transfer is one record with source and destination wallets. Both wallets must belong to the same ledger, and they must differ. Investment transactions decrease cash but are not ordinary expenses. Historical snapshots do neither. There is no automatic inference of a bank balance from incomplete history.

## Extending the app

- Add numbered, transactional `onUpgrade` migrations before changing the schema. Never delete a database to “fix” a migration.
- For larger histories, replace whole-ledger loading with SQL aggregation and paginated queries. Activity already builds visible rows lazily, but report calculations currently use the in-memory ledger. CSV input has a 20 MB limit.
- Add a sync implementation behind the repository boundary if remote sharing is later required; stable ids and explicit kinds support this. Do not sum values from different ledger currencies.
- Add local notifications as a separate scheduling adapter. Current recurring records require explicit confirmation and are available in the app only.
- Add attachments as a separate managed store with backup coverage; no receipt photos are currently collected.

## Tests with financial impact

Money precision/limits, invalid dates and flags, category normalization, multiline CSV, deduplication with repeated occurrences, snapshot/investment semantics, future exclusion, date bounds, report formulas, monthly and leap-day recurrence, wallet isolation, transfer conservation, failed-import rollback, failed-restore rollback, idempotent recurring posting, and on-disk reopen persistence.
