import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../lib/models/vehicle.dart';
import '../../lib/models/vehicle_member.dart';
import '../../lib/screens/account_screen.dart';

Vehicle createVehicle({
  String id = 'vehicle-1',
  String manufacturer = 'Toyota',
  String model = 'Corolla',
  String license = '12345678',
  VehicleMemberRole? role =
      VehicleMemberRole.owner,
}) {
  return Vehicle(
    id: id,
    license: license,
    manufacturer: manufacturer,
    model: model,
    year: 2022,
    mileage: 60000,
    currentUserRole: role,
  );
}

Map<String, Vehicle> createRoleVehicles() {
  return {
    'owner': createVehicle(
      id: 'vehicle-owner',
      manufacturer: 'Toyota',
      model: 'Corolla',
      license: '11111111',
      role: VehicleMemberRole.owner,
    ),
    'admin': createVehicle(
      id: 'vehicle-admin',
      manufacturer: 'Mazda',
      model: '3',
      license: '22222222',
      role: VehicleMemberRole.admin,
    ),
    'member': createVehicle(
      id: 'vehicle-member',
      manufacturer: 'Honda',
      model: 'Civic',
      license: '33333333',
      role: VehicleMemberRole.member,
    ),
  };
}

Future<void> pumpAccountScreen(
  WidgetTester tester, {
  required Future<List<Vehicle>>
      Function() vehiclesLoader,
  String userId = 'user-1',
  String userName = 'Test User',
  String userEmail = 'test@example.com',
  Future<void> Function(
    String newName,
  )? changeNameAction,
  Future<void> Function(
    String currentPassword,
    String newPassword,
  )? changePasswordAction,
  Future<void> Function()?
      signOutAction,
  Future<int> Function(
    String vehicleId,
  )? memberCountLoader,
  Future<AccountDeleteResult>
      Function()? deleteAccountAction,
  bool settle = true,
}) async {
  await tester.binding.setSurfaceSize(
    const Size(
      900,
      2000,
    ),
  );

  addTearDown(() async {
    await tester.binding.setSurfaceSize(
      null,
    );
  });

  // Keep a route underneath AccountScreen.
  // Sign out and successful account deletion
  // should return to this root route.
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'ROOT',
          ),
        ),
      ),
    ),
  );

  final navigator =
      tester.state<NavigatorState>(
    find.byType(
      Navigator,
    ),
  );

  navigator.push(
    MaterialPageRoute(
      builder: (_) => AccountScreen(
        vehiclesLoader:
            vehiclesLoader,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        changeNameAction:
            changeNameAction,
        changePasswordAction:
            changePasswordAction,
        signOutAction:
            signOutAction,
        memberCountLoader:
            memberCountLoader,
        deleteAccountAction:
            deleteAccountAction,
      ),
    ),
  );

  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();

    // Finish the route transition without
    // waiting for an indeterminate loader.
    await tester.pump(
      const Duration(
        milliseconds: 400,
      ),
    );
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

Future<void> tapAccountAction(
  WidgetTester tester,
  String text,
) async {
  final finder = find.text(
    text,
  );

  await tester.ensureVisible(
    finder,
  );

  await tester.tap(
    finder,
  );

  // Do not use pumpAndSettle here.
  // Some account actions show an
  // indeterminate progress indicator
  // while waiting for a dialog result.
  await tester.pump();

  await tester.pump(
    const Duration(
      milliseconds: 400,
    ),
  );
}

Future<void> openChangeNameDialog(
  WidgetTester tester,
) async {
  await tapAccountAction(
    tester,
    'שינוי שם',
  );

  expect(
    find.text(
      'שינוי שם',
    ),
    findsWidgets,
  );

  expect(
    find.byType(
      TextFormField,
    ),
    findsOneWidget,
  );
}

Future<void> openChangePasswordDialog(
  WidgetTester tester,
) async {
  await tapAccountAction(
    tester,
    'שינוי סיסמה',
  );

  expect(
    find.text(
      'שינוי סיסמה',
    ),
    findsWidgets,
  );

  expect(
    find.byType(
      TextFormField,
    ),
    findsNWidgets(3),
  );
}

void main() {
  group(
    'AccountScreen - basic UI and vehicles',
    () {
      testWidgets(
        'shows account information and actions',
        (tester) async {
          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
          );

          expect(
            find.text(
              'החשבון שלי',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'Test User',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'test@example.com',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'התפקידים שלי',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'הגדרות חשבון',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'שינוי שם',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'שינוי סיסמה',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'התנתקות',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'מחיקת חשבון',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'מחיקה מלאה של החשבון',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'empty name falls back to user label',
        (tester) async {
          await pumpAccountScreen(
            tester,
            userName: '',
            vehiclesLoader:
                () async => [],
          );

          expect(
            find.text(
              'משתמש',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'shows vehicle loading indicator while loading',
        (tester) async {
          final completer =
              Completer<List<Vehicle>>();

          await pumpAccountScreen(
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

          expect(
            find.text(
              'אין רכבים המשויכים לחשבון',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'shows empty state when account has no vehicles',
        (tester) async {
          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
          );

          expect(
            find.text(
              'אין רכבים המשויכים לחשבון',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'shows owner admin and member roles',
        (tester) async {
          final vehicles =
              createRoleVehicles();

          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [
              vehicles['owner']!,
              vehicles['admin']!,
              vehicles['member']!,
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
              '11111111',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'Mazda 3',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              '22222222',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'Honda Civic',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              '33333333',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'בעלים',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'מנהל',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'משתמש',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'shows unknown role when current role is null',
        (tester) async {
          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [
              createVehicle(
                role: null,
              ),
            ],
          );

          expect(
            find.text(
              'לא ידוע',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'vehicle loading error shows retry and retry succeeds',
        (tester) async {
          var attempts = 0;

          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async {
              attempts++;

              if (attempts == 1) {
                throw Exception(
                  'test vehicles error',
                );
              }

              return [
                createVehicle(),
              ];
            },
          );

          expect(
            attempts,
            1,
          );

          expect(
            find.text(
              'לא הצלחנו לטעון את תפקידי הרכבים.',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'נסה שוב',
            ),
            findsOneWidget,
          );

          await tester.tap(
            find.text(
              'נסה שוב',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            attempts,
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
              'לא הצלחנו לטעון את תפקידי הרכבים.',
            ),
            findsNothing,
          );
        },
      );
    },
  );

  group(
    'AccountScreen - change name',
    () {
      testWidgets(
        'change name dialog shows current name',
        (tester) async {
          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
          );

          await openChangeNameDialog(
            tester,
          );

          final field =
              tester.widget<TextFormField>(
            find.byType(
              TextFormField,
            ),
          );

          expect(
            field.initialValue,
            'Test User',
          );

          expect(
            find.text(
              'ביטול',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'שמור',
            ),
            findsOneWidget,
          );

          await tester.tap(
            find.text(
              'ביטול',
            ),
          );

          await tester.pumpAndSettle();
        },
      );

      testWidgets(
        'canceling name change does not call action',
        (tester) async {
          var calls = 0;

          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
            changeNameAction:
                (_) async {
              calls++;
            },
          );

          await openChangeNameDialog(
            tester,
          );

          await tester.enterText(
            find.byType(
              TextFormField,
            ),
            'New Name',
          );

          await tester.tap(
            find.text(
              'ביטול',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            calls,
            0,
          );
        },
      );

      testWidgets(
        'empty name keeps dialog open and does not save',
        (tester) async {
          var calls = 0;

          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
            changeNameAction:
                (_) async {
              calls++;
            },
          );

          await openChangeNameDialog(
            tester,
          );

          await tester.enterText(
            find.byType(
              TextFormField,
            ),
            '   ',
          );

          await tester.tap(
            find.text(
              'שמור',
            ),
          );

          await tester.pump();

          expect(
            calls,
            0,
          );

          expect(
            find.byType(
              AlertDialog,
            ),
            findsOneWidget,
          );

          await tester.tap(
            find.text(
              'ביטול',
            ),
          );

          await tester.pumpAndSettle();
        },
      );

      testWidgets(
        'successful name change sends trimmed name',
        (tester) async {
          var calls = 0;
          String? receivedName;

          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
            changeNameAction:
                (newName) async {
              calls++;
              receivedName =
                  newName;
            },
          );

          await openChangeNameDialog(
            tester,
          );

          await tester.enterText(
            find.byType(
              TextFormField,
            ),
            '  Shahar New  ',
          );

          await tester.tap(
            find.text(
              'שמור',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            calls,
            1,
          );

          expect(
            receivedName,
            'Shahar New',
          );

          expect(
            find.text(
              'השם עודכן בהצלחה',
            ),
            findsOneWidget,
          );

          await clearSnackBar(
            tester,
          );
        },
      );

      testWidgets(
        'name change failure shows error message',
        (tester) async {
          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
            changeNameAction:
                (_) async {
              throw Exception(
                'test name error',
              );
            },
          );

          await openChangeNameDialog(
            tester,
          );

          await tester.enterText(
            find.byType(
              TextFormField,
            ),
            'New Name',
          );

          await tester.tap(
            find.text(
              'שמור',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'לא הצלחנו לעדכן את השם. נסה שוב.',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'החשבון שלי',
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
    'AccountScreen - change password',
    () {
      testWidgets(
        'password dialog shows three password fields',
        (tester) async {
          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
          );

          await openChangePasswordDialog(
            tester,
          );

          expect(
            find.text(
              'סיסמה נוכחית',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'סיסמה חדשה',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'אימות סיסמה חדשה',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'שנה סיסמה',
            ),
            findsOneWidget,
          );

          await tester.tap(
            find.text(
              'ביטול',
            ),
          );

          await tester.pumpAndSettle();
        },
      );

      testWidgets(
        'empty password fields show validation errors',
        (tester) async {
          var calls = 0;

          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
            changePasswordAction:
                (
              currentPassword,
              newPassword,
            ) async {
              calls++;
            },
          );

          await openChangePasswordDialog(
            tester,
          );

          await tester.tap(
            find.text(
              'שנה סיסמה',
            ),
          );

          await tester.pump();

          expect(
            find.text(
              'יש להזין את הסיסמה הנוכחית',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'יש להזין סיסמה חדשה',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'יש לאמת את הסיסמה החדשה',
            ),
            findsOneWidget,
          );

          expect(
            calls,
            0,
          );

          await tester.tap(
            find.text(
              'ביטול',
            ),
          );

          await tester.pumpAndSettle();
        },
      );

      testWidgets(
        'new password shorter than six characters is rejected',
        (tester) async {
          var calls = 0;

          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
            changePasswordAction:
                (
              currentPassword,
              newPassword,
            ) async {
              calls++;
            },
          );

          await openChangePasswordDialog(
            tester,
          );

          final fields =
              find.byType(
            TextFormField,
          );

          await tester.enterText(
            fields.at(0),
            'oldPassword',
          );

          await tester.enterText(
            fields.at(1),
            '12345',
          );

          await tester.enterText(
            fields.at(2),
            '12345',
          );

          await tester.tap(
            find.text(
              'שנה סיסמה',
            ),
          );

          await tester.pump();

          expect(
            find.text(
              'הסיסמה צריכה להכיל לפחות 6 תווים',
            ),
            findsOneWidget,
          );

          expect(
            calls,
            0,
          );

          await tester.tap(
            find.text(
              'ביטול',
            ),
          );

          await tester.pumpAndSettle();
        },
      );

      testWidgets(
        'password confirmation must match',
        (tester) async {
          var calls = 0;

          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
            changePasswordAction:
                (
              currentPassword,
              newPassword,
            ) async {
              calls++;
            },
          );

          await openChangePasswordDialog(
            tester,
          );

          final fields =
              find.byType(
            TextFormField,
          );

          await tester.enterText(
            fields.at(0),
            'oldPassword',
          );

          await tester.enterText(
            fields.at(1),
            'newPassword',
          );

          await tester.enterText(
            fields.at(2),
            'differentPassword',
          );

          await tester.tap(
            find.text(
              'שנה סיסמה',
            ),
          );

          await tester.pump();

          expect(
            find.text(
              'הסיסמאות אינן תואמות',
            ),
            findsOneWidget,
          );

          expect(
            calls,
            0,
          );

          await tester.tap(
            find.text(
              'ביטול',
            ),
          );

          await tester.pumpAndSettle();
        },
      );

      testWidgets(
        'canceling password change does not call action',
        (tester) async {
          var calls = 0;

          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
            changePasswordAction:
                (
              currentPassword,
              newPassword,
            ) async {
              calls++;
            },
          );

          await openChangePasswordDialog(
            tester,
          );

          final fields =
              find.byType(
            TextFormField,
          );

          await tester.enterText(
            fields.at(0),
            'oldPassword',
          );

          await tester.enterText(
            fields.at(1),
            'newPassword',
          );

          await tester.enterText(
            fields.at(2),
            'newPassword',
          );

          await tester.tap(
            find.text(
              'ביטול',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            calls,
            0,
          );
        },
      );

      testWidgets(
        'successful password change sends current and new password',
        (tester) async {
          var calls = 0;

          String? receivedCurrent;
          String? receivedNew;

          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
            changePasswordAction:
                (
              currentPassword,
              newPassword,
            ) async {
              calls++;

              receivedCurrent =
                  currentPassword;

              receivedNew =
                  newPassword;
            },
          );

          await openChangePasswordDialog(
            tester,
          );

          final fields =
              find.byType(
            TextFormField,
          );

          await tester.enterText(
            fields.at(0),
            'oldPassword',
          );

          await tester.enterText(
            fields.at(1),
            'newPassword',
          );

          await tester.enterText(
            fields.at(2),
            'newPassword',
          );

          await tester.tap(
            find.text(
              'שנה סיסמה',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            calls,
            1,
          );

          expect(
            receivedCurrent,
            'oldPassword',
          );

          expect(
            receivedNew,
            'newPassword',
          );

          expect(
            find.text(
              'הסיסמה עודכנה בהצלחה',
            ),
            findsOneWidget,
          );

          await clearSnackBar(
            tester,
          );
        },
      );

      testWidgets(
        'AuthException shows wrong current password message',
        (tester) async {
          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
            changePasswordAction:
                (
              currentPassword,
              newPassword,
            ) async {
              throw const AuthException(
                'invalid password',
              );
            },
          );

          await openChangePasswordDialog(
            tester,
          );

          final fields =
              find.byType(
            TextFormField,
          );

          await tester.enterText(
            fields.at(0),
            'wrongPassword',
          );

          await tester.enterText(
            fields.at(1),
            'newPassword',
          );

          await tester.enterText(
            fields.at(2),
            'newPassword',
          );

          await tester.tap(
            find.text(
              'שנה סיסמה',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'הסיסמה הנוכחית אינה נכונה.',
            ),
            findsOneWidget,
          );

          await clearSnackBar(
            tester,
          );
        },
      );

      testWidgets(
        'unexpected password error shows general message',
        (tester) async {
          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
            changePasswordAction:
                (
              currentPassword,
              newPassword,
            ) async {
              throw Exception(
                'test password error',
              );
            },
          );

          await openChangePasswordDialog(
            tester,
          );

          final fields =
              find.byType(
            TextFormField,
          );

          await tester.enterText(
            fields.at(0),
            'oldPassword',
          );

          await tester.enterText(
            fields.at(1),
            'newPassword',
          );

          await tester.enterText(
            fields.at(2),
            'newPassword',
          );

          await tester.tap(
            find.text(
              'שנה סיסמה',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'לא הצלחנו לשנות את הסיסמה. נסה שוב.',
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
    'AccountScreen - sign out',
    () {
      testWidgets(
        'sign out shows confirmation dialog',
        (tester) async {
          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
          );

          await tapAccountAction(
            tester,
            'התנתקות',
          );

          expect(
            find.byType(
              AlertDialog,
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'האם אתה בטוח שברצונך להתנתק?',
            ),
            findsOneWidget,
          );

          expect(
            find.widgetWithText(
              ElevatedButton,
              'התנתק',
            ),
            findsOneWidget,
          );

          await tester.tap(
            find.text(
              'ביטול',
            ),
          );

          await tester.pumpAndSettle();
        },
      );

      testWidgets(
        'canceling sign out does not call action',
        (tester) async {
          var calls = 0;

          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
            signOutAction:
                () async {
              calls++;
            },
          );

          await tapAccountAction(
            tester,
            'התנתקות',
          );

          await tester.tap(
            find.text(
              'ביטול',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            calls,
            0,
          );

          expect(
            find.text(
              'החשבון שלי',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'successful sign out returns to root',
        (tester) async {
          var calls = 0;

          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
            signOutAction:
                () async {
              calls++;
            },
          );

          await tapAccountAction(
            tester,
            'התנתקות',
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'התנתק',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            calls,
            1,
          );

          expect(
            find.text(
              'ROOT',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'החשבון שלי',
            ),
            findsNothing,
          );
        },
      );

      testWidgets(
        'sign out failure keeps screen open and shows message',
        (tester) async {
          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
            signOutAction:
                () async {
              throw Exception(
                'test sign out error',
              );
            },
          );

          await tapAccountAction(
            tester,
            'התנתקות',
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'התנתק',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'לא הצלחנו להתנתק. נסה שוב.',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'החשבון שלי',
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
    'AccountScreen - delete account',
    () {
      testWidgets(
        'shared owned vehicle blocks account deletion',
        (tester) async {
          var memberCountCalls = 0;
          var deleteCalls = 0;

          final vehicle =
              createVehicle(
            role:
                VehicleMemberRole.owner,
          );

          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [
              vehicle,
            ],
            memberCountLoader:
                (vehicleId) async {
              memberCountCalls++;

              expect(
                vehicleId,
                'vehicle-1',
              );

              return 2;
            },
            deleteAccountAction:
                () async {
              deleteCalls++;

              return AccountDeleteResult
                  .success;
            },
          );

          await tapAccountAction(
            tester,
            'מחיקת חשבון',
          );

          expect(
            memberCountCalls,
            1,
          );

          expect(
            find.text(
              'יש להעביר בעלות',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'לא ניתן למחוק את החשבון כרגע. '
              'אתה הבעלים של רכב משותף.',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              '• Toyota Corolla (12345678)',
            ),
            findsOneWidget,
          );

          expect(
            deleteCalls,
            0,
          );

          await tester.tap(
            find.text(
              'הבנתי',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'החשבון שלי',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'solo owned vehicle is shown in deletion warning',
        (tester) async {
          var deleteCalls = 0;

          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [
              createVehicle(),
            ],
            memberCountLoader:
                (_) async => 1,
            deleteAccountAction:
                () async {
              deleteCalls++;

              return AccountDeleteResult
                  .success;
            },
          );

          await tapAccountAction(
            tester,
            'מחיקת חשבון',
          );

          expect(
            find.text(
              'האם אתה בטוח שברצונך למחוק את החשבון?',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'שים לב: הרכבים שבהם אתה '
              'הבעלים היחיד יימחקו יחד עם '
              'כל המידע שלהם:',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              '• Toyota Corolla (12345678)',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'פעולה זו אינה ניתנת לביטול.',
            ),
            findsOneWidget,
          );

          await tester.tap(
            find.text(
              'ביטול',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            deleteCalls,
            0,
          );
        },
      );

      testWidgets(
        'canceling account deletion does not invoke delete action',
        (tester) async {
          var deleteCalls = 0;

          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
            memberCountLoader:
                (_) async => 1,
            deleteAccountAction:
                () async {
              deleteCalls++;

              return AccountDeleteResult
                  .success;
            },
          );

          await tapAccountAction(
            tester,
            'מחיקת חשבון',
          );

          await tester.tap(
            find.text(
              'ביטול',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            deleteCalls,
            0,
          );

          expect(
            find.text(
              'החשבון שלי',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'admin and member vehicles do not require member count check',
        (tester) async {
          var memberCountCalls = 0;
          var deleteCalls = 0;

          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [
              createVehicle(
                id: 'admin-car',
                role:
                    VehicleMemberRole.admin,
              ),
              createVehicle(
                id: 'member-car',
                manufacturer:
                    'Mazda',
                model: '3',
                role:
                    VehicleMemberRole.member,
              ),
            ],
            memberCountLoader:
                (_) async {
              memberCountCalls++;
              return 10;
            },
            deleteAccountAction:
                () async {
              deleteCalls++;

              return AccountDeleteResult
                  .failure;
            },
          );

          await tapAccountAction(
            tester,
            'מחיקת חשבון',
          );

          expect(
            memberCountCalls,
            0,
          );

          // No owned vehicles should be
          // listed as vehicles that will
          // be deleted.
          expect(
            find.textContaining(
              'הבעלים היחיד',
            ),
            findsNothing,
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'מחק חשבון',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            deleteCalls,
            1,
          );

          expect(
            find.text(
              'לא הצלחנו למחוק את החשבון. נסה שוב.',
            ),
            findsOneWidget,
          );

          await clearSnackBar(
            tester,
          );
        },
      );

      testWidgets(
        'successful account deletion signs out and returns to root',
        (tester) async {
          var deleteCalls = 0;
          var signOutCalls = 0;

          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
            memberCountLoader:
                (_) async => 1,
            deleteAccountAction:
                () async {
              deleteCalls++;

              return AccountDeleteResult
                  .success;
            },
            signOutAction:
                () async {
              signOutCalls++;
            },
          );

          await tapAccountAction(
            tester,
            'מחיקת חשבון',
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'מחק חשבון',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            deleteCalls,
            1,
          );

          expect(
            signOutCalls,
            1,
          );

          expect(
            find.text(
              'ROOT',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'החשבון שלי',
            ),
            findsNothing,
          );
        },
      );

      testWidgets(
        'successful deletion still returns to root if local sign out fails',
        (tester) async {
          var deleteCalls = 0;
          var signOutCalls = 0;

          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
            deleteAccountAction:
                () async {
              deleteCalls++;

              return AccountDeleteResult
                  .success;
            },
            signOutAction:
                () async {
              signOutCalls++;

              throw Exception(
                'test local signout error',
              );
            },
          );

          await tapAccountAction(
            tester,
            'מחיקת חשבון',
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'מחק חשבון',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            deleteCalls,
            1,
          );

          expect(
            signOutCalls,
            1,
          );

          expect(
            find.text(
              'ROOT',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'ownership transfer required result shows correct message',
        (tester) async {
          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
            deleteAccountAction:
                () async {
              return AccountDeleteResult
                  .ownershipTransferRequired;
            },
          );

          await tapAccountAction(
            tester,
            'מחיקת חשבון',
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'מחק חשבון',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'יש להעביר בעלות על הרכב לפני מחיקת החשבון.',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'החשבון שלי',
            ),
            findsOneWidget,
          );

          await clearSnackBar(
            tester,
          );
        },
      );

      testWidgets(
        'delete account failure result shows error message',
        (tester) async {
          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
            deleteAccountAction:
                () async {
              return AccountDeleteResult
                  .failure;
            },
          );

          await tapAccountAction(
            tester,
            'מחיקת חשבון',
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'מחק חשבון',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'לא הצלחנו למחוק את החשבון. נסה שוב.',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'החשבון שלי',
            ),
            findsOneWidget,
          );

          await clearSnackBar(
            tester,
          );
        },
      );

      testWidgets(
        'member count error prevents deletion and shows error',
        (tester) async {
          var deleteCalls = 0;

          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [
              createVehicle(),
            ],
            memberCountLoader:
                (_) async {
              throw Exception(
                'test member count error',
              );
            },
            deleteAccountAction:
                () async {
              deleteCalls++;

              return AccountDeleteResult
                  .success;
            },
          );

          await tapAccountAction(
            tester,
            'מחיקת חשבון',
          );

          expect(
            deleteCalls,
            0,
          );

          expect(
            find.text(
              'לא הצלחנו למחוק את החשבון. נסה שוב.',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'החשבון שלי',
            ),
            findsOneWidget,
          );

          await clearSnackBar(
            tester,
          );
        },
      );

      testWidgets(
        'unexpected delete action error shows general error',
        (tester) async {
          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
            deleteAccountAction:
                () async {
              throw Exception(
                'test delete error',
              );
            },
          );

          await tapAccountAction(
            tester,
            'מחיקת חשבון',
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'מחק חשבון',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'לא הצלחנו למחוק את החשבון. נסה שוב.',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'החשבון שלי',
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
    'AccountScreen - drawer',
    () {
      testWidgets(
        'account drawer item only closes drawer',
        (tester) async {
          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
          );

          await tester.tap(
            find.byIcon(
              Icons.menu,
            ),
          );

          await tester.pumpAndSettle();

          final scaffoldState =
              tester.state<ScaffoldState>(
            find.byType(
              Scaffold,
            ).last,
          );

          expect(
            scaffoldState.isDrawerOpen,
            isTrue,
          );

          final accountItem =
              find.descendant(
            of: find.byType(
              Drawer,
            ),
            matching: find.text(
              'החשבון שלי',
            ),
          );

          expect(
            accountItem,
            findsOneWidget,
          );

          await tester.tap(
            accountItem,
          );

          await tester.pumpAndSettle();

          expect(
            scaffoldState.isDrawerOpen,
            isFalse,
          );

          expect(
            find.text(
              'החשבון שלי',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'vehicles drawer item returns to root',
        (tester) async {
          await pumpAccountScreen(
            tester,
            vehiclesLoader:
                () async => [],
          );

          await tester.tap(
            find.byIcon(
              Icons.menu,
            ),
          );

          await tester.pumpAndSettle();

          final vehiclesItem =
              find.descendant(
            of: find.byType(
              Drawer,
            ),
            matching: find.text(
              'הרכבים שלי',
            ),
          );

          expect(
            vehiclesItem,
            findsOneWidget,
          );

          await tester.tap(
            vehiclesItem,
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'ROOT',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'החשבון שלי',
            ),
            findsNothing,
          );
        },
      );
    },
  );
}