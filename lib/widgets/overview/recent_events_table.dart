import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';

class RecentEventsTable extends StatelessWidget {
  const RecentEventsTable({super.key, required this.events});

  final List<Map<String, dynamic>> events;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 1100
            ? 1100.0
            : constraints.maxWidth;

        return Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            color: AppTheme.slateGrey,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    'Recent Events',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Latest safety activity',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      const _HeaderRow(),
                      const SizedBox(height: 8),
                      ...events.map((event) => _EventRow(event: event)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: AppTheme.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _TableCell(flex: 20, child: Text('Time', style: style)),
          _TableCell(flex: 20, child: Text('Event Type', style: style)),
          _TableCell(flex: 18, child: Text('Driver', style: style)),
          _TableCell(flex: 18, child: Text('Vehicle', style: style)),
          _TableCell(flex: 22, child: Text('Location', style: style)),
          _TableCell(flex: 14, child: Text('Severity', style: style)),
          _TableCell(flex: 12, child: Text('Speed', style: style)),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final severity = event['severity']?.toString() ?? 'Low';
    final severityColor = _severityColor(severity);
    final time = _formatTime(event['time']);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          _TableCell(flex: 20, child: Text(time, style: _valueStyle())),
          _TableCell(
            flex: 20,
            child: Text(
              event['eventType']?.toString() ?? '-',
              style: _valueStyle(color: AppTheme.textPrimary),
            ),
          ),
          _TableCell(
            flex: 18,
            child: Text(
              event['driverName']?.toString() ?? '-',
              style: _valueStyle(color: AppTheme.textPrimary),
            ),
          ),
          _TableCell(
            flex: 18,
            child: Text(
              event['vehicleLabel']?.toString() ?? '-',
              style: _valueStyle(),
            ),
          ),
          _TableCell(
            flex: 22,
            child: Text(
              event['location']?.toString() ?? '-',
              style: _valueStyle(),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _TableCell(
            flex: 14,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: severityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(severity, style: _valueStyle(color: severityColor)),
              ],
            ),
          ),
          _TableCell(
            flex: 12,
            child: Text(
              event['speedLabel']?.toString() ?? '-',
              style: _valueStyle(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic value) {
    final time = value is DateTime
        ? value
        : DateTime.tryParse(value?.toString() ?? '')?.toLocal();

    if (time == null) {
      return '-';
    }

    return DateFormat('MMM d, yyyy HH:mm').format(time);
  }

  TextStyle _valueStyle({Color color = AppTheme.textSecondary}) {
    return TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500);
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return AppTheme.error;
      case 'medium':
        return AppTheme.warning;
      default:
        return Colors.blueGrey.shade300;
    }
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({required this.flex, required this.child});

  final int flex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(padding: const EdgeInsets.only(right: 12), child: child),
    );
  }
}
