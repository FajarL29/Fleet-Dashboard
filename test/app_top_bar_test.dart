import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fleet_dashboard/widgets/common/app_top_bar.dart';

void main() {
  testWidgets(
    'account menu routes through callbacks, not the enclosing Navigator',
    (tester) async {
      var settingTaps = 0;
      var logoutTaps = 0;

      // No named routes here on purpose: the bar must not reach for a
      // Navigator of its own, which is what broke "/settings" in the shell.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTopBar(
              userName: 'John Doe',
              userRole: 'Admin',
              onOpenSetting: () => settingTaps++,
              onLogout: () => logoutTaps++,
            ),
          ),
        ),
      );

      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();

      expect(find.text('Admin'), findsOneWidget);

      await tester.tap(find.text('Setting'));
      await tester.pumpAndSettle();
      expect(settingTaps, 1);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      expect(logoutTaps, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
