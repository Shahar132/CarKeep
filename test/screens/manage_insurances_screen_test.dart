import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/vehicle.dart';
import '../../lib/models/vehicle_document.dart';
import '../../lib/models/vehicle_event.dart';
import '../../lib/models/vehicle_insurance.dart';
import '../../lib/models/vehicle_member.dart';
import '../../lib/repositories/vehicle_document_repository.dart';
import '../../lib/repositories/vehicle_repository.dart';
import '../../lib/screens/manage_insurances_screen.dart';

class FakeVehicleRepository
    extends VehicleRepository {
  int addEventCalls = 0;
  int saveInsuranceCalls = 0;

  VehicleEvent? lastAddedEvent;
  VehicleInsurance? lastInsurance;

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
      insuranceType:
          event.insuranceType,
    );
  }

  @override
  Future<VehicleInsurance>
      saveInsurance(
    VehicleInsurance insurance,
  ) async {
    saveInsuranceCalls++;
    lastInsurance = insurance;

    return VehicleInsurance(
      id:
          insurance.id ??
          'insurance-1',
      vehicleId:
          insurance.vehicleId,
      type:
          insurance.type,
      expiryDate:
          insurance.expiryDate,
      showOnHome:
          insurance.showOnHome,
    );
  }

  @override
  Future<void> deleteVehicleEvent(
    String eventId,
  ) async {}

  @override
  Future<void> deleteInsurance(
    String insuranceId,
  ) async {}
}

class FakeVehicleDocumentRepository
    extends VehicleDocumentRepository {
  int uploadCalls = 0;

  VehicleDocumentCategory?
      lastCategory;

  String? lastDisplayName;
  String? lastEventId;

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
    lastDisplayName = displayName;
    lastEventId = eventId;

    return VehicleDocument(
      id: 'document-1',
      vehicleId: vehicleId,
      eventId: eventId,
      displayName: displayName,
      originalFileName:
          originalFileName,
      filePath:
          '$vehicleId/insurance.pdf',
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
  List<VehicleInsurance>?
      insurances,
}) {
  return Vehicle(
    id: 'vehicle-1',
    license: '12345678',
    manufacturer: 'Toyota',
    model: 'Corolla',
    year: 2022,
    mileage: 60000,
    currentUserRole: role,
    insurances: insurances,
  );
}

Widget buildTestWidget({
  required Vehicle vehicle,
  required FakeVehicleRepository
      repository,
  required FakeVehicleDocumentRepository
      documentRepository,
  Future<PlatformFile?> Function(
    InsuranceType type,
  )? documentPicker,
}) {
  return MaterialApp(
    home:
        ManageInsurancesScreen(
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

Future<void> pumpInsuranceScreen(
  WidgetTester tester, {
  required Vehicle vehicle,
  required FakeVehicleRepository
      repository,
  required FakeVehicleDocumentRepository
      documentRepository,
  Future<PlatformFile?> Function(
    InsuranceType type,
  )? documentPicker,
}) async {
  await tester.binding.setSurfaceSize(
    const Size(
      800,
      2200,
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
    'shows all three insurance types',
    (tester) async {
      final repository =
          FakeVehicleRepository();

      final documentRepository =
          FakeVehicleDocumentRepository();

      await pumpInsuranceScreen(
        tester,
        vehicle: createVehicle(),
        repository: repository,
        documentRepository:
            documentRepository,
      );

      expect(
        find.text('ביטוח חובה'),
        findsOneWidget,
      );

      expect(
        find.text('ביטוח מקיף'),
        findsOneWidget,
      );

      expect(
        find.text('ביטוח צד ג׳'),
        findsOneWidget,
      );

      expect(
        find.text(
          'היסטוריית ביטוחים',
        ),
        findsOneWidget,
      );

      expect(
        find.text('הוסף'),
        findsNWidgets(3),
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

      await pumpInsuranceScreen(
        tester,
        vehicle: createVehicle(
          role:
              VehicleMemberRole.member,
        ),
        repository: repository,
        documentRepository:
            documentRepository,
      );

      expect(
        find.text('מצב צפייה בלבד'),
        findsOneWidget,
      );

      expect(
        find.text('הוסף'),
        findsNothing,
      );

      expect(
        find.text('בחר מסמך'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'existing insurance shows expiry and renewal action',
    (tester) async {
      final repository =
          FakeVehicleRepository();

      final documentRepository =
          FakeVehicleDocumentRepository();

      await pumpInsuranceScreen(
        tester,
        vehicle: createVehicle(
          insurances: [
            VehicleInsurance(
              id: 'insurance-1',
              vehicleId:
                  'vehicle-1',
              type:
                  InsuranceType.mandatory,
              expiryDate:
                  DateTime(
                2028,
                12,
                31,
              ),
              showOnHome: true,
            ),
          ],
        ),
        repository: repository,
        documentRepository:
            documentRepository,
      );

      expect(
        find.text(
          'תוקף: 31/12/2028',
        ),
        findsOneWidget,
      );

      expect(
        find.text('חידוש'),
        findsOneWidget,
      );

      expect(
        find.text('הוסף'),
        findsNWidgets(2),
      );
    },
  );

  testWidgets(
    'document picker is connected to selected insurance type',
    (tester) async {
      final repository =
          FakeVehicleRepository();

      final documentRepository =
          FakeVehicleDocumentRepository();

      InsuranceType? pickedType;

      await pumpInsuranceScreen(
        tester,
        vehicle: createVehicle(),
        repository: repository,
        documentRepository:
            documentRepository,
        documentPicker:
            (type) async {
          pickedType = type;

          return PlatformFile(
            name:
                'mandatory.pdf',
            size: 2,
            bytes:
                Uint8List.fromList(
              [1, 2],
            ),
          );
        },
      );

      await tester.tap(
        find.text('בחר מסמך').first,
      );

      await tester.pumpAndSettle();

      expect(
        pickedType,
        InsuranceType.mandatory,
      );

      expect(
        find.text(
          'mandatory.pdf',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'canceling insurance confirmation does not save',
    (tester) async {
      final repository =
          FakeVehicleRepository();

      final documentRepository =
          FakeVehicleDocumentRepository();

      await pumpInsuranceScreen(
        tester,
        vehicle: createVehicle(),
        repository: repository,
        documentRepository:
            documentRepository,
      );

      await tester.tap(
        find.text('הוסף').first,
      );

      await acceptDatePicker(
        tester,
      );

      expect(
        find.text(
          'אישור פרטי הביטוח',
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
        repository.saveInsuranceCalls,
        0,
      );
    },
  );

  testWidgets(
    'saves mandatory insurance correctly',
    (tester) async {
      final repository =
          FakeVehicleRepository();

      final documentRepository =
          FakeVehicleDocumentRepository();

      final vehicle =
          createVehicle(
        insurances: [
          VehicleInsurance(
            id: 'old-insurance',
            vehicleId: 'vehicle-1',
            type:
                InsuranceType.mandatory,
            expiryDate:
                DateTime(
              2028,
              12,
              31,
            ),
          ),
        ],
      );

      await pumpInsuranceScreen(
        tester,
        vehicle: vehicle,
        repository: repository,
        documentRepository:
            documentRepository,
      );

      await tester.tap(
        find.text('חידוש'),
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
        repository.saveInsuranceCalls,
        1,
      );

      expect(
        repository.lastAddedEvent?.type,
        VehicleEventType.insurance,
      );

      expect(
        repository
            .lastAddedEvent
            ?.insuranceType,
        InsuranceType.mandatory,
      );

      expect(
        vehicle.events.length,
        1,
      );

      expect(
        vehicle.insurances
            .first
            .type,
        InsuranceType.mandatory,
      );

      await clearSnackBar(tester);
    },
  );

  testWidgets(
    'insurance document uses insurance category and automatic name',
    (tester) async {
      final repository =
          FakeVehicleRepository();

      final documentRepository =
          FakeVehicleDocumentRepository();

      await pumpInsuranceScreen(
        tester,
        vehicle: createVehicle(
          insurances: [
            VehicleInsurance(
              id: 'insurance-1',
              vehicleId:
                  'vehicle-1',
              type:
                  InsuranceType.mandatory,
              expiryDate:
                  DateTime(
                2028,
                12,
                31,
              ),
            ),
          ],
        ),
        repository: repository,
        documentRepository:
            documentRepository,
        documentPicker:
            (_) async {
          return PlatformFile(
            name:
                'insurance.pdf',
            size: 2,
            bytes:
                Uint8List.fromList(
              [1, 2],
            ),
          );
        },
      );

      await tester.tap(
        find.text('בחר מסמך').first,
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.text('חידוש'),
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
        VehicleDocumentCategory
            .insurance,
      );

      expect(
        documentRepository.lastEventId,
        'event-1',
      );

      expect(
        documentRepository
            .lastDisplayName,
        'ביטוח חובה 2028 - '
        '31/12/2028',
      );

      await clearSnackBar(tester);
    },
  );
}