import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fleet_dashboard/models/auth_user.dart';
import 'package:fleet_dashboard/models/user_role.dart';
import 'package:fleet_dashboard/widgets/auth/role_scope.dart';

AuthUser _user(String? role) => AuthUser(
  userId: '21',
  username: 'fajar',
  fullname: 'Fajar',
  email: '',
  role: role,
);

void main() {
  group('parsing', () {
    test('the values the live API actually sends', () {
      // Captured from the real server: fajar -> "Admin", Ghefira -> "User".
      expect(_user('Admin').accessRole, UserRole.admin);
      expect(_user('User').accessRole, UserRole.user);
    });

    test('casing and padding do not change the answer', () {
      for (final raw in ['admin', 'ADMIN', '  Admin  ', 'Administrator']) {
        expect(_user(raw).accessRole, UserRole.admin, reason: raw);
      }
    });

    test('anything unrecognised lands on the least privileged role', () {
      // A role nobody taught the app about must not be read as permission.
      // Guessing upward here would hand out access that was never granted.
      for (final raw in [null, '', 'Supervisor', 'root', 'superuser']) {
        expect(_user(raw).accessRole, UserRole.user, reason: '$raw');
      }
    });
  });

  group('what each role may do', () {
    test('only an admin changes the fleet or opens settings', () {
      expect(UserRole.admin.canManageFleet, isTrue);
      expect(UserRole.admin.canOpenSettings, isTrue);

      expect(UserRole.user.canManageFleet, isFalse);
      expect(UserRole.user.canOpenSettings, isFalse);
    });

    test('both roles can export, so a manager can still report upward', () {
      expect(UserRole.admin.canExportReports, isTrue);
      expect(UserRole.user.canExportReports, isTrue);
    });

    test('raw driver health readings are admin-only', () {
      expect(UserRole.admin.canSeeRawVitalSigns, isTrue);
      expect(UserRole.user.canSeeRawVitalSigns, isFalse);
    });
  });

  group('RoleScope', () {
    testWidgets('hands the role down the tree', (tester) async {
      late UserRole seen;
      await tester.pumpWidget(
        RoleScope(
          role: UserRole.admin,
          child: Builder(
            builder: (context) {
              seen = RoleScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, UserRole.admin);
    });

    testWidgets('outside any scope it denies rather than allows',
        (tester) async {
      // A widget rendered outside the scope — a dialog on the root navigator,
      // a test — must hide privileged actions, not show them to everyone.
      late UserRole seen;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            seen = RoleScope.of(context);
            return const SizedBox();
          },
        ),
      );
      expect(seen, UserRole.user);
      expect(seen.canManageFleet, isFalse);
    });
  });
}
