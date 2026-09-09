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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final store = await LedgerDatabase.open();
    final controller = Get.put(LedgerController(store));
    await controller.initialize();
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
        child: child!,
      ),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const AppShell()),
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
    final c = Get.find<LedgerController>();
    return Obx(() {
      if (c.ledger == null) return const WelcomePage();
      final index = c.tab.value, t = Theme.of(context), scheme = t.colorScheme;
      final large = MediaQuery.textScalerOf(context).scale(1) > 1.4;
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: large ? 100 : 72,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ['Overview', 'Transactions', 'Insights', 'Your plan'][index],
              ),
              const SizedBox(height: 3),
              Text(
                c.ledger!.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            if (!large)
              IconButton(
                tooltip: 'Import CSV',
                onPressed: () => Get.toNamed('/import'),
                icon: const Icon(Icons.file_upload_outlined),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton.filledTonal(
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
          child: IndexedStack(
            index: index,
            children: const [
              OverviewPage(),
              TransactionsPage(),
              InsightsPage(),
              PlanningPage(),
            ],
          ),
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 7),
              child: Row(
                children: [
                  _destination(
                    context,
                    c,
                    0,
                    Icons.grid_view_rounded,
                    'Overview',
                    large,
                  ),
                  _destination(
                    context,
                    c,
                    1,
                    Icons.receipt_long_outlined,
                    'Activity',
                    large,
                  ),
                  Expanded(
                    child: Center(
                      heightFactor: 1,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(
                          minimumSize: const Size(52, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        tooltip: 'Add transaction',
                        onPressed: () => Get.toNamed('/entry'),
                        icon: const Icon(Icons.add_rounded, size: 28),
                      ),
                    ),
                  ),
                  _destination(
                    context,
                    c,
                    2,
                    Icons.bar_chart_rounded,
                    'Insights',
                    large,
                  ),
                  _destination(
                    context,
                    c,
                    3,
                    Icons.pie_chart_outline_rounded,
                    'Plan',
                    large,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _destination(
    BuildContext context,
    LedgerController c,
    int index,
    IconData icon,
    String label,
    bool large,
  ) {
    final selected = c.tab.value == index,
        scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: Tooltip(
          message: label,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => c.tab.value = index,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: selected
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  if (!large)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
