import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../providers/vehicle_provider.dart';
import '../widgets/neon_widgets.dart';
import '../models/vehicle.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0; // 0 for 2-Wheelers, 1 for 4-Wheelers

  Map<String, dynamic> _calculateStatsForGroup(List<Vehicle> groupVehicles, VehicleProvider provider) {
    if (groupVehicles.isEmpty) {
      return {
        'avgMileage': 0.0,
        'highestMileage': 0.0,
        'lowestMileage': 0.0,
        'totalDistance': 0.0,
        'totalFuel': 0.0,
        'totalEntries': 0,
      };
    }

    double totalDistance = 0.0;
    double totalFuel = 0.0;
    int totalEntries = 0;
    double highestMileage = 0.0;
    double lowestMileage = double.infinity;
    bool foundMileage = false;

    for (var vehicle in groupVehicles) {
      totalDistance += provider.getVehicleTotalDistance(vehicle);
      totalFuel += provider.getVehicleTotalFuel(vehicle);
      
      final entries = provider.getEntriesForVehicle(vehicle.id ?? -1);
      totalEntries += entries.length;

      for (var entry in entries) {
        if (entry.mileage != null && entry.mileage! > 0) {
          foundMileage = true;
          if (entry.mileage! > highestMileage) highestMileage = entry.mileage!;
          if (entry.mileage! < lowestMileage) lowestMileage = entry.mileage!;
        }
      }
    }

    final avgMileage = totalFuel > 0 ? totalDistance / totalFuel : 0.0;

    return {
      'avgMileage': avgMileage,
      'highestMileage': highestMileage,
      'lowestMileage': foundMileage ? lowestMileage : 0.0,
      'totalDistance': totalDistance,
      'totalFuel': totalFuel,
      'totalEntries': totalEntries,
    };
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VehicleProvider>(context);

    // Filter vehicles by category (2-wheelers vs 4-wheelers)
    final twoWheelers = provider.vehicles
        .where((v) => v.type.toLowerCase() == 'bike' || v.type.toLowerCase() == 'scooter')
        .toList();
    final fourWheelers = provider.vehicles
        .where((v) => v.type.toLowerCase() == 'car' || v.type.toLowerCase() == 'truck')
        .toList();

    final activeVehicles = _selectedTab == 0 ? twoWheelers : fourWheelers;
    final groupStats = _calculateStatsForGroup(activeVehicles, provider);

    final double avgMileage = groupStats['avgMileage'];
    final double highestMileage = groupStats['highestMileage'];
    final double lowestMileage = groupStats['lowestMileage'];
    final double totalDistance = groupStats['totalDistance'];
    final double doubleFuel = groupStats['totalFuel'];
    final int totalEntries = groupStats['totalEntries'];

    final List<Map<String, dynamic>> stats = [
      {
        'title': 'Average Mileage',
        'value': avgMileage > 0 ? '${avgMileage.toStringAsFixed(1)} KM/L' : '--',
        'icon': LucideIcons.trending_up,
      },
      {
        'title': 'Highest Mileage',
        'value': highestMileage > 0 ? '${highestMileage.toStringAsFixed(1)} KM/L' : '--',
        'icon': LucideIcons.arrow_up_right,
      },
      {
        'title': 'Lowest Mileage',
        'value': lowestMileage > 0 ? '${lowestMileage.toStringAsFixed(1)} KM/L' : '--',
        'icon': LucideIcons.arrow_down_right,
      },
      {
        'title': 'Total Distance',
        'value': '${totalDistance.toStringAsFixed(0)} KM',
        'icon': LucideIcons.navigation,
      },
      {
        'title': 'Total Fuel Used',
        'value': '${doubleFuel.toStringAsFixed(1)} L',
        'icon': LucideIcons.fuel,
      },
      {
        'title': 'Fuel Refills',
        'value': '$totalEntries times',
        'icon': LucideIcons.hash,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Analytics",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      "Fleet statistics and summaries",
                      style: TextStyle(
                        color: NeonColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Icon(LucideIcons.chart_bar, color: NeonColors.secondary, size: 24),
              ],
            ),
            const SizedBox(height: 20),

            // Segmented Control Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: NeonColors.cardBg,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: NeonColors.border, width: 1.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? NeonColors.primary.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.bike,
                              color: _selectedTab == 0 ? NeonColors.secondary : NeonColors.textSecondary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "2-Wheelers",
                              style: TextStyle(
                                color: _selectedTab == 0 ? Colors.white : NeonColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? NeonColors.primary.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.car,
                              color: _selectedTab == 1 ? NeonColors.secondary : NeonColors.textSecondary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "4-Wheelers",
                              style: TextStyle(
                                color: _selectedTab == 1 ? Colors.white : NeonColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats Cards Grid
            Expanded(
              child: activeVehicles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedTab == 0 ? LucideIcons.bike : LucideIcons.car,
                            size: 64,
                            color: NeonColors.textSecondary.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedTab == 0
                                ? "No 2-Wheelers added yet.\nAdd a Bike or Scooter to view stats."
                                : "No 4-Wheelers added yet.\nAdd a Car or Truck to view stats.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: NeonColors.textSecondary, fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.35,
                      ),
                      itemCount: stats.length,
                      itemBuilder: (context, index) {
                        final stat = stats[index];
                        return NeonStatCard(
                          title: stat['title'] as String,
                          value: stat['value'] as String,
                          icon: stat['icon'] as IconData,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
