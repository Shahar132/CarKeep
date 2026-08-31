import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/vehicle_document.dart';

void main() {
  group('VehicleDocumentCategory', () {
    test(
      'converts all categories to correct database values',
      () {
        expect(
          VehicleDocumentCategory
              .vehicleLicense
              .databaseValue,
          'vehicle_license',
        );

        expect(
          VehicleDocumentCategory
              .test
              .databaseValue,
          'test',
        );

        expect(
          VehicleDocumentCategory
              .insurance
              .databaseValue,
          'insurance',
        );

        expect(
          VehicleDocumentCategory
              .service
              .databaseValue,
          'service',
        );

        expect(
          VehicleDocumentCategory
              .other
              .databaseValue,
          'other',
        );
      },
    );

    test(
      'has correct Hebrew display names',
      () {
        expect(
          VehicleDocumentCategory
              .vehicleLicense
              .displayName,
          'רישיונות רכב',
        );

        expect(
          VehicleDocumentCategory
              .test
              .displayName,
          'טסטים',
        );

        expect(
          VehicleDocumentCategory
              .insurance
              .displayName,
          'ביטוחים',
        );

        expect(
          VehicleDocumentCategory
              .service
              .displayName,
          'טיפולים',
        );

        expect(
          VehicleDocumentCategory
              .other
              .displayName,
          'מסמכים אחרים',
        );
      },
    );
  });

  group('VehicleDocument.fromMap', () {
    test(
      'reads all document fields correctly',
      () {
        final map = {
          'id': 'document-1',
          'vehicle_id': 'vehicle-1',
          'event_id': 'event-1',
          'display_name':
              'רישיון רכב 2028 - 31/08/2028',
          'original_file_name':
              'license_test.pdf',
          'file_path':
              'vehicle-1/license_test.pdf',
          'category':
              'vehicle_license',
          'uploaded_by':
              'user-1',
          'created_at':
              '2026-08-30T10:00:00.000Z',
        };

        final document =
            VehicleDocument.fromMap(map);

        expect(
          document.id,
          'document-1',
        );

        expect(
          document.vehicleId,
          'vehicle-1',
        );

        expect(
          document.eventId,
          'event-1',
        );

        expect(
          document.displayName,
          'רישיון רכב 2028 - 31/08/2028',
        );

        expect(
          document.originalFileName,
          'license_test.pdf',
        );

        expect(
          document.filePath,
          'vehicle-1/license_test.pdf',
        );

        expect(
          document.category,
          VehicleDocumentCategory
              .vehicleLicense,
        );

        expect(
          document.uploadedBy,
          'user-1',
        );

        expect(
          document.createdAt,
          DateTime.parse(
            '2026-08-30T10:00:00.000Z',
          ),
        );
      },
    );

    test(
      'reads all supported categories correctly',
      () {
        final cases = {
          'vehicle_license':
              VehicleDocumentCategory
                  .vehicleLicense,
          'test':
              VehicleDocumentCategory.test,
          'insurance':
              VehicleDocumentCategory
                  .insurance,
          'service':
              VehicleDocumentCategory
                  .service,
          'other':
              VehicleDocumentCategory.other,
        };

        for (final entry
            in cases.entries) {
          final document =
              VehicleDocument.fromMap({
            'display_name': 'מסמך',
            'file_path': 'file.pdf',
            'category': entry.key,
          });

          expect(
            document.category,
            entry.value,
          );
        }
      },
    );

    test(
      'null category becomes other',
      () {
        final document =
            VehicleDocument.fromMap({
          'display_name': 'מסמך',
          'file_path': 'file.pdf',
          'category': null,
        });

        expect(
          document.category,
          VehicleDocumentCategory.other,
        );
      },
    );

    test(
      'unknown category becomes other',
      () {
        final document =
            VehicleDocument.fromMap({
          'display_name': 'מסמך',
          'file_path': 'file.pdf',
          'category':
              'unknown_category',
        });

        expect(
          document.category,
          VehicleDocumentCategory.other,
        );
      },
    );

    test(
      'invalid createdAt becomes null',
      () {
        final document =
            VehicleDocument.fromMap({
          'display_name': 'מסמך',
          'file_path': 'file.pdf',
          'category': 'other',
          'created_at':
              'not-a-valid-date',
        });

        expect(
          document.createdAt,
          isNull,
        );
      },
    );
  });

  group('VehicleDocument.toMap', () {
    test(
      'writes all document fields correctly',
      () {
        const document =
            VehicleDocument(
          vehicleId: 'vehicle-1',
          eventId: 'event-1',
          displayName:
              'טסט 2027 - 31/10/2027',
          originalFileName:
              'test_test.pdf',
          filePath:
              'vehicle-1/test_test.pdf',
          category:
              VehicleDocumentCategory.test,
          uploadedBy: 'user-1',
        );

        final map =
            document.toMap();

        expect(
          map['vehicle_id'],
          'vehicle-1',
        );

        expect(
          map['event_id'],
          'event-1',
        );

        expect(
          map['display_name'],
          'טסט 2027 - 31/10/2027',
        );

        expect(
          map['original_file_name'],
          'test_test.pdf',
        );

        expect(
          map['file_path'],
          'vehicle-1/test_test.pdf',
        );

        expect(
          map['category'],
          'test',
        );

        expect(
          map['uploaded_by'],
          'user-1',
        );
      },
    );

    test(
      'omits vehicle and event ids when they are null',
      () {
        const document =
            VehicleDocument(
          displayName: 'מסמך כללי',
          filePath: 'file.pdf',
        );

        final map =
            document.toMap();

        expect(
          map.containsKey('vehicle_id'),
          isFalse,
        );

        expect(
          map.containsKey('event_id'),
          isFalse,
        );

        expect(
          map['category'],
          'other',
        );
      },
    );
  });
}