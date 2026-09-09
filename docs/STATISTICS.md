# Monthly and yearly statistics

The reporting model in `lib/core/statistics.dart` is independent of storage and accepts entries from one selected ledger. No database migration is required. The new phone statistics interface is pending the design-direction selection.

- A month is a calendar month; a year is January through December.
- Month reports contain one bucket per calendar day. Year reports contain all twelve calendar months.
- Actuals stop at today; future buckets are explicitly upcoming.
- Completed periods compare to the preceding calendar month or year. In-progress periods compare to the same day in the preceding month or the same month/day in the preceding year, clamped to the available final day (including leap years).
- Percent changes are unavailable without a recorded current period and a nonzero spending baseline. Missing records are never represented as proof of zero real spending.
- Expenses, income and investment contributions remain separate. Net cash flow is income minus expenses minus contributions. Transfers and snapshots affect neither spending nor net cash flow.
- Daily average divides recorded expenses by elapsed calendar days, including days with no recorded spending. Yearly monthly average divides by elapsed calendar months, including the current partial month. Average purchase divides by expense record count.
- Days without recorded spending are an observation about the ledger, not a claim that no money was spent.
- Category, wallet, description and weekday breakdowns derive from the existing Report grouping functions. Exact values remain integer minor units until display.
- Expense drill-down clears old search/filter state and caps the range to recorded actuals through today.

Tests cover calendar boundaries, partial comparisons, leap years, future exclusion, cash-flow semantics, missing baselines and drill-down filter consistency.
