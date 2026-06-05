import 'package:flutter/material.dart';

import '../report/report_styles.dart';

class ShimmerSkeleton extends StatefulWidget {
  const ShimmerSkeleton({super.key, required this.child, this.overlay = false});

  final Widget child;
  final bool overlay;

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final width = bounds.width == 0 ? 1.0 : bounds.width;
            final stop = _controller.value;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white.withValues(alpha: widget.overlay ? 0.05 : 0.0),
                Colors.white.withValues(alpha: widget.overlay ? 0.16 : 0.12),
                Colors.white.withValues(alpha: widget.overlay ? 0.05 : 0.0),
              ],
              stops: [
                (stop - 0.22).clamp(0.0, 1.0),
                stop.clamp(0.0, 1.0),
                (stop + 0.22).clamp(0.0, 1.0),
              ],
              transform: _SlidingGradientTransform(offset: width * stop),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.offset});

  final double offset;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(offset - bounds.width, 0, 0);
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
    this.isCircle = false,
  });

  final double width;
  final double height;
  final double radius;
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(radius),
        color: ReportStyles.surfaceBackgroundSoft.withValues(alpha: 0.95),
      ),
    );
  }
}

class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, required this.width, this.height = 10});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(width: width, height: height, radius: 999);
  }
}

class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(width: size, height: size, isCircle: true);
  }
}

class SkeletonListRow extends StatelessWidget {
  const SkeletonListRow({
    super.key,
    this.leadingSize = 34,
    this.trailingWidth = 44,
    this.showSubtitle = true,
  });

  final double leadingSize;
  final double trailingWidth;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            SkeletonCircle(size: leadingSize),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLine(width: 110, height: 12),
                  if (showSubtitle) ...[
                    const SizedBox(height: 6),
                    const SkeletonLine(width: 80, height: 10),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            SkeletonLine(width: trailingWidth, height: 12),
          ],
        ),
        const SizedBox(height: 8),
        const SkeletonLine(width: double.infinity, height: 8),
      ],
    );
  }
}
