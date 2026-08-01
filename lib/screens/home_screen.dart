import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/vehicle_provider.dart';
import '../models/vehicle.dart';
import '../widgets/neon_widgets.dart';
import 'add_vehicle_screen.dart';
import 'detail_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load vehicles and fuel entries when screen initializes
    Future.microtask(() =>
      Provider.of<VehicleProvider>(context, listen: false).loadData()
    );
  }

  @override
  Widget build(BuildContext context) {

    
    // Screens representing each tab
    final List<Widget> tabs = [
      const VehiclesTab(),
      const DashboardScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: NeonColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: tabs,
        ),
      ),
      // Floating Glassmorphic Bottom Navigation Bar
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        height: 70,
        decoration: BoxDecoration(
          color: NeonColors.cardBg.withOpacity(0.9),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: NeonColors.border.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, LucideIcons.car, "Vehicles"),
              _buildNavItem(1, LucideIcons.barChart2, "Dashboard"),
              _buildNavItem(2, LucideIcons.settings, "Settings"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isSelected ? NeonColors.primary.withOpacity(0.2) : Colors.transparent,
              boxShadow: isSelected ? [
                BoxShadow(
                  color: NeonColors.primary.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ] : [],
            ),
            child: Icon(
              icon,
              color: isSelected ? NeonColors.secondary : NeonColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : NeonColors.textSecondary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// TAB 1: VEHICLES LIST
class VehiclesTab extends StatefulWidget {
  const VehiclesTab({super.key});

  @override
  State<VehiclesTab> createState() => _VehiclesTabState();
}

class _VehiclesTabState extends State<VehiclesTab> {
  String _searchQuery = "";
  String _sortBy = "name"; // 'name' (alphabetical) or 'updated' (last updated)

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VehicleProvider>(context);
    final vehicles = provider.vehicles;

    // Filter vehicles by search query
    List<Vehicle> filteredVehicles = vehicles.where((v) {
      return v.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Sort vehicles
    if (_sortBy == "name") {
      filteredVehicles.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_sortBy == "updated") {
      filteredVehicles.sort((a, b) {
        final entriesA = provider.getEntriesForVehicle(a.id ?? -1);
        final entriesB = provider.getEntriesForVehicle(b.id ?? -1);
        
        final dateA = entriesA.isEmpty ? DateTime(1970) : entriesA.first.date;
        final dateB = entriesB.isEmpty ? DateTime(1970) : entriesB.first.date;
        
        // Sort newest first
        return dateB.compareTo(dateA);
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "My Garage",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                // Glowing notification dot or design element
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: NeonColors.secondary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: NeonColors.secondary,
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar & Sort Row
            Row(
              children: [
                // Search Input
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: NeonColors.cardBg,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: NeonColors.border, width: 1.0),
                    ),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search vehicles...",
                        hintStyle: TextStyle(color: NeonColors.textSecondary.withOpacity(0.5)),
                        prefixIcon: const Icon(LucideIcons.search, color: NeonColors.textSecondary, size: 18),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Sort Dropdown Button
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: NeonColors.cardBg,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: NeonColors.border, width: 1.0),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      dropdownColor: NeonColors.surface,
                      icon: const Icon(LucideIcons.chevronDown, color: NeonColors.secondary, size: 16),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      onChanged: (String? val) {
                        if (val != null) {
                          setState(() {
                            _sortBy = val;
                          });
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: "name",
                          child: Text("A-Z"),
                        ),
                        DropdownMenuItem(
                          value: "updated",
                          child: Text("Recent"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Vehicle List
            Expanded(
              child: filteredVehicles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.car, size: 64, color: NeonColors.textSecondary.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty ? "No vehicles added yet" : "No matching vehicles found",
                            style: const TextStyle(color: NeonColors.textSecondary, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredVehicles.length,
                      padding: const EdgeInsets.only(bottom: 100),
                      itemBuilder: (context, index) {
                        final vehicle = filteredVehicles[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildVehicleCard(context, provider, vehicle),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      // FAB to Add Vehicle
      floatingActionButton: NeonFAB(
        icon: LucideIcons.plus,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
          );
        },
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, VehicleProvider provider, Vehicle vehicle) {
    final entries = provider.getEntriesForVehicle(vehicle.id ?? -1);
    final currentOdometer = provider.getVehicleCurrentOdometer(vehicle);
    final avgMileage = provider.getVehicleAverageMileage(vehicle);
    
    String lastFuelDate = "Never refilled";
    if (entries.isNotEmpty) {
      lastFuelDate = DateFormat('dd MMM yyyy').format(entries.first.date);
    }

    return NeonCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleDetailScreen(vehicle: vehicle),
          ),
        );
      },
      onLongPress: () {
        _showActionSheet(context, provider, vehicle);
      },
      child: Row(
        children: [
          // Vehicle Type Icon Container
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: NeonColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: NeonColors.primary.withOpacity(0.4), width: 1.0),
            ),
            child: Icon(
              getVehicleIcon(vehicle.type),
              color: NeonColors.secondary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // Info Block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Last fill: $lastFuelDate",
                  style: const TextStyle(
                    color: NeonColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      "Odo: ${currentOdometer.toStringAsFixed(0)} km",
                      style: const TextStyle(
                        color: NeonColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (vehicle.useReserveOffset)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: NeonColors.secondary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: NeonColors.secondary.withOpacity(0.3), width: 0.8),
                        ),
                        child: const Text(
                          "Reserve Offset",
                          style: TextStyle(
                            color: NeonColors.secondary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Mileage Display + Chevron
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                avgMileage > 0 ? "${avgMileage.toStringAsFixed(1)}" : "--",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                "km/L avg",
                style: TextStyle(
                  color: NeonColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          const Icon(
            LucideIcons.chevronRight,
            color: NeonColors.secondary,
            size: 20,
          ),
        ],
      ),
    );
  }

  void _showActionSheet(BuildContext context, VehicleProvider provider, Vehicle vehicle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: NeonColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: NeonColors.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(LucideIcons.edit2, color: NeonColors.secondary),
                title: const Text('Rename Vehicle', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(context, provider, vehicle);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.trash2, color: Colors.redAccent),
                title: const Text('Delete Vehicle', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmDialog(context, provider, vehicle);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, VehicleProvider provider, Vehicle vehicle) {
    final controller = TextEditingController(text: vehicle.name);
    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: NeonColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Rename Vehicle", style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NeonTextField(
                    controller: controller,
                    label: "New Name",
                    prefixIcon: LucideIcons.car,
                    errorText: errorText,
                    onChanged: (val) {
                      if (val.trim().isNotEmpty && errorText != null) {
                        setState(() {
                          errorText = null;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: NeonColors.textSecondary)),
                ),
                TextButton(
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isEmpty) {
                      setState(() {
                        errorText = "Name cannot be empty";
                      });
                      return;
                    }
                    provider.renameVehicle(vehicle.id!, name);
                    Navigator.pop(context);
                  },
                  child: const Text("Save", style: TextStyle(color: NeonColors.secondary, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, VehicleProvider provider, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: NeonColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Delete Vehicle?", style: TextStyle(color: Colors.white)),
          content: Text(
            "Are you sure you want to delete '${vehicle.name}'? This will permanently erase all fuel entries and history associated with this vehicle. This action cannot be undone.",
            style: const TextStyle(color: NeonColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: NeonColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                provider.deleteVehicle(vehicle.id!);
                Navigator.pop(context);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
