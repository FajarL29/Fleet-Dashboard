import 'package:flutter/material.dart';
import '../models/driver_health.dart';
import '../theme/app_theme.dart';

class DriverMonitoring extends StatelessWidget {
  final List<DriverHealth> drivers;
  final Map<int, Map<String, dynamic>> driverAlerts;

  const DriverMonitoring({
    super.key,
    required this.drivers,
    required this.driverAlerts,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Driver Health Cards
        Container(
          height: 120,
          margin: const EdgeInsets.only(bottom: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final driver = drivers[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: AppTheme.slateGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Driver Image
                    Container(
                      width: 80,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        image: DecorationImage(
                          image: NetworkImage(driver.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Driver Name and Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  driver.name,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: driver.getStatusColor().withOpacity(
                                      0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    driver.getStatusText(),
                                    style: TextStyle(
                                      color: driver.getStatusColor(),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Health Metrics
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.darkNavy,
                                  ),
                                  child: ClipOval(
                                    child: Image.network(
                                      driver.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Icon(
                                              Icons.person,
                                              size: 12,
                                              color: AppTheme.textSecondary,
                                            );
                                          },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _healthMetric(
                                        Icons.favorite,
                                        '${driver.heartRate} BPM',
                                        driver.status != HealthStatus.normal,
                                      ),
                                      _healthMetric(
                                        Icons.thermostat,
                                        '${driver.temperature}°C',
                                        driver.status != HealthStatus.normal,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Activity
                            Text(
                              driver.activity,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Drowsiness Monitoring
        Container(
          decoration: BoxDecoration(
            color: AppTheme.slateGrey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Drowsiness Monitoring',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Camera Feeds
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    final driver = drivers[index];
                    final int driverIdInt =
                        int.tryParse(
                          driver.driverId.replaceAll(RegExp(r'[^0-9]'), ''),
                        ) ??
                        0;
                    final alertData = driverAlerts[driverIdInt];
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: _cameraFeed(
                        driver.name,
                        alertData?['image'],
                        alertData != null
                            ? HealthStatus.warning
                            : HealthStatus.normal,
                        alertData?['type'],
                      ),
                    );
                  },
                ),
              ),
              // Drowsiness Chart (commented out)
              // Expanded(...),
            ],
          ),
        ),
      ],
    );
  }

  Widget _healthMetric(IconData icon, String value, bool isAlert) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isAlert ? AppTheme.error : AppTheme.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: isAlert ? AppTheme.error : AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _cameraFeed(
    String driverName,
    String? imageUrl,
    HealthStatus status,
    String? statusType,
  ) {
    if (imageUrl != null) {
      debugPrint("📸 Gambar terdeteksi untuk $driverName: $imageUrl");
    } else {
      debugPrint("📸 Tidak ada gambar untuk $driverName");
    }
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: AppTheme.darkNavy,
        borderRadius: BorderRadius.circular(8),
        image: imageUrl != null && imageUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
                onError: (error, stackTrace) {
                  debugPrint("❌ Failed to load image for $driverName: $error");
                  debugPrint("❌ Image URL: $imageUrl");
                },
              )
            : null,
      ),
      child: Stack(
        children: [
          if (imageUrl == null)
            const Center(
              child: Icon(
                Icons.videocam_off_outlined,
                color: Colors.white10,
                size: 32,
              ),
            ),

          // Placeholder for camera feed
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: status.getStatusColor(), width: 2),
            ),
          ),
          // Driver name overlay
          Positioned(
            left: 8,
            bottom: 8,
            child: Text(
              driverName,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Status indicator
          Positioned(
            right: 8,
            top: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: status.getStatusColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                if (statusType != null && statusType.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: status.getStatusColor().withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
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
}
