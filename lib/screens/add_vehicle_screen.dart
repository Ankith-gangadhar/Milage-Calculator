import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../providers/vehicle_provider.dart';
import '../widgets/neon_widgets.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _nameController = TextEditingController();
  final _odoController = TextEditingController();
  
  String _selectedType = 'Car';

  String? _nameError;
  String? _odoError;

  final List<Map<String, dynamic>> _vehicleTypes = [
    {'name': 'Car', 'icon': LucideIcons.car},
    {'name': 'Bike', 'icon': LucideIcons.bike},
    {'name': 'Scooter', 'icon': LucideIcons.toy_brick}, // Custom representation
    {'name': 'Truck', 'icon': LucideIcons.truck},
    {'name': 'Bus', 'icon': LucideIcons.bus},
    {'name': 'Van', 'icon': LucideIcons.truck},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _odoController.dispose();
    super.dispose();
  }

  void _saveVehicle() {
    setState(() {
      _nameError = null;
      _odoError = null;
    });

    final name = _nameController.text.trim();
    final odoStr = _odoController.text.trim();

    bool hasError = false;

    if (name.isEmpty) {
      _nameError = "Vehicle name cannot be empty";
      hasError = true;
    }

    double? odo;
    if (odoStr.isEmpty) {
      _odoError = "Initial odometer is required";
      hasError = true;
    } else {
      odo = double.tryParse(odoStr);
      if (odo == null || odo < 0) {
        _odoError = "Enter a valid odometer reading (>= 0)";
        hasError = true;
      }
    }

    if (hasError) {
      setState(() {});
      return;
    }

    final provider = Provider.of<VehicleProvider>(context, listen: false);
    provider.addVehicle(
      name: name,
      type: _selectedType,
      initialOdometer: odo!,
      useReserveOffset: true,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Add Vehicle",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle Name Input
              NeonTextField(
                controller: _nameController,
                label: "Vehicle Name",
                hint: "e.g., Creta, Bullet",
                prefixIcon: LucideIcons.info,
                errorText: _nameError,
              ),
              const SizedBox(height: 24),

              // Vehicle Type Selector Label
              const Text(
                "Vehicle Type",
                style: TextStyle(
                  color: NeonColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),

              // Horizontal Grid for Type Choice
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _vehicleTypes.map((type) {
                  final isSelected = _selectedType == type['name'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedType = type['name'] as String;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? NeonColors.primary.withOpacity(0.15)
                              : NeonColors.cardBg,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isSelected ? NeonColors.secondary : NeonColors.border,
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: NeonColors.secondary.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  )
                                ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              type['icon'] as IconData,
                              color: isSelected ? NeonColors.secondary : NeonColors.textSecondary,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              type['name'] as String,
                              style: TextStyle(
                                color: isSelected ? Colors.white : NeonColors.textSecondary,
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Initial Odometer Input
              NeonTextField(
                controller: _odoController,
                label: "Initial Odometer Reading (KM)",
                hint: "e.g., 48000",
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: LucideIcons.gauge,
                errorText: _odoError,
              ),
              const SizedBox(height: 24),

              const SizedBox(height: 30),

              // Save Button
              NeonButton(
                text: "Save Vehicle",
                icon: LucideIcons.check,
                onPressed: _saveVehicle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
