# Android receipt import

After payment, tap the bank app’s Share action and choose Luma Ledger. For Wondr, share the original receipt image instead of a screenshot of the share sheet. A saved PNG/JPEG can also be chosen from Import receipt. Android only in version 1.3; iPhone retains manual entry and existing CSV/JSON tools.

1. Luma copies the explicitly shared image into its private receipt inbox and reads it on the device with bundled Latin OCR. No model download or notification permission is required.
2. Select the destination IDR ledger. If none exists, return to Overview, create one, then open Import receipt again.
3. Review the suggested amount, recipient and printed calendar date against View receipt. Choose the wallet you paid from and the expense category. Account names, merchant acquirers and bank labels never select a wallet automatically.
4. Confirm the successful IDR payment and reviewed details, then save. The image and raw OCR text are removed from Luma after a successful save; the expense enters the existing reports and budgets.

## Interpretation and limits

Wondr QRIS field labels are supported based on the supplied examples. Automated tests use fictional data with those labels, including Rp1 → one rupiah, not one hundred. GoPay/Permata provider labels and common Indonesian dates/currency are recognized, but their full real receipt layouts have not been validated. Unknown values stay empty for manual completion. The default category is Other. The date is the printed receipt date, not the phone status-bar time. A missing date defaults to today with an explicit review warning.

Failed, pending, cancelled or refunded text blocks recording as a completed expense. Missing success/currency text requires explicit manual confirmation. Text recognition can be wrong and cannot verify a bank transaction. Only successful expenses in IDR are supported: transfers, refunds, multi-currency conversion, PDF receipts, multiple-image shares and bank account synchronization are outside this feature.

A normalized reference, when readable, creates a hashed import key; otherwise the image hash is used. An exact key already in that ledger blocks saving, including after JSON backup/restore. Matching date, amount and recipient with a different key asks before saving another expense. Changed images without a readable reference or edited descriptions may evade this heuristic, so review remains necessary. Deleting an expense also removes its duplicate protection.

## Device lifecycle and privacy

The inbox survives app/process restarts. A share arriving on Overview opens the inbox; a share arriving during another form leaves that form intact and shows a message. Up to five pending images are retained, each at most 20 MB, 16,000 pixels per side and 32 megapixels. Corrupt/unsupported/unreadable images show a recoverable error. Save or discard removes Luma’s private image and OCR copy. Pending copies older than 24 hours expire at the next startup. Originals are untouched and pending images are excluded from both Android backup and Luma JSON backup.

Production Android builds enforce offline behavior by removing internet/network-state permissions. Development debug/profile builds require network access for Flutter and may emit ML Kit SDK diagnostics; see [Privacy](PRIVACY.md). No personal receipts are committed as test fixtures.

## Implementation and reproduction

Android ACTION_SEND with image/* and content URI read grants feeds the native receipt bridge. ACTION_OPEN_DOCUMENT provides manual import. A MethodChannel returns inbox updates to Flutter. The bridge uses bundled com.google.mlkit:text-recognition:16.0.1. Native files are kept in noBackupFilesDir; SQLite uses the existing unique ledger/import-key constraint, without a schema migration.

Run `flutter test` for parser, review validation and responsive coverage. On a disposable Android emulator, run `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/receipt_test.dart -d emulator-5554`. The native test clears that installation’s pending inbox, generates its own fictional receipt, exercises real OCR and SQLite, and captures the review flow. Never run it on an installation holding someone’s pending receipts.

References: [Android receiving shared data](https://developer.android.com/develop/ui/compose/sharing/receive), [bundled Android text recognition](https://developers.google.com/ml-kit/vision/text-recognition/v2/android).
