# Privacy

Luma Ledger stores user-entered financial information locally in an SQLite database in the app's sandbox. It does not require an account or send transaction data to a server. No advertising or analytics SDK is included. Fonts, icons and screens do not require internet access.

The platform file picker reads only files the user selects for import or restore. Export opens the operating system's share/save interface; the user chooses the destination. Exported copies may remain in the app's temporary directory until the operating system clears it. JSON backups and CSV exports are plain text. The database is not encrypted by the application. Device lock, device storage protection and OS backup policies apply.

A complete JSON backup includes all local ledgers. Restoring one replaces the local database contents after confirmation. Users can delete a ledger through Settings or remove all application data using the operating system. Uninstalling without an external backup can lose records.

Each installation begins empty. Example data is fictional and is created only through the explicit demo action. The original CSV supplied during development is not an asset and is not distributed with the app.

Before publishing publicly, add your publisher identity, support contact, store privacy disclosures, and the privacy-policy hosting URL required by your distribution channel. This document accurately describes the implemented local behavior; it is not a hosted store listing.
