import 'package:flutter_test/flutter_test.dart';
import 'package:milage_calculator/models/vehicle.dart';
import 'package:milage_calculator/models/fuel_entry.dart';
import 'package:milage_calculator/providers/vehicle_provider.dart';

void main() {
  group('Mileage and Distance Calculation Tests', () {
    test('Bullet mileage calculation with reserve offset', () {
      final vehicle = Vehicle(
        id: 3,
        name: 'Bullet',
        type: 'Bike',
        initialOdometer: 48330.0,
        useReserveOffset: true,
      );

      final entries = [
        FuelEntry(
          id: 7,
          vehicleId: 3,
          odometer: 48368.0,
          litres: 3.34,
          date: DateTime.parse('2026-07-27T00:00:00.000'),
          reserveOdometer: 48365.0,
          rate: 102.50,
          fuelType: 'Power Petrol',
          bunkName: 'Shell Bunk Whitefield',
        ),
        FuelEntry(
          id: 15,
          vehicleId: 3,
          odometer: 48463.0,
          litres: 1.36,
          date: DateTime.parse('2026-08-18T18:45:15.548'),
          reserveOdometer: 48454.0,
          rate: 101.20,
          fuelType: 'Petrol',
          bunkName: 'HP Bunk Marathahalli',
        ),
      ];

      final result = recalculateFuelEntriesList(entries, vehicle);

      // Verify July 27 entry
      final entryJul27 = result.firstWhere((e) => e.id == 7);
      expect(entryJul27.distance, 0.0);
      expect(entryJul27.reserveOffset, 3.0); // 48368 - 48365
      expect(entryJul27.mileage, isNull);
      expect(entryJul27.rate, 102.50);
      expect(entryJul27.fuelType, 'Power Petrol');
      expect(entryJul27.bunkName, 'Shell Bunk Whitefield');

      // Verify August 18 entry
      final entryAug18 = result.firstWhere((e) => e.id == 15);
      // reserve-to-reserve distance: 48454 - 48365 = 89 km
      // Or by formula: (48454 - 48368) + 3.0 = 89.0 km
      expect(entryAug18.distance, 89.0);
      expect(entryAug18.reserveOffset, 9.0); // 48463 - 48454
      // mileage: distance / prev_litres = 89.0 / 3.34
      expect(entryAug18.mileage, closeTo(26.6467, 0.0001));
      expect(entryAug18.rate, 101.20);
      expect(entryAug18.fuelType, 'Petrol');
      expect(entryAug18.bunkName, 'HP Bunk Marathahalli');
    });

    test('GT 650 mileage calculation with mixed entries', () {
      final vehicle = Vehicle(
        id: 4,
        name: 'GT',
        type: 'Bike',
        initialOdometer: 200.0,
        useReserveOffset: true,
      );

      final entries = [
        FuelEntry(
          id: 8,
          vehicleId: 4,
          odometer: 211.0,
          litres: 3.43,
          date: DateTime.parse('2026-07-28T00:00:00.000'),
          reserveOdometer: 210.0,
          rate: 100.0,
          fuelType: 'Petrol',
          bunkName: 'Bunk A',
        ),
        FuelEntry(
          id: 10,
          vehicleId: 4,
          odometer: 275.0,
          litres: 3.16,
          date: DateTime.parse('2026-08-06T22:02:42.790'),
          reserveOdometer: null, // Refueled before reserve
          rate: 98.50,
          fuelType: 'Diesel',
          bunkName: 'Bunk B',
        ),
        FuelEntry(
          id: 11,
          vehicleId: 4,
          odometer: 361.0,
          litres: 1.8,
          date: DateTime.parse('2026-08-13T10:01:41.910'),
          reserveOdometer: 356.0,
          rate: 103.00,
          fuelType: 'Power Petrol',
          bunkName: 'Bunk C',
        ),
        FuelEntry(
          id: 14,
          vehicleId: 4,
          odometer: 397.0,
          litres: 1.8,
          date: DateTime.parse('2026-08-18T11:23:43.769'),
          reserveOdometer: 394.0,
        ),
        FuelEntry(
          id: 16,
          vehicleId: 4,
          odometer: 436.0,
          litres: 1.25,
          date: DateTime.parse('2026-08-19T13:18:22.536'),
          reserveOdometer: 436.0, // offset = 0
        ),
        FuelEntry(
          id: 18,
          vehicleId: 4,
          odometer: 461.0,
          litres: 1.56,
          date: DateTime.parse('2026-08-22T13:25:51.981'),
          reserveOdometer: 460.0,
        ),
      ];

      final result = recalculateFuelEntriesList(entries, vehicle);

      // 1. Entry 8 (Jul 28)
      final e8 = result.firstWhere((e) => e.id == 8);
      expect(e8.distance, 0.0);
      expect(e8.reserveOffset, 1.0);
      expect(e8.mileage, isNull);
      expect(e8.bunkName, 'Bunk A');

      // 2. Entry 10 (Aug 6) - Refueled before reserve
      final e10 = result.firstWhere((e) => e.id == 10);
      expect(e10.distance, 64.0); // 275 - 211
      expect(e10.reserveOffset, 0.0);
      expect(e10.mileage, isNull);
      expect(e10.rate, 98.50);
      expect(e10.fuelType, 'Diesel');
      expect(e10.bunkName, 'Bunk B');

      // 3. Entry 11 (Aug 13) - Reserve reached
      final e11 = result.firstWhere((e) => e.id == 11);
      // reserve-to-reserve distance since Entry 8: 356 - 210 = 146.0 km
      // Or by formula: (356 - 211) + 1.0 = 146.0 km
      expect(e11.distance, 146.0);
      expect(e11.reserveOffset, 5.0);
      // mileage: 146.0 / (3.43 + 3.16) = 146.0 / 6.59
      expect(e11.mileage, closeTo(22.1547, 0.0001));
      expect(e11.rate, 103.00);
      expect(e11.fuelType, 'Power Petrol');
      expect(e11.bunkName, 'Bunk C');

      // 4. Entry 14 (Aug 18) - Reserve reached
      final e14 = result.firstWhere((e) => e.id == 14);
      // reserve-to-reserve distance since Entry 11: 394 - 356 = 38.0 km
      // Or by formula: (394 - 361) + 5.0 = 38.0 km
      expect(e14.distance, 38.0);
      expect(e14.reserveOffset, 3.0);
      // mileage: 38.0 / 1.8 = 21.1111
      expect(e14.mileage, closeTo(21.1111, 0.0001));

      // 5. Entry 16 (Aug 19) - Reserve reached
      final e16 = result.firstWhere((e) => e.id == 16);
      // reserve-to-reserve distance since Entry 14: 436 - 394 = 42.0 km
      // Or by formula: (436 - 397) + 3.0 = 42.0 km
      expect(e16.distance, 42.0);
      expect(e16.reserveOffset, 0.0);
      // mileage: 42.0 / 1.8 = 23.3333
      expect(e16.mileage, closeTo(23.3333, 0.0001));

      // 6. Entry 18 (Aug 22) - Reserve reached
      final e18 = result.firstWhere((e) => e.id == 18);
      // reserve-to-reserve distance since Entry 16: 460 - 436 = 24.0 km
      // Or by formula: (460 - 436) + 0.0 = 24.0 km
      expect(e18.distance, 24.0);
      expect(e18.reserveOffset, 1.0);
      // mileage: 24.0 / 1.25 = 19.2
      expect(e18.mileage, closeTo(19.2, 0.0001));
    });
  });
}
