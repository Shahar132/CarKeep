import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/app_navigation.dart';
import '../../lib/theme/app_theme.dart';

class FakeAuthScreen extends StatelessWidget {
  const FakeAuthScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'AUTH SCREEN',
        ),
      ),
    );
  }
}

class FakeHomeScreen extends StatelessWidget {
  const FakeHomeScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'HOME SCREEN',
        ),
      ),
    );
  }
}

Future<void> pumpNavigation(
  WidgetTester tester, {
  required StreamController<Object?>
      authController,
  required bool Function()
      isAuthenticatedProvider,
}) async {
  await tester.pumpWidget(
    AppNavigation(
      authStateStream:
          authController.stream,
      isAuthenticatedProvider:
          isAuthenticatedProvider,
      authScreenBuilder:
          () =>
              const FakeAuthScreen(),
      homeScreenBuilder:
          () =>
              const FakeHomeScreen(),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  group(
    'AppNavigation - authentication',
    () {
      testWidgets(
        'shows auth screen when user is not authenticated',
        (tester) async {
          final controller =
              StreamController<Object?>();

          addTearDown(
            controller.close,
          );

          var isAuthenticated =
              false;

          await pumpNavigation(
            tester,
            authController:
                controller,
            isAuthenticatedProvider:
                () =>
                    isAuthenticated,
          );

          expect(
            find.text(
              'AUTH SCREEN',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'HOME SCREEN',
            ),
            findsNothing,
          );
        },
      );

      testWidgets(
        'shows home screen when user is authenticated',
        (tester) async {
          final controller =
              StreamController<Object?>();

          addTearDown(
            controller.close,
          );

          var isAuthenticated =
              true;

          await pumpNavigation(
            tester,
            authController:
                controller,
            isAuthenticatedProvider:
                () =>
                    isAuthenticated,
          );

          expect(
            find.text(
              'HOME SCREEN',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'AUTH SCREEN',
            ),
            findsNothing,
          );
        },
      );

      testWidgets(
        'switches from auth to home after authentication state changes',
        (tester) async {
          final controller =
              StreamController<Object?>();

          addTearDown(
            controller.close,
          );

          var isAuthenticated =
              false;

          await pumpNavigation(
            tester,
            authController:
                controller,
            isAuthenticatedProvider:
                () =>
                    isAuthenticated,
          );

          expect(
            find.text(
              'AUTH SCREEN',
            ),
            findsOneWidget,
          );

          isAuthenticated = true;

          controller.add(
            Object(),
          );

          await tester
              .pumpAndSettle();

          expect(
            find.text(
              'HOME SCREEN',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'AUTH SCREEN',
            ),
            findsNothing,
          );
        },
      );

      testWidgets(
        'switches from home to auth after logout',
        (tester) async {
          final controller =
              StreamController<Object?>();

          addTearDown(
            controller.close,
          );

          var isAuthenticated =
              true;

          await pumpNavigation(
            tester,
            authController:
                controller,
            isAuthenticatedProvider:
                () =>
                    isAuthenticated,
          );

          expect(
            find.text(
              'HOME SCREEN',
            ),
            findsOneWidget,
          );

          isAuthenticated = false;

          controller.add(
            Object(),
          );

          await tester
              .pumpAndSettle();

          expect(
            find.text(
              'AUTH SCREEN',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'HOME SCREEN',
            ),
            findsNothing,
          );
        },
      );

      testWidgets(
        'auth state stream causes authentication provider to be checked again',
        (tester) async {
          final controller =
              StreamController<Object?>();

          addTearDown(
            controller.close,
          );

          var providerCalls = 0;
          var isAuthenticated =
              false;

          await pumpNavigation(
            tester,
            authController:
                controller,
            isAuthenticatedProvider:
                () {
              providerCalls++;

              return isAuthenticated;
            },
          );

          final callsBeforeEvent =
              providerCalls;

          isAuthenticated = true;

          controller.add(
            Object(),
          );

          await tester
              .pumpAndSettle();

          expect(
            providerCalls,
            greaterThan(
              callsBeforeEvent,
            ),
          );

          expect(
            find.text(
              'HOME SCREEN',
            ),
            findsOneWidget,
          );
        },
      );
    },
  );

  group(
    'AppNavigation - app configuration',
    () {
      testWidgets(
        'uses RTL directionality',
        (tester) async {
          final controller =
              StreamController<Object?>();

          addTearDown(
            controller.close,
          );

          await pumpNavigation(
            tester,
            authController:
                controller,
            isAuthenticatedProvider:
                () => false,
          );

          final authElement =
              tester.element(
            find.text(
              'AUTH SCREEN',
            ),
          );

          expect(
            Directionality.of(
              authElement,
            ),
            TextDirection.rtl,
          );
        },
      );

      testWidgets(
        'uses CarKeep as application title',
        (tester) async {
          final controller =
              StreamController<Object?>();

          addTearDown(
            controller.close,
          );

          await pumpNavigation(
            tester,
            authController:
                controller,
            isAuthenticatedProvider:
                () => false,
          );

          final materialApp =
              tester.widget<
                  MaterialApp>(
            find.byType(
              MaterialApp,
            ),
          );

          expect(
            materialApp.title,
            'CarKeep',
          );
        },
      );

      testWidgets(
        'debug banner is disabled',
        (tester) async {
          final controller =
              StreamController<Object?>();

          addTearDown(
            controller.close,
          );

          await pumpNavigation(
            tester,
            authController:
                controller,
            isAuthenticatedProvider:
                () => false,
          );

          final materialApp =
              tester.widget<
                  MaterialApp>(
            find.byType(
              MaterialApp,
            ),
          );

          expect(
            materialApp
                .debugShowCheckedModeBanner,
            isFalse,
          );
        },
      );

      testWidgets(
        'uses the application light theme',
        (tester) async {
          final controller =
              StreamController<Object?>();

          addTearDown(
            controller.close,
          );

          await pumpNavigation(
            tester,
            authController:
                controller,
            isAuthenticatedProvider:
                () => false,
          );

          final authContext =
              tester.element(
            find.text(
              'AUTH SCREEN',
            ),
          );

          final actualTheme =
              Theme.of(
            authContext,
          );

          expect(
            actualTheme.brightness,
            AppTheme
                .lightTheme
                .brightness,
          );

          expect(
            actualTheme
                .colorScheme
                .primary,
            AppTheme
                .lightTheme
                .colorScheme
                .primary,
          );
        },
      );
    },
  );

  group(
    'AppNavigation - screen builders',
    () {
      testWidgets(
        'builds auth screen only when logged out',
        (tester) async {
          final controller =
              StreamController<Object?>();

          addTearDown(
            controller.close,
          );

          var authBuilds = 0;
          var homeBuilds = 0;

          await tester.pumpWidget(
            AppNavigation(
              authStateStream:
                  controller.stream,
              isAuthenticatedProvider:
                  () => false,
              authScreenBuilder:
                  () {
                authBuilds++;

                return const FakeAuthScreen();
              },
              homeScreenBuilder:
                  () {
                homeBuilds++;

                return const FakeHomeScreen();
              },
            ),
          );

          await tester
              .pumpAndSettle();

          expect(
            authBuilds,
            greaterThanOrEqualTo(
              1,
            ),
          );

          expect(
            homeBuilds,
            0,
          );

          expect(
            find.text(
              'AUTH SCREEN',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'builds home screen only when logged in',
        (tester) async {
          final controller =
              StreamController<Object?>();

          addTearDown(
            controller.close,
          );

          var authBuilds = 0;
          var homeBuilds = 0;

          await tester.pumpWidget(
            AppNavigation(
              authStateStream:
                  controller.stream,
              isAuthenticatedProvider:
                  () => true,
              authScreenBuilder:
                  () {
                authBuilds++;

                return const FakeAuthScreen();
              },
              homeScreenBuilder:
                  () {
                homeBuilds++;

                return const FakeHomeScreen();
              },
            ),
          );

          await tester
              .pumpAndSettle();

          expect(
            homeBuilds,
            greaterThanOrEqualTo(
              1,
            ),
          );

          expect(
            authBuilds,
            0,
          );

          expect(
            find.text(
              'HOME SCREEN',
            ),
            findsOneWidget,
          );
        },
      );
    },
  );
}