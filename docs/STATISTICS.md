# Monthly and yearly statistics

The reporting model in `lib/core/statistics.dart` is independent of storage and accepts entries from one selected ledger. No database migration is required. The Insights screen defaults to Monthly and also provides Yearly. The adjacent menu opens the preserved all-time/custom reporting view.

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

## Navigation and interpretation

Use the calendar band arrows to move by a month or year. Tap its label to jump to a date in another period. Upcoming periods cannot be selected through the forward arrow. Open the monthly breakdown to see all twelve months, including explicit upcoming and no-records states; select a month for its daily report. A day opens its expense records in Activity, clearing stale filters and excluding future entries. Returning to Insights preserves the statistics period. Income and investment total rows also open their corresponding entries.

The rust chart shows expense amounts, with a zero baseline, a peak label and labels positioned at their actual calendar buckets. Shaded dates are upcoming. Exact values and accessible native controls live in the breakdown below; chart marks are not undersized tap targets. Category rows include shares, record counts and changes from the previous comparison period.
