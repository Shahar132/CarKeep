import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../lib/models/vehicle.dart';
import '../../lib/repositories/vehicle_repository.dart';
import '../../lib/screens/add_vehicle_screen.dart';

class FakeVehicleRepository
    extends VehicleRepository {
  int addVehicleCalls = 0;

  Vehicle? receivedVehicle;
  Vehicle? vehicleToReturn;

  Object? errorToThrow;

  Completer<Vehicle>? saveCompleter;

  @override
  Future<Vehicle> addVehicle(
    Vehicle vehicle,
  ) async {
    addVehicleCalls++;
    receivedVehicle = vehicle;

    if (errorToThrow != null) {
      throw errorToThrow!;
    }

    if (saveCompleter != null) {
      return saveCompleter!.future;
    }

    return vehicleToReturn ??
        Vehicle(
          id: 'saved-vehicle-1',
          license: vehicle.license,
          manufacturer:
              vehicle.manufacturer,
          model: vehicle.model,
          year: vehicle.year,
          mileage: vehicle.mileage,
        );
  }
}

Future<void> pumpAddVehicleScreen(
  WidgetTester tester,
  FakeVehicleRepository repository,
) async {
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

  // Keep a route under AddVehicleScreen.
  // When saving succeeds, the screen should
  // return to this route.
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
      builder: (_) =>
          AddVehicleScreen(
        repository: repository,
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Finder fieldAt(
  int index,
) {
  return find
      .byType(TextFormField)
      .at(index);
}

Future<void> fillValidForm(
  WidgetTester tester, {
  String license = '12345678',
  String manufacturer = 'Toyota',
  String model = 'Corolla',
  String year = '2022',
  String mileage = '60000',
}) async {
  await tester.enterText(
    fieldAt(0),
    license,
  );

  await tester.enterText(
    fieldAt(1),
    manufacturer,
  );

  await tester.enterText(
    fieldAt(2),
    model,
  );

  await tester.enterText(
    fieldAt(3),
    year,
  );

  await tester.enterText(
    fieldAt(4),
    mileage,
  );

  await tester.pump();
}

Future<void> tapSave(
  WidgetTester tester, {
  bool settle = true,
}) async {
  // Close the keyboard before tapping the
  // save button.
  FocusManager.instance.primaryFocus
      ?.unfocus();

  await tester.pump();

  await tester.ensureVisible(
    find.text(
      'שמור רכב',
    ),
  );

  await tester.tap(
    find.text(
      'שמור רכב',
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

PostgrestException createDatabaseError(
  String code,
) {
  return PostgrestException(
    message: 'test database error',
    code: code,
    details: null,
    hint: null,
  );
}

void main() {
  group(
    'AddVehicleScreen - UI',
    () {
      testWidgets(
        'shows all vehicle fields and save button',
        (tester) async {
          final repository =
              FakeVehicleRepository();

          await pumpAddVehicleScreen(
            tester,
            repository,
          );

          expect(
            find.text(
              'הוספת רכב',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'פרטי הרכב',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'הזן את הפרטים הבסיסיים של הרכב',
            ),
            findsOneWidget,
          );

          expect(
            find.byType(
              TextFormField,
            ),
            findsNWidgets(5),
          );

          expect(
            find.text(
              'מספר רכב',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'יצרן',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'דגם',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'שנת ייצור',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'קילומטראז׳ נוכחי',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'שמור רכב',
            ),
            findsOneWidget,
          );

          expect(
            find.byIcon(
              Icons.directions_car_outlined,
            ),
            findsWidgets,
          );
        },
      );
    },
  );

  group(
    'AddVehicleScreen - required fields',
    () {
      testWidgets(
        'empty form shows all required validation errors',
        (tester) async {
          final repository =
              FakeVehicleRepository();

          await pumpAddVehicleScreen(
            tester,
            repository,
          );

          await tapSave(
            tester,
          );

          expect(
            find.text(
              'יש להזין מספר רכב',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'יש להזין יצרן',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'יש להזין דגם',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'יש להזין שנת ייצור',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'יש להזין קילומטראז׳',
            ),
            findsOneWidget,
          );

          expect(
            repository.addVehicleCalls,
            0,
          );
        },
      );

      testWidgets(
        'manufacturer is required',
        (tester) async {
          final repository =
              FakeVehicleRepository();

          await pumpAddVehicleScreen(
            tester,
            repository,
          );

          await fillValidForm(
            tester,
            manufacturer: '',
          );

          await tapSave(
            tester,
          );

          expect(
            find.text(
              'יש להזין יצרן',
            ),
            findsOneWidget,
          );

          expect(
            repository.addVehicleCalls,
            0,
          );
        },
      );

      testWidgets(
        'model is required',
        (tester) async {
          final repository =
              FakeVehicleRepository();

          await pumpAddVehicleScreen(
            tester,
            repository,
          );

          await fillValidForm(
            tester,
            model: '',
          );

          await tapSave(
            tester,
          );

          expect(
            find.text(
              'יש להזין דגם',
            ),
            findsOneWidget,
          );

          expect(
            repository.addVehicleCalls,
            0,
          );
        },
      );
    },
  );

  group(
    'AddVehicleScreen - license validation',
    () {
      testWidgets(
        'license accepts digits only',
        (tester) async {
          final repository =
              FakeVehicleRepository();

          await pumpAddVehicleScreen(
            tester,
            repository,
          );

          await fillValidForm(
            tester,
            license: '123ABC45',
          );

          await tapSave(
            tester,
          );

          expect(
            find.text(
              'מספר הרכב צריך להכיל ספרות בלבד',
            ),
            findsOneWidget,
          );

          expect(
            repository.addVehicleCalls,
            0,
          );
        },
      );

      testWidgets(
        'license shorter than 7 digits is rejected',
        (tester) async {
          final repository =
              FakeVehicleRepository();

          await pumpAddVehicleScreen(
            tester,
            repository,
          );

          await fillValidForm(
            tester,
            license: '123456',
          );

          await tapSave(
            tester,
          );

          expect(
            find.text(
              'מספר רכב צריך להכיל 7 או 8 ספרות',
            ),
            findsOneWidget,
          );

          expect(
            repository.addVehicleCalls,
            0,
          );
        },
      );

      testWidgets(
        'license longer than 8 digits is rejected',
        (tester) async {
          final repository =
              FakeVehicleRepository();

          await pumpAddVehicleScreen(
            tester,
            repository,
          );

          await fillValidForm(
            tester,
            license: '123456789',
          );

          await tapSave(
            tester,
          );

          expect(
            find.text(
              'מספר רכב צריך להכיל 7 או 8 ספרות',
            ),
            findsOneWidget,
          );

          expect(
            repository.addVehicleCalls,
            0,
          );
        },
      );

      for (final license in [
        '1234567',
        '12345678',
      ]) {
        testWidgets(
          '$license is accepted as a valid license number',
          (tester) async {
            final repository =
                FakeVehicleRepository();

            await pumpAddVehicleScreen(
              tester,
              repository,
            );

            await fillValidForm(
              tester,
              license: license,
            );

            await tapSave(
              tester,
            );

            expect(
              repository.addVehicleCalls,
              1,
            );

            expect(
              repository
                  .receivedVehicle
                  ?.license,
              license,
            );

            expect(
              find.text(
                'ROOT',
              ),
              findsOneWidget,
            );
          },
        );
      }
    },
  );

  group(
    'AddVehicleScreen - year validation',
    () {
      testWidgets(
        'non numeric year is rejected',
        (tester) async {
          final repository =
              FakeVehicleRepository();

          await pumpAddVehicleScreen(
            tester,
            repository,
          );

          await fillValidForm(
            tester,
            year: 'abcd',
          );

          await tapSave(
            tester,
          );

          expect(
            find.text(
              'יש להזין שנה תקינה',
            ),
            findsOneWidget,
          );

          expect(
            repository.addVehicleCalls,
            0,
          );
        },
      );

      testWidgets(
        'year before 1900 is rejected',
        (tester) async {
          final repository =
              FakeVehicleRepository();

          await pumpAddVehicleScreen(
            tester,
            repository,
          );

          await fillValidForm(
            tester,
            year: '1899',
          );

          await tapSave(
            tester,
          );

          expect(
            find.text(
              'יש להזין שנת ייצור תקינה',
            ),
            findsOneWidget,
          );

          expect(
            repository.addVehicleCalls,
            0,
          );
        },
      );

      testWidgets(
        'year more than one year in the future is rejected',
        (tester) async {
          final repository =
              FakeVehicleRepository();

          final invalidYear =
              DateTime.now().year + 2;

          await pumpAddVehicleScreen(
            tester,
            repository,
          );

          await fillValidForm(
            tester,
            year:
                invalidYear.toString(),
          );

          await tapSave(
            tester,
          );

          expect(
            find.text(
              'יש להזין שנת ייצור תקינה',
            ),
            findsOneWidget,
          );

          expect(
            repository.addVehicleCalls,
            0,
          );
        },
      );

      testWidgets(
        'next year is accepted',
        (tester) async {
          final repository =
              FakeVehicleRepository();

          final validYear =
              DateTime.now().year + 1;

          await pumpAddVehicleScreen(
            tester,
            repository,
          );

          await fillValidForm(
            tester,
            year:
                validYear.toString(),
          );

          await tapSave(
            tester,
          );

          expect(
            repository.addVehicleCalls,
            1,
          );

          expect(
            repository
                .receivedVehicle
                ?.year,
            validYear,
          );
        },
      );
    },
  );

  group(
    'AddVehicleScreen - mileage validation',
    () {
      testWidgets(
        'non numeric mileage is rejected',
        (tester) async {
          final repository =
              FakeVehicleRepository();

          await pumpAddVehicleScreen(
            tester,
            repository,
          );

          await fillValidForm(
            tester,
            mileage: 'abc',
          );

          await tapSave(
            tester,
          );

          expect(
            find.text(
              'יש להזין קילומטראז׳ תקין',
            ),
            findsOneWidget,
          );

          expect(
            repository.addVehicleCalls,
            0,
          );
        },
      );

      testWidgets(
        'negative mileage is rejected',
        (tester) async {
          final repository =
              FakeVehicleRepository();

          await pumpAddVehicleScreen(
            tester,
            repository,
          );

          await fillValidForm(
            tester,
            mileage: '-1',
          );

          await tapSave(
            tester,
          );

          expect(
            find.text(
              'קילומטראז׳ לא יכול להיות שלילי',
            ),
            findsOneWidget,
          );

          expect(
            repository.addVehicleCalls,
            0,
          );
        },
      );

      testWidgets(
        'zero mileage is accepted',
        (tester) async {
          final repository =
              FakeVehicleRepository();

          await pumpAddVehicleScreen(
            tester,
            repository,
          );

          await fillValidForm(
            tester,
            mileage: '0',
          );

          await tapSave(
            tester,
          );

          expect(
            repository.addVehicleCalls,
            1,
          );

          expect(
            repository
                .receivedVehicle
                ?.mileage,
            0,
          );
        },
      );
    },
  );

  group(
    'AddVehicleScreen - successful save',
    () {
      testWidgets(
        'valid form creates vehicle with correct values',
        (tester) async {
          final repository =
              FakeVehicleRepository();

          await pumpAddVehicleScreen(
            tester,
            repository,
          );

          await fillValidForm(
            tester,
            license:
                '76543210',
            manufacturer:
                'Mazda',
            model: '3',
            year: '2021',
            mileage:
                '54321',
          );

          await tapSave(
            tester,
          );

          expect(
            repository.addVehicleCalls,
            1,
          );

          final received =
              repository.receivedVehicle;

          expect(
            received,
            isNotNull,
          );

          expect(
            received!.license,
            '76543210',
          );

          expect(
            received.manufacturer,
            'Mazda',
          );

          expect(
            received.model,
            '3',
          );

          expect(
            received.year,
            2021,
          );

          expect(
            received.mileage,
            54321,
          );

          // Successful save closes
          // AddVehicleScreen.
          expect(
            find.text(
              'ROOT',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'הוספת רכב',
            ),
            findsNothing,
          );
        },
      );

      testWidgets(
        'text values are trimmed before vehicle is saved',
        (tester) async {
          final repository =
              FakeVehicleRepository();

          await pumpAddVehicleScreen(
            tester,
            repository,
          );

          await fillValidForm(
            tester,
            license:
                ' 12345678 ',
            manufacturer:
                ' Toyota ',
            model:
                ' Corolla ',
            year:
                ' 2022 ',
            mileage:
                ' 60000 ',
          );

          await tapSave(
            tester,
          );

          expect(
            repository.addVehicleCalls,
            1,
          );

          expect(
            repository
                .receivedVehicle
                ?.license,
            '12345678',
          );

          expect(
            repository
                .receivedVehicle
                ?.manufacturer,
            'Toyota',
          );

          expect(
            repository
                .receivedVehicle
                ?.model,
            'Corolla',
          );

          expect(
            repository
                .receivedVehicle
                ?.year,
            2022,
          );

          expect(
            repository
                .receivedVehicle
                ?.mileage,
            60000,
          );
        },
      );

      testWidgets(
        'shows saving state and disables button while repository is working',
        (tester) async {
          final repository =
              FakeVehicleRepository();

          repository.saveCompleter =
              Completer<Vehicle>();

          await pumpAddVehicleScreen(
            tester,
            repository,
          );

          await fillValidForm(
            tester,
          );

          await tapSave(
            tester,
            settle: false,
          );

          expect(
            repository.addVehicleCalls,
            1,
          );

          expect(
            find.text(
              'שומר...',
            ),
            findsOneWidget,
          );

          expect(
            find.byType(
              CircularProgressIndicator,
            ),
            findsOneWidget,
          );

          final button =
              tester.widget<
                  ElevatedButton>(
            find.byType(
              ElevatedButton,
            ),
          );

          expect(
            button.onPressed,
            isNull,
          );

          repository.saveCompleter!
              .complete(
            Vehicle(
              id:
                  'saved-vehicle-1',
              license:
                  '12345678',
              manufacturer:
                  'Toyota',
              model:
                  'Corolla',
              year: 2022,
              mileage: 60000,
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'ROOT',
            ),
            findsOneWidget,
          );
        },
      );
    },
  );

  group(
    'AddVehicleScreen - database errors',
    () {
      final databaseErrors =
          <String, String>{
        '23505':
            'רכב עם מספר הרישוי הזה כבר קיים במערכת.',
        '42501':
            'אין הרשאה לבצע את הפעולה. נסה להתחבר מחדש.',
        '23514':
            'אחד מהפרטים שהוזנו אינו תקין. בדוק את הנתונים ונסה שוב.',
        '23502':
            'חסר מידע נדרש לשמירת הרכב.',
        '22P02':
            'אחד מהערכים שהוזנו אינו בפורמט תקין.',
        '22003':
            'אחד מהמספרים שהוזנו גדול או קטן מדי.',
        'PGRST116':
            'הרכב נשמר, אך לא הצלחנו לטעון אותו מחדש. נסה לרענן את המסך.',
        'UNKNOWN':
            'לא הצלחנו לשמור את הרכב. נסה שוב.',
      };

      for (final entry
          in databaseErrors.entries) {
        testWidgets(
          'database error ${entry.key} shows correct message',
          (tester) async {
            final repository =
                FakeVehicleRepository();

            repository.errorToThrow =
                createDatabaseError(
              entry.key,
            );

            await pumpAddVehicleScreen(
              tester,
              repository,
            );

            await fillValidForm(
              tester,
            );

            await tapSave(
              tester,
            );

            expect(
              repository.addVehicleCalls,
              1,
            );

            expect(
              find.text(
                entry.value,
              ),
              findsOneWidget,
            );

            // Screen should stay open
            // after save failure.
            expect(
              find.text(
                'הוספת רכב',
              ),
              findsOneWidget,
            );

            expect(
              find.text(
                'שמור רכב',
              ),
              findsOneWidget,
            );

            await clearSnackBar(
              tester,
            );
          },
        );
      }
    },
  );

  group(
    'AddVehicleScreen - unexpected errors',
    () {
      testWidgets(
        'unexpected save error shows connection error message',
        (tester) async {
          final repository =
              FakeVehicleRepository();

          repository.errorToThrow =
              Exception(
            'test save error',
          );

          await pumpAddVehicleScreen(
            tester,
            repository,
          );

          await fillValidForm(
            tester,
          );

          await tapSave(
            tester,
          );

          expect(
            repository.addVehicleCalls,
            1,
          );

          expect(
            find.text(
              'לא הצלחנו לשמור את הרכב. '
              'בדוק את החיבור לאינטרנט ונסה שוב.',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'הוספת רכב',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'שמור רכב',
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
}