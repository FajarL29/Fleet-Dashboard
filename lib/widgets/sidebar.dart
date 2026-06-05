import 'package:flutter/material.dart';

import '../constants/menu_items.dart';
import '../widgets/report/report_styles.dart';

class Sidebar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 960;
    final sidebarWidth = isCompact ? 84.0 : 212.0;

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
              _SidebarBrand(isCompact: isCompact),
              SizedBox(height: isCompact ? 22 : 28),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: MenuItems.items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final item = MenuItems.items[index];
                    final isSelected = index == selectedIndex;

                    return _SidebarItem(
                      item: item,
                      isSelected: isSelected,
                      isCompact: isCompact,
                      onTap: () {
                        onItemSelected(index);
                        onItemTapped(index);
                      },
                    );
                  },
                ),
              ),
              const Divider(color: ReportStyles.border, height: 1),
              const SizedBox(height: 10),
              _CollapseRow(isCompact: isCompact),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final shield = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ReportStyles.blue.withValues(alpha: 0.28)),
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
    );

    if (isCompact) {
      return shield;
    }

    return Row(
      children: [
        shield,
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FleetSafe',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Telematics',
              style: TextStyle(color: ReportStyles.textMuted, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.isSelected,
    required this.isCompact,
    required this.onTap,
  });

  final MenuItem item;
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
                Icon(item.icon, color: iconColor, size: 21),
                if (!isCompact) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      item.title,
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

class _CollapseRow extends StatelessWidget {
  const _CollapseRow({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isCompact
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        const Icon(
          Icons.chevron_left_rounded,
          color: ReportStyles.textMuted,
          size: 18,
        ),
        if (!isCompact) ...[
          const SizedBox(width: 6),
          const Text(
            'Collapse',
            style: TextStyle(color: ReportStyles.textMuted, fontSize: 13),
          ),
        ],
      ],
    );
  }
}
