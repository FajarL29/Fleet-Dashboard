import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/vehicle.dart';
import '../theme/app_theme.dart';

class MapSection extends StatefulWidget {
  final List<Vehicle> vehicles;
  final Function(Vehicle) onVehicleSelected;
  final MapController mapController;
  final bool isFullScreen;
  final VoidCallback? onFullScreenToggle;
  final bool showVehicleList;
  final String? selectedVehicleId;
  final VoidCallback? onClearSelection;
  final ValueChanged<bool>? onFollowModeChanged;

  const MapSection({
    super.key,
    required this.vehicles,
    required this.onVehicleSelected,
    required this.mapController,
    this.isFullScreen = true,
    this.onFullScreenToggle,
    this.showVehicleList = true,
    this.selectedVehicleId,
    this.onClearSelection,
    this.onFollowModeChanged,
  });

  @override
  State<MapSection> createState() => _MapSectionState();
}

class _MapSectionState extends State<MapSection> with TickerProviderStateMixin {
  static final LatLng _headoffice = LatLng(-6.140869, 106.889175);
  static const double _followCancelThreshold = 15.0;
  static const double _initialRefreshNudge = 0.00001;

  bool _isFollowingMode = true;
  bool _didRunInitialMapRefresh = false;
  Offset? _panStartPosition;

  @override
  void didUpdateWidget(MapSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.vehicles.length != widget.vehicles.length) {
      _fitAllVehicles();
    }

    if (oldWidget.selectedVehicleId != widget.selectedVehicleId &&
        widget.selectedVehicleId != null) {
      _setFollowingMode(true);
    }
  }

  void _fitAllVehicles() {
    if (widget.vehicles.isEmpty) {
      widget.mapController.move(_headoffice, 12);
      return;
    }

    widget.onClearSelection?.call();
    _setFollowingMode(false);

    final points = widget.vehicles.map((vehicle) => vehicle.position).toList();
    final bounds = LatLngBounds.fromPoints(points);
    final padding = EdgeInsets.only(
      left: widget.showVehicleList ? 260 : 40,
      right: 40,
      top: 40,
      bottom: 40,
    );

    widget.mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: padding),
    );
  }

  void _handleVehicleTap(Vehicle vehicle) {
    _setFollowingMode(true);
    widget.onVehicleSelected(vehicle);
    widget.mapController.move(vehicle.position, 20);
  }

  void _setFollowingMode(bool enabled) {
    if (_isFollowingMode == enabled) return;
    setState(() {
      _isFollowingMode = enabled;
    });
    widget.onFollowModeChanged?.call(enabled);
  }

  void _handleMapTap() {
    _setFollowingMode(false);
    widget.onClearSelection?.call();
  }

  void _onPointerDown(PointerDownEvent event) {
    _panStartPosition = event.position;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isFollowingMode || _panStartPosition == null) return;
    if ((event.position - _panStartPosition!).distance >
        _followCancelThreshold) {
      _setFollowingMode(false);
      _panStartPosition = null;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _panStartPosition = null;
  }

  void _refreshMapOnFirstReady() {
    if (_didRunInitialMapRefresh || !mounted) return;
    _didRunInitialMapRefresh = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (!widget.isFullScreen) {
        _fitAllVehicles();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final camera = widget.mapController.camera;
        final center = camera.center;
        final zoom = camera.zoom;
        final nudgedCenter = LatLng(
          center.latitude + _initialRefreshNudge,
          center.longitude + _initialRefreshNudge,
        );

        widget.mapController.move(nudgedCenter, zoom);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.mapController.move(center, zoom);
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedVehicleData = widget.selectedVehicleId != null
        ? widget.vehicles.firstWhere(
            (vehicle) => vehicle.id == widget.selectedVehicleId,
            orElse: () => widget.vehicles.first,
          )
        : null;

    return Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
                return const SizedBox.expand();
              }

              return ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Listener(
                    onPointerDown: _onPointerDown,
                    onPointerMove: _onPointerMove,
                    onPointerUp: _onPointerUp,
                    onPointerCancel: (_) => _panStartPosition = null,
                    behavior: HitTestBehavior.opaque,
                    child: FlutterMap(
                      mapController: widget.mapController,
                      options: MapOptions(
                        initialCenter: _headoffice,
                        initialZoom: 12,
                        onMapReady: _refreshMapOnFirstReady,
                        onTap: (tapPosition, point) => _handleMapTap(),
                        onPositionChanged: (position, hasGesture) {
                          if (hasGesture && _isFollowingMode) {
                            _setFollowingMode(false);
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          // TODO: Production should use a proper tile provider instead of the public OSM tile server.
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.fleet.dashboard',
                        ),
                        SmoothVehicleMarkerLayer(
                          vehicles: widget.vehicles,
                          selectedVehicleId: widget.selectedVehicleId,
                          onVehicleTap: _handleVehicleTap,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.showVehicleList)
          Positioned(
            left: 16,
            top: 16,
            bottom: 16,
            child: _buildVehicleSidebar(),
          ),
        if (selectedVehicleData != null)
          Positioned(
            left: widget.showVehicleList ? 250 : 16,
            top: 16,
            child: _buildInfoWindow(selectedVehicleData),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.onFullScreenToggle != null) ...[
                FloatingActionButton.small(
                  heroTag: 'fs_btn',
                  backgroundColor: AppTheme.darkNavy,
                  onPressed: widget.onFullScreenToggle,
                  child: Icon(
                    widget.isFullScreen
                        ? Icons.fullscreen_exit
                        : Icons.fullscreen,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              FloatingActionButton.small(
                heroTag: 'fit_all_btn',
                backgroundColor: AppTheme.darkNavy,
                onPressed: _fitAllVehicles,
                child: const Icon(Icons.zoom_out_map, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleSidebar() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppTheme.darkNavy.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          _buildListHeader(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: widget.vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = widget.vehicles[index];
                return _buildVehicleTile(
                  vehicle,
                  widget.selectedVehicleId == vehicle.id,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping, size: 20, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            'Fleet (${widget.vehicles.length})',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleTile(Vehicle vehicle, bool isSelected) {
    return ListTile(
      dense: true,
      onTap: () => _handleVehicleTap(vehicle),
      selected: isSelected,
      selectedTileColor: Colors.white.withOpacity(0.5),
      leading: CircleAvatar(
        radius: 4,
        backgroundColor: vehicle.getStatusColor(),
      ),
      title: Text(
        vehicle.id,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
      subtitle: Text(
        vehicle.plateNumber,
        style: const TextStyle(color: Colors.white54, fontSize: 11),
      ),
      trailing: isSelected
          ? const Icon(Icons.chevron_right, color: Colors.white, size: 16)
          : null,
    );
  }

  Widget _buildInfoWindow(Vehicle vehicle) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: 240,
      decoration: BoxDecoration(
        color: AppTheme.darkNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                vehicle.id,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                onPressed: widget.onClearSelection,
              ),
            ],
          ),
          const Divider(color: Colors.white10),
          _infoRow('Plate', vehicle.plateNumber),
          _infoRow('Speed', '${vehicle.speed.toStringAsFixed(1)} km/h'),
          _infoRow('Status', vehicle.status.name.toUpperCase()),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class LatLngTween extends Tween<LatLng> {
  LatLngTween({LatLng? begin, LatLng? end}) : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    final begin = this.begin!;
    final end = this.end!;
    return LatLng(
      begin.latitude + (end.latitude - begin.latitude) * t,
      begin.longitude + (end.longitude - begin.longitude) * t,
    );
  }
}

class SmoothVehicleMarkerLayer extends StatefulWidget {
  final List<Vehicle> vehicles;
  final String? selectedVehicleId;
  final Function(Vehicle) onVehicleTap;

  const SmoothVehicleMarkerLayer({
    super.key,
    required this.vehicles,
    required this.onVehicleTap,
    this.selectedVehicleId,
  });

  @override
  State<SmoothVehicleMarkerLayer> createState() =>
      _SmoothVehicleMarkerLayerState();
}

class _MarkerAnimationData {
  Vehicle vehicle;
  final AnimationController controller;
  late LatLngTween tween;
  late Animation<LatLng> animation;

  _MarkerAnimationData({
    required this.vehicle,
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 500),
  }) : controller = AnimationController(vsync: vsync, duration: duration) {
    tween = LatLngTween(begin: vehicle.position, end: vehicle.position);
    animation = tween.animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
    controller.value = 1.0;
  }

  void updateTarget(LatLng newPosition, Duration duration) {
    final currentPos = animation.value;
    tween = LatLngTween(begin: currentPos, end: newPosition);
    animation = tween.animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
    controller.duration = duration;
    controller
      ..reset()
      ..forward();
  }

  void dispose() {
    controller.dispose();
  }
}

class _SmoothVehicleMarkerLayerState extends State<SmoothVehicleMarkerLayer>
    with TickerProviderStateMixin {
  final Map<String, _MarkerAnimationData> _markerData = {};

  @override
  void didUpdateWidget(SmoothVehicleMarkerLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newIds = widget.vehicles.map((vehicle) => vehicle.id).toSet();

    _markerData.keys
        .where((id) => !newIds.contains(id))
        .toList()
        .forEach((id) {
      _markerData[id]?.dispose();
      _markerData.remove(id);
    });

    for (final vehicle in widget.vehicles) {
      final current = _markerData[vehicle.id];
      if (current == null) {
        final data = _MarkerAnimationData(
          vehicle: vehicle,
          vsync: this,
          duration: const Duration(milliseconds: 500),
        );
        _markerData[vehicle.id] = data;
        continue;
      }

      if (current.vehicle.position != vehicle.position) {
        current.updateTarget(
          vehicle.position,
          const Duration(milliseconds: 500),
        );
      }
      current.vehicle = vehicle;
    }
  }

  @override
  void dispose() {
    for (final value in _markerData.values) {
      value.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final map = MapCamera.maybeOf(context);
    if (map == null) {
      throw StateError('No FlutterMapState found.');
    }

    final worldWidth = map.getWorldWidthAtZoom();

    return Stack(
      children: _markerData.values.map((data) {
        return AnimatedBuilder(
          animation: data.animation,
          builder: (context, _) {
            final currentPosition = data.animation.value;
            final pxPoint = map.projectAtZoom(currentPosition);
            final marker = _buildMarkerWidget(data.vehicle);
            final markerSize =
                widget.selectedVehicleId == data.vehicle.id ? 80.0 : 40.0;

            final positions = <Widget>[];

            Widget buildPositioned(double xShift) {
              final shiftedLocalPoint =
                  Offset(pxPoint.dx + xShift, pxPoint.dy) - map.pixelOrigin;
              return Positioned(
                key: ValueKey('${data.vehicle.id}-$xShift'),
                width: markerSize,
                height: markerSize,
                left: shiftedLocalPoint.dx - markerSize / 2,
                top: shiftedLocalPoint.dy - markerSize / 2,
                child: marker,
              );
            }

            positions.add(buildPositioned(0));

            if (worldWidth != 0) {
              for (double shift = -worldWidth;
                  shift.abs() <= worldWidth;
                  shift -= worldWidth) {
                positions.add(buildPositioned(shift));
              }
              for (double shift = worldWidth;
                  shift.abs() <= worldWidth;
                  shift += worldWidth) {
                positions.add(buildPositioned(shift));
              }
            }

            return Stack(children: positions);
          },
        );
      }).toList(),
    );
  }

  Widget _buildMarkerWidget(Vehicle vehicle) {
    final isSelected = widget.selectedVehicleId == vehicle.id;
    return GestureDetector(
      onTap: () => widget.onVehicleTap(vehicle),
      child: _VehicleMarkerWidget(
        color: vehicle.getStatusColor(),
        isSelected: isSelected,
        heading: vehicle.heading,
      ),
    );
  }
}

class _VehicleMarkerWidget extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final double heading;

  const _VehicleMarkerWidget({
    required this.color,
    required this.isSelected,
    required this.heading,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: heading / 360,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.yellow : Colors.white,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : const [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
        ),
        child: const Icon(Icons.navigation, color: Colors.white, size: 18),
      ),
    );
  }
}
