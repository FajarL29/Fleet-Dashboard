import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts how many copies of a page are mounted at once.
int _liveCount = 0;

class _Page extends StatefulWidget {
  const _Page(this.label);
  final String label;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  @override
  void initState() {
    super.initState();
    _liveCount++;
  }

  @override
  void dispose() {
    _liveCount--;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(widget.label);
}

void main() {
  testWidgets('sidebar navigation keeps one page mounted, not a stack', (
    tester,
  ) async {
    _liveCount = 0;
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          key: navigatorKey,
          initialRoute: '/',
          onGenerateRoute: (settings) => MaterialPageRoute(
            builder: (_) => settings.name == '/'
                ? const Text('root')
                : _Page(settings.name!),
            settings: settings,
          ),
        ),
      ),
    );

    // Mirrors DashboardScreen._openRoute.
    void openRoute(String route) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        route,
        (entry) => entry.isFirst,
      );
    }

    for (final route in ['/safety', '/reports', '/safety', '/safety']) {
      openRoute(route);
      await tester.pumpAndSettle();
    }

    expect(
      _liveCount,
      1,
      reason: 'pushNamed used to leave every visited page mounted and polling',
    );
    expect(find.text('/safety'), findsOneWidget);
  });
}
