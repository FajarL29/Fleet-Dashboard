import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;

  const ResponsiveLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1024) {
          // Show warning for small screens
          return Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.screen_rotation,
                    color: Colors.white,
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Screen too small',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please use a larger screen (min. 1024px width)\nor maximize your window.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Normal layout with scroll if needed
        final width = constraints.maxWidth;
        final minWidth = 1440.0;
        
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: minWidth,
              maxWidth: width < minWidth ? minWidth : width,
            ),
            child: SingleChildScrollView(
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class ResponsiveBreakpoints {
  static const double minimum = 1024;
  static const double tablet = 1280;
  static const double desktop = 1440;
  static const double widescreen = 1920;

  static bool isSmall(BuildContext context) =>
      MediaQuery.of(context).size.width < tablet;

  static bool isMedium(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet &&
      MediaQuery.of(context).size.width < desktop;

  static bool isLarge(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop &&
      MediaQuery.of(context).size.width < widescreen;

  static bool isWidescreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= widescreen;

  static double sidePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= widescreen) return 32.0;
    if (width >= desktop) return 24.0;
    if (width >= tablet) return 20.0;
    return 16.0;
  }

  static double contentSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= widescreen) return 24.0;
    if (width >= desktop) return 20.0;
    if (width >= tablet) return 16.0;
    return 12.0;
  }

  static EdgeInsets screenPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final padding = sidePadding(context);
    
    if (width >= desktop) {
      return EdgeInsets.symmetric(
        horizontal: padding,
        vertical: padding,
      );
    }
    
    return EdgeInsets.all(padding);
  }
}