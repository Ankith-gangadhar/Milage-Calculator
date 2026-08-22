import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/vehicle_provider.dart';
import '../models/vehicle.dart';
import '../models/fuel_entry.dart';
import '../widgets/neon_widgets.dart';
import 'add_entry_screen.dart';

class VehicleDetailScreen extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VehicleProvider>(context);
    final entries = provider.getEntriesForVehicle(vehicle.id ?? -1);

    // Re-fetch vehicle details in case it was updated
    final currentVehicle = provider.vehicles.firstWhere((v) => v.id == vehicle.id, orElse: () => vehicle);

    final currentOdometer = provider.getVehicleCurrentOdometer(currentVehicle);
    final avgMileage = provider.getVehicleAverageMileage(currentVehicle);
    final totalDistance = provider.getVehicleTotalDistance(currentVehicle);
    final totalFuel = provider.getVehicleTotalFuel(currentVehicle);

    return Scaffold(
      backgroundColor: NeonColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          currentVehicle.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              getVehicleIcon(currentVehicle.type),
              color: NeonColors.secondary,
            ),
            onPressed: null, // Just display the icon
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Gauge & Top Stats Block
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Circular Progress Gauge
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: NeonCircleGauge(
                        value: avgMileage / 60.0, // scale relative to 60 KM/L max
                        label: "KM/L AVG",
                        valueText: avgMileage > 0 ? avgMileage.toStringAsFixed(1) : "--",
                        size: 130,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Small Stats Grid next to Gauge
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _buildSmallStatTile("Odometer", "${currentOdometer.toStringAsFixed(0)} KM", LucideIcons.gauge),
                        const SizedBox(height: 8),
                        _buildSmallStatTile("Total Distance", "${totalDistance.toStringAsFixed(0)} KM", LucideIcons.navigation),
                        const SizedBox(height: 8),
                        _buildSmallStatTile("Total Fuel", "${totalFuel.toStringAsFixed(2)} L", LucideIcons.fuel),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Mileage Trend Chart Card
              const Text(
                "Mileage Trend",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildTrendChart(entries),
              const SizedBox(height: 20),

              // Large Add Fuel Button
              NeonButton(
                text: "Add Fuel Entry",
                icon: LucideIcons.circle_plus,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEntryScreen(vehicle: currentVehicle),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // History Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Refill History",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${entries.length} entries",
                    style: const TextStyle(
                      color: NeonColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // History Table/List
              entries.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(LucideIcons.history, size: 40, color: NeonColors.textSecondary.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          const Text(
                            "No refill records yet. Swipe right to edit / swipe left to delete once added.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: NeonColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: entries.length,
                      padding: const EdgeInsets.only(bottom: 40),
                      itemBuilder: (context, index) {
                        return _buildDismissibleHistoryRow(context, provider, currentVehicle, entries, index);
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Small stats tile helper
  Widget _buildSmallStatTile(String label, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: NeonColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NeonColors.border.withOpacity(0.5), width: 1.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: NeonColors.secondary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: NeonColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
                ),
                Text(
                  val,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mileage Trend Line Chart using fl_chart
  Widget _buildTrendChart(List<FuelEntry> entries) {
    // Collect entries that have a valid mileage calculated
    final validEntries = entries
        .where((e) => e.mileage != null && e.mileage! > 0)
        .toList();

    // Sort oldest to newest for the chart
    validEntries.sort((a, b) => a.date.compareTo(b.date));

    if (validEntries.length < 2) {
      return NeonCard(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(LucideIcons.trending_up, color: NeonColors.textSecondary.withOpacity(0.3), size: 36),
              const SizedBox(height: 8),
              const Text(
                "Need at least 2 entries with calculated mileage to generate trend chart.",
                textAlign: TextAlign.center,
                style: TextStyle(color: NeonColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    // Map entries to FlSpot coordinates (x is index, y is mileage)
    final spots = List<FlSpot>.generate(
      validEntries.length,
      (i) => FlSpot(i.toDouble(), validEntries[i].mileage!),
    );

    double minY = validEntries.map((e) => e.mileage!).reduce((a, b) => a < b ? a : b) - 2;
    double maxY = validEntries.map((e) => e.mileage!).reduce((a, b) => a > b ? a : b) + 2;
    if (minY < 0) minY = 0;

    return NeonCard(
      padding: const EdgeInsets.fromLTRB(10, 24, 20, 10),
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: NeonColors.border.withOpacity(0.1),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: ((maxY - minY) / 3).clamp(1.0, 50.0),
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(color: NeonColors.textSecondary, fontSize: 10),
                    );
                  },
                  reservedSize: 28,
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < validEntries.length) {
                      // Show date of every few entries to avoid clutter
                      if (validEntries.length <= 4 || index % (validEntries.length ~/ 3) == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            DateFormat('dd/MM').format(validEntries[index].date),
                            style: const TextStyle(color: NeonColors.textSecondary, fontSize: 9),
                          ),
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  },
                  reservedSize: 20,
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (validEntries.length - 1).toDouble(),
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                gradient: const LinearGradient(
                  colors: [NeonColors.primary, NeonColors.secondary],
                ),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 4,
                    color: NeonColors.secondary,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      NeonColors.primary.withOpacity(0.2),
                      NeonColors.secondary.withOpacity(0.01),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Swipeable History List Row Builder
  Widget _buildDismissibleHistoryRow(
      BuildContext context, VehicleProvider provider, Vehicle vehicle, List<FuelEntry> entries, int index) {
    final entry = entries[index];
    final formattedDate = DateFormat('dd MMM yyyy').format(entry.date);
    
    // Find the previous reserve entry (which starts this fuel cycle)
    FuelEntry? prevReserveEntry;
    for (int k = index + 1; k < entries.length; k++) {
      if (entries[k].reserveOdometer != null) {
        prevReserveEntry = entries[k];
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Dismissible(
        key: Key(entry.id.toString()),
        // Swipe Right to Edit
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Edit triggered
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEntryScreen(
                  vehicle: vehicle,
                  editEntry: entry,
                ),
              ),
            );
            return false; // Don't auto dismiss from list view
          } else if (direction == DismissDirection.endToStart) {
            // Delete confirm
            final deleteConfirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: NeonColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text("Delete Record?", style: TextStyle(color: Colors.white)),
                content: const Text(
                  "Are you sure you want to delete this refill record? All subsequent entries will be recalculated.",
                  style: TextStyle(color: NeonColors.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel", style: TextStyle(color: NeonColors.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Delete", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
            
            if (deleteConfirm == true) {
              provider.deleteFuelEntry(entry.id!, vehicle.id!);
              return true;
            }
          }
          return false;
        },
        background: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: NeonColors.primary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NeonColors.primary, width: 1),
          ),
          child: const Row(
            children: [
              Icon(LucideIcons.pencil, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text("Edit Record", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        secondaryBackground: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent, width: 1),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              SizedBox(width: 8),
              Icon(LucideIcons.trash_2, color: Colors.white, size: 20),
            ],
          ),
        ),
        child: NeonCard(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          borderRadius: 16.0,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Date & Details subtitle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(LucideIcons.gauge, color: NeonColors.textSecondary.withOpacity(0.6), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            "${entry.odometer.toStringAsFixed(0)} km",
                            style: const TextStyle(color: NeonColors.textSecondary, fontSize: 11),
                          ),
                          const SizedBox(width: 12),
                          Icon(LucideIcons.fuel, color: NeonColors.textSecondary.withOpacity(0.6), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            "${entry.litres.toStringAsFixed(2)} L",
                            style: const TextStyle(color: NeonColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Calculated Distance & Mileage
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        entry.mileage != null ? "${entry.mileage!.toStringAsFixed(1)} km/L" : "--",
                        style: const TextStyle(
                          color: NeonColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.distance != null ? "+${entry.distance!.toStringAsFixed(0)} km" : "",
                        style: const TextStyle(
                          color: NeonColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Entry's specific fuel details
              if (entry.bunkName != null || entry.rate != null || entry.fuelType != null) ...[
                const Divider(color: NeonColors.border, height: 16, thickness: 0.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.map_pin, color: NeonColors.secondary, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          entry.bunkName ?? "Unknown Station",
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                    Text(
                      "${entry.fuelType ?? 'Petrol'}${entry.rate != null ? ' @ ₹${entry.rate!.toStringAsFixed(2)}/L' : ''}",
                      style: const TextStyle(color: NeonColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ],
              // Cycle Bunk origin
              if (entry.mileage != null && prevReserveEntry != null && prevReserveEntry.bunkName != null) ...[
                const Divider(color: NeonColors.border, height: 12, thickness: 0.5),
                Row(
                  children: [
                    const Icon(LucideIcons.info, color: NeonColors.primary, size: 12),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Mileage achieved using fuel filled at: ${prevReserveEntry.bunkName}",
                        style: const TextStyle(color: NeonColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
              // Extra row for Reserve details if in Reserve Offset Mode
              if (vehicle.useReserveOffset && entry.reserveOdometer != null) ...[
                const Divider(color: NeonColors.border, height: 16, thickness: 0.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: NeonColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "Reserve",
                            style: TextStyle(color: NeonColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Reached at ${entry.reserveOdometer!.toStringAsFixed(0)} km",
                          style: const TextStyle(color: NeonColors.textSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                    Text(
                      "Offset: ${entry.reserveOffset?.toStringAsFixed(0)} km",
                      style: const TextStyle(color: NeonColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ] else if (vehicle.useReserveOffset && entry.reserveOdometer == null) ...[
                const Divider(color: NeonColors.border, height: 16, thickness: 0.5),
                Row(
                  children: [
                    const Icon(LucideIcons.circle_question_mark, color: Colors.orangeAccent, size: 12),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        "Mileage cannot be calculated yet (refueled before reserve). Keep riding until reserve light turns on.",
                        style: TextStyle(color: Colors.orangeAccent, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
