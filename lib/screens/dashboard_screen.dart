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
  String _selectedPeriod = "Last 1 Month";

  final List<String> _periods = [
    "All Time",
    "Last 1 Week",
    "Last 1 Month",
    "Last 3 Months",
    "Last 6 Months",
    "Last 1 Year"
  ];

  DateTime? _getCutoffDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case "Last 1 Week":
        return now.subtract(const Duration(days: 7));
      case "Last 1 Month":
        return now.subtract(const Duration(days: 30));
      case "Last 3 Months":
        return now.subtract(const Duration(days: 90));
      case "Last 6 Months":
        return now.subtract(const Duration(days: 180));
      case "Last 1 Year":
        return now.subtract(const Duration(days: 365));
      default:
        return null;
    }
  }

  Map<String, dynamic> _calculateStatsForGroup(
    List<Vehicle> groupVehicles,
    VehicleProvider provider,
    DateTime? cutoffDate,
  ) {
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
    double totalCost = 0.0;
    int totalEntries = 0;
    double highestMileage = 0.0;
    double lowestMileage = double.infinity;
    bool foundMileage = false;

    for (var vehicle in groupVehicles) {
      final entries = provider.getEntriesForVehicle(vehicle.id ?? -1);
      final filteredEntries = cutoffDate == null
          ? entries
          : entries.where((e) => e.date.isAfter(cutoffDate)).toList();

      totalEntries += filteredEntries.length;

      for (var entry in filteredEntries) {
        if (entry.reserveOdometer != null) {
          totalDistance += entry.distance ?? 0.0;
        }
        totalFuel += entry.litres;
        
        final rate = entry.rate ?? provider.avgFuelCost;
        totalCost += entry.litres * rate;

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
      'totalCost': totalCost,
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
    
    // Apply dynamic period filtering
    final cutoffDate = _getCutoffDate();
    final groupStats = _calculateStatsForGroup(activeVehicles, provider, cutoffDate);

    final double avgMileage = groupStats['avgMileage'];
    final double highestMileage = groupStats['highestMileage'];
    final double lowestMileage = groupStats['lowestMileage'];
    final double totalDistance = groupStats['totalDistance'];
    final double doubleFuel = groupStats['totalFuel'];
    final int totalEntries = groupStats['totalEntries'];
    final double totalCost = groupStats['totalCost'];

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
        'value': '${doubleFuel.toStringAsFixed(2)} L',
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
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
              const SizedBox(height: 16),

              // Period Filter Choice Chips
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _periods.length,
                  itemBuilder: (context, index) {
                    final period = _periods[index];
                    final isSelected = _selectedPeriod == period;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          period,
                          style: TextStyle(
                            color: isSelected ? Colors.white : NeonColors.textSecondary,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: NeonColors.primary.withOpacity(0.25),
                        backgroundColor: NeonColors.cardBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected ? NeonColors.secondary : NeonColors.border,
                            width: 1.0,
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedPeriod = period;
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Content conditional display
              if (activeVehicles.isEmpty)
                Container(
                  height: 300,
                  alignment: Alignment.center,
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
              else ...[
                // Stats Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
                const SizedBox(height: 28),

                // Expenses Section
                const Text(
                  "Estimated Fuel Expenses",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                NeonCard(
                  padding: const EdgeInsets.all(16.0),
                  borderRadius: 16.0,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.banknote, color: NeonColors.secondary, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                "Fuel Cost ($_selectedPeriod)",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            totalCost > 0 ? "₹${totalCost.toStringAsFixed(2)}" : "₹0.00",
                            style: const TextStyle(
                              color: NeonColors.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Fuel Consumed",
                            style: TextStyle(color: NeonColors.textSecondary, fontSize: 12),
                          ),
                          Text(
                            "${doubleFuel.toStringAsFixed(2)} Litres",
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Average Fuel Price",
                            style: TextStyle(color: NeonColors.textSecondary, fontSize: 12),
                          ),
                          Text(
                            "₹${provider.avgFuelCost.toStringAsFixed(2)} / L",
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const Divider(color: NeonColors.border, height: 24, thickness: 0.5),
                      
                      // Note Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.info, color: Colors.orangeAccent, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Estimated using average fuel price. If your actual fuel price is different, change it in Settings.",
                              style: const TextStyle(
                                color: NeonColors.textSecondary,
                                fontSize: 10,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
