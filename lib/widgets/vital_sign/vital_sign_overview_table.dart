import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../common/app_card.dart';
import '../common/app_pagination.dart';
import '../common/subscript_label.dart';
import 'vital_sign_reading.dart';

/// "Driver Vital Sign Overview": one paginated page of readings.
class VitalSignOverviewTable extends StatelessWidget {
  const VitalSignOverviewTable({
    super.key,
    required this.pageReadings,
    required this.page,
    required this.pageCount,
    required this.onPageChanged,
    required this.emptyMessage,
  });

  final List<VitalSignReading> pageReadings;
  final int page;
  final int pageCount;
  final ValueChanged<int> onPageChanged;
  final String emptyMessage;

  static const List<int> _flex = [4, 4, 3, 3, 4, 3];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Driver Vital Sign Overview',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          const _HeaderRow(flex: _flex),
          if (pageReadings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  emptyMessage,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            for (final reading in pageReadings) _ReadingRow(reading: reading),
          if (pageCount > 1) ...[
            const SizedBox(height: 14),
            AppPagination(
              page: page,
              pageCount: pageCount,
              onPageChanged: onPageChanged,
              alignment: MainAxisAlignment.start,
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.flex});

  final List<int> flex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.tileBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(flex: flex[0], child: const _HeaderCell('Driver')),
          Expanded(flex: flex[1], child: const _HeaderCell('Vehicle')),
          Expanded(
            flex: flex[2],
            child: const _HeaderCell(
              'Heart Rate',
              secondLine: '(BPM)',
              centered: true,
            ),
          ),
          Expanded(
            flex: flex[3],
            child: const _HeaderCell(
              'SpO',
              subscript: '2',
              secondLine: '(%)',
              centered: true,
            ),
          ),
          Expanded(
            flex: flex[4],
            child: const _HeaderCell('Work Duration', centered: true),
          ),
          Expanded(
            flex: flex[5],
            child: const _HeaderCell('Last Telemetry', centered: true),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(
    this.label, {
    this.subscript,
    this.secondLine,
    this.centered = false,
  });

  final String label;
  final String? subscript;
  final String? secondLine;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 10.5,
      fontWeight: FontWeight.w500,
      height: 1.25,
    );
    final align = centered ? TextAlign.center : TextAlign.left;

    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (subscript == null)
          Text(label, textAlign: align, style: style)
        else
          SubscriptLabel(
            text: label,
            subscript: subscript!,
            style: style,
            textAlign: align,
          ),
        if (secondLine != null)
          Text(secondLine!, textAlign: align, style: style),
      ],
    );
  }
}

class _ReadingRow extends StatelessWidget {
  const _ReadingRow({required this.reading});

  final VitalSignReading reading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: VitalSignOverviewTable._flex[0],
            child: _Cell(reading.driverName),
          ),
          Expanded(
            flex: VitalSignOverviewTable._flex[1],
            child: _Cell(reading.vehicleLabel, emphasis: true),
          ),
          Expanded(
            flex: VitalSignOverviewTable._flex[2],
            child: _Cell(_number(reading.heartRate), centered: true),
          ),
          Expanded(
            flex: VitalSignOverviewTable._flex[3],
            child: _Cell(_number(reading.spo2), centered: true),
          ),
          Expanded(
            flex: VitalSignOverviewTable._flex[4],
            child: _Cell(_duration(reading.workDuration), centered: true),
          ),
          Expanded(
            flex: VitalSignOverviewTable._flex[5],
            child: _Cell(_time(reading.lastTelemetry), centered: true),
          ),
        ],
      ),
    );
  }

  static String _number(int? value) => value?.toString() ?? '-';

  static String _duration(Duration? value) {
    if (value == null) return '-';
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    return hours == 0 ? '${minutes}m' : '${hours}h ${minutes}m';
  }

  static String _time(DateTime? value) =>
      value == null ? '-' : DateFormat('HH:mm:ss').format(value.toLocal());
}

class _Cell extends StatelessWidget {
  const _Cell(this.value, {this.emphasis = false, this.centered = false});

  final String value;
  final bool emphasis;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: centered ? TextAlign.center : TextAlign.left,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 12.5,
        fontWeight: emphasis ? FontWeight.w700 : FontWeight.w400,
        height: 1.2,
      ),
    );
  }
}
