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
import '../../lib/screens/manage_test_screen.dart';

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
          '$vehicleId/test.pdf',
      category: category,
    );
  }

  @override
  Future<void> deleteDocument(
    VehicleDocument document,
  ) async {}
}

Vehicle createVehicle({
  VehicleMemberRole role =
      VehicleMemberRole.owner,
  DateTime? testExpiryDate,
}) {
  return Vehicle(
    id: 'vehicle-1',
    license: '12345678',
    manufacturer: 'Toyota',
    model: 'Corolla',
    year: 2022,
    mileage: 60000,
    testExpiryDate:
        testExpiryDate,
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
    home: ManageTestScreen(
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
    'shows current test information',
    (tester) async {
      final repository =
          FakeVehicleRepository();

      final documentRepository =
          FakeVehicleDocumentRepository();

      await tester.pumpWidget(
        buildTestWidget(
          vehicle: createVehicle(
            testExpiryDate:
                DateTime(2028, 5, 10),
          ),
          repository: repository,
          documentRepository:
              documentRepository,
        ),
      );

      expect(
        find.text('טסט נוכחי'),
        findsOneWidget,
      );

      expect(
        find.text(
          'תוקף: 10/05/2028',
        ),
        findsOneWidget,
      );

      expect(
        find.text('טסט חדש'),
        findsOneWidget,
      );

      expect(
        find.text('בחר מסמך'),
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
        find.text('טסט חדש'),
        findsNothing,
      );

      expect(
        find.text('בחר מסמך'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'selected test document can be removed',
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
              name: 'test_2028.pdf',
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
          'test_2028.pdf',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byIcon(Icons.close),
      );

      await tester.pump();

      expect(
        find.text(
          'test_2028.pdf',
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'canceling test confirmation does not save',
    (tester) async {
      final repository =
          FakeVehicleRepository();

      final documentRepository =
          FakeVehicleDocumentRepository();

      await tester.pumpWidget(
        buildTestWidget(
          vehicle: createVehicle(
            testExpiryDate:
                DateTime(2028, 5, 10),
          ),
          repository: repository,
          documentRepository:
              documentRepository,
        ),
      );

      await tester.tap(
        find.text('טסט חדש'),
      );

      await acceptDatePicker(
        tester,
      );

      expect(
        find.text(
          'אישור פרטי הטסט',
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
    'saves new test and updates current date',
    (tester) async {
      final repository =
          FakeVehicleRepository();

      final documentRepository =
          FakeVehicleDocumentRepository();

      final vehicle =
          createVehicle(
        testExpiryDate:
            DateTime(2028, 5, 10),
      );

      await tester.pumpWidget(
        buildTestWidget(
          vehicle: vehicle,
          repository: repository,
          documentRepository:
              documentRepository,
        ),
      );

      await tester.tap(
        find.text('טסט חדש'),
      );

      await acceptDatePicker(
        tester,
      );

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
        VehicleEventType.test,
      );

      expect(
        vehicle.testExpiryDate,
        DateTime(2028, 5, 10),
      );

      expect(
        vehicle.events.length,
        1,
      );

      await clearSnackBar(tester);
    },
  );

  testWidgets(
    'saves test document with correct category and name',
    (tester) async {
      final repository =
          FakeVehicleRepository();

      final documentRepository =
          FakeVehicleDocumentRepository();

      await tester.pumpWidget(
        buildTestWidget(
          vehicle: createVehicle(
            testExpiryDate:
                DateTime(2028, 5, 10),
          ),
          repository: repository,
          documentRepository:
              documentRepository,
          documentPicker: () async {
            return PlatformFile(
              name: 'test.pdf',
              size: 2,
              bytes:
                  Uint8List.fromList(
                [1, 2],
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
        find.text('טסט חדש'),
      );

      await acceptDatePicker(
        tester,
      );

      await tester.tap(
        find.text('אישור ושמירה'),
      );

      await tester.pumpAndSettle();

      expect(
        documentRepository.uploadCalls,
        1,
      );

      expect(
        documentRepository.lastCategory,
        VehicleDocumentCategory.test,
      );

      expect(
        documentRepository.lastEventId,
        'event-1',
      );

      expect(
        documentRepository
            .lastDisplayName,
        'טסט 2028 - 10/05/2028',
      );

      await clearSnackBar(tester);
    },
  );
}