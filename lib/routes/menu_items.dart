import 'package:flutter/material.dart';

class MenuItem {
  final String title;
  final IconData icon;
  final String route;

  const MenuItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}

class MenuItems {
  static const List<MenuItem> items = [
    MenuItem(
      title: 'Dashboard',
      icon: Icons.dashboard_rounded,
      route: '/',
    ),
    MenuItem(
      title: 'Vehicles',
      icon: Icons.local_shipping_rounded,
      route: '/vehicles',
    ),
    MenuItem(
      title: 'Drivers',
      icon: Icons.person_rounded,
      route: '/drivers',
    ),
    MenuItem(
      title: 'Safety',
      icon: Icons.security_rounded,
      route: '/safety',
    ),
    MenuItem(
      title: 'Reports',
      icon: Icons.assessment_rounded,
      route: '/reports',
    ),
    MenuItem(
      title: 'Settings',
      icon: Icons.settings_rounded,
      route: '/settings',
    ),
  ];
}