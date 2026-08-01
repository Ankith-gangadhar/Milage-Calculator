import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../database/db_helper.dart';
import '../models/vehicle.dart';
import '../models/fuel_entry.dart';

class VehicleProvider with ChangeNotifier {
  List<Vehicle> _vehicles = [];
  final Map<int, List<FuelEntry>> _fuelEntries = {};
  bool _isDarkMode = true; // Default to dark theme

  List<Vehicle> get vehicles => _vehicles;
  bool get isDarkMode => _isDarkMode;

  // Initialize and load all data from database
  Future<void> loadData() async {
    _vehicles = await DBHelper.instance.getVehicles();
    _fuelEntries.clear();
    for (var vehicle in _vehicles) {
      if (vehicle.id != null) {
        final entries = await DBHelper.instance.getFuelEntries(vehicle.id!);
        _fuelEntries[vehicle.id!] = entries;
      }
    }
    notifyListeners();
  }

  List<FuelEntry> getEntriesForVehicle(int vehicleId) {
    return _fuelEntries[vehicleId] ?? [];
  }

  // Toggle App Theme
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // Set Theme explicitly (e.g. from loaded settings if needed)
  void setDarkMode(bool val) {
    _isDarkMode = val;
    notifyListeners();
  }

  // --- VEHICLE OPERATIONS ---

  Future<void> addVehicle({
    required String name,
    required String type,
    required double initialOdometer,
    required bool useReserveOffset,
  }) async {
    final vehicle = Vehicle(
      name: name,
      type: type,
      initialOdometer: initialOdometer,
      useReserveOffset: useReserveOffset,
    );
    await DBHelper.instance.insertVehicle(vehicle);
    await loadData();
  }

  Future<void> renameVehicle(int id, String newName) async {
    final index = _vehicles.indexWhere((v) => v.id == id);
    if (index != -1) {
      final updated = _vehicles[index].copyWith(name: newName);
      await DBHelper.instance.updateVehicle(updated);
      await loadData();
    }
  }

  Future<void> deleteVehicle(int id) async {
    await DBHelper.instance.deleteVehicle(id);
    await loadData();
  }

  // --- FUEL ENTRY OPERATIONS ---

  Future<void> addFuelEntry({
    required int vehicleId,
    required double odometer,
    required double litres,
    required DateTime date,
    double? reserveOdometer,
  }) async {
    final vehicle = _vehicles.firstWhere((v) => v.id == vehicleId);
    
    // Create new entry
    final newEntry = FuelEntry(
      vehicleId: vehicleId,
      odometer: odometer,
      litres: litres,
      date: date,
      reserveOdometer: reserveOdometer,
    );

    // Save temporarily in db
    await DBHelper.instance.insertFuelEntry(newEntry);

    // Load entries, recalculate all to ensure mathematical consistency
    await _recalculateAndUpdateVehicleEntries(vehicleId, vehicle);
  }

  Future<void> updateFuelEntry({
    required int entryId,
    required int vehicleId,
    required double odometer,
    required double litres,
    required DateTime date,
    double? reserveOdometer,
  }) async {
    final vehicle = _vehicles.firstWhere((v) => v.id == vehicleId);
    final existingEntry = (_fuelEntries[vehicleId] ?? []).firstWhere((e) => e.id == entryId);
    
    final updatedEntry = existingEntry.copyWith(
      odometer: odometer,
      litres: litres,
      date: date,
      reserveOdometer: reserveOdometer,
    );

    await DBHelper.instance.updateFuelEntry(updatedEntry);
    await _recalculateAndUpdateVehicleEntries(vehicleId, vehicle);
  }

  Future<void> deleteFuelEntry(int entryId, int vehicleId) async {
    final vehicle = _vehicles.firstWhere((v) => v.id == vehicleId);
    await DBHelper.instance.deleteFuelEntry(entryId);
    await _recalculateAndUpdateVehicleEntries(vehicleId, vehicle);
  }

  // --- RECALCULATION ALGORITHM ---

  Future<void> _recalculateAndUpdateVehicleEntries(int vehicleId, Vehicle vehicle) async {
    // 1. Fetch raw entries from DB
    List<FuelEntry> rawEntries = await DBHelper.instance.getFuelEntries(vehicleId);

    // 2. Sort chronologically (oldest to newest) for recalculation
    rawEntries.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return a.odometer.compareTo(b.odometer);
    });

    // 3. Recalculate each entry
    for (int i = 0; i < rawEntries.length; i++) {
      final current = rawEntries[i];
      final double prevRefillOdo = i == 0 ? vehicle.initialOdometer : rawEntries[i - 1].odometer;

      if (vehicle.useReserveOffset) {
        // Reserve Offset mode calculations
        final double reserveOdo = current.reserveOdometer ?? current.odometer;
        final double offset = current.odometer - reserveOdo;
        final double displayedDist = reserveOdo - prevRefillOdo;
        final double prevOffset = i == 0 ? 0.0 : (rawEntries[i - 1].reserveOffset ?? 0.0);
        final double actualDist = displayedDist - prevOffset;

        double? mileage;
        if (i > 0) {
          final double prevLitres = rawEntries[i - 1].litres;
          if (prevLitres > 0) {
            mileage = actualDist / prevLitres;
          }
        }

        rawEntries[i] = current.copyWith(
          reserveOdometer: reserveOdo,
          reserveOffset: offset,
          distance: actualDist,
          mileage: mileage,
        );
      } else {
        // Standard mode calculations
        final double dist = current.odometer - prevRefillOdo;
        final double mileage = current.litres > 0 ? (dist / current.litres) : 0.0;

        rawEntries[i] = current.copyWith(
          reserveOdometer: null,
          reserveOffset: null,
          distance: dist,
          mileage: mileage,
        );
      }

      // Update in SQLite
      await DBHelper.instance.updateFuelEntry(rawEntries[i]);
    }

    // 4. Reload full app data to sync memory with DB
    await loadData();
  }

  // --- STATS CALCULATIONS ---

  // Get current odometer (highest recorded reading)
  double getVehicleCurrentOdometer(Vehicle vehicle) {
    final entries = _fuelEntries[vehicle.id] ?? [];
    if (entries.isEmpty) return vehicle.initialOdometer;
    
    double maxOdo = vehicle.initialOdometer;
    for (var entry in entries) {
      if (entry.odometer > maxOdo) maxOdo = entry.odometer;
      if (entry.reserveOdometer != null && entry.reserveOdometer! > maxOdo) {
        maxOdo = entry.reserveOdometer!;
      }
    }
    return maxOdo;
  }

  // Get average mileage (total distance / total fuel consumed)
  double getVehicleAverageMileage(Vehicle vehicle) {
    final entries = _fuelEntries[vehicle.id] ?? [];
    if (entries.isEmpty) return 0.0;

    if (vehicle.useReserveOffset) {
      // For reserve offset, we can sum mileage values for i > 0,
      // or sum actual distances and divide by previous cycle fuel.
      double totalDistance = 0.0;
      double totalFuel = 0.0;
      // Sort oldest to newest
      final sorted = List<FuelEntry>.from(entries)..sort((a, b) => a.date.compareTo(b.date));
      
      for (int i = 1; i < sorted.length; i++) {
        totalDistance += sorted[i].distance ?? 0.0;
        totalFuel += sorted[i - 1].litres;
      }
      return totalFuel > 0 ? totalDistance / totalFuel : 0.0;
    } else {
      double totalDistance = 0.0;
      double totalFuel = 0.0;
      for (var entry in entries) {
        totalDistance += entry.distance ?? 0.0;
        totalFuel += entry.litres;
      }
      return totalFuel > 0 ? totalDistance / totalFuel : 0.0;
    }
  }

  // Get total distance travelled
  double getVehicleTotalDistance(Vehicle vehicle) {
    final entries = _fuelEntries[vehicle.id] ?? [];
    if (entries.isEmpty) return 0.0;

    if (vehicle.useReserveOffset) {
      double totalDistance = 0.0;
      final sorted = List<FuelEntry>.from(entries)..sort((a, b) => a.date.compareTo(b.date));
      for (int i = 1; i < sorted.length; i++) {
        totalDistance += sorted[i].distance ?? 0.0;
      }
      return totalDistance;
    } else {
      double totalDistance = 0.0;
      for (var entry in entries) {
        totalDistance += entry.distance ?? 0.0;
      }
      return totalDistance;
    }
  }

  // Get total fuel consumed
  double getVehicleTotalFuel(Vehicle vehicle) {
    final entries = _fuelEntries[vehicle.id] ?? [];
    if (entries.isEmpty) return 0.0;

    if (vehicle.useReserveOffset) {
      double totalFuel = 0.0;
      final sorted = List<FuelEntry>.from(entries)..sort((a, b) => a.date.compareTo(b.date));
      // Exclude the last refill since it is not fully consumed
      for (int i = 0; i < sorted.length - 1; i++) {
        totalFuel += sorted[i].litres;
      }
      return totalFuel;
    } else {
      double totalFuel = 0.0;
      for (var entry in entries) {
        totalFuel += entry.litres;
      }
      return totalFuel;
    }
  }

  // --- GLOBAL STATS (across all vehicles) ---

  double getGlobalAverageMileage() {
    double totalDistance = 0.0;
    double totalFuel = 0.0;
    for (var vehicle in _vehicles) {
      totalDistance += getVehicleTotalDistance(vehicle);
      totalFuel += getVehicleTotalFuel(vehicle);
    }
    return totalFuel > 0 ? totalDistance / totalFuel : 0.0;
  }

  double getGlobalHighestMileage() {
    double highest = 0.0;
    for (var entryList in _fuelEntries.values) {
      for (var entry in entryList) {
        if (entry.mileage != null && entry.mileage! > highest) {
          highest = entry.mileage!;
        }
      }
    }
    return highest;
  }

  double getGlobalLowestMileage() {
    double lowest = double.infinity;
    bool found = false;
    for (var entryList in _fuelEntries.values) {
      for (var entry in entryList) {
        if (entry.mileage != null && entry.mileage! > 0) {
          if (entry.mileage! < lowest) {
            lowest = entry.mileage!;
            found = true;
          }
        }
      }
    }
    return found ? lowest : 0.0;
  }

  double getGlobalTotalFuel() {
    double total = 0.0;
    for (var vehicle in _vehicles) {
      total += getVehicleTotalFuel(vehicle);
    }
    return total;
  }

  double getGlobalTotalDistance() {
    double total = 0.0;
    for (var vehicle in _vehicles) {
      total += getVehicleTotalDistance(vehicle);
    }
    return total;
  }

  int getGlobalTotalEntries() {
    int total = 0;
    for (var entryList in _fuelEntries.values) {
      total += entryList.length;
    }
    return total;
  }

  // --- BACKUP & RESTORE ---

  Future<void> exportData() async {
    final data = {
      'vehicles': _vehicles.map((v) => v.toMap()).toList(),
      'fuel_entries': _fuelEntries.values
          .expand((list) => list)
          .map((e) => e.toMap())
          .toList(),
    };

    final jsonString = jsonEncode(data);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/mileage_backup.json');
    await file.writeAsString(jsonString);

    // Share the file
    await Share.shareXFiles([XFile(file.path)], text: 'Mileage Calculator Backup');
  }

  Future<bool> importData(String jsonContent) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonContent);
      
      final db = await DBHelper.instance.database;
      await db.transaction((txn) async {
        // Clear tables
        await txn.delete('vehicles');
        await txn.delete('fuel_entries');

        // Insert vehicles
        if (data.containsKey('vehicles')) {
          final List<dynamic> vehiclesList = data['vehicles'];
          for (var v in vehiclesList) {
            await txn.insert('vehicles', v as Map<String, dynamic>);
          }
        }

        // Insert fuel entries
        if (data.containsKey('fuel_entries')) {
          final List<dynamic> entriesList = data['fuel_entries'];
          for (var e in entriesList) {
            await txn.insert('fuel_entries', e as Map<String, dynamic>);
          }
        }
      });

      await loadData();
      return true;
    } catch (e) {
      debugPrint('Error importing data: $e');
      return false;
    }
  }
}
