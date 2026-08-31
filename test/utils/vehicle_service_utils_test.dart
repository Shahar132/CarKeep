import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/vehicle.dart';
import '../../lib/models/vehicle_event.dart';
import '../../lib/utils/vehicle_service_utils.dart';

Vehicle createVehicle({
  DateTime? lastServiceDate,
  int? lastServiceMileage,
  int? serviceIntervalKm,
  List<VehicleEvent>? events,
}) {
  return Vehicle(
    license: '12345678',
    manufacturer: 'Toyota',
    model: 'Corolla',
    year: 2022,
    mileage: 70000,
    lastServiceDate:
        lastServiceDate,
    lastServiceMileage:
        lastServiceMileage,
    serviceIntervalKm:
        serviceIntervalKm,
    events: events,
  );
}

void main() {
  group(
    'VehicleServiceUtils.getNextServiceDate',
    () {
      test(
        'returns null when last service date is missing',
        () {
          final vehicle =
              createVehicle();

          final result =
              VehicleServiceUtils
                  .getNextServiceDate(
            vehicle,
          );

          expect(
            result,
            isNull,
          );
        },
      );

      test(
        'returns date one year after last service',
        () {
          final vehicle =
              createVehicle(
            lastServiceDate:
                DateTime(2026, 8, 30),
          );

          final result =
              VehicleServiceUtils
                  .getNextServiceDate(
            vehicle,
          );

          expect(
            result,
            DateTime(2027, 8, 30),
          );
        },
      );

      test(
        'keeps end of year date correctly',
        () {
          final vehicle =
              createVehicle(
            lastServiceDate:
                DateTime(2026, 12, 31),
          );

          final result =
              VehicleServiceUtils
                  .getNextServiceDate(
            vehicle,
          );

          expect(
            result,
            DateTime(2027, 12, 31),
          );
        },
      );

      test(
        'converts February 29 to February 28 in non leap year',
        () {
          final vehicle =
              createVehicle(
            lastServiceDate:
                DateTime(2024, 2, 29),
          );

          final result =
              VehicleServiceUtils
                  .getNextServiceDate(
            vehicle,
          );

          expect(
            result,
            DateTime(2025, 2, 28),
          );
        },
      );
    },
  );

  group(
    'VehicleServiceUtils.getNextServiceMileage',
    () {
      test(
        'calculates next mileage correctly',
        () {
          final vehicle =
              createVehicle(
            lastServiceMileage: 60000,
            serviceIntervalKm: 15000,
          );

          final result =
              VehicleServiceUtils
                  .getNextServiceMileage(
            vehicle,
          );

          expect(
            result,
            75000,
          );
        },
      );

      test(
        'returns null when last service mileage is missing',
        () {
          final vehicle =
              createVehicle(
            serviceIntervalKm: 15000,
          );

          final result =
              VehicleServiceUtils
                  .getNextServiceMileage(
            vehicle,
          );

          expect(
            result,
            isNull,
          );
        },
      );

      test(
        'returns null when service interval is missing',
        () {
          final vehicle =
              createVehicle(
            lastServiceMileage: 60000,
          );

          final result =
              VehicleServiceUtils
                  .getNextServiceMileage(
            vehicle,
          );

          expect(
            result,
            isNull,
          );
        },
      );

      test(
        'returns null when both values are missing',
        () {
          final vehicle =
              createVehicle();

          final result =
              VehicleServiceUtils
                  .getNextServiceMileage(
            vehicle,
          );

          expect(
            result,
            isNull,
          );
        },
      );
    },
  );

  group(
    'VehicleServiceUtils.getLatestServiceEvent',
    () {
      test(
        'returns null for empty list',
        () {
          final result =
              VehicleServiceUtils
                  .getLatestServiceEvent(
            [],
          );

          expect(
            result,
            isNull,
          );
        },
      );

      test(
        'returns null when there are no service events',
        () {
          final events = [
            VehicleEvent(
              type:
                  VehicleEventType.test,
              date:
                  DateTime(2030, 1, 1),
              title: 'טסט',
            ),
          ];

          final result =
              VehicleServiceUtils
                  .getLatestServiceEvent(
            events,
          );

          expect(
            result,
            isNull,
          );
        },
      );

      test(
        'returns latest service event',
        () {
          final oldService =
              VehicleEvent(
            type:
                VehicleEventType.service,
            date:
                DateTime(2025, 8, 30),
            title: 'טיפול',
            mileage: 45000,
          );

          final latestService =
              VehicleEvent(
            type:
                VehicleEventType.service,
            date:
                DateTime(2026, 8, 30),
            title: 'טיפול',
            mileage: 60000,
          );

          final result =
              VehicleServiceUtils
                  .getLatestServiceEvent(
            [
              oldService,
              latestService,
            ],
          );

          expect(
            result,
            same(latestService),
          );
        },
      );

      test(
        'finds latest service when list is not sorted',
        () {
          final latestService =
              VehicleEvent(
            type:
                VehicleEventType.service,
            date:
                DateTime(2028, 8, 30),
            title: 'טיפול',
          );

          final result =
              VehicleServiceUtils
                  .getLatestServiceEvent(
            [
              latestService,
              VehicleEvent(
                type:
                    VehicleEventType.service,
                date:
                    DateTime(2026, 8, 30),
                title: 'טיפול',
              ),
              VehicleEvent(
                type:
                    VehicleEventType.service,
                date:
                    DateTime(2027, 8, 30),
                title: 'טיפול',
              ),
            ],
          );

          expect(
            result,
            same(latestService),
          );
        },
      );

      test(
        'ignores newer non service events',
        () {
          final service =
              VehicleEvent(
            type:
                VehicleEventType.service,
            date:
                DateTime(2026, 8, 30),
            title: 'טיפול',
          );

          final result =
              VehicleServiceUtils
                  .getLatestServiceEvent(
            [
              service,
              VehicleEvent(
                type:
                    VehicleEventType.test,
                date:
                    DateTime(2030, 1, 1),
                title: 'טסט',
              ),
            ],
          );

          expect(
            result,
            same(service),
          );
        },
      );

      test(
        'does not change original event order',
        () {
          final first =
              VehicleEvent(
            type:
                VehicleEventType.service,
            date:
                DateTime(2025, 1, 1),
            title: 'ראשון',
          );

          final second =
              VehicleEvent(
            type:
                VehicleEventType.service,
            date:
                DateTime(2027, 1, 1),
            title: 'שני',
          );

          final events = [
            first,
            second,
          ];

          VehicleServiceUtils
              .getLatestServiceEvent(
            events,
          );

          expect(
            events[0],
            same(first),
          );

          expect(
            events[1],
            same(second),
          );
        },
      );
    },
  );

  group(
    'VehicleServiceUtils.updateCurrentServiceFromHistory',
    () {
      test(
        'updates vehicle from latest service',
        () {
          final vehicle =
              createVehicle(
            events: [
              VehicleEvent(
                type:
                    VehicleEventType.service,
                date:
                    DateTime(2025, 8, 30),
                title: 'טיפול',
                mileage: 45000,
                serviceIntervalKm:
                    10000,
              ),
              VehicleEvent(
                type:
                    VehicleEventType.service,
                date:
                    DateTime(2026, 8, 30),
                title: 'טיפול',
                mileage: 60000,
                serviceIntervalKm:
                    15000,
              ),
            ],
          );

          VehicleServiceUtils
              .updateCurrentServiceFromHistory(
            vehicle,
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
        },
      );

      test(
        'returns to previous service after latest is removed',
        () {
          final oldService =
              VehicleEvent(
            type:
                VehicleEventType.service,
            date:
                DateTime(2025, 8, 30),
            title: 'טיפול',
            mileage: 45000,
            serviceIntervalKm:
                10000,
          );

          final latestService =
              VehicleEvent(
            type:
                VehicleEventType.service,
            date:
                DateTime(2026, 8, 30),
            title: 'טיפול',
            mileage: 60000,
            serviceIntervalKm:
                15000,
          );

          final vehicle =
              createVehicle(
            events: [
              oldService,
              latestService,
            ],
          );

          vehicle.events.remove(
            latestService,
          );

          VehicleServiceUtils
              .updateCurrentServiceFromHistory(
            vehicle,
          );

          expect(
            vehicle.lastServiceDate,
            DateTime(2025, 8, 30),
          );

          expect(
            vehicle.lastServiceMileage,
            45000,
          );

          expect(
            vehicle.serviceIntervalKm,
            10000,
          );
        },
      );

      test(
        'keeps latest service after older service is removed',
        () {
          final oldService =
              VehicleEvent(
            type:
                VehicleEventType.service,
            date:
                DateTime(2025, 8, 30),
            title: 'טיפול',
            mileage: 45000,
          );

          final latestService =
              VehicleEvent(
            type:
                VehicleEventType.service,
            date:
                DateTime(2026, 8, 30),
            title: 'טיפול',
            mileage: 60000,
            serviceIntervalKm:
                15000,
          );

          final vehicle =
              createVehicle(
            events: [
              oldService,
              latestService,
            ],
          );

          vehicle.events.remove(
            oldService,
          );

          VehicleServiceUtils
              .updateCurrentServiceFromHistory(
            vehicle,
          );

          expect(
            vehicle.lastServiceDate,
            DateTime(2026, 8, 30),
          );

          expect(
            vehicle.lastServiceMileage,
            60000,
          );
        },
      );

      test(
        'clears current service when no service events remain',
        () {
          final vehicle =
              createVehicle(
            lastServiceDate:
                DateTime(2026, 8, 30),
            lastServiceMileage: 60000,
            serviceIntervalKm: 15000,
            events: [
              VehicleEvent(
                type:
                    VehicleEventType.test,
                date:
                    DateTime(2027, 1, 1),
                title: 'טסט',
              ),
            ],
          );

          VehicleServiceUtils
              .updateCurrentServiceFromHistory(
            vehicle,
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
        'copies null mileage and interval from latest service',
        () {
          final vehicle =
              createVehicle(
            lastServiceMileage: 60000,
            serviceIntervalKm: 15000,
            events: [
              VehicleEvent(
                type:
                    VehicleEventType.service,
                date:
                    DateTime(2027, 8, 30),
                title: 'טיפול',
                mileage: null,
                serviceIntervalKm: null,
              ),
            ],
          );

          VehicleServiceUtils
              .updateCurrentServiceFromHistory(
            vehicle,
          );

          expect(
            vehicle.lastServiceDate,
            DateTime(2027, 8, 30),
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
    },
  );
}