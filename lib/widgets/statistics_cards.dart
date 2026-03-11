import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/aqi_data.dart';
import '../theme/app_theme.dart';

class StatisticsCards extends StatelessWidget {
  final AQIData aqiData;
  final int onlineDrivers;
  final int highRiskAlerts;
  final List<String> alertLog;

  const StatisticsCards({
    super.key,
    required this.aqiData,
    required this.onlineDrivers,
    required this.highRiskAlerts,
    required this.alertLog,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Fleet AQI Index
        Expanded(
          flex: 2,
          child: Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.slateGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fleet AQI Index',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: aqiData.index.toDouble(),
                                  color: aqiData.getQualityColor(),
                                  radius: 12,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  value: 100 - aqiData.index.toDouble(),
                                  color: AppTheme.darkNavy,
                                  radius: 10,
                                  showTitle: false,
                                ),
                              ],
                              sectionsSpace: 0,
                              centerSpaceRadius: 40,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              aqiData.index.toString(),
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              aqiData.getQualityText(),
                              style: TextStyle(
                                color: aqiData.getQualityColor(),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // AQI Details
        Expanded(
          flex: 2,
          child: Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.slateGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AQI Details',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildAQIDetail('PM2.5', '${aqiData.pm25} μg/m³'),
                const SizedBox(height: 12),
                _buildAQIDetail('CO2', '${aqiData.co2} ppm'),
                const SizedBox(height: 12),
                _buildAQIDetail('NO2', '${aqiData.no2} ppb'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Drivers Online & High Risk Alerts
        Expanded(
          flex: 2,
          child: Column(
            children: [
              // Drivers Online
              Container(
                height: 92,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.slateGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Drivers Online',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2  ),
                        Text(
                          onlineDrivers.toString(),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // High Risk Alerts
              Container(
                height: 92,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.slateGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'High Risk Alerts',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          highRiskAlerts.toString(),
                          style: const TextStyle(
                            color: AppTheme.error,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 80,
                      height: 40,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: 4,
                          minY: 0,
                          maxY: 5,
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 1),
                                FlSpot(1, 2),
                                FlSpot(2, 4),
                                FlSpot(3, 3),
                                FlSpot(4, 5),
                              ],
                              isCurved: true,
                              color: AppTheme.error,
                              barWidth: 2,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Alert Log
        Expanded(
          flex: 2,
          child: Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.slateGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alert Log',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: alertLog.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                alertLog[index],
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAQIDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
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
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: aqiData.getProgressValue(label),
            backgroundColor: AppTheme.darkNavy,
            valueColor: AlwaysStoppedAnimation<Color>(
              aqiData.getQualityColor(),
            ),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}