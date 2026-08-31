import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/vehicle.dart';
import '../../lib/models/vehicle_document.dart';
import '../../lib/models/vehicle_event.dart';
import '../../lib/models/vehicle_member.dart';
import '../../lib/repositories/vehicle_document_repository.dart';
import '../../lib/repositories/vehicle_repository.dart';
import '../../lib/screens/manage_vehicle_license_screen.dart';

class FakeVehicleRepository
    extends VehicleRepository {
  int addEventCalls = 0;
  int updateVehicleCalls = 0;
  int deleteEventCalls = 0;

  VehicleEvent? lastAddedEvent;

  @override
  Future<VehicleEvent> addVehicleEvent(
    VehicleEvent event,
  ) async {
    addEventCalls++;
    lastAddedEvent = event;

    return VehicleEvent(
      id: 'event-1',
      vehicleId: event.vehicleId,
      type: event.type,
      date: event.date,
      title: event.title,
      mileage: event.mileage,
      cost: event.cost,
      notes: event.notes,
      serviceIntervalKm:
          event.serviceIntervalKm,
      insuranceType:
          event.insuranceType,
    );
  }

  @override
  Future<void> updateVehicle(
    Vehicle vehicle,
  ) async {
    updateVehicleCalls++;
  }

  @override
  Future<void> deleteVehicleEvent(
    String eventId,
  ) async {
    deleteEventCalls++;
  }
}

class FakeVehicleDocumentRepository
    extends VehicleDocumentRepository {
  int uploadCalls = 0;
  int deleteCalls = 0;

  String? lastDisplayName;
  String? lastEventId;

  VehicleDocumentCategory?
      lastCategory;

  @override
  Future<VehicleDocument> uploadDocument({
    required String vehicleId,
    required String displayName,
    required String originalFileName,
    required Uint8List fileBytes,
    required VehicleDocumentCategory category,
    String? eventId,
  }) async {
    uploadCalls++;

    lastDisplayName = displayName;
    lastEventId = eventId;
    lastCategory = category;

    return VehicleDocument(
      id: 'document-1',
      vehicleId: vehicleId,
      eventId: eventId,
      displayName: displayName,
      originalFileName:
          originalFileName,
      filePath:
          '$vehicleId/test-file',
      category: category,
    );
  }

  @override
  Future<void> deleteDocument(
    VehicleDocument document,
  ) async {
    deleteCalls++;
  }
}

Vehicle createVehicle({
  VehicleMemberRole role =
      VehicleMemberRole.owner,
  DateTime? expiryDate,
}) {
  return Vehicle(
    id: 'vehicle-1',
    license: '12345678',
    manufacturer: 'Toyota',
    model: 'Corolla',
    year: 2022,
    mileage: 60000,
    vehicleLicenseExpiryDate:
        expiryDate,
    currentUserRole: role,
  );
}

Widget buildTestWidget({
  required Vehicle vehicle,
  required FakeVehicleRepository
      repository,
  required FakeVehicleDocumentRepository
      documentRepository,
  Future<PlatformFile?> Function()?
      documentPicker,
}) {
  return MaterialApp(
    home:
        ManageVehicleLicenseScreen(
      vehicle: vehicle,
      repository: repository,
      documentRepository:
          documentRepository,
      documentPicker:
          documentPicker,
      historyEventsLoader:
          (_) async => [],
    ),
  );
}

Future<void> acceptDatePicker(
  WidgetTester tester,
) async {
  await tester.pumpAndSettle();

  expect(
    find.byType(DatePickerDialog),
    findsOneWidget,
  );

  await tester.tap(
    find.text('OK'),
  );

  await tester.pumpAndSettle();
}

Future<void> clearSnackBar(
  WidgetTester tester,
) async {
  await tester.pump(
    const Duration(seconds: 5),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'owner sees current license information and edit controls',
    (tester) async {
      final repository =
          FakeVehicleRepository();

      final documentRepository =
          FakeVehicleDocumentRepository();

      await tester.pumpWidget(
        buildTestWidget(
          vehicle: createVehicle(
            expiryDate:
                DateTime(2028, 8, 31),
          ),
          repository: repository,
          documentRepository:
              documentRepository,
        ),
      );

      expect(
        find.text(
          'תוקף: 31/08/2028',
        ),
        findsOneWidget,
      );

      expect(
        find.text('שמור'),
        findsOneWidget,
      );

      expect(
        find.text('בחר תאריך'),
        findsOneWidget,
      );

      expect(
        find.text('בחר מסמך'),
        findsOneWidget,
      );

      expect(
        find.text(
          'היסטוריית רישיונות רכב',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'member sees read only mode',
    (tester) async {
      final repository =
          FakeVehicleRepository();

      final documentRepository =
          FakeVehicleDocumentRepository();

      await tester.pumpWidget(
        buildTestWidget(
          vehicle: createVehicle(
            role:
                VehicleMemberRole.member,
          ),
          repository: repository,
          documentRepository:
              documentRepository,
        ),
      );

      expect(
        find.text('מצב צפייה בלבד'),
        findsOneWidget,
      );

      expect(
        find.text('שמור'),
        findsNothing,
      );

      expect(
        find.text('בחר תאריך'),
        findsNothing,
      );

      expect(
        find.text('בחר מסמך'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'save without selecting expiry date shows validation message',
    (tester) async {
      final repository =
          FakeVehicleRepository();

      final documentRepository =
          FakeVehicleDocumentRepository();

      await tester.pumpWidget(
        buildTestWidget(
          vehicle: createVehicle(),
          repository: repository,
          documentRepository:
              documentRepository,
        ),
      );

      await tester.tap(
        find.text('שמור'),
      );

      await tester.pump();

      expect(
        find.text(
          'יש לבחור תאריך תוקף לרישיון הרכב.',
        ),
        findsOneWidget,
      );

      expect(
        repository.addEventCalls,
        0,
      );

      await clearSnackBar(tester);
    },
  );

  testWidgets(
    'selected document can be added and removed',
    (tester) async {
      final repository =
          FakeVehicleRepository();

      final documentRepository =
          FakeVehicleDocumentRepository();

      await tester.pumpWidget(
        buildTestWidget(
          vehicle: createVehicle(),
          repository: repository,
          documentRepository:
              documentRepository,
          documentPicker: () async {
            return PlatformFile(
              name:
                  'license_test.pdf',
              size: 3,
              bytes:
                  Uint8List.fromList(
                [1, 2, 3],
              ),
            );
          },
        ),
      );

      await tester.tap(
        find.text('בחר מסמך'),
      );

      await tester.pumpAndSettle();

      expect(
        find.text(
          'license_test.pdf',
        ),
        findsOneWidget,
      );

      expect(
        find.text('החלף מסמך'),
        findsOneWidget,
      );

      await tester.tap(
        find.byIcon(Icons.close),
      );

      await tester.pump();

      expect(
        find.text(
          'license_test.pdf',
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'canceling confirmation does not save',
    (tester) async {
      final repository =
          FakeVehicleRepository();

      final documentRepository =
          FakeVehicleDocumentRepository();

      await tester.pumpWidget(
        buildTestWidget(
          vehicle: createVehicle(
            expiryDate:
                DateTime(2028, 8, 31),
          ),
          repository: repository,
          documentRepository:
              documentRepository,
        ),
      );

      await tester.tap(
        find.text('בחר תאריך'),
      );

      await acceptDatePicker(
        tester,
      );

      await tester.tap(
        find.text('שמור'),
      );

      await tester.pumpAndSettle();

      expect(
        find.text(
          'אישור פרטי רישיון הרכב',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.text('חזור לתיקון'),
      );

      await tester.pumpAndSettle();

      expect(
        repository.addEventCalls,
        0,
      );

      expect(
        repository.updateVehicleCalls,
        0,
      );
    },
  );

  testWidgets(
    'saves license event and document correctly',
    (tester) async {
      final repository =
          FakeVehicleRepository();

      final documentRepository =
          FakeVehicleDocumentRepository();

      final vehicle =
          createVehicle(
        expiryDate:
            DateTime(2028, 8, 31),
      );

      await tester.pumpWidget(
        buildTestWidget(
          vehicle: vehicle,
          repository: repository,
          documentRepository:
              documentRepository,
          documentPicker: () async {
            return PlatformFile(
              name:
                  'license_test.pdf',
              size: 3,
              bytes:
                  Uint8List.fromList(
                [1, 2, 3],
              ),
            );
          },
        ),
      );

      await tester.tap(
        find.text('בחר מסמך'),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.text('בחר תאריך'),
      );

      await acceptDatePicker(
        tester,
      );

      await tester.tap(
        find.text('שמור'),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.text('אישור ושמירה'),
      );

      await tester.pumpAndSettle();

      expect(
        repository.addEventCalls,
        1,
      );

      expect(
        repository.updateVehicleCalls,
        1,
      );

      expect(
        repository.lastAddedEvent?.type,
        VehicleEventType
            .vehicleLicense,
      );

      expect(
        documentRepository.uploadCalls,
        1,
      );

      expect(
        documentRepository.lastCategory,
        VehicleDocumentCategory
            .vehicleLicense,
      );

      expect(
        documentRepository.lastEventId,
        'event-1',
      );

      expect(
        documentRepository
            .lastDisplayName,
        'רישיון רכב 2028 - '
        '31/08/2028',
      );

      expect(
        vehicle
            .vehicleLicenseExpiryDate,
        DateTime(2028, 8, 31),
      );

      expect(
        vehicle.events.length,
        1,
      );

      await clearSnackBar(tester);
    },
  );
}