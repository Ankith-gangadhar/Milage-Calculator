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
  String _ownerName = "My";
  double _avgFuelCost = 111.0; // Default to 111.0

  List<Vehicle> get vehicles => _vehicles;
  bool get isDarkMode => _isDarkMode;
  String get ownerName => _ownerName;
  double get avgFuelCost => _avgFuelCost;

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

    final savedName = await DBHelper.instance.getSetting('owner_name');
    if (savedName != null && savedName.trim().isNotEmpty) {
      _ownerName = savedName;
    } else {
      _ownerName = "My";
    }

    final savedCost = await DBHelper.instance.getSetting('avg_fuel_cost');
    if (savedCost != null) {
      _avgFuelCost = double.tryParse(savedCost) ?? 111.0;
    } else {
      _avgFuelCost = 111.0;
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

  // Update Owner Name
  Future<void> updateOwnerName(String name) async {
    _ownerName = name.trim().isEmpty ? "My" : name.trim();
    await DBHelper.instance.saveSetting('owner_name', _ownerName);
    notifyListeners();
  }

  // Update Average Fuel Cost
  Future<void> updateAvgFuelCost(double cost) async {
    _avgFuelCost = cost <= 0 ? 111.0 : cost;
    await DBHelper.instance.saveSetting('avg_fuel_cost', _avgFuelCost.toString());
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
    double? rate,
    String? fuelType,
    String? bunkName,
  }) async {
    final vehicle = _vehicles.firstWhere((v) => v.id == vehicleId);
    
    // Create new entry
    final newEntry = FuelEntry(
      vehicleId: vehicleId,
      odometer: odometer,
      litres: litres,
      date: date,
      reserveOdometer: reserveOdometer,
      rate: rate,
      fuelType: fuelType,
      bunkName: bunkName,
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
    double? rate,
    String? fuelType,
    String? bunkName,
  }) async {
    final vehicle = _vehicles.firstWhere((v) => v.id == vehicleId);
    final existingEntry = (_fuelEntries[vehicleId] ?? []).firstWhere((e) => e.id == entryId);
    
    final updatedEntry = existingEntry.copyWith(
      odometer: odometer,
      litres: litres,
      date: date,
      reserveOdometer: reserveOdometer,
      rate: rate,
      fuelType: fuelType,
      bunkName: bunkName,
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

    // 2. Recalculate using pure function
    final updatedEntries = recalculateFuelEntriesList(rawEntries, vehicle);

    // 3. Update in SQLite
    for (var entry in updatedEntries) {
      await DBHelper.instance.updateFuelEntry(entry);
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

    final sorted = List<FuelEntry>.from(entries)..sort((a, b) => a.date.compareTo(b.date));
    
    // Find index of the last reserve entry
    int lastReserveIdx = -1;
    for (int i = sorted.length - 1; i >= 0; i--) {
      if (sorted[i].reserveOdometer != null) {
        lastReserveIdx = i;
        break;
      }
    }

    if (lastReserveIdx == -1) return 0.0; // Need at least one completed cycle

    double totalDistance = 0.0;
    for (var entry in sorted) {
      if (entry.mileage != null) {
        totalDistance += entry.distance ?? 0.0;
      }
    }

    double totalFuel = 0.0;
    for (int i = 0; i < lastReserveIdx; i++) {
      totalFuel += sorted[i].litres;
    }

    return totalFuel > 0 ? totalDistance / totalFuel : 0.0;
  }

  // Get total distance travelled
  double getVehicleTotalDistance(Vehicle vehicle) {
    final entries = _fuelEntries[vehicle.id] ?? [];
    if (entries.isEmpty) return 0.0;

    final sorted = List<FuelEntry>.from(entries)..sort((a, b) => a.date.compareTo(b.date));
    
    int lastReserveIdx = -1;
    for (int i = sorted.length - 1; i >= 0; i--) {
      if (sorted[i].reserveOdometer != null) {
        lastReserveIdx = i;
        break;
      }
    }

    if (lastReserveIdx == -1) {
      // If no reserve reached, show the sum of intermediate distances as fallback
      double total = 0.0;
      for (var entry in sorted) {
        total += entry.distance ?? 0.0;
      }
      return total;
    }

    double totalDistance = 0.0;
    for (var entry in sorted) {
      if (entry.mileage != null) {
        totalDistance += entry.distance ?? 0.0;
      }
    }
    return totalDistance;
  }

  // Get total fuel consumed
  double getVehicleTotalFuel(Vehicle vehicle) {
    final entries = _fuelEntries[vehicle.id] ?? [];
    if (entries.isEmpty) return 0.0;

    final sorted = List<FuelEntry>.from(entries)..sort((a, b) => a.date.compareTo(b.date));
    
    int lastReserveIdx = -1;
    for (int i = sorted.length - 1; i >= 0; i--) {
      if (sorted[i].reserveOdometer != null) {
        lastReserveIdx = i;
        break;
      }
    }

    if (lastReserveIdx == -1) {
      // Fallback: sum all fuel if no cycle completed
      double total = 0.0;
      for (var entry in sorted) {
        total += entry.litres;
      }
      return total;
    }

    double totalFuel = 0.0;
    for (int i = 0; i < lastReserveIdx; i++) {
      totalFuel += sorted[i].litres;
    }
    return totalFuel;
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

List<FuelEntry> recalculateFuelEntriesList(List<FuelEntry> rawEntries, Vehicle vehicle) {
  // Sort chronologically (oldest to newest) for recalculation
  final sortedEntries = List<FuelEntry>.from(rawEntries)..sort((a, b) {
    final dateCompare = a.date.compareTo(b.date);
    if (dateCompare != 0) return dateCompare;
    return a.odometer.compareTo(b.odometer);
  });

  // Step 1: Initialize all entries with segment distance, null mileage, and 0.0 reserveOffset
  for (int i = 0; i < sortedEntries.length; i++) {
    final current = sortedEntries[i];
    final double prevRefillOdo = i == 0 ? vehicle.initialOdometer : sortedEntries[i - 1].odometer;
    final double dist = current.odometer - prevRefillOdo;

    sortedEntries[i] = current.copyWith(
      reserveOffset: 0.0,
      distance: dist,
      mileage: null,
    );
  }

  // Step 2: Recalculate fuel cycles chronologically when reserve is reached
  for (int i = 0; i < sortedEntries.length; i++) {
    final current = sortedEntries[i];
    if (current.reserveOdometer == null) {
      continue;
    }

    // Refueled AFTER reserve was reached (Reserve Offset Mode)
    // Find the index of the most recent previous entry where reserve was reached
    int startIndex = -1;
    for (int k = i - 1; k >= 0; k--) {
      if (sortedEntries[k].reserveOdometer != null) {
        startIndex = k;
        break;
      }
    }

    double startRefillOdo;
    double startOffset;
    int sumStartIdx;

    if (startIndex != -1) {
      startRefillOdo = sortedEntries[startIndex].odometer;
      startOffset = sortedEntries[startIndex].reserveOffset ?? 0.0;
      sumStartIdx = startIndex;
    } else {
      // No previous reserve entry exists
      if (i > 0) {
        startRefillOdo = sortedEntries[0].odometer;
        startOffset = 0.0;
        sumStartIdx = 0;
      } else {
        // This is the first entry and it is a reserve entry
        startRefillOdo = vehicle.initialOdometer;
        startOffset = 0.0;
        sumStartIdx = 0;
      }
    }

    final double reserveOdo = current.reserveOdometer!;
    final double offset = current.odometer - reserveOdo;
    
    // Keep the reserve offset on the current entry
    sortedEntries[i] = sortedEntries[i].copyWith(
      reserveOffset: offset,
    );

    if (i > 0) {
      final double displayedDist = reserveOdo - startRefillOdo;
      final double actualDist = displayedDist + startOffset;

      // Sum litres of all entries from sumStartIdx to i-1
      double totalLitres = 0.0;
      for (int p = sumStartIdx; p < i; p++) {
        totalLitres += sortedEntries[p].litres;
      }

      double? mileage;
      if (totalLitres > 0) {
        mileage = actualDist / totalLitres;
      }

      // Assign the mileage and actual cycle distance to sumStartIdx (where fuel was filled)
      sortedEntries[sumStartIdx] = sortedEntries[sumStartIdx].copyWith(
        distance: actualDist,
        mileage: mileage,
      );
    }
  }

  return sortedEntries;
}
