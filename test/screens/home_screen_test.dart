import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/vehicle.dart';
import '../../lib/models/vehicle_insurance.dart';
import '../../lib/models/vehicle_member.dart';
import '../../lib/screens/home_screen.dart';
import '../../lib/utils/vehicle_date_utils.dart';

Vehicle createVehicle({
  String id = 'vehicle-1',
  String manufacturer = 'Toyota',
  String model = 'Corolla',
  String license = '12345678',
  VehicleMemberRole role =
      VehicleMemberRole.owner,
  DateTime? testExpiryDate,
  bool showTestOnHome = true,
  DateTime? vehicleLicenseExpiryDate,
  bool showVehicleLicenseOnHome = false,
  List<VehicleInsurance>? insurances,
  DateTime? lastServiceDate,
  int? lastServiceMileage,
  int? serviceIntervalKm,
  bool showServiceOnHome = true,
}) {
  return Vehicle(
    id: id,
    license: license,
    manufacturer: manufacturer,
    model: model,
    year: 2022,
    mileage: 70000,
    testExpiryDate: testExpiryDate,
    showTestOnHome: showTestOnHome,
    vehicleLicenseExpiryDate:
        vehicleLicenseExpiryDate,
    showVehicleLicenseOnHome:
        showVehicleLicenseOnHome,
    insurances: insurances,
    lastServiceDate: lastServiceDate,
    lastServiceMileage:
        lastServiceMileage,
    serviceIntervalKm:
        serviceIntervalKm,
    showServiceOnHome:
        showServiceOnHome,
    currentUserRole: role,
  );
}

Future<void> pumpHomeScreen(
  WidgetTester tester, {
  required Future<List<Vehicle>>
      Function() vehiclesLoader,
  String userDisplayName = 'Test User',
  Widget Function()? addVehicleScreenBuilder,
  Widget Function(Vehicle vehicle)?
      vehicleDetailsScreenBuilder,
  Widget Function()? accountScreenBuilder,
  bool settle = true,
}) async {
  await tester.binding.setSurfaceSize(
    const Size(
      900,
      1800,
    ),
  );

  addTearDown(() async {
    await tester.binding.setSurfaceSize(
      null,
    );
  });

  await tester.pumpWidget(
    MaterialApp(
      home: HomeScreen(
        vehiclesLoader:
            vehiclesLoader,
        userDisplayName:
            userDisplayName,
        drawerUserName:
            'Test User',
        drawerUserEmail:
            'test@example.com',
        addVehicleScreenBuilder:
            addVehicleScreenBuilder,
        vehicleDetailsScreenBuilder:
            vehicleDetailsScreenBuilder,
        accountScreenBuilder:
            accountScreenBuilder,
      ),
    ),
  );

  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> clearSnackBar(
  WidgetTester tester,
) async {
  await tester.pump(
    const Duration(
      seconds: 5,
    ),
  );

  await tester.pumpAndSettle();
}

class FakeAddVehicleScreen
    extends StatelessWidget {
  final Vehicle vehicle;

  const FakeAddVehicleScreen({
    super.key,
    required this.vehicle,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'הוספת רכב בדיקה',
        ),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop<Vehicle>(
              context,
              vehicle,
            );
          },
          child: const Text(
            'החזר רכב חדש',
          ),
        ),
      ),
    );
  }
}

class FakeVehicleDetailsScreen
    extends StatelessWidget {
  final bool result;

  const FakeVehicleDetailsScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'פרטי רכב בדיקה',
        ),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop<bool>(
              context,
              result,
            );
          },
          child: Text(
            result
                ? 'מחק וחזור'
                : 'חזור ללא מחיקה',
          ),
        ),
      ),
    );
  }
}

class FakeAccountScreen
    extends StatelessWidget {
  const FakeAccountScreen({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'חשבון בדיקה',
        ),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'חזור לבית',
          ),
        ),
      ),
    );
  }
}

void main() {
  group(
    'HomeScreen - loading',
    () {
      testWidgets(
        'shows loading indicator while vehicles are loading',
        (tester) async {
          final completer =
              Completer<List<Vehicle>>();

          await pumpHomeScreen(
            tester,
            vehiclesLoader:
                () => completer.future,
            settle: false,
          );

          expect(
            find.byType(
              CircularProgressIndicator,
            ),
            findsOneWidget,
          );

          completer.complete([]);

          await tester.pumpAndSettle();

          expect(
            find.byType(
              CircularProgressIndicator,
            ),
            findsNothing,
          );
        },
      );

      testWidgets(
        'shows empty state when user has no vehicles',
        (tester) async {
          await pumpHomeScreen(
            tester,
            vehiclesLoader:
                () async => [],
          );

          expect(
            find.text(
              'עדיין לא הוספת רכבים',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'shows loading error and retry works',
        (tester) async {
          var loadAttempts = 0;

          final vehicle =
              createVehicle();

          await pumpHomeScreen(
            tester,
            vehiclesLoader:
                () async {
              loadAttempts++;

              if (loadAttempts == 1) {
                throw Exception(
                  'test load error',
                );
              }

              return [
                vehicle,
              ];
            },
          );

          expect(
            find.text(
              'שגיאה בטעינת הרכבים',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'נסה שוב',
            ),
            findsOneWidget,
          );

          expect(
            loadAttempts,
            1,
          );

          await tester.tap(
            find.text(
              'נסה שוב',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            loadAttempts,
            2,
          );

          expect(
            find.text(
              'Toyota Corolla',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'שגיאה בטעינת הרכבים',
            ),
            findsNothing,
          );
        },
      );
    },
  );

  group(
    'HomeScreen - app bar and vehicle card',
    () {
      testWidgets(
        'shows page title and user name',
        (tester) async {
          await pumpHomeScreen(
            tester,
            vehiclesLoader:
                () async => [],
            userDisplayName:
                'Shahar Test',
          );

          expect(
            find.text(
              'הרכבים שלי',
            ),
            findsOneWidget,
          );

          expect(
            find.descendant(
              of: find.byType(
                AppBar,
              ),
              matching: find.text(
                'Shahar Test',
              ),
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'shows basic vehicle information',
        (tester) async {
          await pumpHomeScreen(
            tester,
            vehiclesLoader:
                () async => [
              createVehicle(
                manufacturer:
                    'Mazda',
                model: '3',
                license:
                    '98765432',
                showTestOnHome:
                    false,
                showServiceOnHome:
                    false,
              ),
            ],
          );

          expect(
            find.text(
              'Mazda 3',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              '98765432',
            ),
            findsOneWidget,
          );

          expect(
            find.byIcon(
              Icons.directions_car_outlined,
            ),
            findsOneWidget,
          );

          expect(
            find.byIcon(
              Icons.chevron_left,
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'shows multiple vehicles',
        (tester) async {
          await pumpHomeScreen(
            tester,
            vehiclesLoader:
                () async => [
              createVehicle(
                id: 'vehicle-1',
                manufacturer:
                    'Toyota',
                model:
                    'Corolla',
                showTestOnHome:
                    false,
                showServiceOnHome:
                    false,
              ),
              createVehicle(
                id: 'vehicle-2',
                manufacturer:
                    'Honda',
                model:
                    'Civic',
                license:
                    '22222222',
                showTestOnHome:
                    false,
                showServiceOnHome:
                    false,
              ),
            ],
          );

          expect(
            find.text(
              'Toyota Corolla',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'Honda Civic',
            ),
            findsOneWidget,
          );
        },
      );
    },
  );

  group(
    'HomeScreen - home information',
    () {
      testWidgets(
        'shows enabled test license insurance and service information',
        (tester) async {
          final now =
              DateTime.now();

          final today =
              DateTime(
            now.year,
            now.month,
            now.day,
          );

          final testDate =
              today.add(
            const Duration(
              days: 10,
            ),
          );

          final licenseDate =
              today.add(
            const Duration(
              days: 20,
            ),
          );

          final insuranceDate =
              today.add(
            const Duration(
              days: 30,
            ),
          );

          final vehicle =
              createVehicle(
            testExpiryDate:
                testDate,
            showTestOnHome:
                true,
            vehicleLicenseExpiryDate:
                licenseDate,
            showVehicleLicenseOnHome:
                true,
            insurances: [
              VehicleInsurance(
                id: 'insurance-1',
                vehicleId:
                    'vehicle-1',
                type:
                    InsuranceType.mandatory,
                expiryDate:
                    insuranceDate,
                showOnHome: true,
              ),
            ],
            lastServiceDate:
                DateTime(
              2026,
              8,
              30,
            ),
            lastServiceMileage:
                60000,
            serviceIntervalKm:
                15000,
            showServiceOnHome:
                true,
          );

          await pumpHomeScreen(
            tester,
            vehiclesLoader:
                () async => [
              vehicle,
            ],
          );

          expect(
            find.text(
              'טסט: '
              '${VehicleDateUtils.getExpiryText(testDate)}',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'רישיון רכב: '
              '${VehicleDateUtils.getExpiryText(licenseDate)}',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'ביטוח חובה: '
              '${VehicleDateUtils.getExpiryText(insuranceDate)}',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'טיפול הבא: '
              '30/08/2027 או 75000 ק"מ',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'does not show disabled home information',
        (tester) async {
          final vehicle =
              createVehicle(
            testExpiryDate:
                DateTime(
              2028,
              1,
              1,
            ),
            showTestOnHome:
                false,
            vehicleLicenseExpiryDate:
                DateTime(
              2028,
              2,
              1,
            ),
            showVehicleLicenseOnHome:
                false,
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
                  3,
                  1,
                ),
                showOnHome:
                    false,
              ),
            ],
            lastServiceDate:
                DateTime(
              2026,
              8,
              30,
            ),
            showServiceOnHome:
                false,
          );

          await pumpHomeScreen(
            tester,
            vehiclesLoader:
                () async => [
              vehicle,
            ],
          );

          expect(
            find.textContaining(
              'טסט:',
            ),
            findsNothing,
          );

          expect(
            find.textContaining(
              'רישיון רכב:',
            ),
            findsNothing,
          );

          expect(
            find.textContaining(
              'ביטוח חובה:',
            ),
            findsNothing,
          );

          expect(
            find.textContaining(
              'טיפול הבא:',
            ),
            findsNothing,
          );
        },
      );

      testWidgets(
        'shows only insurances enabled for home with expiry date',
        (tester) async {
          final now =
              DateTime.now();

          final today =
              DateTime(
            now.year,
            now.month,
            now.day,
          );

          final mandatoryDate =
              today.add(
            const Duration(
              days: 15,
            ),
          );

          final vehicle =
              createVehicle(
            showTestOnHome:
                false,
            showServiceOnHome:
                false,
            insurances: [
              VehicleInsurance(
                id: 'mandatory',
                vehicleId:
                    'vehicle-1',
                type:
                    InsuranceType.mandatory,
                expiryDate:
                    mandatoryDate,
                showOnHome:
                    true,
              ),
              VehicleInsurance(
                id: 'comprehensive',
                vehicleId:
                    'vehicle-1',
                type:
                    InsuranceType.comprehensive,
                expiryDate:
                    today.add(
                  const Duration(
                    days: 20,
                  ),
                ),
                showOnHome:
                    false,
              ),
              VehicleInsurance(
                id: 'third-party',
                vehicleId:
                    'vehicle-1',
                type:
                    InsuranceType.thirdParty,
                expiryDate:
                    null,
                showOnHome:
                    true,
              ),
            ],
          );

          await pumpHomeScreen(
            tester,
            vehiclesLoader:
                () async => [
              vehicle,
            ],
          );

          expect(
            find.text(
              'ביטוח חובה: '
              '${VehicleDateUtils.getExpiryText(mandatoryDate)}',
            ),
            findsOneWidget,
          );

          expect(
            find.textContaining(
              'ביטוח מקיף:',
            ),
            findsNothing,
          );

          expect(
            find.textContaining(
              'ביטוח צד ג׳:',
            ),
            findsNothing,
          );
        },
      );

      testWidgets(
        'shows not defined when enabled test or service has no data',
        (tester) async {
          final vehicle =
              createVehicle(
            testExpiryDate:
                null,
            showTestOnHome:
                true,
            lastServiceDate:
                null,
            showServiceOnHome:
                true,
          );

          await pumpHomeScreen(
            tester,
            vehiclesLoader:
                () async => [
              vehicle,
            ],
          );

          expect(
            find.text(
              'טסט: לא הוגדר',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'טיפול הבא: לא הוגדר',
            ),
            findsOneWidget,
          );
        },
      );
    },
  );

  group(
    'HomeScreen - add vehicle',
    () {
      testWidgets(
        'add button opens add vehicle screen and returned vehicle is added',
        (tester) async {
          final newVehicle =
              createVehicle(
            id: 'new-vehicle',
            manufacturer:
                'Hyundai',
            model: 'i20',
            license:
                '55555555',
            showTestOnHome:
                false,
            showServiceOnHome:
                false,
          );

          await pumpHomeScreen(
            tester,
            vehiclesLoader:
                () async => [],
            addVehicleScreenBuilder:
                () =>
                    FakeAddVehicleScreen(
              vehicle:
                  newVehicle,
            ),
          );

          expect(
            find.text(
              'עדיין לא הוספת רכבים',
            ),
            findsOneWidget,
          );

          await tester.tap(
            find.byIcon(
              Icons.add,
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'הוספת רכב בדיקה',
            ),
            findsOneWidget,
          );

          await tester.tap(
            find.text(
              'החזר רכב חדש',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'Hyundai i20',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              '55555555',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'עדיין לא הוספת רכבים',
            ),
            findsNothing,
          );
        },
      );
    },
  );

  group(
    'HomeScreen - vehicle details',
    () {
      testWidgets(
        'vehicle remains when details screen returns false',
        (tester) async {
          final vehicle =
              createVehicle(
            showTestOnHome:
                false,
            showServiceOnHome:
                false,
          );

          await pumpHomeScreen(
            tester,
            vehiclesLoader:
                () async => [
              vehicle,
            ],
            vehicleDetailsScreenBuilder:
                (_) =>
                    const FakeVehicleDetailsScreen(
              result: false,
            ),
          );

          await tester.tap(
            find.text(
              'Toyota Corolla',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'פרטי רכב בדיקה',
            ),
            findsOneWidget,
          );

          await tester.tap(
            find.text(
              'חזור ללא מחיקה',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'Toyota Corolla',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              '12345678',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'vehicle is removed when details screen returns true',
        (tester) async {
          final vehicle =
              createVehicle(
            showTestOnHome:
                false,
            showServiceOnHome:
                false,
          );

          await pumpHomeScreen(
            tester,
            vehiclesLoader:
                () async => [
              vehicle,
            ],
            vehicleDetailsScreenBuilder:
                (_) =>
                    const FakeVehicleDetailsScreen(
              result: true,
            ),
          );

          await tester.tap(
            find.text(
              'Toyota Corolla',
            ),
          );

          await tester.pumpAndSettle();

          await tester.tap(
            find.text(
              'מחק וחזור',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'Toyota Corolla',
            ),
            findsNothing,
          );

          expect(
            find.text(
              'עדיין לא הוספת רכבים',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'הרכב נמחק בהצלחה',
            ),
            findsOneWidget,
          );

          await clearSnackBar(
            tester,
          );
        },
      );
    },
  );

  group(
    'HomeScreen - drawer',
    () {
      testWidgets(
        'vehicles drawer item closes drawer',
        (tester) async {
          await pumpHomeScreen(
            tester,
            vehiclesLoader:
                () async => [],
          );

          final scaffoldState =
              tester.state<ScaffoldState>(
            find.byType(
              Scaffold,
            ),
          );

          await tester.tap(
            find.byIcon(
              Icons.menu,
            ),
          );

          await tester.pumpAndSettle();

          expect(
            scaffoldState.isDrawerOpen,
            isTrue,
          );

          expect(
            find.text(
              'הרכבים שלי',
            ),
            findsWidgets,
          );

          expect(
            find.text(
              'החשבון שלי',
            ),
            findsOneWidget,
          );

          await tester.tap(
            find.text(
              'הרכבים שלי',
            ).last,
          );

          await tester.pumpAndSettle();

          expect(
            scaffoldState.isDrawerOpen,
            isFalse,
          );
        },
      );

      testWidgets(
        'account drawer item opens account screen',
        (tester) async {
          await pumpHomeScreen(
            tester,
            vehiclesLoader:
                () async => [],
            accountScreenBuilder:
                () =>
                    const FakeAccountScreen(),
          );

          await tester.tap(
            find.byIcon(
              Icons.menu,
            ),
          );

          await tester.pumpAndSettle();

          await tester.tap(
            find.text(
              'החשבון שלי',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'חשבון בדיקה',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'חזור לבית',
            ),
            findsOneWidget,
          );

          await tester.tap(
            find.text(
              'חזור לבית',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'הרכבים שלי',
            ),
            findsOneWidget,
          );
        },
      );
    },
  );
}