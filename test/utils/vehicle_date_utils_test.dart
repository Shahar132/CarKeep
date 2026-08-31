import 'package:flutter_test/flutter_test.dart';

import '../../lib/utils/vehicle_date_utils.dart';

void main() {
  group('VehicleDateUtils.getExpiryText', () {
    final today = DateTime(2026, 8, 30);

    test(
      'returns not defined when expiry date is null',
      () {
        final result =
            VehicleDateUtils.getExpiryText(
          null,
          currentDate: today,
        );

        expect(
          result,
          'לא הוגדר',
        );
      },
    );

    test(
      'returns expired today when expiry date is today',
      () {
        final result =
            VehicleDateUtils.getExpiryText(
          DateTime(2026, 8, 30),
          currentDate: today,
        );

        expect(
          result,
          'פג היום',
        );
      },
    );

    test(
      'returns expires tomorrow when one day remains',
      () {
        final result =
            VehicleDateUtils.getExpiryText(
          DateTime(2026, 8, 31),
          currentDate: today,
        );

        expect(
          result,
          'פג מחר',
        );
      },
    );

    test(
      'returns expired yesterday when one day has passed',
      () {
        final result =
            VehicleDateUtils.getExpiryText(
          DateTime(2026, 8, 29),
          currentDate: today,
        );

        expect(
          result,
          'פג אתמול',
        );
      },
    );

    test(
      'returns remaining days for future expiry date',
      () {
        final result =
            VehicleDateUtils.getExpiryText(
          DateTime(2026, 9, 9),
          currentDate: today,
        );

        expect(
          result,
          'בעוד 10 ימים',
        );
      },
    );

    test(
      'returns passed days for expired date',
      () {
        final result =
            VehicleDateUtils.getExpiryText(
          DateTime(2026, 8, 20),
          currentDate: today,
        );

        expect(
          result,
          'פג לפני 10 ימים',
        );
      },
    );

    test(
      'ignores time of day',
      () {
        final result =
            VehicleDateUtils.getExpiryText(
          DateTime(
            2026,
            8,
            31,
            0,
            1,
          ),
          currentDate: DateTime(
            2026,
            8,
            30,
            23,
            59,
          ),
        );

        expect(
          result,
          'פג מחר',
        );
      },
    );

    test(
      'handles transition to next year',
      () {
        final result =
            VehicleDateUtils.getExpiryText(
          DateTime(2027, 1, 1),
          currentDate:
              DateTime(2026, 12, 31),
        );

        expect(
          result,
          'פג מחר',
        );
      },
    );

    test(
      'handles leap day correctly',
      () {
        final result =
            VehicleDateUtils.getExpiryText(
          DateTime(2024, 2, 29),
          currentDate:
              DateTime(2024, 2, 28),
        );

        expect(
          result,
          'פג מחר',
        );
      },
    );
  });
}