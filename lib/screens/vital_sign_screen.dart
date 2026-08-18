import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/dashboard/dashboard_bloc.dart';
import '../bloc/dashboard/dashboard_state.dart';
import '../models/vehicle.dart';
import '../models/vital_sign_reading.dart';
import '../services/vital_sign_service.dart';
import '../widgets/monitoring/monitoring_components.dart';

class VitalSignScreen extends StatelessWidget {
  const VitalSignScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      buildWhen: (previous, current) =>
          previous.selectedVehicle?.id != current.selectedVehicle?.id,
      builder: (context, state) {
        final vehicle = state.selectedVehicle;
        if (vehicle == null) {
          return const _NoVitalSignVehicle();
        }
        return _VitalSignContent(
          key: ValueKey('vital-${vehicle.id}'),
          vehicle: vehicle,
        );
      },
    );
  }
}

class _VitalSignContent extends StatefulWidget {
  const _VitalSignContent({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  State<_VitalSignContent> createState() => _VitalSignContentState();
}

class _VitalSignContentState extends State<_VitalSignContent> {
  static const _refreshInterval = Duration(seconds: 8);
  final VitalSignService _service = const VitalSignService();
  Timer? _timer;
  VitalSignReading? _reading;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _requestInFlight = false;
  String? _error;
  String? _refreshError;

  @override
  void initState() {
    super.initState();
    _loadLatest();
    _timer = Timer.periodic(_refreshInterval, (_) {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) {
        _loadLatest(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadLatest({bool refresh = false}) async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    if (mounted) {
      setState(() {
        if (refresh) {
          _isRefreshing = true;
          _refreshError = null;
        } else {
          _isLoading = true;
          _error = null;
        }
      });
    }

    try {
      final reading = await _service.getLatestByVehicle(widget.vehicle.id);
      if (!mounted) return;
      setState(() {
        _reading = reading;
        _isLoading = false;
        _isRefreshing = false;
        _error = null;
        _refreshError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_reading == null) {
          _error = 'Unable to load the latest Vital Sign reading.';
        } else {
          _refreshError = 'Latest Vital Sign refresh failed. Showing the previous reading.';
        }
        _isLoading = false;
        _isRefreshing = false;
      });
    } finally {
      _requestInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MonitoringPageLayout(
      title: 'Vital Sign Monitoring',
      subtitle: 'Latest driver measurement for the selected Fleet vehicle',
      vehicleLabel: _vehicleLabel(widget.vehicle),
      icon: Icons.monitor_heart_outlined,
      onRefresh: () => _loadLatest(refresh: true),
      isRefreshing: _isRefreshing,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const MonitoringLoadingCard();
    if (_error != null) {
      return MonitoringMessageCard(
        icon: Icons.cloud_off_outlined,
        title: 'Vital Sign data unavailable',
        message: _error!,
        onRetry: _loadLatest,
      );
    }
    final reading = _reading;
    if (reading == null) {
      return MonitoringMessageCard(
        icon: Icons.monitor_heart_outlined,
        title: 'No Vital Sign reading',
        message: 'No reading is available for ${_vehicleLabel(widget.vehicle)}.',
        onRetry: _loadLatest,
      );
    }

    return Column(
      children: [
        if (_refreshError != null) ...[
          MonitoringRefreshError(message: _refreshError!),
          const SizedBox(height: 14),
        ],
        MonitoringMetricGrid(
          metrics: [
            MonitoringMetric(label: 'Heart Rate', value: _value(reading.heartRate, 'bpm'), icon: Icons.favorite_outline),
            MonitoringMetric(label: 'SpO2', value: _value(reading.spo2, '%'), icon: Icons.water_drop_outlined),
            MonitoringMetric(label: 'Body Temperature', value: _value(reading.bodyTemperature, '°C'), icon: Icons.thermostat_outlined),
            MonitoringMetric(label: 'Blood Pressure', value: _bloodPressure(reading), icon: Icons.speed_outlined),
            MonitoringMetric(label: 'Respiratory Rate', value: _value(reading.respiratoryRate, 'breaths/min'), icon: Icons.air_rounded),
          ],
        ),
        const SizedBox(height: 14),
        MonitoringInfoCard(
          rows: [
            ('Measured at', _date(reading.time)),
            ('Device ID', reading.deviceId ?? 'Not available'),
            ('Vehicle ID', reading.vehicleId ?? widget.vehicle.id),
          ],
        ),
      ],
    );
  }
}

class _NoVitalSignVehicle extends StatelessWidget {
  const _NoVitalSignVehicle();

  @override
  Widget build(BuildContext context) {
    return MonitoringPageLayout(
      title: 'Vital Sign Monitoring',
      subtitle: 'Latest driver measurement for the selected Fleet vehicle',
      vehicleLabel: 'No vehicle selected',
      icon: Icons.monitor_heart_outlined,
      onRefresh: () {},
      isRefreshing: false,
      child: const MonitoringMessageCard(
        icon: Icons.local_shipping_outlined,
        title: 'Select a vehicle first',
        message: 'Choose a vehicle from the Overview map, then return to Vital Sign Monitoring.',
      ),
    );
  }
}

String _vehicleLabel(Vehicle vehicle) {
  final plate = vehicle.plateNumber.trim();
  return plate.isEmpty ? vehicle.id : '$plate · ${vehicle.id}';
}

String _value(double? value, String unit) {
  if (value == null) return 'Not available';
  final number = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$number $unit';
}

String _bloodPressure(VitalSignReading reading) {
  if (reading.systolicBp == null && reading.diastolicBp == null) {
    return 'Not available';
  }
  final systolic = reading.systolicBp?.toStringAsFixed(0) ?? '—';
  final diastolic = reading.diastolicBp?.toStringAsFixed(0) ?? '—';
  return '$systolic/$diastolic mmHg';
}

String _date(DateTime? value) {
  if (value == null) return 'Not available';
  return DateFormat('dd MMM yyyy, HH:mm:ss').format(value.toLocal());
}
