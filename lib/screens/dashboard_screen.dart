import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../providers/vehicle_provider.dart';
import '../widgets/neon_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VehicleProvider>(context);

    final avgMileage = provider.getGlobalAverageMileage();
    final highestMileage = provider.getGlobalHighestMileage();
    final lowestMileage = provider.getGlobalLowestMileage();
    final totalDistance = provider.getGlobalTotalDistance();
    final totalFuel = provider.getGlobalTotalFuel();
    final totalEntries = provider.getGlobalTotalEntries();

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
        'value': '${totalFuel.toStringAsFixed(1)} L',
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
                      "Combined stats across all vehicles",
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
            const SizedBox(height: 24),

            // Stats Cards Grid
            Expanded(
              child: provider.vehicles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.chart_pie, size: 64, color: NeonColors.textSecondary.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          const Text(
                            "Add vehicles and fuel entries\nto view analytics.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: NeonColors.textSecondary, fontSize: 16),
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
