import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/vehicle.dart';
import '../../lib/models/vehicle_member.dart';
import '../../lib/screens/manage_vehicle_members_screen.dart';

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

Map<String, dynamic> ownerMember() {
  return {
    'user_id': 'owner-1',
    'name': 'Owner User',
    'email': 'owner@test.com',
    'role': 'owner',
  };
}

Map<String, dynamic> regularMember() {
  return {
    'user_id': 'member-1',
    'name': 'Regular Member',
    'email': 'member@test.com',
    'role': 'member',
  };
}

Map<String, dynamic> adminMember() {
  return {
    'user_id': 'admin-1',
    'name': 'Admin User',
    'email': 'admin@test.com',
    'role': 'admin',
  };
}

Future<void> pumpMembersScreen(
  WidgetTester tester, {
  required Vehicle vehicle,
  required Future<List<Map<String, dynamic>>>
      Function(String vehicleId)
      membersLoader,
  Future<void> Function(
    String vehicleId,
    String email,
  )? addMemberAction,
  Future<void> Function(
    String vehicleId,
    String userId,
    VehicleMemberRole newRole,
  )? changeRoleAction,
  Future<void> Function(
    String vehicleId,
    String userId,
  )? removeMemberAction,
  Future<void> Function(
    String vehicleId,
    String newOwnerUserId,
  )? transferOwnershipAction,
  String? Function()?
      currentUserIdProvider,
}) async {
  await tester.binding.setSurfaceSize(
    const Size(
      900,
      1600,
    ),
  );

  addTearDown(() async {
    await tester.binding.setSurfaceSize(
      null,
    );
  });

  // Keep a route underneath the tested screen.
  // This is important because ownership transfer
  // closes ManageVehicleMembersScreen.
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
          ManageVehicleMembersScreen(
        vehicle: vehicle,
        membersLoader:
            membersLoader,
        addMemberAction:
            addMemberAction,
        changeRoleAction:
            changeRoleAction,
        removeMemberAction:
            removeMemberAction,
        transferOwnershipAction:
            transferOwnershipAction,
        currentUserIdProvider:
            currentUserIdProvider ??
                () => 'owner-1',
      ),
    ),
  );

  await tester.pumpAndSettle();
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
    'ManageVehicleMembersScreen - loading and display',
    () {
      testWidgets(
        'owner sees vehicle and member information',
        (tester) async {
          final vehicle =
              createVehicle();

          await pumpMembersScreen(
            tester,
            vehicle: vehicle,
            membersLoader:
                (_) async => [
              ownerMember(),
              regularMember(),
              adminMember(),
            ],
          );

          expect(
            find.text(
              'ניהול משתמשים',
            ),
            findsOneWidget,
          );

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

          expect(
            find.text(
              'משתמשי הרכב',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'Owner User',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'Regular Member',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'Admin User',
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

          expect(
            find.text(
              'הוסף משתמש',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'marks current user correctly',
        (tester) async {
          await pumpMembersScreen(
            tester,
            vehicle:
                createVehicle(),
            membersLoader:
                (_) async => [
              ownerMember(),
              regularMember(),
            ],
            currentUserIdProvider:
                () => 'owner-1',
          );

          expect(
            find.text(
              '(אתה)',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'shows message when owner is the only member',
        (tester) async {
          await pumpMembersScreen(
            tester,
            vehicle:
                createVehicle(),
            membersLoader:
                (_) async => [
              ownerMember(),
            ],
          );

          expect(
            find.text(
              'כרגע רק אתה משויך לרכב.',
            ),
            findsOneWidget,
          );

          expect(
            find.byIcon(
              Icons.more_vert,
            ),
            findsNothing,
          );
        },
      );

      testWidgets(
        'non owner cannot manage members',
        (tester) async {
          var loaderCalls = 0;

          await pumpMembersScreen(
            tester,
            vehicle:
                createVehicle(
              role:
                  VehicleMemberRole.admin,
            ),
            membersLoader:
                (_) async {
              loaderCalls++;

              return [
                ownerMember(),
              ];
            },
          );

          expect(
            find.text(
              'רק בעל הרכב יכול לנהל משתמשים.',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'הוסף משתמש',
            ),
            findsNothing,
          );

          expect(
            loaderCalls,
            0,
          );
        },
      );

      testWidgets(
        'shows vehicle id error when vehicle id is null',
        (tester) async {
          var loaderCalls = 0;

          await pumpMembersScreen(
            tester,
            vehicle:
                createVehicle(
              id: null,
            ),
            membersLoader:
                (_) async {
              loaderCalls++;

              return [];
            },
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

          expect(
            loaderCalls,
            0,
          );
        },
      );

      testWidgets(
        'shows load error and retry works',
        (tester) async {
          var loadAttempts = 0;

          await pumpMembersScreen(
            tester,
            vehicle:
                createVehicle(),
            membersLoader:
                (_) async {
              loadAttempts++;

              if (loadAttempts == 1) {
                throw Exception(
                  'test load error',
                );
              }

              return [
                ownerMember(),
                regularMember(),
              ];
            },
          );

          expect(
            find.text(
              'לא הצלחנו לטעון את משתמשי הרכב.',
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
            loadAttempts,
            2,
          );

          expect(
            find.text(
              'Owner User',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'Regular Member',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'לא הצלחנו לטעון את משתמשי הרכב.',
            ),
            findsNothing,
          );
        },
      );

      testWidgets(
        'uses email when member name is empty',
        (tester) async {
          await pumpMembersScreen(
            tester,
            vehicle:
                createVehicle(),
            membersLoader:
                (_) async => [
              ownerMember(),
              {
                'user_id':
                    'member-2',
                'name': '',
                'email':
                    'fallback@test.com',
                'role':
                    'member',
              },
            ],
          );

          expect(
            find.text(
              'fallback@test.com',
            ),
            findsNWidgets(2),
          );
        },
      );

      testWidgets(
        'non owner members have action buttons but owner does not',
        (tester) async {
          await pumpMembersScreen(
            tester,
            vehicle:
                createVehicle(),
            membersLoader:
                (_) async => [
              ownerMember(),
              regularMember(),
              adminMember(),
            ],
          );

          expect(
            find.byIcon(
              Icons.more_vert,
            ),
            findsNWidgets(2),
          );
        },
      );
    },
  );

  group(
    'ManageVehicleMembersScreen - add member',
    () {
      testWidgets(
        'add member button opens dialog',
        (tester) async {
          await pumpMembersScreen(
            tester,
            vehicle:
                createVehicle(),
            membersLoader:
                (_) async => [
              ownerMember(),
            ],
          );

          await tester.tap(
            find.text(
              'הוסף משתמש',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'הוספת משתמש',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'אימייל',
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
              'הוסף',
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
        'invalid email does not add member',
        (tester) async {
          var addCalls = 0;

          await pumpMembersScreen(
            tester,
            vehicle:
                createVehicle(),
            membersLoader:
                (_) async => [
              ownerMember(),
            ],
            addMemberAction:
                (
              vehicleId,
              email,
            ) async {
              addCalls++;
            },
          );

          await tester.tap(
            find.text(
              'הוסף משתמש',
            ),
          );

          await tester.pumpAndSettle();

          await tester.enterText(
            find.byType(
              TextField,
            ),
            'invalid-email',
          );

          await tester.tap(
            find.text(
              'הוסף',
            ),
          );

          await tester.pump();

          expect(
            addCalls,
            0,
          );

          // Dialog should remain open.
          expect(
            find.text(
              'הוספת משתמש',
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
        'valid email adds member and reloads list',
        (tester) async {
          final members = [
            ownerMember(),
          ];

          var addCalls = 0;

          String? receivedVehicleId;
          String? receivedEmail;

          await pumpMembersScreen(
            tester,
            vehicle:
                createVehicle(),
            membersLoader:
                (_) async => List<
                    Map<String, dynamic>>.from(
              members,
            ),
            addMemberAction:
                (
              vehicleId,
              email,
            ) async {
              addCalls++;

              receivedVehicleId =
                  vehicleId;

              receivedEmail =
                  email;

              members.add({
                'user_id':
                    'new-member',
                'name':
                    'New Member',
                'email':
                    email,
                'role':
                    'member',
              });
            },
          );

          await tester.tap(
            find.text(
              'הוסף משתמש',
            ),
          );

          await tester.pumpAndSettle();

          await tester.enterText(
            find.byType(
              TextField,
            ),
            'new@test.com',
          );

          await tester.tap(
            find.text(
              'הוסף',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            addCalls,
            1,
          );

          expect(
            receivedVehicleId,
            'vehicle-1',
          );

          expect(
            receivedEmail,
            'new@test.com',
          );

          expect(
            find.text(
              'New Member',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'המשתמש נוסף לרכב',
            ),
            findsOneWidget,
          );

          await clearSnackBar(
            tester,
          );
        },
      );

      testWidgets(
        'add member failure shows error message',
        (tester) async {
          await pumpMembersScreen(
            tester,
            vehicle:
                createVehicle(),
            membersLoader:
                (_) async => [
              ownerMember(),
            ],
            addMemberAction:
                (
              vehicleId,
              email,
            ) async {
              throw Exception(
                'test add error',
              );
            },
          );

          await tester.tap(
            find.text(
              'הוסף משתמש',
            ),
          );

          await tester.pumpAndSettle();

          await tester.enterText(
            find.byType(
              TextField,
            ),
            'new@test.com',
          );

          await tester.tap(
            find.text(
              'הוסף',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'לא הצלחנו להוסיף את המשתמש. נסה שוב.',
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
    'ManageVehicleMembersScreen - member actions',
    () {
      testWidgets(
        'member action sheet shows all actions',
        (tester) async {
          await pumpMembersScreen(
            tester,
            vehicle:
                createVehicle(),
            membersLoader:
                (_) async => [
              ownerMember(),
              regularMember(),
            ],
          );

          await tester.tap(
            find.byIcon(
              Icons.more_vert,
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'הפוך למנהל',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'העבר בעלות',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'הסר מהרכב',
            ),
            findsOneWidget,
          );

          Navigator.of(
            tester.element(
              find.text(
                'הפוך למנהל',
              ),
            ),
          ).pop();

          await tester.pumpAndSettle();
        },
      );

      testWidgets(
        'admin action sheet offers change to member',
        (tester) async {
          await pumpMembersScreen(
            tester,
            vehicle:
                createVehicle(),
            membersLoader:
                (_) async => [
              ownerMember(),
              adminMember(),
            ],
          );

          await tester.tap(
            find.byIcon(
              Icons.more_vert,
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'הפוך למשתמש',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'הפוך למנהל',
            ),
            findsNothing,
          );

          Navigator.of(
            tester.element(
              find.text(
                'הפוך למשתמש',
              ),
            ),
          ).pop();

          await tester.pumpAndSettle();
        },
      );

      testWidgets(
        'changes member to admin',
        (tester) async {
          final members = [
            ownerMember(),
            regularMember(),
          ];

          var changeCalls = 0;

          String? changedUserId;

          VehicleMemberRole?
              receivedRole;

          await pumpMembersScreen(
            tester,
            vehicle:
                createVehicle(),
            membersLoader:
                (_) async => List<
                    Map<String, dynamic>>.from(
              members,
            ),
            changeRoleAction:
                (
              vehicleId,
              userId,
              newRole,
            ) async {
              changeCalls++;

              changedUserId =
                  userId;

              receivedRole =
                  newRole;

              members[1]['role'] =
                  newRole.databaseValue;
            },
          );

          await tester.tap(
            find.byIcon(
              Icons.more_vert,
            ),
          );

          await tester.pumpAndSettle();

          await tester.tap(
            find.text(
              'הפוך למנהל',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            changeCalls,
            1,
          );

          expect(
            changedUserId,
            'member-1',
          );

          expect(
            receivedRole,
            VehicleMemberRole.admin,
          );

          expect(
            find.text(
              'המשתמש הפך למנהל',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'מנהל',
            ),
            findsOneWidget,
          );

          await clearSnackBar(
            tester,
          );
        },
      );

      testWidgets(
        'changes admin back to member',
        (tester) async {
          final members = [
            ownerMember(),
            adminMember(),
          ];

          VehicleMemberRole?
              receivedRole;

          await pumpMembersScreen(
            tester,
            vehicle:
                createVehicle(),
            membersLoader:
                (_) async => List<
                    Map<String, dynamic>>.from(
              members,
            ),
            changeRoleAction:
                (
              vehicleId,
              userId,
              newRole,
            ) async {
              receivedRole =
                  newRole;

              members[1]['role'] =
                  newRole.databaseValue;
            },
          );

          await tester.tap(
            find.byIcon(
              Icons.more_vert,
            ),
          );

          await tester.pumpAndSettle();

          await tester.tap(
            find.text(
              'הפוך למשתמש',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            receivedRole,
            VehicleMemberRole.member,
          );

          expect(
            find.text(
              'המנהל הפך למשתמש',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'משתמש',
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
    'ManageVehicleMembersScreen - remove member',
    () {
      testWidgets(
        'canceling remove confirmation does not remove member',
        (tester) async {
          var removeCalls = 0;

          await pumpMembersScreen(
            tester,
            vehicle:
                createVehicle(),
            membersLoader:
                (_) async => [
              ownerMember(),
              regularMember(),
            ],
            removeMemberAction:
                (
              vehicleId,
              userId,
            ) async {
              removeCalls++;
            },
          );

          await tester.tap(
            find.byIcon(
              Icons.more_vert,
            ),
          );

          await tester.pumpAndSettle();

          await tester.tap(
            find.text(
              'הסר מהרכב',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'הסרת משתמש',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'האם להסיר את Regular Member מהרכב?',
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
            removeCalls,
            0,
          );

          expect(
            find.text(
              'Regular Member',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'confirmed remove deletes member and reloads list',
        (tester) async {
          final members = [
            ownerMember(),
            regularMember(),
          ];

          var removeCalls = 0;
          String? removedUserId;

          await pumpMembersScreen(
            tester,
            vehicle:
                createVehicle(),
            membersLoader:
                (_) async => List<
                    Map<String, dynamic>>.from(
              members,
            ),
            removeMemberAction:
                (
              vehicleId,
              userId,
            ) async {
              removeCalls++;

              removedUserId =
                  userId;

              members.removeWhere(
                (member) =>
                    member['user_id'] ==
                    userId,
              );
            },
          );

          await tester.tap(
            find.byIcon(
              Icons.more_vert,
            ),
          );

          await tester.pumpAndSettle();

          await tester.tap(
            find.text(
              'הסר מהרכב',
            ),
          );

          await tester.pumpAndSettle();

          await tester.tap(
            find.text(
              'הסר',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            removeCalls,
            1,
          );

          expect(
            removedUserId,
            'member-1',
          );

          expect(
            find.text(
              'Regular Member',
            ),
            findsNothing,
          );

          expect(
            find.text(
              'כרגע רק אתה משויך לרכב.',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'המשתמש הוסר מהרכב',
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
    'ManageVehicleMembersScreen - ownership transfer',
    () {
      testWidgets(
        'canceling ownership transfer does nothing',
        (tester) async {
          var transferCalls = 0;

          final vehicle =
              createVehicle();

          await pumpMembersScreen(
            tester,
            vehicle: vehicle,
            membersLoader:
                (_) async => [
              ownerMember(),
              regularMember(),
            ],
            transferOwnershipAction:
                (
              vehicleId,
              newOwnerUserId,
            ) async {
              transferCalls++;
            },
          );

          await tester.tap(
            find.byIcon(
              Icons.more_vert,
            ),
          );

          await tester.pumpAndSettle();

          await tester.tap(
            find.text(
              'העבר בעלות',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.text(
              'העברת בעלות',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'האם להעביר את הבעלות על הרכב '
              'לRegular Member?',
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
            transferCalls,
            0,
          );

          expect(
            vehicle.currentUserRole,
            VehicleMemberRole.owner,
          );

          expect(
            find.text(
              'Regular Member',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'confirmed ownership transfer changes current owner to admin',
        (tester) async {
          var transferCalls = 0;

          String? receivedVehicleId;
          String? receivedNewOwnerId;

          final vehicle =
              createVehicle();

          await pumpMembersScreen(
            tester,
            vehicle: vehicle,
            membersLoader:
                (_) async => [
              ownerMember(),
              regularMember(),
            ],
            transferOwnershipAction:
                (
              vehicleId,
              newOwnerUserId,
            ) async {
              transferCalls++;

              receivedVehicleId =
                  vehicleId;

              receivedNewOwnerId =
                  newOwnerUserId;
            },
          );

          await tester.tap(
            find.byIcon(
              Icons.more_vert,
            ),
          );

          await tester.pumpAndSettle();

          await tester.tap(
            find.text(
              'העבר בעלות',
            ),
          );

          await tester.pumpAndSettle();

          await tester.tap(
            find.text(
              'העבר בעלות',
            ),
          );

          await tester.pumpAndSettle();

          expect(
            transferCalls,
            1,
          );

          expect(
            receivedVehicleId,
            'vehicle-1',
          );

          expect(
            receivedNewOwnerId,
            'member-1',
          );

          expect(
            vehicle.currentUserRole,
            VehicleMemberRole.admin,
          );

          // Successful ownership transfer
          // closes the management screen.
          expect(
            find.text(
              'ROOT',
            ),
            findsOneWidget,
          );

          expect(
            find.text(
              'ניהול משתמשים',
            ),
            findsNothing,
          );
        },
      );
    },
  );
}