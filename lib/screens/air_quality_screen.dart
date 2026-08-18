import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/dashboard/dashboard_bloc.dart';
import '../bloc/dashboard/dashboard_state.dart';
import '../models/air_quality_reading.dart';
import '../models/vehicle.dart';
import '../services/air_quality_service.dart';
import '../widgets/monitoring/monitoring_components.dart';

class AirQualityScreen extends StatelessWidget {
  const AirQualityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      buildWhen: (previous, current) =>
          previous.selectedVehicle?.id != current.selectedVehicle?.id,
      builder: (context, state) {
        final vehicle = state.selectedVehicle;
        if (vehicle == null) return const _NoAirQualityVehicle();
        return _AirQualityContent(
          key: ValueKey('air-${vehicle.id}'),
          vehicle: vehicle,
        );
      },
    );
  }
}

class _AirQualityContent extends StatefulWidget {
  const _AirQualityContent({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  State<_AirQualityContent> createState() => _AirQualityContentState();
}

class _AirQualityContentState extends State<_AirQualityContent> {
  static const _refreshInterval = Duration(seconds: 8);
  final AirQualityService _service = const AirQualityService();
  Timer? _timer;
  AirQualityReading? _reading;
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
          _error = 'Unable to load the latest Air Quality reading.';
        } else {
          _refreshError = 'Latest Air Quality refresh failed. Showing the previous reading.';
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
      title: 'Air Quality Monitoring',
      subtitle: 'Latest cabin measurement for the selected Fleet vehicle',
      vehicleLabel: _vehicleLabel(widget.vehicle),
      icon: Icons.air_rounded,
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
        title: 'Air Quality data unavailable',
        message: _error!,
        onRetry: _loadLatest,
      );
    }
    final reading = _reading;
    if (reading == null) {
      return MonitoringMessageCard(
        icon: Icons.air_rounded,
        title: 'No Air Quality reading',
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
            MonitoringMetric(label: 'AQI', value: _value(reading.aqi), icon: Icons.analytics_outlined),
            MonitoringMetric(label: 'CO', value: _value(reading.co), icon: Icons.blur_on_outlined),
            MonitoringMetric(label: 'CO2', value: _value(reading.co2), icon: Icons.cloud_outlined),
            MonitoringMetric(label: 'PM2.5', value: _value(reading.pm25), icon: Icons.grain_rounded),
            MonitoringMetric(label: 'PM10', value: _value(reading.pm10), icon: Icons.scatter_plot_outlined),
            MonitoringMetric(label: 'Temperature', value: _value(reading.temperature, '°C'), icon: Icons.thermostat_outlined),
            MonitoringMetric(label: 'O2', value: _value(reading.o2), icon: Icons.bubble_chart_outlined),
            MonitoringMetric(label: 'Humidity', value: _value(reading.humidity, '%'), icon: Icons.water_drop_outlined),
          ],
        ),
        const SizedBox(height: 14),
        MonitoringInfoCard(
          rows: [
            ('Measured at', _date(reading.timestamp)),
            ('Device ID', reading.deviceId ?? 'Not available'),
            ('Vehicle ID', reading.vehicleId ?? widget.vehicle.id),
          ],
        ),
      ],
    );
  }
}

class _NoAirQualityVehicle extends StatelessWidget {
  const _NoAirQualityVehicle();

  @override
  Widget build(BuildContext context) {
    return MonitoringPageLayout(
      title: 'Air Quality Monitoring',
      subtitle: 'Latest cabin measurement for the selected Fleet vehicle',
      vehicleLabel: 'No vehicle selected',
      icon: Icons.air_rounded,
      onRefresh: () {},
      isRefreshing: false,
      child: const MonitoringMessageCard(
        icon: Icons.local_shipping_outlined,
        title: 'Select a vehicle first',
        message: 'Choose a vehicle from the Overview map, then return to Air Quality Monitoring.',
      ),
    );
  }
}

String _vehicleLabel(Vehicle vehicle) {
  final plate = vehicle.plateNumber.trim();
  return plate.isEmpty ? vehicle.id : '$plate · ${vehicle.id}';
}

String _value(double? value, [String? unit]) {
  if (value == null) return 'Not available';
  final number = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return unit == null ? number : '$number $unit';
}

String _date(DateTime? value) {
  if (value == null) return 'Not available';
  return DateFormat('dd MMM yyyy, HH:mm:ss').format(value.toLocal());
}
