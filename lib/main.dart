import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/ledger_controller.dart';
import 'core/models.dart';
import 'data/database.dart';
import 'ui/theme.dart';
import 'ui/overview.dart';
import 'ui/planning.dart';
import 'ui/settings.dart';
import 'ui/entry_form.dart';
import 'ui/data_tools.dart';
import 'receipts/receipt_inbox.dart';
import 'ui/receipt_import.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final store = await LedgerDatabase.open();
    final controller = Get.put(LedgerController(store));
    await controller.initialize();
    if (Platform.isAndroid) {
      final inbox = Get.put(ReceiptInbox(), permanent: true);
      try {
        await inbox.start();
      } catch (_) {
        /* Ledger startup remains available if receipt import fails. */
      }
    }
    runApp(const LumaApp());
  } catch (_) {
    runApp(
      MaterialApp(
        theme: lumaTheme(Brightness.light),
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storage_outlined, size: 48),
                    const SizedBox(height: 20),
                    const Text(
                      'Your ledger could not be opened. Close and reopen Luma to try again. Your data has not been reset.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: main,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LumaApp extends StatelessWidget {
  const LumaApp({super.key});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<LedgerController>();
    return GetMaterialApp(
      title: 'Luma Ledger',
      debugShowCheckedModeBanner: false,
      theme: lumaTheme(Brightness.light),
      darkTheme: lumaTheme(Brightness.dark),
      themeMode: c.themeMode,
      defaultTransition:
          WidgetsBinding
              .instance
              .platformDispatcher
              .accessibilityFeatures
              .disableAnimations
          ? Transition.noTransition
          : Transition.native,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: MediaQuery.of(context).disableAnimations),
        child: ReceiptArrival(child: child!),
      ),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const AppShell()),
        GetPage(name: '/receipts', page: () => const ReceiptImportPage()),
        GetPage(
          name: '/entry',
          page: () => _guard(
            () => EntryFormPage(
              entry: Get.arguments is Entry ? Get.arguments as Entry : null,
              initialKind: Get.arguments is EntryKind
                  ? Get.arguments as EntryKind
                  : EntryKind.expense,
            ),
          ),
        ),
        GetPage(name: '/import', page: () => _guard(() => const ImportPage())),
        GetPage(name: '/export', page: () => _guard(() => const ExportPage())),
        GetPage(
          name: '/wallets',
          page: () => _guard(() => const WalletsPage()),
        ),
        GetPage(
          name: '/recurring',
          page: () => _guard(() => const RecurringPage()),
        ),
        GetPage(
          name: '/settings',
          page: () => _guard(() => const SettingsPage()),
        ),
        GetPage(
          name: '/transactions',
          page: () {
            c.tab.value = 1;
            return const AppShell();
          },
        ),
        GetPage(
          name: '/insights',
          page: () {
            c.tab.value = 2;
            return const AppShell();
          },
        ),
        GetPage(
          name: '/plan',
          page: () {
            c.tab.value = 3;
            return const AppShell();
          },
        ),
      ],
    );
  }

  Widget _guard(Widget Function() page) =>
      Get.find<LedgerController>().ledger == null
      ? const WelcomePage()
      : page();
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<LedgerController>(), t = Theme.of(context);
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    final expanded = MediaQuery.sizeOf(context).width >= 720;
    const icons = [
      Icons.space_dashboard_outlined,
      Icons.receipt_long_outlined,
      Icons.calendar_month_outlined,
      Icons.pie_chart_outline_rounded,
    ];
    const labels = ['Overview', 'Activity', 'Insights', 'Plan'];
    Widget addButton() => FloatingActionButton(
      tooltip: 'Add transaction',
      onPressed: () => Get.toNamed('/entry'),
      child: const Icon(Icons.add_rounded, size: 28),
    );
    return Obx(() {
      if (c.ledger == null) return const WelcomePage();
      final index = c.tab.value;
      final pages = IndexedStack(
        index: index,
        children: const [
          OverviewPage(),
          TransactionsPage(),
          InsightsPage(),
          PlanningPage(),
        ],
      );
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: large ? 144 : 76,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(labels[index], maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(
                c.ledger!.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            if (Get.isRegistered<ReceiptInbox>())
              IconButton(
                tooltip: 'Import receipt',
                onPressed: () => Get.toNamed('/receipts'),
                icon: Badge(
                  isLabelVisible: Get.find<ReceiptInbox>().items.isNotEmpty,
                  child: const Icon(Icons.add_photo_alternate_outlined),
                ),
              ),
            if (!large)
              IconButton(
                tooltip: 'Import CSV',
                onPressed: () => Get.toNamed('/import'),
                icon: const Icon(Icons.file_upload_outlined),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                tooltip: 'Settings',
                onPressed: () => Get.toNamed('/settings'),
                icon: const Icon(Icons.tune_rounded),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: expanded
              ? Row(
                  children: [
                    LayoutBuilder(
                      builder: (context, bounds) => SingleChildScrollView(
                        child: SizedBox(
                          height: bounds.maxHeight < 420
                              ? 420
                              : bounds.maxHeight,
                          child: NavigationRail(
                            selectedIndex: index,
                            onDestinationSelected: (i) => c.tab.value = i,
                            labelType: large
                                ? NavigationRailLabelType.none
                                : NavigationRailLabelType.all,
                            leading: Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: addButton(),
                            ),
                            destinations: List.generate(
                              4,
                              (i) => NavigationRailDestination(
                                icon: Icon(icons[i]),
                                label: Text(labels[i]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    VerticalDivider(
                      width: 1,
                      color: t.colorScheme.outlineVariant,
                    ),
                    Expanded(child: pages),
                  ],
                )
              : pages,
        ),
        floatingActionButton: expanded ? null : addButton(),
        bottomNavigationBar: expanded
            ? null
            : NavigationBar(
                selectedIndex: index,
                onDestinationSelected: (i) => c.tab.value = i,
                labelBehavior: large
                    ? NavigationDestinationLabelBehavior.alwaysHide
                    : NavigationDestinationLabelBehavior.alwaysShow,
                destinations: List.generate(
                  4,
                  (i) => NavigationDestination(
                    icon: Icon(icons[i]),
                    label: labels[i],
                    tooltip: labels[i],
                  ),
                ),
              ),
      );
    });
  }
}
