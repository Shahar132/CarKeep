import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/vehicle.dart';
import '../../lib/models/vehicle_event.dart';
import '../../lib/models/vehicle_member.dart';
import '../../lib/screens/vehicle_history_screen.dart';

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
    mileage: 70000,
    currentUserRole: role,
  );
}

List<VehicleEvent> createEvents() {
  return [
    VehicleEvent(
      id: 'service-1',
      vehicleId: 'vehicle-1',
      type: VehicleEventType.service,
      date: DateTime(2026, 8, 30),
      title: 'טיפול 60,000',
      mileage: 60000,
      serviceIntervalKm: 15000,
      cost: 750.50,
      notes: 'טיפול תקופתי',
    ),
    VehicleEvent(
      id: 'test-1',
      vehicleId: 'vehicle-1',
      type: VehicleEventType.test,
      date: DateTime(2027, 10, 31),
      title: 'טסט 2027',
    ),
    VehicleEvent(
      id: 'license-1',
      vehicleId: 'vehicle-1',
      type:
          VehicleEventType.vehicleLicense,
      date: DateTime(2028, 8, 31),
      title: 'חידוש רישיון רכב',
    ),
  ];
}

Widget buildTestWidget({
  required Vehicle vehicle,
  required VehicleEventType eventType,
  required String title,
  List<VehicleEvent>? events,
}) {
  return MaterialApp(
    home: VehicleHistoryScreen(
      vehicle: vehicle,
      eventType: eventType,
      title: title,
      eventsLoader:
          (_) async => events ?? [],
    ),
  );
}

void main() {
  group(
    'VehicleHistoryScreen - loading',
    () {
      testWidgets(
        'shows empty state when history is empty',
        (tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              vehicle:
                  createVehicle(),
              eventType:
                  VehicleEventType.test,
              title:
                  'היסטוריית טסטים',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'עדיין אין פריטים בהיסטוריית טסטים',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'shows vehicle identification error when vehicle id is null',
        (tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              vehicle:
                  createVehicle(
                id: null,
              ),
              eventType:
                  VehicleEventType.test,
              title:
                  'היסטוריית טסטים',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'לא הצלחנו לזהות את הרכב.',
            ),
            findsOneWidget,
          );

          expect(
            find.text('נסה שוב'),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'shows loading error when loader throws',
        (tester) async {
          final vehicle =
              createVehicle();

          await tester.pumpWidget(
            MaterialApp(
              home:
                  VehicleHistoryScreen(
                vehicle: vehicle,
                eventType:
                    VehicleEventType.test,
                title:
                    'היסטוריית טסטים',
                eventsLoader:
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
              'לא הצלחנו לטעון את ההיסטוריה.',
            ),
            findsOneWidget,
          );

          expect(
            find.text('נסה שוב'),
            findsOneWidget,
          );
        },
      );
    },
  );

  group(
    'VehicleHistoryScreen - filtering',
    () {
      testWidgets(
        'shows only requested event type',
        (tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              vehicle:
                  createVehicle(),
              eventType:
                  VehicleEventType.test,
              title:
                  'היסטוריית טסטים',
              events:
                  createEvents(),
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text('טסט 2027'),
            findsOneWidget,
          );

          expect(
            find.text(
              'טיפול 60,000',
            ),
            findsNothing,
          );

          expect(
            find.text(
              'חידוש רישיון רכב',
            ),
            findsNothing,
          );
        },
      );

      testWidgets(
        'shows event notes and formatted service details',
        (tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              vehicle:
                  createVehicle(),
              eventType:
                  VehicleEventType.service,
              title:
                  'היסטוריית טיפולים',
              events:
                  createEvents(),
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              '30/08/2026 • '
              '60,000 ק"מ • '
              'מרווח: 15,000 ק"מ • '
              'עלות: 750.50 ₪',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'טיפול תקופתי',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'shows newest matching event before older event',
        (tester) async {
          final events = [
            VehicleEvent(
              id: 'test-old',
              vehicleId: 'vehicle-1',
              type:
                  VehicleEventType.test,
              date:
                  DateTime(2026, 1, 1),
              title: 'טסט ישן',
            ),
            VehicleEvent(
              id: 'test-new',
              vehicleId: 'vehicle-1',
              type:
                  VehicleEventType.test,
              date:
                  DateTime(2028, 1, 1),
              title: 'טסט חדש',
            ),
          ];

          await tester.pumpWidget(
            buildTestWidget(
              vehicle:
                  createVehicle(),
              eventType:
                  VehicleEventType.test,
              title:
                  'היסטוריית טסטים',
              events: events,
            ),
          );

          await tester.pumpAndSettle();

          final newPosition =
              tester.getTopLeft(
            find.text('טסט חדש'),
          );

          final oldPosition =
              tester.getTopLeft(
            find.text('טסט ישן'),
          );

          expect(
            newPosition.dy <
                oldPosition.dy,
            isTrue,
          );
        },
      );
    },
  );

  group(
    'VehicleHistoryScreen - permissions',
    () {
      testWidgets(
        'owner sees delete button',
        (tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              vehicle:
                  createVehicle(
                role:
                    VehicleMemberRole.owner,
              ),
              eventType:
                  VehicleEventType.test,
              title:
                  'היסטוריית טסטים',
              events:
                  createEvents(),
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.byIcon(
              Icons.delete_outline,
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'admin sees delete button',
        (tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              vehicle:
                  createVehicle(
                role:
                    VehicleMemberRole.admin,
              ),
              eventType:
                  VehicleEventType.test,
              title:
                  'היסטוריית טסטים',
              events:
                  createEvents(),
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.byIcon(
              Icons.delete_outline,
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'member sees read only mode and no delete button',
        (tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              vehicle:
                  createVehicle(
                role:
                    VehicleMemberRole.member,
              ),
              eventType:
                  VehicleEventType.test,
              title:
                  'היסטוריית טסטים',
              events:
                  createEvents(),
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'מצב צפייה בלבד',
            ),
            findsOneWidget,
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
        'delete button opens confirmation dialog',
        (tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              vehicle:
                  createVehicle(
                role:
                    VehicleMemberRole.owner,
              ),
              eventType:
                  VehicleEventType.test,
              title:
                  'היסטוריית טסטים',
              events:
                  createEvents(),
            ),
          );

          await tester.pumpAndSettle();

          await tester.tap(
            find.byIcon(
              Icons.delete_outline,
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'מחיקת פריט',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'האם אתה בטוח שברצונך למחוק '
              'את הפריט מההיסטוריה?',
            ),
            findsOneWidget,
          );

          expect(
            find.text('ביטול'),
            findsOneWidget,
          );

          expect(
            find.text('מחק'),
            findsOneWidget,
          );

          // Cancel so the test does not call
          // the real repository.
          await tester.tap(
            find.text('ביטול'),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'מחיקת פריט',
            ),
            findsNothing,
          );
        },
      );
    },
  );

  group(
    'VehicleHistoryScreen - app bar',
    () {
      testWidgets(
        'shows supplied history title',
        (tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              vehicle:
                  createVehicle(),
              eventType:
                  VehicleEventType.vehicleLicense,
              title:
                  'היסטוריית רישיונות רכב',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'היסטוריית רישיונות רכב',
            ),
            findsOneWidget,
          );
        },
      );
    },
  );
}