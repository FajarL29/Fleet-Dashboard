import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Account bar shown above every page. Tapping it opens the account menu
/// (profile, Setting, Logout).
class AppTopBar extends StatefulWidget {
  const AppTopBar({
    super.key,
    required this.userName,
    this.userRole = 'Admin',
    this.onOpenSetting,
    this.onLogout,
  });

  final String userName;
  final String userRole;

  /// Where the menu's "Setting" entry goes. The bar renders above the app's
  /// nested Navigator, so routing is the shell's job, not this widget's.
  final VoidCallback? onOpenSetting;
  final VoidCallback? onLogout;

  @override
  State<AppTopBar> createState() => _AppTopBarState();
}

class _AppTopBarState extends State<AppTopBar> {
  final MenuController _menuController = MenuController();

  void _close() {
    if (_menuController.isOpen) {
      _menuController.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            MenuAnchor(
              controller: _menuController,
              consumeOutsideTap: true,
              alignmentOffset: const Offset(0, 6),
              style: MenuStyle(
                backgroundColor: const WidgetStatePropertyAll(
                  AppColors.surface,
                ),
                surfaceTintColor: const WidgetStatePropertyAll(
                  Colors.transparent,
                ),
                shadowColor: WidgetStatePropertyAll(AppColors.menuShadow),
                elevation: const WidgetStatePropertyAll(9),
                padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              menuChildren: [
                _AccountMenuPanel(
                  userName: widget.userName,
                  userRole: widget.userRole,
                  // Null all the way down hides the entry rather than
                  // leaving a Setting row that quietly does nothing.
                  onSetting: widget.onOpenSetting == null
                      ? null
                      : () {
                          _close();
                          widget.onOpenSetting!.call();
                        },
                  onLogout: () {
                    _close();
                    widget.onLogout?.call();
                  },
                ),
              ],
              builder: (context, controller, child) {
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  hoverColor: AppColors.tileBackground,
                  splashColor: AppColors.blueSoft,
                  highlightColor: AppColors.tileBackground,
                  onTap: () => controller.isOpen
                      ? controller.close()
                      : controller.open(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          radius: 17,
                          backgroundColor: AppColors.blueSoft,
                          child: Icon(
                            Icons.person_rounded,
                            size: 20,
                            color: AppColors.blue,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.userName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountMenuPanel extends StatelessWidget {
  const _AccountMenuPanel({
    required this.userName,
    required this.userRole,
    this.onSetting,
    required this.onLogout,
  });

  final String userName;
  final String userRole;

  /// Null hides the Setting row entirely.
  final VoidCallback? onSetting;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.blueSoft,
                  child: Icon(
                    Icons.person_rounded,
                    size: 21,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blueSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          userRole,
                          style: const TextStyle(
                            color: AppColors.blue,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Divider(
              color: AppColors.cardBorder,
              height: 1,
              thickness: 1,
            ),
          ),
          const SizedBox(height: 6),
          if (onSetting != null)
            _AccountMenuItem(
              icon: Icons.settings_rounded,
              label: 'Setting',
              onTap: onSetting!,
            ),
          _AccountMenuItem(
            icon: Icons.logout_rounded,
            label: 'Logout',
            onTap: onLogout,
            danger: true,
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _AccountMenuItem extends StatelessWidget {
  const _AccountMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.red : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      hoverColor: danger ? AppColors.redSoft : AppColors.tileBackground,
      splashColor: danger ? AppColors.redSoft : AppColors.blueSoft,
      highlightColor: danger ? AppColors.redSoft : AppColors.tileBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
