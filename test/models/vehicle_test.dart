import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/vehicle.dart';
import '../../lib/models/vehicle_event.dart';
import '../../lib/models/vehicle_insurance.dart';
import '../../lib/models/vehicle_member.dart';

void main() {
  group('Vehicle constructor', () {
    test(
      'uses correct default values',
      () {
        final vehicle = Vehicle(
          license: '12345678',
          manufacturer: 'Toyota',
          model: 'Corolla',
          year: 2022,
          mileage: 60000,
        );

        expect(
          vehicle.testExpiryDate,
          isNull,
        );

        expect(
          vehicle.showTestOnHome,
          isTrue,
        );

        expect(
          vehicle.vehicleLicenseExpiryDate,
          isNull,
        );

        expect(
          vehicle.showVehicleLicenseOnHome,
          isFalse,
        );

        expect(
          vehicle.insurances,
          isEmpty,
        );

        expect(
          vehicle.events,
          isEmpty,
        );

        expect(
          vehicle.lastServiceDate,
          isNull,
        );

        expect(
          vehicle.lastServiceMileage,
          isNull,
        );

        expect(
          vehicle.serviceIntervalKm,
          isNull,
        );

        expect(
          vehicle.showServiceOnHome,
          isTrue,
        );

        expect(
          vehicle.currentUserRole,
          isNull,
        );
      },
    );

    test(
      'keeps supplied related data and role',
      () {
        final insurance =
            VehicleInsurance(
          type:
              InsuranceType.mandatory,
        );

        final event =
            VehicleEvent(
          type: VehicleEventType.test,
          date: DateTime(2027, 1, 1),
          title: 'טסט',
        );

        final vehicle = Vehicle(
          license: '12345678',
          manufacturer: 'Toyota',
          model: 'Corolla',
          year: 2022,
          mileage: 60000,
          insurances: [insurance],
          events: [event],
          currentUserRole:
              VehicleMemberRole.owner,
        );

        expect(
          vehicle.insurances.length,
          1,
        );

        expect(
          vehicle.events.length,
          1,
        );

        expect(
          vehicle.currentUserRole,
          VehicleMemberRole.owner,
        );
      },
    );
  });

  group('Vehicle.fromMap', () {
    test(
      'reads complete vehicle correctly',
      () {
        final vehicle =
            Vehicle.fromMap({
          'id': 'vehicle-1',
          'license': '12345678',
          'manufacturer': 'Toyota',
          'model': 'Corolla',
          'year': 2022,
          'mileage': 60000,
          'test_expiry_date':
              '2027-10-31',
          'show_test_on_home':
              false,
          'vehicle_license_expiry_date':
              '2028-08-31',
          'show_vehicle_license_on_home':
              true,
          'last_service_date':
              '2026-08-30',
          'last_service_mileage':
              60000,
          'service_interval_km':
              15000,
          'show_service_on_home':
              false,
        });

        expect(
          vehicle.id,
          'vehicle-1',
        );

        expect(
          vehicle.license,
          '12345678',
        );

        expect(
          vehicle.manufacturer,
          'Toyota',
        );

        expect(
          vehicle.model,
          'Corolla',
        );

        expect(
          vehicle.year,
          2022,
        );

        expect(
          vehicle.mileage,
          60000,
        );

        expect(
          vehicle.testExpiryDate,
          DateTime(2027, 10, 31),
        );

        expect(
          vehicle.showTestOnHome,
          isFalse,
        );

        expect(
          vehicle.vehicleLicenseExpiryDate,
          DateTime(2028, 8, 31),
        );

        expect(
          vehicle.showVehicleLicenseOnHome,
          isTrue,
        );

        expect(
          vehicle.lastServiceDate,
          DateTime(2026, 8, 30),
        );

        expect(
          vehicle.lastServiceMileage,
          60000,
        );

        expect(
          vehicle.serviceIntervalKm,
          15000,
        );

        expect(
          vehicle.showServiceOnHome,
          isFalse,
        );
      },
    );

    test(
      'accepts DateTime values directly',
      () {
        final testDate =
            DateTime(2027, 10, 31);

        final licenseDate =
            DateTime(2028, 8, 31);

        final serviceDate =
            DateTime(2026, 8, 30);

        final vehicle =
            Vehicle.fromMap({
          'license': '12345678',
          'manufacturer': 'Toyota',
          'model': 'Corolla',
          'year': 2022,
          'mileage': 60000,
          'test_expiry_date':
              testDate,
          'vehicle_license_expiry_date':
              licenseDate,
          'last_service_date':
              serviceDate,
        });

        expect(
          vehicle.testExpiryDate,
          testDate,
        );

        expect(
          vehicle.vehicleLicenseExpiryDate,
          licenseDate,
        );

        expect(
          vehicle.lastServiceDate,
          serviceDate,
        );
      },
    );

    test(
      'uses correct visibility defaults when database values are missing',
      () {
        final vehicle =
            Vehicle.fromMap({
          'license': '12345678',
          'manufacturer': 'Toyota',
          'model': 'Corolla',
          'year': 2022,
          'mileage': 60000,
        });

        expect(
          vehicle.showTestOnHome,
          isTrue,
        );

        expect(
          vehicle.showVehicleLicenseOnHome,
          isFalse,
        );

        expect(
          vehicle.showServiceOnHome,
          isTrue,
        );
      },
    );

    test(
      'keeps nullable fields null',
      () {
        final vehicle =
            Vehicle.fromMap({
          'license': '12345678',
          'manufacturer': 'Toyota',
          'model': 'Corolla',
          'year': 2022,
          'mileage': 60000,
          'test_expiry_date': null,
          'vehicle_license_expiry_date':
              null,
          'last_service_date': null,
          'last_service_mileage':
              null,
          'service_interval_km':
              null,
        });

        expect(
          vehicle.testExpiryDate,
          isNull,
        );

        expect(
          vehicle.vehicleLicenseExpiryDate,
          isNull,
        );

        expect(
          vehicle.lastServiceDate,
          isNull,
        );

        expect(
          vehicle.lastServiceMileage,
          isNull,
        );

        expect(
          vehicle.serviceIntervalKm,
          isNull,
        );
      },
    );

    test(
      'invalid date strings become null',
      () {
        final vehicle =
            Vehicle.fromMap({
          'license': '12345678',
          'manufacturer': 'Toyota',
          'model': 'Corolla',
          'year': 2022,
          'mileage': 60000,
          'test_expiry_date':
              'invalid',
          'vehicle_license_expiry_date':
              'invalid',
          'last_service_date':
              'invalid',
        });

        expect(
          vehicle.testExpiryDate,
          isNull,
        );

        expect(
          vehicle.vehicleLicenseExpiryDate,
          isNull,
        );

        expect(
          vehicle.lastServiceDate,
          isNull,
        );
      },
    );
  });

  group('Vehicle.toMap', () {
    test(
      'writes complete vehicle correctly',
      () {
        final vehicle = Vehicle(
          license: '12345678',
          manufacturer: 'Toyota',
          model: 'Corolla',
          year: 2022,
          mileage: 60000,
          testExpiryDate:
              DateTime(2027, 10, 5),
          showTestOnHome: false,
          vehicleLicenseExpiryDate:
              DateTime(2028, 8, 31),
          showVehicleLicenseOnHome:
              true,
          lastServiceDate:
              DateTime(2026, 8, 30),
          lastServiceMileage: 60000,
          serviceIntervalKm: 15000,
          showServiceOnHome: false,
        );

        final map = vehicle.toMap();

        expect(
          map['license'],
          '12345678',
        );

        expect(
          map['manufacturer'],
          'Toyota',
        );

        expect(
          map['model'],
          'Corolla',
        );

        expect(
          map['year'],
          2022,
        );

        expect(
          map['mileage'],
          60000,
        );

        expect(
          map['test_expiry_date'],
          '2027-10-05',
        );

        expect(
          map['show_test_on_home'],
          isFalse,
        );

        expect(
          map['vehicle_license_expiry_date'],
          '2028-08-31',
        );

        expect(
          map['show_vehicle_license_on_home'],
          isTrue,
        );

        expect(
          map['last_service_date'],
          '2026-08-30',
        );

        expect(
          map['last_service_mileage'],
          60000,
        );

        expect(
          map['service_interval_km'],
          15000,
        );

        expect(
          map['show_service_on_home'],
          isFalse,
        );
      },
    );

    test(
      'writes nullable values as null',
      () {
        final vehicle = Vehicle(
          license: '12345678',
          manufacturer: 'Toyota',
          model: 'Corolla',
          year: 2022,
          mileage: 60000,
        );

        final map = vehicle.toMap();

        expect(
          map['test_expiry_date'],
          isNull,
        );

        expect(
          map['vehicle_license_expiry_date'],
          isNull,
        );

        expect(
          map['last_service_date'],
          isNull,
        );

        expect(
          map['last_service_mileage'],
          isNull,
        );

        expect(
          map['service_interval_km'],
          isNull,
        );
      },
    );
  });
}