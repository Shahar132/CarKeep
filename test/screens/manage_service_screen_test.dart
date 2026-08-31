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
import '../../lib/screens/manage_service_screen.dart';

class FakeVehicleRepository
    extends VehicleRepository {
  int addEventCalls = 0;
  int updateVehicleCalls = 0;

  VehicleEvent? lastAddedEvent;

  @override
  Future<VehicleEvent> addVehicleEvent(
    VehicleEvent event,
  ) async {
    addEventCalls++;
    lastAddedEvent = event;

    return VehicleEvent(
      id: 'service-event-1',
      vehicleId: event.vehicleId,
      type: event.type,
      date: event.date,
      title: event.title,
      mileage: event.mileage,
      cost: event.cost,
      notes: event.notes,
      serviceIntervalKm:
          event.serviceIntervalKm,
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
  ) async {}
}

class FakeVehicleDocumentRepository
    extends VehicleDocumentRepository {
  int uploadCalls = 0;

  VehicleDocumentCategory?
      lastCategory;

  String? lastEventId;
  String? lastDisplayName;

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

    lastCategory = category;
    lastEventId = eventId;
    lastDisplayName = displayName;

    return VehicleDocument(
      id: 'document-1',
      vehicleId: vehicleId,
      eventId: eventId,
      displayName: displayName,
      originalFileName:
          originalFileName,
      filePath:
          '$vehicleId/service.pdf',
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
}) {
  return Vehicle(
    id: 'vehicle-1',
    license: '12345678',
    manufacturer: 'Toyota',
    model: 'Corolla',
    year: 2022,
    mileage: 70000,
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
    home: ManageServiceScreen(
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

Future<void> pumpServiceScreen(
  WidgetTester tester, {
  required Vehicle vehicle,
  required FakeVehicleRepository
      repository,
  required FakeVehicleDocumentRepository
      documentRepository,
  Future<PlatformFile?> Function()?
      documentPicker,
}) async {
  await tester.binding.setSurfaceSize(
    const Size(
      800,
      1800,
    ),
  );

  addTearDown(() async {
    await tester.binding
        .setSurfaceSize(null);
  });

  await tester.pumpWidget(
    buildTestWidget(
      vehicle: vehicle,
      repository: repository,
      documentRepository:
          documentRepository,
      documentPicker:
          documentPicker,
    ),
  );

  await tester.pump();
}

Future<void> chooseServiceDate(
  WidgetTester tester,
) async {
  await tester.tap(
    find.text('בחר תאריך'),
  );

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
    'owner sees service edit form',
    (tester) async {
      final repository =
          FakeVehicleRepository();

      final documentRepository =
          FakeVehicleDocumentRepository();

      await pumpServiceScreen(
        tester,
        vehicle: createVehicle(),
        repository: repository,
        documentRepository:
            documentRepository,
      );

      expect(
        find.text('טיפול חדש'),
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
        find.text(
          'קילומטראז׳ בזמן הטיפול',
        ),
        findsOneWidget,
      );

      expect(
        find.text(
          'מרווח טיפול בק"מ',
        ),
        findsOneWidget,
      );

      expect(
        find.text('בחר מסמך'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'member sees read only service details',
    (tester) async {
      final repository =
          FakeVehicleRepository();

      final documentRepository =
          FakeVehicleDocumentRepository();

      final vehicle =
          createVehicle(
        role:
            VehicleMemberRole.member,
      );

      vehicle.lastServiceDate =
          DateTime(2026, 8, 30);

      vehicle.lastServiceMileage =
          60000;

      vehicle.serviceIntervalKm =
          15000;

      await pumpServiceScreen(
        tester,
        vehicle: vehicle,
        repository: repository,
        documentRepository:
            documentRepository,
      );

      expect(
        find.text('מצב צפייה בלבד'),
        findsOneWidget,
      );

      expect(
        find.text('30/08/2026'),
        findsOneWidget,
      );

      expect(
        find.text('60,000 ק"מ'),
        findsOneWidget,
      );

      expect(
        find.text('15,000 ק"מ'),
        findsOneWidget,
      );

      expect(
        find.text('שמור'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'save without service date shows message',
    (tester) async {
      final repository =
          FakeVehicleRepository();

      final documentRepository =
          FakeVehicleDocumentRepository();

      await pumpServiceScreen(
        tester,
        vehicle: createVehicle(),
        repository: repository,
        documentRepository:
            documentRepository,
      );

      await tester.tap(
        find.text('שמור'),
      );

      await tester.pump();

      expect(
        find.text(
          'יש לבחור תאריך טיפול',
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
    'mileage field is required',
    (tester) async {
      final repository =
          FakeVehicleRepository();

      final documentRepository =
          FakeVehicleDocumentRepository();

      await pumpServiceScreen(
        tester,
        vehicle: createVehicle(),
        repository: repository,
        documentRepository:
            documentRepository,
      );

      await chooseServiceDate(
        tester,
      );

      await tester.tap(
        find.text('שמור'),
      );

      await tester.pump();

      expect(
        find.text(
          'יש להזין קילומטראז׳',
        ),
        findsOneWidget,
      );

      expect(
        repository.addEventCalls,
        0,
      );
    },
  );

  testWidgets(
    'invalid service interval shows validation error',
    (tester) async {
      final repository =
          FakeVehicleRepository();

      final documentRepository =
          FakeVehicleDocumentRepository();

      await pumpServiceScreen(
        tester,
        vehicle: createVehicle(),
        repository: repository,
        documentRepository:
            documentRepository,
      );

      await chooseServiceDate(
        tester,
      );

      final fields =
          find.byType(
        TextFormField,
      );

      await tester.enterText(
        fields.at(0),
        '60000',
      );

      await tester.enterText(
        fields.at(1),
        '0',
      );

      await tester.tap(
        find.text('שמור'),
      );

      await tester.pump();

      expect(
        find.text(
          'יש להזין מרווח תקין',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'service document can be selected and removed',
    (tester) async {
      final repository =
          FakeVehicleRepository();

      final documentRepository =
          FakeVehicleDocumentRepository();

      await pumpServiceScreen(
        tester,
        vehicle: createVehicle(),
        repository: repository,
        documentRepository:
            documentRepository,
        documentPicker: () async {
          return PlatformFile(
            name:
                'service_invoice.pdf',
            size: 3,
            bytes:
                Uint8List.fromList(
              [1, 2, 3],
            ),
          );
        },
      );

      await tester.tap(
        find.text('בחר מסמך'),
      );

      await tester.pumpAndSettle();

      expect(
        find.text(
          'service_invoice.pdf',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byIcon(Icons.close),
      );

      await tester.pump();

      expect(
        find.text(
          'service_invoice.pdf',
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'successful service save updates current service',
    (tester) async {
      final repository =
          FakeVehicleRepository();

      final documentRepository =
          FakeVehicleDocumentRepository();

      final vehicle =
          createVehicle();

      await pumpServiceScreen(
        tester,
        vehicle: vehicle,
        repository: repository,
        documentRepository:
            documentRepository,
      );

      await chooseServiceDate(
        tester,
      );

      final fields =
          find.byType(
        TextFormField,
      );

      await tester.enterText(
        fields.at(0),
        '60000',
      );

      await tester.enterText(
        fields.at(1),
        '15000',
      );

      await tester.tap(
        find.text('שמור'),
      );

      await tester.pumpAndSettle();

      expect(
        find.text(
          'אישור פרטי הטיפול',
        ),
        findsOneWidget,
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
        VehicleEventType.service,
      );

      expect(
        vehicle.lastServiceMileage,
        60000,
      );

      expect(
        vehicle.serviceIntervalKm,
        15000,
      );

      expect(
        vehicle.lastServiceDate,
        isNotNull,
      );
    },
  );

  testWidgets(
    'service document uses correct category and event id',
    (tester) async {
      final repository =
          FakeVehicleRepository();

      final documentRepository =
          FakeVehicleDocumentRepository();

      await pumpServiceScreen(
        tester,
        vehicle: createVehicle(),
        repository: repository,
        documentRepository:
            documentRepository,
        documentPicker: () async {
          return PlatformFile(
            name: 'service.pdf',
            size: 2,
            bytes:
                Uint8List.fromList(
              [1, 2],
            ),
          );
        },
      );

      await chooseServiceDate(
        tester,
      );

      final fields =
          find.byType(
        TextFormField,
      );

      await tester.enterText(
        fields.at(0),
        '60000',
      );

      await tester.enterText(
        fields.at(1),
        '15000',
      );

      await tester.tap(
        find.text('בחר מסמך'),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.text('שמור'),
      );

      await tester.pumpAndSettle();

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
        VehicleDocumentCategory.service,
      );

      expect(
        documentRepository.lastEventId,
        'service-event-1',
      );

      expect(
        documentRepository
            .lastDisplayName,
        contains(
          'טיפול 60,000 ק"מ',
        ),
      );
    },
  );
}