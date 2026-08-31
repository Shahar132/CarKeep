import 'package:flutter_test/flutter_test.dart';

import '../../lib/utils/vehicle_document_name_utils.dart';

void main() {
  group(
    'VehicleDocumentNameUtils.vehicleLicense',
    () {
      test(
        'creates correct vehicle license document name',
        () {
          final result =
              VehicleDocumentNameUtils
                  .vehicleLicense(
            DateTime(2028, 8, 31),
          );

          expect(
            result,
            'רישיון רכב 2028 - 31/08/2028',
          );
        },
      );

      test(
        'adds leading zero to day and month',
        () {
          final result =
              VehicleDocumentNameUtils
                  .vehicleLicense(
            DateTime(2028, 3, 5),
          );

          expect(
            result,
            'רישיון רכב 2028 - 05/03/2028',
          );
        },
      );
    },
  );

  group(
    'VehicleDocumentNameUtils.test',
    () {
      test(
        'creates correct test document name',
        () {
          final result =
              VehicleDocumentNameUtils.test(
            DateTime(2027, 10, 31),
          );

          expect(
            result,
            'טסט 2027 - 31/10/2027',
          );
        },
      );
    },
  );

  group(
    'VehicleDocumentNameUtils.insurance',
    () {
      test(
        'creates correct mandatory insurance document name',
        () {
          final result =
              VehicleDocumentNameUtils
                  .insurance(
            insuranceType:
                'ביטוח חובה',
            expiryDate:
                DateTime(2027, 12, 31),
          );

          expect(
            result,
            'ביטוח חובה 2027 - 31/12/2027',
          );
        },
      );

      test(
        'uses supplied insurance type in name',
        () {
          final result =
              VehicleDocumentNameUtils
                  .insurance(
            insuranceType:
                'ביטוח מקיף',
            expiryDate:
                DateTime(2028, 1, 5),
          );

          expect(
            result,
            'ביטוח מקיף 2028 - 05/01/2028',
          );
        },
      );
    },
  );

  group(
    'VehicleDocumentNameUtils.service',
    () {
      test(
        'creates correct service document name',
        () {
          final result =
              VehicleDocumentNameUtils
                  .service(
            mileage: 60000,
            serviceDate:
                DateTime(2026, 8, 30),
          );

          expect(
            result,
            'טיפול 60,000 ק"מ - 30/08/2026',
          );
        },
      );

      test(
        'formats four digit mileage with comma',
        () {
          final result =
              VehicleDocumentNameUtils
                  .service(
            mileage: 1000,
            serviceDate:
                DateTime(2026, 1, 1),
          );

          expect(
            result,
            'טיפול 1,000 ק"מ - 01/01/2026',
          );
        },
      );

      test(
        'formats large mileage with multiple commas',
        () {
          final result =
              VehicleDocumentNameUtils
                  .service(
            mileage: 1000000,
            serviceDate:
                DateTime(2026, 1, 1),
          );

          expect(
            result,
            'טיפול 1,000,000 ק"מ - 01/01/2026',
          );
        },
      );

      test(
        'does not add comma below one thousand',
        () {
          final result =
              VehicleDocumentNameUtils
                  .service(
            mileage: 999,
            serviceDate:
                DateTime(2026, 1, 1),
          );

          expect(
            result,
            'טיפול 999 ק"מ - 01/01/2026',
          );
        },
      );
    },
  );
}