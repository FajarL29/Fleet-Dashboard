import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/air_quality_reading.dart';
import '../../models/vehicle.dart';
import '../../models/vital_sign_reading.dart';
import '../../services/air_quality_service.dart';
import '../../services/vital_sign_service.dart';
import '../report/report_styles.dart';

typedef LatestVitalSignLoader =
    Future<VitalSignReading?> Function(String vehicleId);
typedef LatestAirQualityLoader =
    Future<AirQualityReading?> Function(String vehicleId);

class OverviewMonitoringSummary extends StatefulWidget {
  OverviewMonitoringSummary({
    super.key,
    required this.vehicle,
    LatestVitalSignLoader? loadVitalSign,
    LatestAirQualityLoader? loadAirQuality,
    this.refreshInterval = const Duration(seconds: 8),
  }) : loadVitalSign =
           loadVitalSign ?? const VitalSignService().getLatestByVehicle,
       loadAirQuality =
           loadAirQuality ?? const AirQualityService().getLatestByVehicle;

  final Vehicle? vehicle;
  final LatestVitalSignLoader loadVitalSign;
  final LatestAirQualityLoader loadAirQuality;
  final Duration refreshInterval;

  @override
  State<OverviewMonitoringSummary> createState() =>
      _OverviewMonitoringSummaryState();
}

class _OverviewMonitoringSummaryState extends State<OverviewMonitoringSummary> {
  Timer? _timer;
  VitalSignReading? _vitalSign;
  AirQualityReading? _airQuality;
  bool _vitalLoading = false;
  bool _airLoading = false;
  bool _vitalInFlight = false;
  bool _airInFlight = false;
  String? _vitalError;
  String? _airError;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    _startPolling();
    _refreshForVehicleChange();
  }

  @override
  void didUpdateWidget(covariant OverviewMonitoringSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehicle?.id != widget.vehicle?.id) {
      _refreshForVehicleChange();
    }
    if (oldWidget.refreshInterval != widget.refreshInterval) {
      _startPolling();
    }
  }

  @override
  void dispose() {
    _requestGeneration++;
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.refreshInterval, (_) {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) {
        _loadVitalSign();
        _loadAirQuality();
      }
    });
  }

  void _refreshForVehicleChange() {
    _requestGeneration++;
    _vitalInFlight = false;
    _airInFlight = false;
    _vitalSign = null;
    _airQuality = null;
    _vitalError = null;
    _airError = null;

    if (widget.vehicle == null) {
      _vitalLoading = false;
      _airLoading = false;
      if (mounted) setState(() {});
      return;
    }

    _vitalLoading = true;
    _airLoading = true;
    if (mounted) setState(() {});
    _loadVitalSign();
    _loadAirQuality();
  }

  Future<void> _loadVitalSign() async {
    final vehicleId = widget.vehicle?.id;
    if (vehicleId == null || _vitalInFlight) return;
    final generation = _requestGeneration;
    _vitalInFlight = true;
    try {
      final reading = await widget.loadVitalSign(vehicleId);
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _vitalSign = reading;
        _vitalError = null;
        _vitalLoading = false;
      });
    } catch (_) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _vitalError = _vitalSign == null
            ? 'Unable to load Vital Sign data.'
            : 'Refresh failed. Showing the previous reading.';
        _vitalLoading = false;
      });
    } finally {
      if (generation == _requestGeneration) _vitalInFlight = false;
    }
  }

  Future<void> _loadAirQuality() async {
    final vehicleId = widget.vehicle?.id;
    if (vehicleId == null || _airInFlight) return;
    final generation = _requestGeneration;
    _airInFlight = true;
    try {
      final reading = await widget.loadAirQuality(vehicleId);
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _airQuality = reading;
        _airError = null;
        _airLoading = false;
      });
    } catch (_) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _airError = _airQuality == null
            ? 'Unable to load Cabin Environment data.'
            : 'Refresh failed. Showing the previous reading.';
        _airLoading = false;
      });
    } finally {
      if (generation == _requestGeneration) _airInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _MonitoringCard(
            title: 'Vital Sign',
            icon: Icons.monitor_heart_outlined,
            loading: _vitalLoading,
            error: _vitalError,
            empty: _vitalSign == null,
            emptyMessage: _emptyMessage('Vital Sign'),
            onRetry: _loadVitalSign,
            timestamp: _vitalSign?.time,
            metrics: [
              ('Heart Rate', _value(_vitalSign?.heartRate, 'bpm')),
              ('SpO2', _value(_vitalSign?.spo2, '%')),
              ('Body Temp.', _value(_vitalSign?.bodyTemperature, '°C')),
            ],
          ),
          _MonitoringCard(
            title: 'Cabin Environment',
            icon: Icons.air_rounded,
            loading: _airLoading,
            error: _airError,
            empty: _airQuality == null,
            emptyMessage: _emptyMessage('Cabin Environment'),
            onRetry: _loadAirQuality,
            timestamp: _airQuality?.timestamp,
            metrics: [
              ('AQI', _value(_airQuality?.aqi)),
              ('PM2.5', _value(_airQuality?.pm25, 'µg/m³')),
              ('CO2', _value(_airQuality?.co2, 'ppm')),
            ],
          ),
        ];

        if (constraints.maxWidth >= 480) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
            ],
          );
        }
        return Column(
          children: [cards[0], const SizedBox(height: 16), cards[1]],
        );
      },
    );
  }

  String _emptyMessage(String domain) => widget.vehicle == null
      ? 'Select a vehicle to view $domain data.'
      : 'No $domain reading is available for this vehicle.';
}

class _MonitoringCard extends StatelessWidget {
  const _MonitoringCard({
    required this.title,
    required this.icon,
    required this.loading,
    required this.error,
    required this.empty,
    required this.emptyMessage,
    required this.onRetry,
    required this.timestamp,
    required this.metrics,
  });

  final String title;
  final IconData icon;
  final bool loading;
  final String? error;
  final bool empty;
  final String emptyMessage;
  final VoidCallback onRetry;
  final DateTime? timestamp;
  final List<(String, String)> metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportStyles.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: ReportStyles.blue, size: 18),
              const SizedBox(width: 7),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '(Latest)',
                      style: TextStyle(color: ReportStyles.blue, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          if (loading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (empty)
            _Message(message: error ?? emptyMessage, onRetry: onRetry)
          else ...[
            ...metrics.map(
              (metric) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        metric.$1,
                        style: const TextStyle(
                          color: ReportStyles.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Text(
                      metric.$2,
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
            const Spacer(),
            Text(
              error ??
                  (timestamp == null
                      ? 'Latest: time unavailable'
                      : 'Latest: ${_wibTime(timestamp!)}'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: error == null
                    ? ReportStyles.textMuted
                    : ReportStyles.orange,
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: ReportStyles.textMuted, fontSize: 12),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

String _value(double? value, [String? unit]) {
  if (value == null) return '—';
  final number = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return unit == null ? number : '$number $unit';
}

String _wibTime(DateTime value) {
  // Monitoring timestamps are emitted as WIB wall-clock values with a `Z`
  // suffix by the current backend. Preserve those clock components here to
  // avoid applying UTC+7 a second time in presentation.
  return '${DateFormat('HH:mm').format(value.toUtc())} WIB';
}
