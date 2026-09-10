# Version 1.2 native captures

These are actual Flutter renders of the Pocket almanac redesign using fictional demo records. Screenshots are captured by `integration_test/app_test.dart` and exported through `test_driver/integration_test.dart`; each PNG embeds its origin.

- `android/`: API 33 phone emulator, monthly/yearly reports, overview and expanded monthly breakdown.
- `iphone/`: iPhone 16 Pro, iOS 18.5 simulator, monthly/yearly reports, overview, transaction entry, dark appearance and 1.3× system text scaling.
- `ipad/`: iPad Pro 11-inch M4, iOS 18.5 simulator, yearly report, expanded monthly breakdown and transaction entry.

The monthly-breakdown images intentionally scroll to the opened section. Other captures start at the top. Viewport boundaries can cut off rows that remain available by scrolling. These replace the historical version 1.1 screenshots; Git history preserves those.

Reproduce with:

```sh
LUMA_SCREENSHOTS=.impeccable/review/iphone flutter drive --no-pub \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart -d <device-id>
```

The capture driver uses an isolated test database and must not be used as a distribution build. Build `lib/main.dart` normally for the application.
