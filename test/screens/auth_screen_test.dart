import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../lib/screens/auth_screen.dart';

Finder fieldWithLabel(
  String label,
) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is TextField &&
        widget.decoration?.labelText == label,
    description:
        'TextField with label "$label"',
  );
}

Future<void> pumpAuthScreen(
  WidgetTester tester, {
  Future<void> Function(
    String email,
    String password,
  )? signInAction,
  Future<bool> Function(
    String name,
    String email,
    String password,
  )? signUpAction,
}) async {
  await tester.binding.setSurfaceSize(
    const Size(
      900,
      1400,
    ),
  );

  addTearDown(() async {
    await tester.binding.setSurfaceSize(
      null,
    );
  });

  await tester.pumpWidget(
    MaterialApp(
      home: AuthScreen(
        // Always inject fake actions so
        // Widget Tests never touch Supabase.
        signInAction:
            signInAction ??
            (
              email,
              password,
            ) async {},
        signUpAction:
            signUpAction ??
            (
              name,
              email,
              password,
            ) async {
              return true;
            },
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> switchToSignUp(
  WidgetTester tester,
) async {
  await tester.tap(
    find.text(
      'אין לך חשבון? הירשם',
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> switchToLogin(
  WidgetTester tester,
) async {
  await tester.tap(
    find.text(
      'כבר יש לך חשבון? התחבר',
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> fillLoginForm(
  WidgetTester tester, {
  String email =
      'test@example.com',
  String password =
      'password123',
}) async {
  await tester.enterText(
    fieldWithLabel(
      'אימייל',
    ),
    email,
  );

  await tester.enterText(
    fieldWithLabel(
      'סיסמה',
    ),
    password,
  );

  await tester.pump();
}

Future<void> fillSignUpForm(
  WidgetTester tester, {
  String name = 'Test User',
  String email =
      'test@example.com',
  String password =
      'password123',
}) async {
  await tester.enterText(
    fieldWithLabel(
      'שם',
    ),
    name,
  );

  await tester.enterText(
    fieldWithLabel(
      'אימייל',
    ),
    email,
  );

  await tester.enterText(
    fieldWithLabel(
      'סיסמה',
    ),
    password,
  );

  await tester.pump();
}

Future<void> pumpAction(
  WidgetTester tester,
) async {
  // Enough time for the async action and
  // SnackBar/dialog animations without
  // relying unnecessarily on pumpAndSettle.
  await tester.pump();

  await tester.pump(
    const Duration(
      milliseconds: 400,
    ),
  );
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

void main() {
  group(
    'AuthScreen - login UI',
    () {
      testWidgets(
        'starts in login mode',
        (tester) async {
          await pumpAuthScreen(
            tester,
          );

          expect(
            find.text(
              'ברוך הבא',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'התחבר כדי לנהל את הרכבים שלך',
            ),
            findsOneWidget,
          );

          expect(
            fieldWithLabel(
              'אימייל',
            ),
            findsOneWidget,
          );

          expect(
            fieldWithLabel(
              'סיסמה',
            ),
            findsOneWidget,
          );

          expect(
            fieldWithLabel(
              'שם',
            ),
            findsNothing,
          );

          expect(
            find.widgetWithText(
              ElevatedButton,
              'התחבר',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'אין לך חשבון? הירשם',
            ),
            findsOneWidget,
          );

          expect(
            find.byType(
              Image,
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'login mode has two input fields',
        (tester) async {
          await pumpAuthScreen(
            tester,
          );

          expect(
            find.byType(
              TextField,
            ),
            findsNWidgets(2),
          );
        },
      );
    },
  );

  group(
    'AuthScreen - switching modes',
    () {
      testWidgets(
        'switches from login to sign up',
        (tester) async {
          await pumpAuthScreen(
            tester,
          );

          await switchToSignUp(
            tester,
          );

          expect(
            find.text(
              'יצירת חשבון',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'צור חשבון והתחל לנהל את הרכבים שלך',
            ),
            findsOneWidget,
          );

          expect(
            fieldWithLabel(
              'שם',
            ),
            findsOneWidget,
          );

          expect(
            fieldWithLabel(
              'אימייל',
            ),
            findsOneWidget,
          );

          expect(
            fieldWithLabel(
              'סיסמה',
            ),
            findsOneWidget,
          );

          expect(
            find.byType(
              TextField,
            ),
            findsNWidgets(3),
          );

          expect(
            find.widgetWithText(
              ElevatedButton,
              'הרשם',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'כבר יש לך חשבון? התחבר',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'switches from sign up back to login',
        (tester) async {
          await pumpAuthScreen(
            tester,
          );

          await switchToSignUp(
            tester,
          );

          await switchToLogin(
            tester,
          );

          expect(
            find.text(
              'ברוך הבא',
            ),
            findsOneWidget,
          );

          expect(
            fieldWithLabel(
              'שם',
            ),
            findsNothing,
          );

          expect(
            find.byType(
              TextField,
            ),
            findsNWidgets(2),
          );

          expect(
            find.widgetWithText(
              ElevatedButton,
              'התחבר',
            ),
            findsOneWidget,
          );
        },
      );
    },
  );

  group(
    'AuthScreen - login validation',
    () {
      testWidgets(
        'empty login form shows required message',
        (tester) async {
          var signInCalls = 0;

          await pumpAuthScreen(
            tester,
            signInAction:
                (
              email,
              password,
            ) async {
              signInCalls++;
            },
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'התחבר',
            ),
          );

          await pumpAction(
            tester,
          );

          expect(
            find.text(
              'יש למלא אימייל וסיסמה',
            ),
            findsOneWidget,
          );

          expect(
            signInCalls,
            0,
          );

          await clearSnackBar(
            tester,
          );
        },
      );

      testWidgets(
        'missing email prevents login',
        (tester) async {
          var signInCalls = 0;

          await pumpAuthScreen(
            tester,
            signInAction:
                (
              email,
              password,
            ) async {
              signInCalls++;
            },
          );

          await fillLoginForm(
            tester,
            email: '',
            password:
                'password123',
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'התחבר',
            ),
          );

          await pumpAction(
            tester,
          );

          expect(
            find.text(
              'יש למלא אימייל וסיסמה',
            ),
            findsOneWidget,
          );

          expect(
            signInCalls,
            0,
          );

          await clearSnackBar(
            tester,
          );
        },
      );

      testWidgets(
        'missing password prevents login',
        (tester) async {
          var signInCalls = 0;

          await pumpAuthScreen(
            tester,
            signInAction:
                (
              email,
              password,
            ) async {
              signInCalls++;
            },
          );

          await fillLoginForm(
            tester,
            email:
                'test@example.com',
            password: '',
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'התחבר',
            ),
          );

          await pumpAction(
            tester,
          );

          expect(
            find.text(
              'יש למלא אימייל וסיסמה',
            ),
            findsOneWidget,
          );

          expect(
            signInCalls,
            0,
          );

          await clearSnackBar(
            tester,
          );
        },
      );
    },
  );

  group(
    'AuthScreen - login action',
    () {
      testWidgets(
        'successful login sends email and password',
        (tester) async {
          var signInCalls = 0;

          String? receivedEmail;
          String? receivedPassword;

          await pumpAuthScreen(
            tester,
            signInAction:
                (
              email,
              password,
            ) async {
              signInCalls++;

              receivedEmail =
                  email;

              receivedPassword =
                  password;
            },
          );

          await fillLoginForm(
            tester,
            email:
                'test@example.com',
            password:
                'password123',
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'התחבר',
            ),
          );

          await pumpAction(
            tester,
          );

          expect(
            signInCalls,
            1,
          );

          expect(
            receivedEmail,
            'test@example.com',
          );

          expect(
            receivedPassword,
            'password123',
          );
        },
      );

      testWidgets(
        'login values are trimmed',
        (tester) async {
          String? receivedEmail;
          String? receivedPassword;

          await pumpAuthScreen(
            tester,
            signInAction:
                (
              email,
              password,
            ) async {
              receivedEmail =
                  email;

              receivedPassword =
                  password;
            },
          );

          await fillLoginForm(
            tester,
            email:
                '  test@example.com  ',
            password:
                '  password123  ',
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'התחבר',
            ),
          );

          await pumpAction(
            tester,
          );

          expect(
            receivedEmail,
            'test@example.com',
          );

          expect(
            receivedPassword,
            'password123',
          );
        },
      );

      testWidgets(
        'AuthException during login shows auth message',
        (tester) async {
          await pumpAuthScreen(
            tester,
            signInAction:
                (
              email,
              password,
            ) async {
              throw const AuthException(
                'Invalid login credentials',
              );
            },
          );

          await fillLoginForm(
            tester,
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'התחבר',
            ),
          );

          await pumpAction(
            tester,
          );

          expect(
            find.text(
              'Invalid login credentials',
            ),
            findsOneWidget,
          );

          await clearSnackBar(
            tester,
          );
        },
      );

      testWidgets(
        'unexpected login error shows general message',
        (tester) async {
          await pumpAuthScreen(
            tester,
            signInAction:
                (
              email,
              password,
            ) async {
              throw Exception(
                'test login error',
              );
            },
          );

          await fillLoginForm(
            tester,
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'התחבר',
            ),
          );

          await pumpAction(
            tester,
          );

          expect(
            find.text(
              'אירעה שגיאה. נסה שוב.',
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
    'AuthScreen - sign up validation',
    () {
      testWidgets(
        'name is required when signing up',
        (tester) async {
          var signUpCalls = 0;

          await pumpAuthScreen(
            tester,
            signUpAction:
                (
              name,
              email,
              password,
            ) async {
              signUpCalls++;

              return true;
            },
          );

          await switchToSignUp(
            tester,
          );

          await fillSignUpForm(
            tester,
            name: '',
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'הרשם',
            ),
          );

          await pumpAction(
            tester,
          );

          expect(
            find.text(
              'יש להזין שם',
            ),
            findsOneWidget,
          );

          expect(
            signUpCalls,
            0,
          );

          await clearSnackBar(
            tester,
          );
        },
      );

      testWidgets(
        'email and password are required when signing up',
        (tester) async {
          var signUpCalls = 0;

          await pumpAuthScreen(
            tester,
            signUpAction:
                (
              name,
              email,
              password,
            ) async {
              signUpCalls++;

              return true;
            },
          );

          await switchToSignUp(
            tester,
          );

          await fillSignUpForm(
            tester,
            name: 'Test User',
            email: '',
            password: '',
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'הרשם',
            ),
          );

          await pumpAction(
            tester,
          );

          expect(
            find.text(
              'יש למלא אימייל וסיסמה',
            ),
            findsOneWidget,
          );

          expect(
            signUpCalls,
            0,
          );

          await clearSnackBar(
            tester,
          );
        },
      );
    },
  );

  group(
    'AuthScreen - sign up action',
    () {
      testWidgets(
        'successful sign up sends correct values',
        (tester) async {
          var signUpCalls = 0;

          String? receivedName;
          String? receivedEmail;
          String? receivedPassword;

          await pumpAuthScreen(
            tester,
            signUpAction:
                (
              name,
              email,
              password,
            ) async {
              signUpCalls++;

              receivedName =
                  name;

              receivedEmail =
                  email;

              receivedPassword =
                  password;

              return true;
            },
          );

          await switchToSignUp(
            tester,
          );

          await fillSignUpForm(
            tester,
            name:
                'Test User',
            email:
                'test@example.com',
            password:
                'password123',
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'הרשם',
            ),
          );

          await pumpAction(
            tester,
          );

          expect(
            signUpCalls,
            1,
          );

          expect(
            receivedName,
            'Test User',
          );

          expect(
            receivedEmail,
            'test@example.com',
          );

          expect(
            receivedPassword,
            'password123',
          );
        },
      );

      testWidgets(
        'sign up values are trimmed',
        (tester) async {
          String? receivedName;
          String? receivedEmail;
          String? receivedPassword;

          await pumpAuthScreen(
            tester,
            signUpAction:
                (
              name,
              email,
              password,
            ) async {
              receivedName =
                  name;

              receivedEmail =
                  email;

              receivedPassword =
                  password;

              return true;
            },
          );

          await switchToSignUp(
            tester,
          );

          await fillSignUpForm(
            tester,
            name:
                '  Test User  ',
            email:
                '  test@example.com  ',
            password:
                '  password123  ',
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'הרשם',
            ),
          );

          await pumpAction(
            tester,
          );

          expect(
            receivedName,
            'Test User',
          );

          expect(
            receivedEmail,
            'test@example.com',
          );

          expect(
            receivedPassword,
            'password123',
          );
        },
      );

      testWidgets(
        'sign up without session shows email confirmation message and returns to login',
        (tester) async {
          await pumpAuthScreen(
            tester,
            signUpAction:
                (
              name,
              email,
              password,
            ) async {
              return false;
            },
          );

          await switchToSignUp(
            tester,
          );

          await fillSignUpForm(
            tester,
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'הרשם',
            ),
          );

          await pumpAction(
            tester,
          );

          expect(
            find.text(
              'החשבון נוצר. יש לאשר את האימייל לפני ההתחברות.',
            ),
            findsOneWidget,
          );

          // Screen should return to login mode.
          expect(
            find.text(
              'ברוך הבא',
            ),
            findsOneWidget,
          );

          expect(
            fieldWithLabel(
              'שם',
            ),
            findsNothing,
          );

          expect(
            find.widgetWithText(
              ElevatedButton,
              'התחבר',
            ),
            findsOneWidget,
          );

          await clearSnackBar(
            tester,
          );
        },
      );

      testWidgets(
        'sign up with active session does not show email confirmation message',
        (tester) async {
          await pumpAuthScreen(
            tester,
            signUpAction:
                (
              name,
              email,
              password,
            ) async {
              return true;
            },
          );

          await switchToSignUp(
            tester,
          );

          await fillSignUpForm(
            tester,
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'הרשם',
            ),
          );

          await pumpAction(
            tester,
          );

          expect(
            find.text(
              'החשבון נוצר. יש לאשר את האימייל לפני ההתחברות.',
            ),
            findsNothing,
          );

          // In the isolated Widget Test there is
          // no AppNavigation listening to the real
          // Supabase auth state, so the screen
          // simply remains in sign-up mode.
          expect(
            find.text(
              'יצירת חשבון',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'AuthException during sign up shows auth message',
        (tester) async {
          await pumpAuthScreen(
            tester,
            signUpAction:
                (
              name,
              email,
              password,
            ) async {
              throw const AuthException(
                'User already registered',
              );
            },
          );

          await switchToSignUp(
            tester,
          );

          await fillSignUpForm(
            tester,
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'הרשם',
            ),
          );

          await pumpAction(
            tester,
          );

          expect(
            find.text(
              'User already registered',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'יצירת חשבון',
            ),
            findsOneWidget,
          );

          await clearSnackBar(
            tester,
          );
        },
      );

      testWidgets(
        'unexpected sign up error shows general message',
        (tester) async {
          await pumpAuthScreen(
            tester,
            signUpAction:
                (
              name,
              email,
              password,
            ) async {
              throw Exception(
                'test signup error',
              );
            },
          );

          await switchToSignUp(
            tester,
          );

          await fillSignUpForm(
            tester,
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'הרשם',
            ),
          );

          await pumpAction(
            tester,
          );

          expect(
            find.text(
              'אירעה שגיאה. נסה שוב.',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'יצירת חשבון',
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
    'AuthScreen - loading state',
    () {
      testWidgets(
        'login shows loading indicator and disables buttons while request is running',
        (tester) async {
          final completer =
              Completer<void>();

          await pumpAuthScreen(
            tester,
            signInAction:
                (
              email,
              password,
            ) {
              return completer.future;
            },
          );

          await fillLoginForm(
            tester,
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'התחבר',
            ),
          );

          // Do not use pumpAndSettle because
          // the Future intentionally remains
          // incomplete here.
          await tester.pump();

          expect(
            find.byType(
              CircularProgressIndicator,
            ),
            findsOneWidget,
          );

          expect(
            find.widgetWithText(
              ElevatedButton,
              'התחבר',
            ),
            findsNothing,
          );

          final submitButton =
              tester.widget<
                  ElevatedButton>(
            find.byType(
              ElevatedButton,
            ),
          );

          expect(
            submitButton.onPressed,
            isNull,
          );

          final switchButton =
              tester.widget<TextButton>(
            find.byType(
              TextButton,
            ),
          );

          expect(
            switchButton.onPressed,
            isNull,
          );

          completer.complete();

          await tester.pumpAndSettle();

          expect(
            find.byType(
              CircularProgressIndicator,
            ),
            findsNothing,
          );

          expect(
            find.widgetWithText(
              ElevatedButton,
              'התחבר',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'sign up shows loading indicator while request is running',
        (tester) async {
          final completer =
              Completer<bool>();

          await pumpAuthScreen(
            tester,
            signUpAction:
                (
              name,
              email,
              password,
            ) {
              return completer.future;
            },
          );

          await switchToSignUp(
            tester,
          );

          await fillSignUpForm(
            tester,
          );

          await tester.tap(
            find.widgetWithText(
              ElevatedButton,
              'הרשם',
            ),
          );

          await tester.pump();

          expect(
            find.byType(
              CircularProgressIndicator,
            ),
            findsOneWidget,
          );

          final submitButton =
              tester.widget<
                  ElevatedButton>(
            find.byType(
              ElevatedButton,
            ),
          );

          expect(
            submitButton.onPressed,
            isNull,
          );

          completer.complete(
            true,
          );

          await tester.pumpAndSettle();

          expect(
            find.byType(
              CircularProgressIndicator,
            ),
            findsNothing,
          );

          expect(
            find.widgetWithText(
              ElevatedButton,
              'הרשם',
            ),
            findsOneWidget,
          );
        },
      );
    },
  );
}