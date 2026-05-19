import 'package:flutter/material.dart';
import '../constants/menu_items.dart';
import '../theme/app_theme.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final Function(int) onItemTapped;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      color: const Color.fromARGB(255, 255, 255, 255),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.car_crash_sharp,
              color: Theme.of(context).primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: MenuItems.items.length,
              itemBuilder: (context, index) {
                final item = MenuItems.items[index];
                final isSelected = index == selectedIndex;

                return InkWell(
                  onTap: () {
                    onItemSelected(index);
                    onItemTapped(index);
                  },
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      color:
                          isSelected ? const Color.fromARGB(255, 255, 255, 255) : Colors.transparent,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : AppTheme.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: IconButton(
              icon: const Icon(Icons.help_outline,
                  color: AppTheme.textSecondary),
              onPressed: () {
                // TODO: Implement help functionality
              },
            ),
          ),
        ],
      ),
    );
  }
}
