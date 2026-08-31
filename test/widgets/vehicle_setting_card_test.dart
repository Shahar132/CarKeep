import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/widgets/vehicle_setting_card.dart';

void main() {
  Widget buildTestWidget({
    String title = 'רישיון רכב',
    String? subtitle = 'בתוקף',
    String? actionText = 'חידוש',
    VoidCallback? onActionPressed,
    bool isActionLoading = false,
    bool showOnHome = false,
    ValueChanged<bool>? onShowOnHomeChanged,
    String homeDescription =
        'הצגת תוקף רישיון הרכב',
    Widget? content,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: VehicleSettingCard(
          icon: Icons.badge_outlined,
          title: title,
          subtitle: subtitle,
          actionText: actionText,
          onActionPressed:
              onActionPressed,
          isActionLoading:
              isActionLoading,
          showOnHome:
              showOnHome,
          onShowOnHomeChanged:
              onShowOnHomeChanged,
          homeDescription:
              homeDescription,
          content: content,
        ),
      ),
    );
  }

  group('VehicleSettingCard', () {
    testWidgets(
      'shows title subtitle action and home description',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(),
        );

        expect(
          find.text('רישיון רכב'),
          findsOneWidget,
        );

        expect(
          find.text('בתוקף'),
          findsOneWidget,
        );

        expect(
          find.text('חידוש'),
          findsOneWidget,
        );

        expect(
          find.text(
            'הצג במסך הבית',
          ),
          findsOneWidget,
        );

        expect(
          find.text(
            'הצגת תוקף רישיון הרכב',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'does not show subtitle when subtitle is null',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            subtitle: null,
          ),
        );

        expect(
          find.text('בתוקף'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'does not show blank subtitle',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            subtitle: '   ',
          ),
        );

        expect(
          find.text('   '),
          findsNothing,
        );
      },
    );

    testWidgets(
      'calls action callback when action button is tapped',
      (tester) async {
        var tapped = false;

        await tester.pumpWidget(
          buildTestWidget(
            onActionPressed: () {
              tapped = true;
            },
          ),
        );

        await tester.tap(
          find.text('חידוש'),
        );

        await tester.pump();

        expect(
          tapped,
          isTrue,
        );
      },
    );

    testWidgets(
      'shows loading indicator instead of action text while loading',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            isActionLoading: true,
          ),
        );

        expect(
          find.byType(
            CircularProgressIndicator,
          ),
          findsOneWidget,
        );

        expect(
          find.text('חידוש'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'does not call action while loading',
      (tester) async {
        var tapped = false;

        await tester.pumpWidget(
          buildTestWidget(
            isActionLoading: true,
            onActionPressed: () {
              tapped = true;
            },
          ),
        );

        final button =
            tester.widget<OutlinedButton>(
          find.byType(
            OutlinedButton,
          ),
        );

        expect(
          button.onPressed,
          isNull,
        );

        expect(
          tapped,
          isFalse,
        );
      },
    );

    testWidgets(
      'shows switch with supplied value',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            showOnHome: true,
          ),
        );

        final switchTile =
            tester.widget<SwitchListTile>(
          find.byType(
            SwitchListTile,
          ),
        );

        expect(
          switchTile.value,
          isTrue,
        );
      },
    );

    testWidgets(
      'calls switch callback with new value',
      (tester) async {
        bool? receivedValue;

        await tester.pumpWidget(
          buildTestWidget(
            showOnHome: false,
            onShowOnHomeChanged:
                (value) {
              receivedValue = value;
            },
          ),
        );

        await tester.tap(
          find.byType(
            SwitchListTile,
          ),
        );

        await tester.pump();

        expect(
          receivedValue,
          isTrue,
        );
      },
    );

    testWidgets(
      'disables switch when callback is null',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            onShowOnHomeChanged: null,
          ),
        );

        final switchTile =
            tester.widget<SwitchListTile>(
          find.byType(
            SwitchListTile,
          ),
        );

        expect(
          switchTile.onChanged,
          isNull,
        );
      },
    );

    testWidgets(
      'renders custom content',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            content: const Text(
              'תוכן בדיקה',
            ),
          ),
        );

        expect(
          find.text('תוכן בדיקה'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'does not show action button when action text is null',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            actionText: null,
          ),
        );

        expect(
          find.byType(
            OutlinedButton,
          ),
          findsNothing,
        );
      },
    );
  });
}