import 'package:flutter/material.dart';

import '../constants/menu_items.dart';
import 'auth/role_scope.dart';
import '../widgets/report/report_styles.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onItemTapped,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final ValueChanged<int> onItemTapped;

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> with SingleTickerProviderStateMixin {
  // Explicit, click-driven expand state (no hover -- that read as flaky
  // and unpredictable). Starts expanded to match the default full layout.
  bool _expanded = true;

  // Whether the full labeled layout is showing. Deliberately NOT the same
  // as "expanded": it only flips true once the width animation has
  // finished growing, and flips false immediately when collapsing starts.
  // Text/labels demand their full intrinsic width the instant they render,
  // so if this flipped in lockstep with _expanded (as a plain derived
  // bool) the labels would render before the container finished growing
  // and overflow the Row for the first few animation frames. Collapsing is
  // the safe direction (icon-only content never overflows any width from
  // 84 up to 212), so that side switches immediately.
  bool _showLabels = true;

  late final AnimationController _controller =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 180),
        value: 1,
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _showLabels = true);
        }
      });

  late final Animation<double> _width = Tween<double>(
    begin: 84,
    end: 212,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _controller.forward();
    } else {
      if (_showLabels) setState(() => _showLabels = false);
      _controller.reverse();
    }
  }

  /// The sidebar entries this person may open.
  ///
  /// Hiding a page here is presentation, not enforcement: the API does not yet
  /// check roles, so anything hidden is still reachable by calling it
  /// directly. It keeps the sidebar honest about what the user can act on,
  /// nothing more.
  List<MenuSection> _visibleSections(BuildContext context) {
    final role = RoleScope.of(context);
    return [
      for (final section in MenuItems.sections)
        if (section.route != '/settings' || role.canOpenSettings) section,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Small screens: always icon-only regardless of the expand toggle --
    // there isn't room for the full layout.
    final isNarrowScreen = screenWidth < 960;
    final isCompact = isNarrowScreen || !_showLabels;

    void select(String route) {
      final index = MenuItems.items.indexWhere((it) => it.route == route);
      if (index == -1) return;
      widget.onItemSelected(index);
      widget.onItemTapped(index);
    }

    return AnimatedBuilder(
      animation: _controller,
      // sidebarWidth must be read from _width.value INSIDE this builder,
      // not captured from the outer build() -- AnimatedBuilder re-invokes
      // this closure on every animation tick without a full setState, so a
      // value computed outside it would freeze at whatever it was when
      // _SidebarState.build() last ran and never reflect the animation's
      // progress (this was the "width stays the same as expanded" bug).
      builder: (context, child) {
        final sidebarWidth = isNarrowScreen ? 84.0 : _width.value;
        return Container(
          width: sidebarWidth,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF071426), Color(0xFF06101D)],
            ),
            border: Border(right: BorderSide(color: ReportStyles.border)),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isCompact ? 10 : 16,
                16,
                isCompact ? 10 : 16,
                14,
              ),
              child: Column(
                crossAxisAlignment: isCompact
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  if (isCompact)
                    Center(child: _SidebarToggleButton(onTap: _toggleExpanded))
                  else
                    Row(
                      children: [
                        const Expanded(child: _SidebarBrand()),
                        _SidebarToggleButton(onTap: _toggleExpanded),
                      ],
                    ),
                  SizedBox(height: isCompact ? 22 : 28),
                  if (!isCompact) ...[
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 10),
                      child: Text(
                        'MENU',
                        style: TextStyle(
                          color: ReportStyles.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        for (final section in _visibleSections(context)) ...[
                          if (section.isGroup)
                            _SidebarGroup(
                              section: section,
                              isCompact: isCompact,
                              selectedRoute:
                                  MenuItems.items[widget.selectedIndex].route,
                              onSelect: select,
                            )
                          else
                            _SidebarItem(
                              title: section.title,
                              icon: section.icon,
                              isCompact: isCompact,
                              isSelected:
                                  MenuItems.items[widget.selectedIndex].route ==
                                  section.route,
                              onTap: () => select(section.route!),
                            ),
                          const SizedBox(height: 6),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Purely decorative -- only rendered in the expanded layout (the compact
/// header shows just [_SidebarToggleButton] instead, see build() above).
class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: ReportStyles.blue.withValues(alpha: 0.28),
            ),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F2442), Color(0xFF091427)],
            ),
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: ReportStyles.blue,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        // Flexible: this Row shares space with the toggle button next to
        // it, so the text needs to be able to shrink/ellipsize rather than
        // demanding its full intrinsic width unconditionally.
        const Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'FleetSafe',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Telematics',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: ReportStyles.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Explicit collapse/expand control. Styled after a "toggle sidebar" glyph
/// (a panel outline split into two, arrow indicating direction) rather than
/// a generic hamburger, per the reference icon.
class _SidebarToggleButton extends StatelessWidget {
  const _SidebarToggleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: ReportStyles.border),
          ),
          child: const Icon(
            Icons.view_sidebar_outlined,
            color: ReportStyles.textMuted,
            size: 18,
          ),
        ),
      ),
    );
  }
}

/// Standalone top-level item (Overview, Reports, Setting): icon + label,
/// highlighted pill when selected.
class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.isCompact,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected ? Colors.white : ReportStyles.textSecondary;
    final iconColor = isSelected ? Colors.white : ReportStyles.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF123A6B), Color(0xFF0E2950)],
                  )
                : null,
            border: Border.all(
              color: isSelected
                  ? ReportStyles.blue.withValues(alpha: 0.55)
                  : Colors.transparent,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x220F62FE),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 0 : 12),
            child: Row(
              mainAxisAlignment: isCompact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor, size: 21),
                if (!isCompact) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Collapsible group (Vehicle, Driver): header toggles expand/collapse of
/// its navigable children. In compact (icon-rail) mode there's no room to
/// show child labels, so tapping the header jumps straight to the first
/// child instead of expanding.
class _SidebarGroup extends StatefulWidget {
  const _SidebarGroup({
    required this.section,
    required this.isCompact,
    required this.selectedRoute,
    required this.onSelect,
  });

  final MenuSection section;
  final bool isCompact;
  final String selectedRoute;
  final ValueChanged<String> onSelect;

  @override
  State<_SidebarGroup> createState() => _SidebarGroupState();
}

class _SidebarGroupState extends State<_SidebarGroup> {
  bool _expanded = true;

  bool get _hasSelectedChild =>
      widget.section.children.any((c) => c.route == widget.selectedRoute);

  @override
  Widget build(BuildContext context) {
    final headerColor = _hasSelectedChild
        ? Colors.white
        : ReportStyles.textSecondary;
    final iconColor = _hasSelectedChild ? Colors.white : ReportStyles.textMuted;

    if (widget.isCompact) {
      return _SidebarItem(
        title: widget.section.title,
        icon: widget.section.icon,
        isCompact: true,
        isSelected: _hasSelectedChild,
        onTap: () => widget.onSelect(widget.section.children.first.route),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Ink(
              height: 46,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(widget.section.icon, color: iconColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.section.title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: headerColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: ReportStyles.textMuted,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 2, bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final child in widget.section.children)
                  _SidebarChildItem(
                    title: child.title,
                    isSelected: child.route == widget.selectedRoute,
                    onTap: () => widget.onSelect(child.route),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A sub-item under a group header: text only, indented, no icon.
class _SidebarChildItem extends StatelessWidget {
  const _SidebarChildItem({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? Colors.white : ReportStyles.textMuted,
              fontSize: 13.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
