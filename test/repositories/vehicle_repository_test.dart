import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../lib/models/vehicle.dart';
import '../../lib/models/vehicle_event.dart';
import '../../lib/models/vehicle_insurance.dart';
import '../../lib/repositories/vehicle_repository.dart';

void main() {
  late SupabaseClient testSupabase;
  late VehicleRepository repository;

  setUp(() {
    testSupabase = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
    );

    repository = VehicleRepository(
      supabase: testSupabase,
    );
  });

  group(
    'VehicleRepository.updateVehicle',
    () {
      test(
        'throws when vehicle has no id',
        () async {
          final vehicle = Vehicle(
            license: '12345678',
            manufacturer: 'Toyota',
            model: 'Corolla',
            year: 2022,
            mileage: 60000,
          );

          expect(
            () => repository
                .updateVehicle(vehicle),
            throwsException,
          );
        },
      );
    },
  );

  group(
    'VehicleRepository.saveInsurance',
    () {
      test(
        'throws when insurance has no vehicle id',
        () async {
          final insurance =
              VehicleInsurance(
            type:
                InsuranceType.mandatory,
            expiryDate:
                DateTime(2027, 12, 31),
          );

          expect(
            () => repository
                .saveInsurance(insurance),
            throwsException,
          );
        },
      );
    },
  );

  group(
    'VehicleRepository.addVehicleEvent',
    () {
      test(
        'throws when event has no vehicle id',
        () async {
          final event = VehicleEvent(
            type:
                VehicleEventType.test,
            date:
                DateTime(2027, 10, 31),
            title: 'טסט',
          );

          expect(
            () => repository
                .addVehicleEvent(event),
            throwsException,
          );
        },
      );
    },
  );

  group(
    'VehicleRepository.updateVehicleEvent',
    () {
      test(
        'throws when event has no id',
        () async {
          final event = VehicleEvent(
            vehicleId: 'vehicle-1',
            type:
                VehicleEventType.test,
            date:
                DateTime(2027, 10, 31),
            title: 'טסט',
          );

          expect(
            () => repository
                .updateVehicleEvent(event),
            throwsException,
          );
        },
      );
    },
  );

  group(
    'VehicleRepository.getCurrentUserVehicleRole',
    () {
      test(
        'returns null when no user is signed in',
        () async {
          final result =
              await repository
                  .getCurrentUserVehicleRole(
            'vehicle-1',
          );

          expect(
            result,
            isNull,
          );
        },
      );
    },
  );
}