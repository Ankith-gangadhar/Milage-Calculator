import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/vehicle_provider.dart';
import '../models/vehicle.dart';
import '../models/fuel_entry.dart';
import '../widgets/neon_widgets.dart';

class AddEntryScreen extends StatefulWidget {
  final Vehicle vehicle;
  final FuelEntry? editEntry; // Non-null if editing an existing entry

  const AddEntryScreen({super.key, required this.vehicle, this.editEntry});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _odoController = TextEditingController();
  final _litresController = TextEditingController();
  final _reserveOdoController = TextEditingController();
  
  late DateTime _selectedDate;

  String? _odoError;
  String? _litresError;
  String? _reserveOdoError;

  @override
  void initState() {
    super.initState();
    if (widget.editEntry != null) {
      _odoController.text = widget.editEntry!.odometer.toStringAsFixed(1);
      _litresController.text = widget.editEntry!.litres.toStringAsFixed(2);
      _selectedDate = widget.editEntry!.date;
      if (widget.vehicle.useReserveOffset && widget.editEntry!.reserveOdometer != null) {
        _reserveOdoController.text = widget.editEntry!.reserveOdometer!.toStringAsFixed(1);
      }
    } else {
      _selectedDate = DateTime.now();
      // Pre-fill litres as hint or blank, and reserve odometer as empty
    }
  }

  @override
  void dispose() {
    _odoController.dispose();
    _litresController.dispose();
    _reserveOdoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: NeonColors.primary,
              onPrimary: Colors.white,
              surface: NeonColors.surface,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: NeonColors.background,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveEntry() {
    setState(() {
      _odoError = null;
      _litresError = null;
      _reserveOdoError = null;
    });

    final odoStr = _odoController.text.trim();
    final litresStr = _litresController.text.trim();
    final reserveOdoStr = _reserveOdoController.text.trim();

    bool hasError = false;

    // Validate Litres (Must be positive)
    final double? litres = double.tryParse(litresStr);
    if (litresStr.isEmpty) {
      _litresError = "Litres filled is required";
      hasError = true;
    } else if (litres == null || litres <= 0) {
      _litresError = "Enter a valid positive fuel amount";
      hasError = true;
    }

    // Validate Refill Odometer
    final double? odo = double.tryParse(odoStr);
    if (odoStr.isEmpty) {
      _odoError = "Refill odometer reading is required";
      hasError = true;
    } else if (odo == null || odo < 0) {
      _odoError = "Enter a valid odometer reading";
      hasError = true;
    }

    // Get sibling entries for validation
    final provider = Provider.of<VehicleProvider>(context, listen: false);
    final entries = provider.getEntriesForVehicle(widget.vehicle.id!);
    
    double lastRefillOdo = widget.vehicle.initialOdometer;
    double? nextRefillOdo;

    if (widget.editEntry != null) {
      // Find the index of the entry we are editing
      final index = entries.indexWhere((e) => e.id == widget.editEntry!.id);
      if (index != -1) {
        // Since list is sorted newest first (descending):
        // Previous chronological entry is at index + 1
        if (index < entries.length - 1) {
          lastRefillOdo = entries[index + 1].odometer;
        }
        // Next chronological entry is at index - 1
        if (index > 0) {
          nextRefillOdo = entries[index - 1].odometer;
        }
      }
    } else {
      // Adding new entry (will be the newest if date is now)
      if (entries.isNotEmpty) {
        lastRefillOdo = entries.first.odometer; // Entries is sorted DESC (newest first)
      }
    }

    // Odometer validation against last entry
    if (odo != null) {
      if (odo <= lastRefillOdo) {
        _odoError = "Must be greater than last odometer (${lastRefillOdo.toStringAsFixed(0)} KM)";
        hasError = true;
      }
      if (nextRefillOdo != null && odo >= nextRefillOdo) {
        _odoError = "Must be less than next odometer (${nextRefillOdo.toStringAsFixed(0)} KM)";
        hasError = true;
      }
    }

    // Validate Reserve Odometer (if enabled)
    double? reserveOdo;
    if (widget.vehicle.useReserveOffset) {
      reserveOdo = double.tryParse(reserveOdoStr);
      if (reserveOdoStr.isEmpty) {
        _reserveOdoError = "Reserve odometer is required";
        hasError = true;
      } else if (reserveOdo == null || reserveOdo < 0) {
        _reserveOdoError = "Enter a valid reserve odometer reading";
        hasError = true;
      } else if (odo != null && reserveOdo > odo) {
        _reserveOdoError = "Cannot exceed refill odometer (${odo.toStringAsFixed(0)} KM)";
        hasError = true;
      } else if (reserveOdo < lastRefillOdo) {
        _reserveOdoError = "Cannot be lower than last refill (${lastRefillOdo.toStringAsFixed(0)} KM)";
        hasError = true;
      }
    }

    if (hasError) {
      setState(() {});
      return;
    }

    if (widget.editEntry != null) {
      provider.updateFuelEntry(
        entryId: widget.editEntry!.id!,
        vehicleId: widget.vehicle.id!,
        odometer: odo!,
        litres: litres!,
        date: _selectedDate,
        reserveOdometer: reserveOdo,
      );
    } else {
      provider.addFuelEntry(
        vehicleId: widget.vehicle.id!,
        odometer: odo!,
        litres: litres!,
        date: _selectedDate,
        reserveOdometer: reserveOdo,
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editEntry != null;

    return Scaffold(
      backgroundColor: NeonColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? "Edit Refill Record" : "Add Fuel Refill",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              // Vehicle Header Info
              NeonCard(
                borderRadius: 16.0,
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Icon(getVehicleIcon(widget.vehicle.type), color: NeonColors.secondary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.vehicle.name,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (widget.vehicle.useReserveOffset)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: NeonColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "Reserve Offset Active",
                          style: TextStyle(color: NeonColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Conditionally render Reserve Odometer field first if in Reserve Offset Mode
              if (widget.vehicle.useReserveOffset) ...[
                NeonTextField(
                  controller: _reserveOdoController,
                  label: "Reserve Odometer Reading (KM)",
                  hint: "Odometer when reserve was reached",
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: LucideIcons.fuel,
                  errorText: _reserveOdoError,
                ),
                const SizedBox(height: 24),
              ],

              // Refill Odometer Input
              NeonTextField(
                controller: _odoController,
                label: "Current Refill Odometer (KM)",
                hint: "Odometer reading at gas station",
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: LucideIcons.gauge,
                errorText: _odoError,
              ),
              const SizedBox(height: 24),

              // Litres Filled Input
              NeonTextField(
                controller: _litresController,
                label: "Litres Filled",
                hint: "e.g., 3.0, 15.5",
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: LucideIcons.droplets,
                errorText: _litresError,
              ),
              const SizedBox(height: 24),

              // Date Picker Field
              const Text(
                "Refill Date",
                style: TextStyle(
                  color: NeonColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: NeonColors.cardBg,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: NeonColors.border, width: 1.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.calendar, color: NeonColors.secondary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('dd MMMM yyyy').format(_selectedDate),
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                      const Icon(LucideIcons.chevronDown, color: NeonColors.textSecondary, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Save Button
              NeonButton(
                text: isEditing ? "Update Entry" : "Save Refill Record",
                icon: LucideIcons.check,
                onPressed: _saveEntry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
