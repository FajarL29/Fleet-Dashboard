import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';

class MapSection extends StatefulWidget {
  final List<Vehicle> vehicles;
  final Function(Vehicle) onVehicleSelected;

  const MapSection({
    super.key,
    required this.vehicles,
    required this.onVehicleSelected,
  });

  @override
  State<MapSection> createState() => _MapSectionState();
}

class _MapSectionState extends State<MapSection> {
  final MapController _mapController = MapController();
  Vehicle? _selectedVehicle;
  static final LatLng _jakartaCenter = LatLng(-6.2088, 106.8456);

  List<Marker> _buildMarkers() {
    return widget.vehicles.map((vehicle) {
      return Marker(
        point: vehicle.position,
        width: 30,
        height: 30,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedVehicle = vehicle;
            });
            widget.onVehicleSelected(vehicle);
          },
          child: Container(
            decoration: BoxDecoration(
              color: vehicle.getStatusColor().withOpacity(0.8),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.local_shipping,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _jakartaCenter,
                zoom: 12,
                minZoom: 5,
                maxZoom: 18,
                interactiveFlags: InteractiveFlag.all,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.fleet_dashboard',
                ),
                MarkerLayer(
                  markers: _buildMarkers(),
                ),
              ],
            ),
          ),
        ),

        // Vehicle List Overlay
        Positioned(
          left: 16,
          top: 16,
          bottom: 16,
          child: Container(
            width: 200,
            decoration: BoxDecoration(
              color: AppTheme.slateGrey.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.list_alt, color: AppTheme.textPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'Vehicles (${widget.vehicles.length})',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = widget.vehicles[index];
                      final isSelected = _selectedVehicle?.id == vehicle.id;
                      
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedVehicle = vehicle;
                          });
                          widget.onVehicleSelected(vehicle);
                          _mapController.move(vehicle.position, 14);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.darkNavy : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: AppTheme.darkNavy,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: vehicle.getStatusColor(),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vehicle.id,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      vehicle.plateNumber,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Info Window for selected vehicle
        if (_selectedVehicle != null)
          Positioned(
            left: 232,
            top: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.slateGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedVehicle!.plateNumber,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _infoRow('Vehicle', _selectedVehicle!.type),
                  _infoRow('Driver', _selectedVehicle!.driverName),
                  _infoRow('Activity', _selectedVehicle!.activityTime),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
