---
version: 1
slug: "lib-ui-receipt-import-dart"
primary_target: "lib/ui/receipt_import.dart"
related_targets: ["lib/ui/entry_form.dart", "lib/main.dart", "lib/ui/settings.dart"]
---

# Receipt import

Mode: Operate. Local extension of the existing Pocket almanac entry/import workflows. Inherit DESIGN.md; no new palette, typography, composition tournament or visual-world replacement.

The user pays with Wondr, GoPay and Permata on Android. Wondr's shared output is an image. Accept an explicitly shared or picked image, read it locally, show the pending receipt, then prefill the existing entry form for review. Nominal, merchant, receipt date and reference are suggestions. The account holder is not the merchant; an acquirer is not necessarily the payer's bank.

Hierarchy: Import receipt top bar, short Share instruction and image picker, IDR ledger selector, pending item with reading/error state, Review transaction and discard actions. The existing entry form gains receipt context and image inspection above the amount, explicit wallet selection, a neutral default category, and confirmation before the persistent Save action becomes available. Missing/uncertain values stay editable; failed/pending/refunded status blocks saving. Exact reference duplicates are blocked; likely manually entered duplicates ask before recording another.

A share arriving while a form is open stays in the inbox and does not replace the form. Images and OCR text are temporary, device-local, excluded from backups and source control, and removed after save/discard or on startup expiry. Native sharing/OCR is Android-only; existing iPhone/manual entry remains compatible. Use the existing system transitions, text scaling, dark theme and Material controls. Verify native phone captures, enlarged text, responsive widget cases and actual storage/duplicate behavior. Finish with a fresh scoped reviewer and a documenter comparison that preserves the existing design-system files.
