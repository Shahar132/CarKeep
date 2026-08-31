import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/vehicle.dart';
import '../../lib/models/vehicle_document.dart';
import '../../lib/models/vehicle_member.dart';
import '../../lib/screens/vehicle_documents_screen.dart';

Vehicle createVehicle({
  VehicleMemberRole role =
      VehicleMemberRole.owner,
  String? id = 'vehicle-1',
}) {
  return Vehicle(
    id: id,
    license: '12345678',
    manufacturer: 'Toyota',
    model: 'Corolla',
    year: 2022,
    mileage: 60000,
    currentUserRole: role,
  );
}

List<VehicleDocument>
    createTestDocuments() {
  return const [
    VehicleDocument(
      id: 'document-1',
      vehicleId: 'vehicle-1',
      eventId: 'event-1',
      displayName:
          'רישיון רכב 2028 - 31/08/2028',
      originalFileName:
          'license_test.pdf',
      filePath:
          'vehicle-1/license_test.pdf',
      category:
          VehicleDocumentCategory
              .vehicleLicense,
    ),
    VehicleDocument(
      id: 'document-2',
      vehicleId: 'vehicle-1',
      eventId: 'event-2',
      displayName:
          'טסט 2027 - 31/10/2027',
      originalFileName:
          'test_test.pdf',
      filePath:
          'vehicle-1/test_test.pdf',
      category:
          VehicleDocumentCategory.test,
    ),
    VehicleDocument(
      id: 'document-3',
      vehicleId: 'vehicle-1',
      eventId: 'event-3',
      displayName:
          'ביטוח חובה 2027 - 31/12/2027',
      originalFileName:
          'insurance_test.jpg',
      filePath:
          'vehicle-1/insurance_test.jpg',
      category:
          VehicleDocumentCategory
              .insurance,
    ),
    VehicleDocument(
      id: 'document-4',
      vehicleId: 'vehicle-1',
      eventId: 'event-4',
      displayName:
          'טיפול 60,000 ק"מ - 30/08/2026',
      originalFileName:
          'service_test.png',
      filePath:
          'vehicle-1/service_test.png',
      category:
          VehicleDocumentCategory.service,
    ),
    VehicleDocument(
      id: 'document-5',
      vehicleId: 'vehicle-1',
      displayName:
          'מסמך כללי',
      originalFileName:
          'other.pdf',
      filePath:
          'vehicle-1/other.pdf',
      category:
          VehicleDocumentCategory.other,
    ),
  ];
}

Widget buildTestWidget({
  required Vehicle vehicle,
  List<VehicleDocument>? documents,
  bool embedded = false,
}) {
  return MaterialApp(
    home: VehicleDocumentsScreen(
      vehicle: vehicle,
      embedded: embedded,
      documentsLoader:
          (_) async =>
              documents ?? [],
    ),
  );
}

Future<void> pumpDocumentsScreen(
  WidgetTester tester, {
  required Vehicle vehicle,
  List<VehicleDocument>? documents,
  bool embedded = false,
}) async {
  await tester.binding.setSurfaceSize(
    const Size(
      800,
      2400,
    ),
  );

  addTearDown(() async {
    await tester.binding.setSurfaceSize(
      null,
    );
  });

  await tester.pumpWidget(
    buildTestWidget(
      vehicle: vehicle,
      documents: documents,
      embedded: embedded,
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  group(
    'VehicleDocumentsScreen - loading',
    () {
      testWidgets(
        'shows empty state when there are no documents',
        (tester) async {
          await pumpDocumentsScreen(
            tester,
            vehicle:
                createVehicle(),
          );

          expect(
            find.text(
              'עדיין אין מסמכים לרכב',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'אפשר להעלות PDF או תמונה.',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'shows vehicle identification error when vehicle id is null',
        (tester) async {
          await pumpDocumentsScreen(
            tester,
            vehicle:
                createVehicle(
              id: null,
            ),
          );

          expect(
            find.text(
              'לא הצלחנו לזהות את הרכב.',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'נסה שוב',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'shows loading error when loader throws',
        (tester) async {
          await tester.binding
              .setSurfaceSize(
            const Size(
              800,
              1200,
            ),
          );

          addTearDown(() async {
            await tester.binding
                .setSurfaceSize(
              null,
            );
          });

          final vehicle =
              createVehicle();

          await tester.pumpWidget(
            MaterialApp(
              home:
                  VehicleDocumentsScreen(
                vehicle: vehicle,
                documentsLoader:
                    (_) async {
                  throw Exception(
                    'test error',
                  );
                },
              ),
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'לא הצלחנו לטעון את המסמכים.',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'נסה שוב',
            ),
            findsOneWidget,
          );
        },
      );
    },
  );

  group(
    'VehicleDocumentsScreen - categories',
    () {
      testWidgets(
        'shows all document category headers',
        (tester) async {
          await pumpDocumentsScreen(
            tester,
            vehicle:
                createVehicle(),
            documents:
                createTestDocuments(),
          );

          expect(
            find.text(
              'רישיונות רכב',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'טסטים',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'ביטוחים',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'טיפולים',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'מסמכים אחרים',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'shows documents under their categories',
        (tester) async {
          await pumpDocumentsScreen(
            tester,
            vehicle:
                createVehicle(),
            documents:
                createTestDocuments(),
          );

          expect(
            find.text(
              'רישיון רכב 2028 - 31/08/2028',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'טסט 2027 - 31/10/2027',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'ביטוח חובה 2027 - 31/12/2027',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'טיפול 60,000 ק"מ - 30/08/2026',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'מסמך כללי',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'does not show empty categories',
        (tester) async {
          const document =
              VehicleDocument(
            id: 'document-1',
            vehicleId: 'vehicle-1',
            displayName:
                'טסט',
            filePath:
                'vehicle-1/test.pdf',
            category:
                VehicleDocumentCategory
                    .test,
          );

          await pumpDocumentsScreen(
            tester,
            vehicle:
                createVehicle(),
            documents:
                const [
              document,
            ],
          );

          expect(
            find.text(
              'טסטים',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'רישיונות רכב',
            ),
            findsNothing,
          );

          expect(
            find.text(
              'ביטוחים',
            ),
            findsNothing,
          );

          expect(
            find.text(
              'טיפולים',
            ),
            findsNothing,
          );

          expect(
            find.text(
              'מסמכים אחרים',
            ),
            findsNothing,
          );
        },
      );
    },
  );

  group(
    'VehicleDocumentsScreen - permissions',
    () {
      testWidgets(
        'owner sees upload button',
        (tester) async {
          await pumpDocumentsScreen(
            tester,
            vehicle:
                createVehicle(
              role:
                  VehicleMemberRole.owner,
            ),
          );

          expect(
            find.text(
              'העלה מסמך',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'admin sees upload button',
        (tester) async {
          await pumpDocumentsScreen(
            tester,
            vehicle:
                createVehicle(
              role:
                  VehicleMemberRole.admin,
            ),
          );

          expect(
            find.text(
              'העלה מסמך',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'member sees read only message and no upload button',
        (tester) async {
          await pumpDocumentsScreen(
            tester,
            vehicle:
                createVehicle(
              role:
                  VehicleMemberRole.member,
            ),
            documents:
                createTestDocuments(),
          );

          expect(
            find.text(
              'מצב צפייה בלבד',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'העלה מסמך',
            ),
            findsNothing,
          );

          expect(
            find.byIcon(
              Icons.delete_outline,
            ),
            findsNothing,
          );
        },
      );

      testWidgets(
        'owner sees delete buttons for all documents',
        (tester) async {
          await pumpDocumentsScreen(
            tester,
            vehicle:
                createVehicle(
              role:
                  VehicleMemberRole.owner,
            ),
            documents:
                createTestDocuments(),
          );

          expect(
            find.byIcon(
              Icons.delete_outline,
            ),
            findsNWidgets(5),
          );
        },
      );
    },
  );

  group(
    'VehicleDocumentsScreen - document icons',
    () {
      testWidgets(
        'shows PDF icons for PDF files',
        (tester) async {
          await pumpDocumentsScreen(
            tester,
            vehicle:
                createVehicle(),
            documents:
                createTestDocuments(),
          );

          expect(
            find.byIcon(
              Icons
                  .picture_as_pdf_outlined,
            ),
            findsNWidgets(3),
          );
        },
      );

      testWidgets(
        'shows image icons for image files',
        (tester) async {
          await pumpDocumentsScreen(
            tester,
            vehicle:
                createVehicle(),
            documents:
                createTestDocuments(),
          );

          expect(
            find.byIcon(
              Icons.image_outlined,
            ),
            findsNWidgets(2),
          );
        },
      );
    },
  );

  group(
    'VehicleDocumentsScreen - actions',
    () {
      testWidgets(
        'tapping document opens view and download actions',
        (tester) async {
          final documents =
              createTestDocuments();

          await pumpDocumentsScreen(
            tester,
            vehicle:
                createVehicle(),
            documents: [
              documents.first,
            ],
          );

          await tester.tap(
            find.text(
              'רישיון רכב 2028 - 31/08/2028',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'צפה במסמך',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'הורד מחדש',
            ),
            findsOneWidget,
          );

          // Close the bottom sheet
          // without calling Storage.
          Navigator.of(
            tester.element(
              find.text(
                'צפה במסמך',
              ),
            ),
          ).pop();

          await tester.pumpAndSettle();
        },
      );

      testWidgets(
        'delete button opens confirmation dialog',
        (tester) async {
          final documents =
              createTestDocuments();

          await pumpDocumentsScreen(
            tester,
            vehicle:
                createVehicle(
              role:
                  VehicleMemberRole.owner,
            ),
            documents: [
              documents.first,
            ],
          );

          await tester.tap(
            find.byIcon(
              Icons.delete_outline,
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'מחיקת מסמך',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'האם למחוק את '
              '"רישיון רכב 2028 - 31/08/2028"?',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'ביטול',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'מחק',
            ),
            findsOneWidget,
          );

          // Cancel so we do not call
          // the real repository.
          await tester.tap(
            find.text(
              'ביטול',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'מחיקת מסמך',
            ),
            findsNothing,
          );
        },
      );

      testWidgets(
        'embedded screen does not show app bar',
        (tester) async {
          await pumpDocumentsScreen(
            tester,
            vehicle:
                createVehicle(),
            embedded: true,
          );

          expect(
            find.byType(
              AppBar,
            ),
            findsNothing,
          );
        },
      );

      testWidgets(
        'non embedded screen shows documents app bar',
        (tester) async {
          await pumpDocumentsScreen(
            tester,
            vehicle:
                createVehicle(),
          );

          expect(
            find.byType(
              AppBar,
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'מסמכי הרכב',
            ),
            findsOneWidget,
          );
        },
      );
    },
  );
}