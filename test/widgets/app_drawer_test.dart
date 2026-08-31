import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/widgets/app_drawer.dart';

void main() {
  Widget buildTestWidget({
    VoidCallback? onVehiclesTap,
    VoidCallback? onAccountTap,
    bool vehiclesSelected = false,
    bool accountSelected = false,
    String? userName = 'שחר',
    String? userEmail = 'test@example.com',
  }) {
    return MaterialApp(
      home: Scaffold(
        body: AppDrawer(
          onVehiclesTap:
              onVehiclesTap ?? () {},
          onAccountTap:
              onAccountTap ?? () {},
          vehiclesSelected:
              vehiclesSelected,
          accountSelected:
              accountSelected,
          userName: userName,
          userEmail: userEmail,
        ),
      ),
    );
  }

  group('AppDrawer', () {
    testWidgets(
      'shows user name and email',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(),
        );

        expect(
          find.text('שחר'),
          findsOneWidget,
        );

        expect(
          find.text(
            'test@example.com',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows main navigation items',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(),
        );

        expect(
          find.text('הרכבים שלי'),
          findsOneWidget,
        );

        expect(
          find.text('החשבון שלי'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows CarKeep branding',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(),
        );

        expect(
          find.text('CarKeep'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'calls vehicles callback when vehicles item is tapped',
      (tester) async {
        var tapped = false;

        await tester.pumpWidget(
          buildTestWidget(
            onVehiclesTap: () {
              tapped = true;
            },
          ),
        );

        await tester.tap(
          find.text('הרכבים שלי'),
        );

        await tester.pump();

        expect(
          tapped,
          isTrue,
        );
      },
    );

    testWidgets(
      'calls account callback when account item is tapped',
      (tester) async {
        var tapped = false;

        await tester.pumpWidget(
          buildTestWidget(
            onAccountTap: () {
              tapped = true;
            },
          ),
        );

        await tester.tap(
          find.text('החשבון שלי'),
        );

        await tester.pump();

        expect(
          tapped,
          isTrue,
        );
      },
    );

    testWidgets(
      'shows selected indicator for selected menu item',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            vehiclesSelected: true,
          ),
        );

        expect(
          find.byIcon(Icons.circle),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows fallback user name when supplied name is empty',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            userName: '   ',
          ),
        );

        expect(
          find.text('משתמש'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'hides email when supplied email is empty',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            userEmail: '',
          ),
        );

        expect(
          find.text(
            'test@example.com',
          ),
          findsNothing,
        );
      },
    );
  });
}