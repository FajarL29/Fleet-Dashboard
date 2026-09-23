import 'package:flutter/material.dart';

/// The body of a page inside [AppPageSurface], laid out the same way on every
/// page: stretched to the panel's full height when there is room, scrolling
/// when there is not.
///
/// Every page used to make this choice for itself, and most put their
/// `LayoutBuilder` *inside* a `SingleChildScrollView` — where the incoming
/// height is unbounded, so there was no viewport height to decide against.
/// That is why one page could end in a strip of dead white while the next one
/// reached the bottom.
class AppPageBody extends StatelessWidget {
  const AppPageBody({
    super.key,
    required this.wideBreakpoint,
    required this.builder,
    this.padding = const EdgeInsets.fromLTRB(26, 24, 26, 26),
    this.minFillHeight = 620,
    this.canFill = false,
  });

  /// Width at or above which the page uses its side-by-side layout.
  final double wideBreakpoint;

  /// Whether this page has a section that can absorb leftover height — an
  /// `Expanded` that grows to reach the bottom.
  ///
  /// Opt-in, because a page without one would simply overflow instead of
  /// scrolling: the vehicle list and the vital-sign table grow a row at a
  /// time and can easily be taller than the panel.
  final bool canFill;

  /// Shorter than this and the panel cannot hold a full page, so it scrolls
  /// rather than squeezing every section into a letterbox.
  final double minFillHeight;

  final EdgeInsets padding;

  /// Builds the page.
  ///
  /// `fills` is true when the body is being laid out at the panel's full
  /// height — which is exactly when an `Expanded` inside it will work. When it
  /// is false the body is inside a scroll view and must size to its content.
  final Widget Function(
    BuildContext context, {
    required bool isWide,
    required bool fills,
  })
  builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= wideBreakpoint;
        final fills =
            canFill && isWide && constraints.maxHeight >= minFillHeight;
        final page = builder(context, isWide: isWide, fills: fills);

        if (fills) {
          return Padding(padding: padding, child: page);
        }
        return SingleChildScrollView(padding: padding, child: page);
      },
    );
  }
}
