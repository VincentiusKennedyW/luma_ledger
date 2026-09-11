# Privacy

Luma Ledger stores user-entered financial information locally in an SQLite database in the app's sandbox. It does not require an account or send transaction data to a server. There is no advertising or product analytics. Fonts, icons and screens do not require internet access. Android receipt recognition uses the bundled Google ML Kit Latin text model on the device. Release manifests explicitly remove INTERNET and ACCESS_NETWORK_STATE permissions, including those contributed by dependencies, so production builds cannot upload OCR SDK telemetry. Debug/profile builds retain network access for Flutter tooling; ML Kit can send SDK diagnostics in those development builds. Do not treat a debug APK as the production privacy configuration.

The platform file picker reads only files the user selects for import or restore. Export opens the operating system's share/save interface; the user chooses the destination. Exported copies may remain in the app's temporary directory until the operating system clears it. JSON backups and CSV exports are plain text. The database is not encrypted by the application. Device lock, device storage protection and OS backup policies apply.

A complete JSON backup includes all local ledgers. Restoring one replaces the local database contents after confirmation. Users can delete a ledger through Settings or remove all application data using the operating system. Uninstalling without an external backup can lose records.

Each installation begins empty. Example data is fictional and is created only through the explicit demo action. The original CSV supplied during development is not an asset and is not distributed with the app.

Before publishing publicly, add your publisher identity, support contact, store privacy disclosures, and the privacy-policy hosting URL required by your distribution channel. This document accurately describes the implemented local behavior; it is not a hosted store listing.

## Android receipt images

Only images explicitly shared to Luma or selected through the system picker are read. No notification access, bank login, broad storage access or background bank monitoring is requested. A private copy and extracted text remain in Android’s no-backup directory until save/discard; pending copies older than 24 hours are removed at the next app startup. At most five images, each up to 20 MB and 32 megapixels, are held. These are not receipt archives and are excluded from Luma JSON backups. The original image in the bank app or selected source is never deleted by Luma.

Only the reviewed transaction fields and a hashed reference (or image fingerprint) are saved in SQLite. Account names, masked account numbers, PANs and raw OCR text are not copied into transaction notes or backups. OCR results do not authenticate a successful payment. Examples committed for testing are fictional; personal receipt screenshots provided during development are excluded.
