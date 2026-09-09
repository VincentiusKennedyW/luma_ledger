# Luma Ledger

<!-- impeccable:product-schema 1 -->

## Platform

android

Android-first Flutter app, also supporting iPhone. macOS is a development runner. Preserve iPhone safe areas, system text scaling, reduced motion and back navigation.

## Users

People tracking their own finances on a phone: quick daily entry, monthly budgeting, and yearly spending review. Confirmed by the user on 2026-09-09.

## Product Purpose

Make recorded income, everyday spending, investment contributions and remaining cash understandable over a month and a year. Success means entering a transaction quickly and answering where money went without confusing cash flow with investment performance or a verified bank balance.

## Operating Context

Personal finance, entirely offline with no account. Each installation begins empty; fictional demonstration data is explicitly opt-in. Separate local ledgers can represent personal or household purposes; they are not authenticated users or shared workspaces. IDR is the default currency.

## Capabilities and Constraints

Existing implementation evidence: README.md, docs/ARCHITECTURE.md, docs/PRIVACY.md and lib/.

- Flutter, GetX, local SQLite. Preserve existing entries and backup compatibility during UI/statistics changes.
- Entries: expense, income, investment contribution, transfer and historical balance snapshot. Transfers preserve overall cash; snapshots are excluded from actual balances and cash flow. Future entries are excluded until their date.
- Ledgers each have one fixed currency; never aggregate across currencies. Wallets, categories, budgets and recurring schedules belong to a ledger.
- Add, edit, duplicate, delete with immediate undo; search/filter; monthly total/category budgets; manually confirm or skip recurring occurrences.
- CSV preview/import with validation and duplicate handling; CSV export; complete JSON backup/restore. Restore replaces all local ledgers after confirmation.
- User-requested extension: richer monthly and yearly statistics with phone-first navigation and readable detail.
- No server, account, analytics, advertising, bank connection, automatic sync, exchange-rate conversion, investment valuation, automatic recurring posting or reminders.
- Local database and exported backups are not application-encrypted. Do not describe offline storage as encryption.

## Brand Commitments

Name: Luma Ledger. Preserve truthful, plain financial terminology. Visual identity is being redesigned at the user's request; existing colors are implementation evidence, not a newly confirmed constraint.

## Evidence on Hand

Existing Flutter source, domain/layout/integration tests, bundled icon and licensed Inter font, and fictional screenshots in docs/screenshots/. No verified customer claims, performance benchmarks or investment returns are supplied. Never invent them.

## Product Principles

1. Make daily entry quick and monthly/yearly review understandable on a phone.
2. Keep financial data local and under the user's control.
3. Separate expenses, investments, transfers and snapshots honestly.
4. Show exact amounts and disclose partial periods and incomplete records.
5. Preserve history and full-fidelity backups as the interface evolves.

## Accessibility & Inclusion

Preserve the existing support for system text scaling, light/dark/system appearance and reduced motion. Use Android-sized touch targets and semantic chart alternatives. Additional user-specific accessibility requirements and future localization remain open.
