import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../models/drowsiness_report.dart';
import '../../theme/app_theme.dart';
import 'safety_severity_pill.dart';

/// Event footage: plays the clip when the backend provides one, otherwise
/// falls back to the still frame it has always sent.
class SafetyEventMedia extends StatefulWidget {
  const SafetyEventMedia({super.key, required this.event});

  final DrowsinessEvent event;

  @override
  State<SafetyEventMedia> createState() => _SafetyEventMediaState();
}

class _SafetyEventMediaState extends State<SafetyEventMedia> {
  VideoPlayerController? _controller;
  bool _videoFailed = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant SafetyEventMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event.videoUrl != widget.event.videoUrl) {
      _disposeVideo();
      _videoFailed = false;
      _initVideo();
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  void _disposeVideo() {
    _controller?.dispose();
    _controller = null;
  }

  Future<void> _initVideo() async {
    final url = widget.event.videoUrl?.trim();
    if (url == null || url.isEmpty) return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      await controller.setLooping(true);
      setState(() => _controller = controller);
    } catch (_) {
      controller.dispose();
      if (mounted) setState(() => _videoFailed = true);
    }
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 11,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildSurface(),
            Positioned(
              left: 10,
              top: 10,
              child: SafetySeverityPill(riskLevel: widget.event.riskLevel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurface() {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      return GestureDetector(
        onTap: _togglePlayback,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
            if (!controller.value.isPlaying)
              const Center(child: _PlayBadge(icon: Icons.play_arrow_rounded)),
          ],
        ),
      );
    }

    // Waiting on the clip: show the still frame rather than a blank box.
    if (widget.event.hasVideo && !_videoFailed) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _StillFrame(event: widget.event),
          const Center(
            child: SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ],
      );
    }

    return _StillFrame(event: widget.event);
  }
}

class _StillFrame extends StatelessWidget {
  const _StillFrame({required this.event});

  final DrowsinessEvent event;

  @override
  Widget build(BuildContext context) {
    final url = event.imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return const _MediaPlaceholder(message: 'No footage for this event');
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const _MediaPlaceholder(message: 'Footage could not be loaded'),
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const ColoredBox(color: AppColors.tileBackground),
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.tileBackground,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_outlined,
              size: 28,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 28, color: Colors.white),
    );
  }
}
