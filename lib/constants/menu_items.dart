import 'package:flutter/material.dart';

/// A single navigable entry: a standalone top-level item, or a child
/// nested inside a [MenuSection] group.
class MenuItem {
  final String title;
  final IconData? icon;
  final String route;

  const MenuItem({required this.title, this.icon, required this.route});
}

/// A top-level sidebar entry.
///
/// - Standalone (e.g. Overview, Reports, Setting): has its own [route] and
///   navigates directly, [children] is empty.
/// - Group (e.g. Vehicle, Driver): [route] is null, [children] holds the
///   navigable sub-items, and the header just expands/collapses them.
class MenuSection {
  final String title;
  final IconData icon;
  final String? route;
  final List<MenuItem> children;

  const MenuSection({
    required this.title,
    required this.icon,
    this.route,
    this.children = const [],
  });

  bool get isGroup => children.isNotEmpty;
}

class MenuItems {
  /// Visual/navigational structure of the sidebar.
  static const List<MenuSection> sections = [
    MenuSection(title: 'Overview', icon: Icons.dashboard_rounded, route: '/'),
    MenuSection(
      title: 'Vehicle',
      icon: Icons.directions_bus_filled_rounded,
      children: [
        MenuItem(title: 'Live Tracking', route: '/live-tracking'),
        MenuItem(title: 'List of Vehicle', route: '/vehicles'),
        MenuItem(title: 'Air Quality', route: '/air-quality'),
      ],
    ),
    MenuSection(
      title: 'Driver',
      icon: Icons.drive_eta_rounded,
      children: [
        MenuItem(title: 'Vital Sign', route: '/vital-sign'),
        MenuItem(title: 'Safety Event', route: '/safety'),
      ],
    ),
    MenuSection(
      title: 'Reports',
      icon: Icons.assessment_rounded,
      route: '/reports',
    ),
    MenuSection(
      title: 'Setting',
      icon: Icons.settings_rounded,
      route: '/settings',
    ),
  ];

  /// Flat, index-addressable list of every navigable route in display
  /// order (standalone sections, then each group's children in place).
  /// Kept because navigation elsewhere (DashboardBloc.selectedMenuIndex,
  /// DashboardScreen's route switch) selects by flat index, not by route.
  static final List<MenuItem> items = [
    for (final s in sections)
      if (s.isGroup)
        ...s.children
      else
        MenuItem(title: s.title, icon: s.icon, route: s.route!),
  ];
}
