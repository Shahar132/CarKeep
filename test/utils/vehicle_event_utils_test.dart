import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/vehicle_event.dart';
import '../../lib/utils/vehicle_event_utils.dart';

void main() {
  group(
    'VehicleEventUtils.getLatestEventDate',
    () {
      test(
        'returns null for empty event list',
        () {
          final result =
              VehicleEventUtils
                  .getLatestEventDate(
            [],
            VehicleEventType.vehicleLicense,
          );

          expect(
            result,
            isNull,
          );
        },
      );

      test(
        'returns null when requested event type does not exist',
        () {
          final events = [
            VehicleEvent(
              type:
                  VehicleEventType.test,
              date:
                  DateTime(2028, 5, 10),
              title: 'טסט',
            ),
          ];

          final result =
              VehicleEventUtils
                  .getLatestEventDate(
            events,
            VehicleEventType.vehicleLicense,
          );

          expect(
            result,
            isNull,
          );
        },
      );

      test(
        'returns latest vehicle license date',
        () {
          final events = [
            VehicleEvent(
              type:
                  VehicleEventType.vehicleLicense,
              date:
                  DateTime(2027, 8, 31),
              title:
                  'חידוש רישיון רכב',
            ),
            VehicleEvent(
              type:
                  VehicleEventType.vehicleLicense,
              date:
                  DateTime(2028, 8, 31),
              title:
                  'חידוש רישיון רכב',
            ),
          ];

          final result =
              VehicleEventUtils
                  .getLatestEventDate(
            events,
            VehicleEventType.vehicleLicense,
          );

          expect(
            result,
            DateTime(2028, 8, 31),
          );
        },
      );

      test(
        'finds latest event even when list is not sorted',
        () {
          final events = [
            VehicleEvent(
              type:
                  VehicleEventType.test,
              date:
                  DateTime(2028, 1, 1),
              title: 'טסט',
            ),
            VehicleEvent(
              type:
                  VehicleEventType.test,
              date:
                  DateTime(2026, 1, 1),
              title: 'טסט',
            ),
            VehicleEvent(
              type:
                  VehicleEventType.test,
              date:
                  DateTime(2027, 1, 1),
              title: 'טסט',
            ),
          ];

          final result =
              VehicleEventUtils
                  .getLatestEventDate(
            events,
            VehicleEventType.test,
          );

          expect(
            result,
            DateTime(2028, 1, 1),
          );
        },
      );

      test(
        'ignores newer events of different type',
        () {
          final events = [
            VehicleEvent(
              type:
                  VehicleEventType.test,
              date:
                  DateTime(2027, 10, 31),
              title: 'טסט',
            ),
            VehicleEvent(
              type:
                  VehicleEventType.vehicleLicense,
              date:
                  DateTime(2030, 8, 31),
              title:
                  'חידוש רישיון רכב',
            ),
          ];

          final result =
              VehicleEventUtils
                  .getLatestEventDate(
            events,
            VehicleEventType.test,
          );

          expect(
            result,
            DateTime(2027, 10, 31),
          );
        },
      );

      test(
        'returns previous date after latest event is removed',
        () {
          final events = [
            VehicleEvent(
              type:
                  VehicleEventType.vehicleLicense,
              date:
                  DateTime(2027, 8, 31),
              title:
                  'חידוש רישיון רכב',
            ),
            VehicleEvent(
              type:
                  VehicleEventType.vehicleLicense,
              date:
                  DateTime(2028, 8, 31),
              title:
                  'חידוש רישיון רכב',
            ),
          ];

          events.removeWhere(
            (event) =>
                event.date ==
                DateTime(2028, 8, 31),
          );

          final result =
              VehicleEventUtils
                  .getLatestEventDate(
            events,
            VehicleEventType.vehicleLicense,
          );

          expect(
            result,
            DateTime(2027, 8, 31),
          );
        },
      );

      test(
        'keeps latest date after older event is removed',
        () {
          final events = [
            VehicleEvent(
              type:
                  VehicleEventType.vehicleLicense,
              date:
                  DateTime(2027, 8, 31),
              title:
                  'חידוש רישיון רכב',
            ),
            VehicleEvent(
              type:
                  VehicleEventType.vehicleLicense,
              date:
                  DateTime(2028, 8, 31),
              title:
                  'חידוש רישיון רכב',
            ),
          ];

          events.removeWhere(
            (event) =>
                event.date ==
                DateTime(2027, 8, 31),
          );

          final result =
              VehicleEventUtils
                  .getLatestEventDate(
            events,
            VehicleEventType.vehicleLicense,
          );

          expect(
            result,
            DateTime(2028, 8, 31),
          );
        },
      );
    },
  );
}