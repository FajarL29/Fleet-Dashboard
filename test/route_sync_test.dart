import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fleet_dashboard/utils/app_navigation.dart';

/// Mirrors the shell: an observer reports the top route, a "sidebar" shows it,
/// and a page navigates with [openAppRoute] the way an in-page link does.
class _Shell extends StatefulWidget {
  const _Shell({super.key});

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  String _active = '/';

  /// How many non-root pages are mounted right now.
  int livePages = 0;

  /// Stands in for a sidebar tap, which navigates from the shell rather than
  /// from inside the page (the page is covered once another route is on top).
  void openFromSidebar(String route) =>
      _navigatorKey.currentState!.pushNamedAndRemoveUntil(
        route,
        (entry) => entry.isFirst,
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('sidebar:$_active'),
        Expanded(
          child: Navigator(
            key: _navigatorKey,
            initialRoute: '/',
            observers: [
              _Observer(
                onRouteChanged: (route) {
                  if (route == null || !mounted) return;
                  setState(() => _active = route);
                },
              ),
            ],
            onGenerateRoute: (settings) => MaterialPageRoute(
              builder: (context) => settings.name == '/'
                  ? const _Overview()
                  : _Page(
                      label: settings.name!,
                      onCounted: (delta) => livePages += delta,
                    ),
              settings: settings,
            ),
          ),
        ),
      ],
    );
  }
}

/// Same stack tracking as the shell's observer.
///
/// Tracks the stack itself rather than reading the callback arguments: a
/// `pushNamedAndRemoveUntil` removes routes from the middle of the stack, and
/// `didRemove` hands back the route *below* the removed one, which is not
/// where the user ended up.
class _Observer extends NavigatorObserver {
  _Observer({required this.onRouteChanged});

  final ValueChanged<String?> onRouteChanged;

  final List<Route<dynamic>> _stack = [];

  /// Deferred to the next frame: the observer fires during navigation, and
  /// dispatching a bloc event mid-build would rebuild the widget tree while
  /// it is already being laid out.
  void _report() {
    if (_stack.isEmpty) return;
    final name = _stack.last.settings.name;
    WidgetsBinding.instance.addPostFrameCallback((_) => onRouteChanged(name));
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    _report();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _report();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _report();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (index >= 0 && newRoute != null) {
      _stack[index] = newRoute;
    } else if (newRoute != null) {
      _stack.add(newRoute);
    }
    _report();
  }
}

/// Stands in for Overview: the shell's permanent root, carrying the links
/// that jump elsewhere.
class _Overview extends StatelessWidget {
  const _Overview();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextButton(
        onPressed: () => openAppRoute(context, '/safety'),
        child: const Text('View All'),
      ),
    ],
  );
}

/// A routed page that reports whether it is still mounted, standing in for
/// the pages that poll the API while they live.
class _Page extends StatefulWidget {
  const _Page({required this.label, required this.onCounted});

  final String label;
  final ValueChanged<int> onCounted;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  @override
  void initState() {
    super.initState();
    widget.onCounted(1);
  }

  @override
  void dispose() {
    widget.onCounted(-1);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text('page:${widget.label}');
}

void main() {
  testWidgets('a View All link moves the sidebar highlight with it', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: _Shell())));
    await tester.pumpAndSettle();

    expect(find.text('sidebar:/'), findsOneWidget);

    await tester.tap(find.text('View All'));
    await tester.pumpAndSettle();

    // The bug: the page changed but the sidebar still said Overview.
    expect(find.text('page:/safety'), findsOneWidget);
    expect(find.text('sidebar:/safety'), findsOneWidget);
  });

  testWidgets('in-page links replace the page instead of stacking pages', (
    tester,
  ) async {
    final key = GlobalKey<_ShellState>();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: _Shell(key: key))),
    );
    await tester.pumpAndSettle();
    expect(key.currentState!.livePages, 0);

    await tester.tap(find.text('View All'));
    await tester.pumpAndSettle();
    expect(key.currentState!.livePages, 1);

    // Overview stays as the shell's root, so its links are still reachable —
    // and jumping on to another page must swap, not stack: a left-behind page
    // keeps polling the API from underneath.
    key.currentState!.openFromSidebar('/reports');
    await tester.pumpAndSettle();

    expect(key.currentState!.livePages, 1);
    expect(find.text('page:/reports'), findsOneWidget);
    expect(find.text('sidebar:/reports'), findsOneWidget);
  });
}
