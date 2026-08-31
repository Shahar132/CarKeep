import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/vehicle_insurance.dart';

void main() {
  group('InsuranceType', () {
    test(
      'converts all insurance types to correct database values',
      () {
        expect(
          InsuranceType
              .mandatory
              .databaseValue,
          'mandatory',
        );

        expect(
          InsuranceType
              .comprehensive
              .databaseValue,
          'comprehensive',
        );

        expect(
          InsuranceType
              .thirdParty
              .databaseValue,
          'third_party',
        );
      },
    );

    test(
      'has correct Hebrew display names',
      () {
        expect(
          InsuranceType.mandatory.displayName,
          'ביטוח חובה',
        );

        expect(
          InsuranceType
              .comprehensive
              .displayName,
          'ביטוח מקיף',
        );

        expect(
          InsuranceType.thirdParty.displayName,
          'ביטוח צד ג׳',
        );
      },
    );
  });

  group('VehicleInsurance.fromMap', () {
    test(
      'reads all supported insurance types',
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
          final insurance =
              VehicleInsurance.fromMap({
            'type': entry.key,
          });

          expect(
            insurance.type,
            entry.value,
          );
        }
      },
    );

    test(
      'reads complete insurance correctly',
      () {
        final insurance =
            VehicleInsurance.fromMap({
          'id': 'insurance-1',
          'vehicle_id': 'vehicle-1',
          'type': 'mandatory',
          'expiry_date': '2027-12-31',
          'show_on_home': true,
        });

        expect(
          insurance.id,
          'insurance-1',
        );

        expect(
          insurance.vehicleId,
          'vehicle-1',
        );

        expect(
          insurance.type,
          InsuranceType.mandatory,
        );

        expect(
          insurance.expiryDate,
          DateTime(2027, 12, 31),
        );

        expect(
          insurance.showOnHome,
          isTrue,
        );
      },
    );

    test(
      'accepts DateTime expiry value',
      () {
        final date =
            DateTime(2027, 12, 31);

        final insurance =
            VehicleInsurance.fromMap({
          'type': 'mandatory',
          'expiry_date': date,
        });

        expect(
          insurance.expiryDate,
          date,
        );
      },
    );

    test(
      'null expiry date stays null',
      () {
        final insurance =
            VehicleInsurance.fromMap({
          'type': 'mandatory',
          'expiry_date': null,
        });

        expect(
          insurance.expiryDate,
          isNull,
        );
      },
    );

    test(
      'invalid expiry date becomes null',
      () {
        final insurance =
            VehicleInsurance.fromMap({
          'type': 'mandatory',
          'expiry_date':
              'invalid-date',
        });

        expect(
          insurance.expiryDate,
          isNull,
        );
      },
    );

    test(
      'showOnHome defaults to false',
      () {
        final insurance =
            VehicleInsurance.fromMap({
          'type': 'mandatory',
        });

        expect(
          insurance.showOnHome,
          isFalse,
        );
      },
    );

    test(
      'throws for unknown insurance type',
      () {
        expect(
          () =>
              VehicleInsurance.fromMap({
            'type':
                'unknown_insurance',
          }),
          throwsArgumentError,
        );
      },
    );
  });

  group('VehicleInsurance.toMap', () {
    test(
      'writes complete insurance correctly',
      () {
        final insurance =
            VehicleInsurance(
          vehicleId: 'vehicle-1',
          type:
              InsuranceType.comprehensive,
          expiryDate:
              DateTime(2028, 1, 5),
          showOnHome: true,
        );

        final map =
            insurance.toMap();

        expect(
          map['vehicle_id'],
          'vehicle-1',
        );

        expect(
          map['type'],
          'comprehensive',
        );

        expect(
          map['expiry_date'],
          '2028-01-05',
        );

        expect(
          map['show_on_home'],
          isTrue,
        );
      },
    );

    test(
      'writes null expiry correctly',
      () {
        final insurance =
            VehicleInsurance(
          type:
              InsuranceType.thirdParty,
        );

        final map =
            insurance.toMap();

        expect(
          map['expiry_date'],
          isNull,
        );

        expect(
          map.containsKey('vehicle_id'),
          isFalse,
        );
      },
    );
  });
}