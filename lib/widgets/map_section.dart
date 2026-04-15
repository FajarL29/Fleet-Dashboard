import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';

class MapSection extends StatefulWidget {
  final List<Vehicle> vehicles;
  final Function(Vehicle) onVehicleSelected;
  final MapController mapController;

  const MapSection({
    super.key,
    required this.vehicles,
    required this.onVehicleSelected,
    required this.mapController,
  });

  @override
  State<MapSection> createState() => _MapSectionState();
}

class _MapSectionState extends State<MapSection> {
  String? _selectedVehicleId;
  static final LatLng _headoffice = LatLng(-6.140869, 106.889175);

  @override
  void initState() {
    super.initState();
    // JALANKAN AUTO-FIT SAAT PERTAMA KALI DIBUKA
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitAllVehicles();
    });
  }

  @override
  void didUpdateWidget(MapSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jika jumlah kendaraan berubah, hitung ulang batas peta secara otomatis
    if (oldWidget.vehicles.length != widget.vehicles.length) {
      _fitAllVehicles();
    }
  }

  // --- FUNGSI UNTUK MENAMPILKAN SEMUA ARMADA DALAM SATU LAYAR ---
  void _fitAllVehicles() {
    if (widget.vehicles.isEmpty) return;

    final points = widget.vehicles.map((v) => v.position).toList();
    final bounds = LatLngBounds.fromPoints(points);

    widget.mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.only(
          left: 260,  // Lebar sidebar + sedikit jarak aman
        right: 70,
        top: 70,
        bottom: 70,










        
        ), // Memberi ruang di pinggir peta
      ),
    );
  }

  void _handleVehicleTap(Vehicle vehicle) {
    setState(() {
      _selectedVehicleId = vehicle.id;
    });
    widget.onVehicleSelected(vehicle);
    widget.mapController.move(vehicle.position, 15);
  }

  List<Marker> _buildMarkers() {
    return widget.vehicles.map((vehicle) {
      final isSelected = _selectedVehicleId == vehicle.id;

      return Marker(
        point: vehicle.position,
        width: isSelected ? 45 : 35,
        height: isSelected ? 45 : 35,
        child: GestureDetector(
          onTap: () => _handleVehicleTap(vehicle),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: vehicle.getStatusColor().withOpacity(0.9),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.yellow : Colors.white,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: Colors.yellow.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)]
                  : [const BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: const Icon(Icons.airport_shuttle, color: Colors.white, size: 18),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Cari data kendaraan terbaru berdasarkan ID terpilih
    final selectedVehicleData = _selectedVehicleId != null
        ? widget.vehicles.firstWhere((v) => v.id == _selectedVehicleId, orElse: () => widget.vehicles.first)
        : null;

    return Stack(
      children: [
        // 1. PETA UTAMA
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FlutterMap(
            mapController: widget.mapController,
            options: MapOptions(
              initialCenter: _headoffice,
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.fleet_dashboard',
              ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
        ),

        // 2. LIST ARMADA (KIRI)
        Positioned(
          left: 16, top: 16, bottom: 16,
          child: Container(
            width: 220,
            decoration: BoxDecoration(
              color: AppTheme.darkNavy.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                _buildListHeader(),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.vehicles.length,
                    itemBuilder: (context, index) {
                      final v = widget.vehicles[index];
                      return _buildVehicleTile(v, _selectedVehicleId == v.id);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. INFO WINDOW (ATAS)
        if (selectedVehicleData != null)
          Positioned(
            left: 250, top: 16,
            child: _buildInfoWindow(selectedVehicleData),
          ),

        // 4. TOMBOL RECENTER (BAWAH KANAN) - Biar gampang balik ke view semua armada
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            backgroundColor: AppTheme.darkNavy,
            onPressed: () {
              setState(() => _selectedVehicleId = null);
              _fitAllVehicles();
            },
            child: const Icon(Icons.zoom_out_map, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildListHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
      child: Row(
        children: [
          const Icon(Icons.local_shipping, size: 20),
          const SizedBox(width: 10),
          Text('Fleet (${widget.vehicles.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildVehicleTile(Vehicle vehicle, bool isSelected) {
    return InkWell(
      onTap: () => _handleVehicleTap(vehicle),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
        child: Row(
          children: [
            CircleAvatar(radius: 4, backgroundColor: vehicle.getStatusColor()),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vehicle.id, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  Text(vehicle.plateNumber, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.chevron_right, color: Colors.yellow, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoWindow(Vehicle vehicle) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minWidth: 220),
      decoration: BoxDecoration(
        color: AppTheme.darkNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.yellow.withOpacity(0.3)),
        boxShadow: [const BoxShadow(color: Colors.black45, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(vehicle.plateNumber, style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(color: Colors.white10),
          _infoRow('Driver', vehicle.driverName),
          _infoRow('Speed', '${vehicle.speed.toStringAsFixed(1)} km/h'),
          _infoRow('Status', vehicle.status.name.toUpperCase()),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: RichText(
        text: TextSpan(
          text: '$label: ',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
          children: [TextSpan(text: value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))],
        ),
      ),
    );
  }
}