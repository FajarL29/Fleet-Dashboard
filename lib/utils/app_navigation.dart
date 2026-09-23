import 'package:flutter/material.dart';

/// Opens a shell route from anywhere inside a page.
///
/// Every in-app link must go through this rather than calling `pushNamed`
/// directly. A plain push leaves the page you came from mounted underneath —
/// so its timers and polling keep running — and the shell only learns about
/// routes it opened itself, which is how a "View All" link could land on
/// Safety while the sidebar still highlighted Overview.
void openAppRoute(BuildContext context, String route) {
  Navigator.of(
    context,
  ).pushNamedAndRemoveUntil(route, (entry) => entry.isFirst);
}
