import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/drowsiness_report.dart';
import '../report/report_styles.dart';

class SafetyReviewActionRequest {
  const SafetyReviewActionRequest({
    required this.eventId,
    required this.reviewStatus,
    this.reviewNote,
    this.followUpNote,
  });

  final int eventId;
  final String reviewStatus;
  final String? reviewNote;
  final String? followUpNote;
}

String _eventTypeLabel(DrowsinessEvent event) {
  return _readableLabel(event.behaviorType ?? event.status);
}

String _severityLabel(DrowsinessEvent event) {
  final value = event.riskLevel.trim();
  return value.isEmpty ? 'Unknown' : _readableLabel(value);
}

String _locationLabel(DrowsinessEvent event) {
  final coordinate = _coordinateLabel(event);
  final location = event.location?.trim();
  if (location != null && location.isNotEmpty) {
    return '$location\n$coordinate';
  }
  return coordinate == 'Unknown' ? 'Unknown' : coordinate;
}

String _coordinateLabel(DrowsinessEvent event) {
  if (event.latitude == null || event.longitude == null) {
    return 'Unknown';
  }
  return '${event.latitude!.toStringAsFixed(5)}, ${event.longitude!.toStringAsFixed(5)}';
}

String _dateTimeLabel(DateTime value) {
  return DateFormat('MMM d, yyyy hh:mm:ss a').format(value);
}

String _readableLabel(String value) {
  final source = value.trim();
  if (source.isEmpty) {
    return '-';
  }

  return source
      .split(RegExp(r'[_\s]+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

class SafetyEventDetailPanel extends StatelessWidget {
  const SafetyEventDetailPanel({
    super.key,
    required this.event,
    this.isUpdatingReview = false,
    this.onReviewAction,
  });

  final DrowsinessEvent? event;
  final bool isUpdatingReview;
  final Future<void> Function(SafetyReviewActionRequest request)?
  onReviewAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.65)),
      ),
      child: event == null
          ? const _EmptyDetail()
          : Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Event Detail',
                          style: TextStyle(
                            color: ReportStyles.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _SeverityPill(label: _severityLabel(event!)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(right: 4),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _EvidenceCard(event: event!),
                                  const SizedBox(height: 14),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _InfoCard(
                                          icon: Icons.speed_rounded,
                                          title: 'Speed at Event',
                                          value: event!.formattedSpeed ?? '-',
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _InfoCard(
                                          icon: Icons.pin_drop_outlined,
                                          title: 'Location',
                                          value: _locationLabel(event!),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      _MetaTile(
                                        icon: Icons.badge_outlined,
                                        label: 'Event ID',
                                        value: event!.id.toString(),
                                      ),
                                      _MetaTile(
                                        icon: Icons.emergency_outlined,
                                        label: 'Event Type',
                                        value: _eventTypeLabel(event!),
                                      ),
                                      _MetaTile(
                                        icon: Icons.task_alt_outlined,
                                        label: 'Status',
                                        value: _readableLabel(event!.status),
                                      ),
                                      _MetaTile(
                                        icon: Icons.warning_amber_rounded,
                                        label: 'Risk Level',
                                        value: _severityLabel(event!),
                                      ),
                                      _MetaTile(
                                        icon: Icons.person_outline_rounded,
                                        label: 'Driver/User',
                                        value: event!.driverLabel,
                                      ),
                                      _MetaTile(
                                        icon: Icons.local_shipping_outlined,
                                        label: 'Vehicle',
                                        value: event!.vehicleId.isEmpty
                                            ? '-'
                                            : event!.vehicleId,
                                      ),
                                      _MetaTile(
                                        icon: Icons.schedule_rounded,
                                        label: 'Event Time',
                                        value: _dateTimeLabel(event!.time),
                                      ),
                                      _MetaTile(
                                        icon: Icons.av_timer_rounded,
                                        label: 'Telemetry Timestamp',
                                        value: event!.telemetryTimestamp == null
                                            ? '-'
                                            : _dateTimeLabel(
                                                event!.telemetryTimestamp!,
                                              ),
                                      ),
                                      _MetaTile(
                                        icon: Icons.radar_rounded,
                                        label: 'Speed Source',
                                        value:
                                            event!.speedSource
                                                    ?.trim()
                                                    .isNotEmpty ==
                                                true
                                            ? event!.speedSource!
                                            : '-',
                                      ),
                                      _MetaTile(
                                        icon: Icons.my_location_rounded,
                                        label: 'Location Coordinate',
                                        value: _coordinateLabel(event!),
                                      ),
                                      _MetaTile(
                                        icon: Icons.access_time_rounded,
                                        label: 'Location Time',
                                        value: event!.telemetryTimestamp == null
                                            ? '-'
                                            : _dateTimeLabel(
                                                event!.telemetryTimestamp!,
                                              ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  _ReviewStatusSection(event: event!),
                                  const SizedBox(height: 14),
                                  _ReviewActionsCard(
                                    event: event!,
                                    isUpdatingReview: isUpdatingReview,
                                    onReviewAction: onReviewAction,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ReviewStatusSection extends StatelessWidget {
  const _ReviewStatusSection({required this.event});

  final DrowsinessEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ReportStyles.surfaceBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ReportStyles.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Review Status',
                style: TextStyle(
                  color: ReportStyles.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 10),
              _ReviewStatusBadge(status: event.reviewStatus),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetaTile(
                icon: Icons.verified_user_outlined,
                label: 'Reviewed By',
                value: event.reviewedBy ?? '-',
              ),
              _MetaTile(
                icon: Icons.event_available_rounded,
                label: 'Reviewed At',
                value: event.formattedReviewedAt ?? '-',
              ),
              _MetaTile(
                icon: Icons.note_alt_outlined,
                label: 'Review Note',
                value: event.reviewNote ?? '-',
              ),
              _MetaTile(
                icon: Icons.assignment_turned_in_outlined,
                label: 'Follow-up Note',
                value: event.followUpNote ?? '-',
              ),
              _MetaTile(
                icon: Icons.update_rounded,
                label: 'Followed Up At',
                value: event.formattedFollowedUpAt ?? '-',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewActionsCard extends StatelessWidget {
  const _ReviewActionsCard({
    required this.event,
    required this.isUpdatingReview,
    required this.onReviewAction,
  });

  final DrowsinessEvent event;
  final bool isUpdatingReview;
  final Future<void> Function(SafetyReviewActionRequest request)?
  onReviewAction;

  @override
  Widget build(BuildContext context) {
    final hasCallback = onReviewAction != null;
    final canRunActions = hasCallback && !isUpdatingReview;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12264A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ReportStyles.blue.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rate_review_outlined, color: ReportStyles.blue),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review actions',
                      style: TextStyle(
                        color: ReportStyles.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Update review status and notes without leaving this page.',
                      style: TextStyle(
                        color: ReportStyles.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (isUpdatingReview)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: canRunActions
                    ? () => _promptForAction(
                        context,
                        status: 'confirmed',
                        title: 'Confirm Event',
                        message: 'Confirm this as a valid drowsiness event.',
                        initialNote:
                            'Valid drowsiness event from camera evidence',
                        submitLabel: 'Confirm Event',
                      )
                    : null,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Confirm Event'),
              ),
              OutlinedButton.icon(
                onPressed: canRunActions
                    ? () => _promptForAction(
                        context,
                        status: 'false_alarm',
                        title: 'Mark False Alarm',
                        message: 'Record why this event is a false positive.',
                        initialNote: 'False positive after evidence check',
                        submitLabel: 'Mark False Alarm',
                      )
                    : null,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Mark False Alarm'),
              ),
              OutlinedButton.icon(
                onPressed: canRunActions
                    ? () => _promptForAction(
                        context,
                        status: 'follow_up_required',
                        title: 'Follow-up Required',
                        message: 'Add a note for supervisor follow-up.',
                        initialNote: 'Needs supervisor follow-up',
                        submitLabel: 'Save Follow-up Required',
                      )
                    : null,
                icon: const Icon(Icons.assignment_late_outlined),
                label: const Text('Follow-up Required'),
              ),
              FilledButton.icon(
                onPressed: canRunActions
                    ? () => _promptForAction(
                        context,
                        status: 'followed_up',
                        title: 'Mark Followed Up',
                        message: 'Add the outcome of the follow-up.',
                        initialNote: 'Supervisor contacted driver',
                        submitLabel: 'Mark Followed Up',
                        isFollowUp: true,
                      )
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: event.isFollowUpRequired
                      ? ReportStyles.blue
                      : ReportStyles.green,
                ),
                icon: const Icon(Icons.task_alt_rounded),
                label: const Text('Mark Followed Up'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _promptForAction(
    BuildContext context, {
    required String status,
    required String title,
    required String message,
    required String initialNote,
    required String submitLabel,
    bool isFollowUp = false,
  }) async {
    if (onReviewAction == null) {
      return;
    }

    final note = await showDialog<String?>(
      context: context,
      builder: (context) => _ReviewNoteDialog(
        title: title,
        message: message,
        label: isFollowUp ? 'Follow-up note' : 'Review note',
        initialValue: isFollowUp
            ? (event.followUpNote ?? initialNote)
            : (event.reviewNote ?? initialNote),
        submitLabel: submitLabel,
      ),
    );

    if (note == null) {
      return;
    }

    await onReviewAction!(
      SafetyReviewActionRequest(
        eventId: event.id,
        reviewStatus: status,
        reviewNote: isFollowUp ? null : note,
        followUpNote: isFollowUp ? note : null,
      ),
    );
  }
}

class _ReviewNoteDialog extends StatefulWidget {
  const _ReviewNoteDialog({
    required this.title,
    required this.message,
    required this.label,
    required this.initialValue,
    required this.submitLabel,
  });

  final String title;
  final String message;
  final String label;
  final String initialValue;
  final String submitLabel;

  @override
  State<_ReviewNoteDialog> createState() => _ReviewNoteDialogState();
}

class _ReviewNoteDialogState extends State<_ReviewNoteDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ReportStyles.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.title,
        style: const TextStyle(color: ReportStyles.textPrimary),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message,
              style: const TextStyle(
                color: ReportStyles.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              maxLines: 4,
              style: const TextStyle(color: ReportStyles.textPrimary),
              decoration: InputDecoration(
                labelText: widget.label,
                labelStyle: const TextStyle(color: ReportStyles.textSecondary),
                filled: true,
                fillColor: ReportStyles.surfaceBackground,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ReportStyles.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ReportStyles.blue),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}

class _ReviewStatusBadge extends StatelessWidget {
  const _ReviewStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    switch (status) {
      case 'confirmed':
        color = ReportStyles.green;
        break;
      case 'false_alarm':
        color = ReportStyles.orange;
        break;
      case 'follow_up_required':
        color = ReportStyles.blue;
        break;
      case 'followed_up':
        color = ReportStyles.purple;
        break;
      case 'new':
      default:
        color = ReportStyles.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        _readableLabel(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({required this.event});

  final DrowsinessEvent event;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _validatedImageUrl(event.imageUrl);
    final previewBytes = _decodePreview(event.previewBase64);
    final canPreview = imageUrl != null || previewBytes != null;

    final media = _NetworkFallbackImage(
      imageUrl: imageUrl,
      previewBytes: previewBytes,
      placeholderBuilder: _placeholder,
    );

    return Container(
      decoration: BoxDecoration(
        color: ReportStyles.surfaceBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportStyles.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: canPreview
                    ? () => _openPreviewDialog(
                        context,
                        imageUrl: imageUrl,
                        previewBytes: previewBytes,
                      )
                    : null,
                child: Stack(
                  children: [
                    media,
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              canPreview
                                  ? Icons.open_in_full_rounded
                                  : Icons.image_not_supported_outlined,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              canPreview ? 'Open' : 'Unavailable',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ReportStyles.red.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _severityLabel(event).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Camera Snapshot',
                        style: TextStyle(
                          color: ReportStyles.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _eventTypeLabel(event),
                        style: const TextStyle(
                          color: ReportStyles.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    _dateTimeLabel(event.time),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: ReportStyles.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openPreviewDialog(
    BuildContext context, {
    String? imageUrl,
    Uint8List? previewBytes,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1624),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: ReportStyles.border),
                ),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Drowsiness Evidence',
                      style: TextStyle(
                        color: ReportStyles.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 920,
                          maxHeight: 620,
                        ),
                        child: _NetworkFallbackImage(
                          imageUrl: imageUrl,
                          previewBytes: previewBytes,
                          placeholderBuilder: _placeholder,
                          height: null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  tooltip: 'Close',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _placeholder() {
    return Container(
      height: 240,
      color: const Color(0xFF131B28),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              color: ReportStyles.textMuted,
              size: 34,
            ),
            SizedBox(height: 10),
            Text(
              'Evidence image unavailable',
              style: TextStyle(
                color: ReportStyles.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Uint8List? _decodePreview(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.startsWith('data:image/') && value.contains(';base64,')) {
      final encoded = value.split(',').last;
      try {
        return base64Decode(encoded);
      } catch (_) {
        return null;
      }
    }

    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  String? _validatedImageUrl(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasScheme ||
        !(uri.isScheme('http') || uri.isScheme('https'))) {
      return null;
    }

    return uri.toString();
  }
}

class _NetworkFallbackImage extends StatefulWidget {
  const _NetworkFallbackImage({
    required this.imageUrl,
    required this.previewBytes,
    required this.placeholderBuilder,
    this.height = 240,
  });

  final String? imageUrl;
  final Uint8List? previewBytes;
  final Widget Function() placeholderBuilder;
  final double? height;

  @override
  State<_NetworkFallbackImage> createState() => _NetworkFallbackImageState();
}

class _NetworkFallbackImageState extends State<_NetworkFallbackImage> {
  bool _networkFailed = false;

  @override
  Widget build(BuildContext context) {
    if (!_networkFailed && widget.imageUrl != null) {
      return Image.network(
        widget.imageUrl!,
        height: widget.height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          if (!_networkFailed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _networkFailed = true;
                });
              }
            });
          }
          return _fallbackContent();
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }

          return Container(
            height: widget.height ?? 320,
            color: const Color(0xFF131B28),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  value: progress.expectedTotalBytes == null
                      ? null
                      : progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Loading evidence image...',
                  style: TextStyle(
                    color: ReportStyles.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return _fallbackContent();
  }

  Widget _fallbackContent() {
    if (widget.previewBytes != null) {
      return Image.memory(
        widget.previewBytes!,
        height: widget.height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => widget.placeholderBuilder(),
      );
    }

    return widget.placeholderBuilder();
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ReportStyles.surfaceBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ReportStyles.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ReportStyles.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ReportStyles.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: ReportStyles.textPrimary,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ReportStyles.surfaceBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ReportStyles.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: ReportStyles.textSecondary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: ReportStyles.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: ReportStyles.textPrimary,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeverityPill extends StatelessWidget {
  const _SeverityPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();
    Color color;
    switch (normalized) {
      case 'high':
        color = ReportStyles.red;
        break;
      case 'medium':
        color = ReportStyles.orange;
        break;
      case 'low':
        color = const Color(0xFF3BA55D);
        break;
      default:
        color = ReportStyles.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_outlined,
              color: ReportStyles.textMuted,
              size: 30,
            ),
            SizedBox(height: 12),
            Text(
              'Select an event to inspect details',
              style: TextStyle(
                color: ReportStyles.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
