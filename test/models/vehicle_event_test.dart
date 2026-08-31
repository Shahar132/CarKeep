import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/vehicle_event.dart';
import '../../lib/models/vehicle_insurance.dart';

void main() {
  group('VehicleEventType', () {
    test(
      'converts all event types to correct database values',
      () {
        expect(
          VehicleEventType.service.databaseValue,
          'service',
        );

        expect(
          VehicleEventType.test.databaseValue,
          'test',
        );

        expect(
          VehicleEventType
              .vehicleLicense
              .databaseValue,
          'vehicle_license',
        );

        expect(
          VehicleEventType
              .insurance
              .databaseValue,
          'insurance',
        );

        expect(
          VehicleEventType.repair.databaseValue,
          'repair',
        );

        expect(
          VehicleEventType.other.databaseValue,
          'other',
        );
      },
    );

    test(
      'has correct Hebrew display names',
      () {
        expect(
          VehicleEventType.service.displayName,
          'טיפול',
        );

        expect(
          VehicleEventType.test.displayName,
          'טסט',
        );

        expect(
          VehicleEventType
              .vehicleLicense
              .displayName,
          'רישיון רכב',
        );

        expect(
          VehicleEventType
              .insurance
              .displayName,
          'ביטוח',
        );

        expect(
          VehicleEventType.repair.displayName,
          'תיקון',
        );

        expect(
          VehicleEventType.other.displayName,
          'אחר',
        );
      },
    );
  });

  group('VehicleEvent.fromMap', () {
    test(
      'reads every supported event type correctly',
      () {
        final cases = {
          'service':
              VehicleEventType.service,
          'test':
              VehicleEventType.test,
          'vehicle_license':
              VehicleEventType.vehicleLicense,
          'insurance':
              VehicleEventType.insurance,
          'repair':
              VehicleEventType.repair,
          'other':
              VehicleEventType.other,
        };

        for (final entry
            in cases.entries) {
          final event =
              VehicleEvent.fromMap({
            'type': entry.key,
            'event_date': '2028-08-31',
            'title': 'בדיקה',
          });

          expect(
            event.type,
            entry.value,
          );
        }
      },
    );

    test(
      'reads complete service event correctly',
      () {
        final event =
            VehicleEvent.fromMap({
          'id': 'event-1',
          'vehicle_id': 'vehicle-1',
          'type': 'service',
          'event_date': '2026-08-30',
          'title': 'טיפול',
          'mileage': 60000.0,
          'cost': 750,
          'notes': 'טיפול תקופתי',
          'service_interval_km':
              15000.0,
          'insurance_type': null,
        });

        expect(
          event.id,
          'event-1',
        );

        expect(
          event.vehicleId,
          'vehicle-1',
        );

        expect(
          event.type,
          VehicleEventType.service,
        );

        expect(
          event.date,
          DateTime(2026, 8, 30),
        );

        expect(
          event.mileage,
          60000,
        );

        expect(
          event.cost,
          750.0,
        );

        expect(
          event.notes,
          'טיפול תקופתי',
        );

        expect(
          event.serviceIntervalKm,
          15000,
        );

        expect(
          event.insuranceType,
          isNull,
        );
      },
    );

    test(
      'reads every insurance type correctly',
      () {
        final cases = {
          'mandatory':
              InsuranceType.mandatory,
          'comprehensive':
              InsuranceType.comprehensive,
          'third_party':
              InsuranceType.thirdParty,
        };

        for (final entry
            in cases.entries) {
          final event =
              VehicleEvent.fromMap({
            'type': 'insurance',
            'event_date': '2027-12-31',
            'title': 'ביטוח',
            'insurance_type': entry.key,
          });

          expect(
            event.insuranceType,
            entry.value,
          );
        }
      },
    );

    test(
      'throws for unknown event type',
      () {
        expect(
          () => VehicleEvent.fromMap({
            'type': 'invalid_type',
            'event_date': '2028-01-01',
            'title': 'בדיקה',
          }),
          throwsArgumentError,
        );
      },
    );

    test(
      'throws for unknown insurance type',
      () {
        expect(
          () => VehicleEvent.fromMap({
            'type': 'insurance',
            'event_date': '2028-01-01',
            'title': 'ביטוח',
            'insurance_type':
                'invalid_insurance',
          }),
          throwsArgumentError,
        );
      },
    );
  });

  group('VehicleEvent.toMap', () {
    test(
      'writes service event correctly',
      () {
        final event = VehicleEvent(
          vehicleId: 'vehicle-1',
          type: VehicleEventType.service,
          date: DateTime(2026, 8, 5),
          title: 'טיפול',
          mileage: 60000,
          cost: 750.50,
          notes: 'טיפול תקופתי',
          serviceIntervalKm: 15000,
        );

        final map = event.toMap();

        expect(
          map['vehicle_id'],
          'vehicle-1',
        );

        expect(
          map['type'],
          'service',
        );

        expect(
          map['event_date'],
          '2026-08-05',
        );

        expect(
          map['title'],
          'טיפול',
        );

        expect(
          map['mileage'],
          60000,
        );

        expect(
          map['cost'],
          750.50,
        );

        expect(
          map['notes'],
          'טיפול תקופתי',
        );

        expect(
          map['service_interval_km'],
          15000,
        );

        expect(
          map['insurance_type'],
          isNull,
        );
      },
    );

    test(
      'writes insurance type correctly',
      () {
        final event = VehicleEvent(
          vehicleId: 'vehicle-1',
          type:
              VehicleEventType.insurance,
          date: DateTime(2027, 12, 31),
          title: 'ביטוח חובה',
          insuranceType:
              InsuranceType.mandatory,
        );

        final map = event.toMap();

        expect(
          map['type'],
          'insurance',
        );

        expect(
          map['insurance_type'],
          'mandatory',
        );
      },
    );

    test(
      'omits vehicle id when it is null',
      () {
        final event = VehicleEvent(
          type: VehicleEventType.other,
          date: DateTime(2028, 1, 1),
          title: 'אחר',
        );

        final map = event.toMap();

        expect(
          map.containsKey('vehicle_id'),
          isFalse,
        );
      },
    );
  });
}