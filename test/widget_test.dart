import 'package:fleet_dashboard/constants/menu_items.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('monitoring routes are registered in the sidebar', () {
    final routes = MenuItems.items.map((item) => item.route).toSet();

    expect(routes, contains('/vital-sign'));
    expect(routes, contains('/air-quality'));
    expect(routes, containsAll(<String>['/', '/vehicles', '/drivers', '/safety', '/reports']));
  });
}
