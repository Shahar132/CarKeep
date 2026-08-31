import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/vehicle.dart';
import '../../lib/models/vehicle_insurance.dart';
import '../../lib/models/vehicle_member.dart';
import '../../lib/screens/vehicle_details_screen.dart';

Vehicle createTestVehicle({
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
    testExpiryDate:
        DateTime(2027, 10, 31),
    vehicleLicenseExpiryDate:
        DateTime(2028, 8, 31),
    lastServiceDate:
        DateTime(2026, 8, 30),
    lastServiceMileage: 60000,
    serviceIntervalKm: 15000,
    currentUserRole: role,
    insurances: [
      VehicleInsurance(
        id: 'insurance-1',
        vehicleId: 'vehicle-1',
        type:
            InsuranceType.mandatory,
        expiryDate:
            DateTime(2027, 12, 31),
      ),
    ],
  );
}

Widget buildTestWidget(
  Vehicle vehicle,
) {
  return MaterialApp(
    home: VehicleDetailsScreen(
      vehicle: vehicle,

      // Prevent AppDrawer from reading
      // Supabase during Widget Tests.
      drawerUserName:
          'Test User',
      drawerUserEmail:
          'test@example.com',
    ),
  );
}

Finder findVehicleMenuButton() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is PopupMenuButton,
    description:
        'vehicle management popup menu',
  );
}

void main() {
  group(
    'VehicleDetailsScreen - overview',
    () {
      testWidgets(
        'shows vehicle information and role',
        (tester) async {
          final vehicle =
              createTestVehicle();

          await tester.pumpWidget(
            buildTestWidget(
              vehicle,
            ),
          );

          await tester.pump();

          expect(
            find.text(
              'Toyota Corolla',
            ),
            findsNWidgets(2),
          );

          expect(
            find.text(
              'התפקיד שלך: בעלים',
            ),
            findsOneWidget,
          );

          expect(
            find.text('טסט'),
            findsOneWidget,
          );

          expect(
            find.text(
              'רישיון רכב',
            ),
            findsOneWidget,
          );

          expect(
            find.text('ביטוחים'),
            findsOneWidget,
          );

          expect(
            find.text(
              'טיפול הבא',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'shows current test expiry date',
        (tester) async {
          final vehicle =
              createTestVehicle();

          await tester.pumpWidget(
            buildTestWidget(
              vehicle,
            ),
          );

          await tester.pump();

          expect(
            find.text(
              'בתוקף עד 31/10/2027',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'shows current vehicle license expiry date',
        (tester) async {
          final vehicle =
              createTestVehicle();

          await tester.pumpWidget(
            buildTestWidget(
              vehicle,
            ),
          );

          await tester.pump();

          expect(
            find.text(
              'בתוקף עד 31/08/2028',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'shows number of insurances',
        (tester) async {
          final vehicle =
              createTestVehicle();

          await tester.pumpWidget(
            buildTestWidget(
              vehicle,
            ),
          );

          await tester.pump();

          expect(
            find.text(
              '1 ביטוחים',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'shows not defined when values are missing',
        (tester) async {
          final vehicle = Vehicle(
            id: 'vehicle-1',
            license: '12345678',
            manufacturer: 'Toyota',
            model: 'Corolla',
            year: 2022,
            mileage: 70000,
            currentUserRole:
                VehicleMemberRole.member,
          );

          await tester.pumpWidget(
            buildTestWidget(
              vehicle,
            ),
          );

          await tester.pump();

          expect(
            find.text(
              'לא הוגדר',
            ),
            findsNWidgets(4),
          );
        },
      );

      testWidgets(
        'shows all vehicles button',
        (tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              createTestVehicle(),
            ),
          );

          await tester.pump();

          expect(
            find.text(
              'לכל הרכבים',
            ),
            findsOneWidget,
          );

          expect(
            find.byIcon(
              Icons
                  .directions_car_outlined,
            ),
            findsOneWidget,
          );
        },
      );
    },
  );

  group(
    'VehicleDetailsScreen - navigation',
    () {
      testWidgets(
        'bottom navigation has correct order',
        (tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              createTestVehicle(),
            ),
          );

          await tester.pump();

          final navigationBar =
              tester.widget<
                  NavigationBar>(
            find.byType(
              NavigationBar,
            ),
          );

          final destinations =
              navigationBar
                  .destinations
                  .cast<
                      NavigationDestination>();

          expect(
            destinations
                .map(
                  (destination) =>
                      destination.label,
                )
                .toList(),
            [
              'סקירה',
              'מסמכים',
              'היסטוריה',
            ],
          );

          expect(
            navigationBar
                .selectedIndex,
            0,
          );
        },
      );

      testWidgets(
        'opens history categories tab',
        (tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              createTestVehicle(),
            ),
          );

          await tester.pump();

          await tester.tap(
            find.text(
              'היסטוריה',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'היסטוריית טיפולים',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'היסטוריית טסטים',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'היסטוריית רישיונות רכב',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'היסטוריית ביטוחים',
            ),
            findsOneWidget,
          );
        },
      );
    },
  );

  group(
    'VehicleDetailsScreen - permissions',
    () {
      testWidgets(
        'owner sees vehicle management menu',
        (tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              createTestVehicle(
                role:
                    VehicleMemberRole
                        .owner,
              ),
            ),
          );

          await tester.pump();

          expect(
            findVehicleMenuButton(),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'owner menu contains member management and delete vehicle',
        (tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              createTestVehicle(
                role:
                    VehicleMemberRole
                        .owner,
              ),
            ),
          );

          await tester.pump();

          await tester.tap(
            findVehicleMenuButton(),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'ניהול משתמשים',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'מחיקת רכב',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'admin does not see owner management menu',
        (tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              createTestVehicle(
                role:
                    VehicleMemberRole
                        .admin,
              ),
            ),
          );

          await tester.pump();

          expect(
            findVehicleMenuButton(),
            findsNothing,
          );

          expect(
            find.text(
              'התפקיד שלך: מנהל',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'member does not see owner management menu',
        (tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              createTestVehicle(
                role:
                    VehicleMemberRole
                        .member,
              ),
            ),
          );

          await tester.pump();

          expect(
            findVehicleMenuButton(),
            findsNothing,
          );

          expect(
            find.text(
              'התפקיד שלך: משתמש',
            ),
            findsOneWidget,
          );
        },
      );
    },
  );
}