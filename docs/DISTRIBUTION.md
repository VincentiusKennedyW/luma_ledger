# Install and share Luma

## Android

A release signing key has been created locally for this project. It is unique to this app and kept in ignored files:

- `android/luma-release.jks`
- `android/key.properties`

**Back up both files privately.** Keep the same key for future updates. Do not send either file to other people, commit them, or include them in a public source archive. The provided source archive excludes them.

To generate your own signing identity in a separate copy of the project, run `python3 tool/create_signing_key.py` once. It refuses to overwrite existing files. A Java keytool installation is required. The Gradle release configuration reads `android/key.properties` and does not fall back to debug signing.

```sh
flutter pub get
flutter build apk --release
# For Play Console, when ready:
flutter build appbundle --release
```

The APK is at `build/app/outputs/flutter-apk/app-release.apk`. Copy it to an Android phone and open it. The phone may ask you to allow installs from the file-sharing/browser app you chose. You can send the APK to another person; their installation starts empty and contains none of your history. To update an existing installation, retain the same application id and signing key and increase the version/build in `pubspec.yaml`.

Debug and release builds use different signing identities. Android cannot install a release over a debug build with the same id. Back up your data before removing an older test build.

Before store publication, choose your final publisher identity and application id, add support/privacy URLs, prepare store listings/screenshots, and meet the store's current signing and policy requirements. No store upload is performed by this project.

## iOS

```sh
flutter run -d <simulator-id>
# Physical devices / archive:
open ios/Runner.xcworkspace
```

Choose your Apple Developer team and a bundle identifier registered to you in Xcode. Then use Xcode Archive or `flutter build ipa --release`. Personal device installation and sharing via TestFlight require the appropriate Apple signing/provisioning. A simulator app is not an installable iPhone IPA. No TestFlight or App Store publishing has been performed.

## macOS developer runner

`flutter run -d macos` uses the same SQLite backend. File-picker read/write entitlements are configured. Public macOS distribution would additionally need the publisher's signing and notarization setup.

## Data migration

App installation packages never contain your local SQLite database. If you want to move *your* history to another device, use the app's complete JSON backup and restore. A backup intentionally includes all ledgers and financial records, unlike a clean APK.
