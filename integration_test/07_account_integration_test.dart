import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../lib/models/vehicle.dart';
import '../lib/models/vehicle_document.dart';
import '../lib/models/vehicle_event.dart';
import '../lib/models/vehicle_insurance.dart';
import '../lib/repositories/vehicle_document_repository.dart';
import '../lib/repositories/vehicle_repository.dart';

import 'helpers/integration_config.dart';
import 'helpers/supabase_test_clients.dart';
import 'helpers/test_data_factory.dart';
import 'helpers/test_users.dart';

int _userCounter = 0;

IntegrationTestUser _createUniqueUser(
  String suffix,
) {
  _userCounter++;

  return IntegrationTestUser(
    label:
        'Account Test $suffix',
    name:
        'CarKeep $suffix',
    email:
        'carkeep.account.$suffix.'
        '${IntegrationConfig.runId}.'
        '$_userCounter@example.com',
    password:
        'CarKeepTest!2026$suffix$_userCounter',
    expectedVehicleRole:
        'member',
  );
}

class _DeleteAccountResult {
  final int status;
  final Map<String, dynamic> data;

  const _DeleteAccountResult({
    required this.status,
    required this.data,
  });
}

Map<String, dynamic> _responseMap(
  dynamic value,
) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(
      value,
    );
  }

  if (value is String) {
    try {
      final decoded =
          jsonDecode(value);

      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded,
        );
      }
    } catch (_) {}
  }

  return {};
}

Future<_DeleteAccountResult>
    _invokeDeleteAccount(
  SupabaseClient client,
) async {
  try {
    final response =
        await client.functions.invoke(
      'delete-account',
    );

    return _DeleteAccountResult(
      status:
          response.status,
      data:
          _responseMap(
        response.data,
      ),
    );
  } on FunctionException catch (error) {
    return _DeleteAccountResult(
      status:
          error.status,
      data:
          _responseMap(
        error.details,
      ),
    );
  }
}

Future<bool> _canLogin(
  IntegrationTestUser user, {
  String? password,
}) async {
  final client =
      SupabaseTestClients.createClient();

  try {
    await client.auth
        .signInWithPassword(
      email:
          user.email,
      password:
          password ??
              user.password,
    );

    await SupabaseTestClients
        .signOutQuietly(
      client,
    );

    return true;
  } catch (_) {
    return false;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group(
    'CarKeep Account Integration Tests',
    () {
      testWidgets(
        'name password vehicle deletion and account deletion rules work correctly',
        (tester) async {
          IntegrationConfig.validate();

          final clients =
              <SupabaseClient>[];

          final vehiclesToCleanup =
              <MapEntry<
                  SupabaseClient,
                  String>>[];

          try {
            // ==========================================================
            // CHANGE NAME + PASSWORD
            // ==========================================================

            final profileUser =
                _createUniqueUser(
              'Profile',
            );

            final profileClient =
                await SupabaseTestClients
                    .createAuthenticatedUser(
              profileUser,
            );

            clients.add(
              profileClient,
            );

            final profileUserId =
                SupabaseTestClients
                    .requireCurrentUserId(
              profileClient,
            );

            const newName =
                'Shahar Test';

            await profileClient.auth
                .updateUser(
              UserAttributes(
                data: {
                  'name': newName,
                },
              ),
            );

            await profileClient
                .from(
                  IntegrationConfig
                      .profilesTable,
                )
                .update({
                  'name': newName,
                })
                .eq(
                  'id',
                  profileUserId,
                );

            final updatedProfile =
                await profileClient
                    .from(
                      IntegrationConfig
                          .profilesTable,
                    )
                    .select(
                      'name',
                    )
                    .eq(
                      'id',
                      profileUserId,
                    )
                    .single();

            expect(
              updatedProfile['name'],
              newName,
            );

            final updatedAuthUser =
                await profileClient.auth
                    .getUser();

            expect(
              updatedAuthUser
                  .user
                  ?.userMetadata?['name'],
              newName,
            );

            // Change password.
            const newPassword =
                'CarKeepTest!2026NewPassword';

            await profileClient.auth
                .updateUser(
               UserAttributes(
                password:
                    newPassword,
              ),
            );

            await profileClient.auth
                .signOut();

            expect(
              await _canLogin(
                profileUser,
              ),
              isFalse,
              reason:
                  'Old password must stop working after password change.',
            );

            expect(
              await _canLogin(
                profileUser,
                password:
                    newPassword,
              ),
              isTrue,
            );

            // ==========================================================
            // DELETE VEHICLE + CASCADE
            // ==========================================================

            final deleteVehicleOwner =
                _createUniqueUser(
              'VehicleOwner',
            );

            final deleteVehicleMember =
                _createUniqueUser(
              'VehicleMember',
            );

            final deleteVehicleOwnerClient =
                await SupabaseTestClients
                    .createAuthenticatedUser(
              deleteVehicleOwner,
            );

            final deleteVehicleMemberClient =
                await SupabaseTestClients
                    .createAuthenticatedUser(
              deleteVehicleMember,
            );

            clients.addAll([
              deleteVehicleOwnerClient,
              deleteVehicleMemberClient,
            ]);

            final deleteVehicleRepository =
                VehicleRepository(
              supabase:
                  deleteVehicleOwnerClient,
            );

            final deleteVehicleDocumentRepository =
                VehicleDocumentRepository(
              supabase:
                  deleteVehicleOwnerClient,
            );

            final deletionVehicleData =
                IntegrationTestDataFactory
                    .createVehicle();

            final deletionVehicle =
                await deleteVehicleRepository
                    .addVehicle(
              Vehicle(
                license:
                    deletionVehicleData
                        .licenseNumber,
                manufacturer:
                    'Toyota',
                model:
                    'Delete Test',
                year:
                    2022,
                mileage:
                    50000,
              ),
            );

            final deletionVehicleId =
                deletionVehicle.id!;

            await deleteVehicleOwnerClient
                .rpc(
              'add_vehicle_member_by_email',
              params: {
                'target_vehicle_id':
                    deletionVehicleId,
                'member_email':
                    deleteVehicleMember
                        .email,
              },
            );

            await deleteVehicleRepository
                .addVehicleEvent(
              VehicleEvent(
                vehicleId:
                    deletionVehicleId,
                type:
                    VehicleEventType.test,
                date:
                    DateTime(2027, 1, 1),
                title:
                    'Delete vehicle event',
              ),
            );

            await deleteVehicleRepository
                .saveInsurance(
              VehicleInsurance(
                vehicleId:
                    deletionVehicleId,
                type:
                    InsuranceType
                        .mandatory,
                expiryDate:
                    DateTime(2027, 1, 1),
              ),
            );

            final deletionDocument =
                await deleteVehicleDocumentRepository
                    .uploadDocument(
              vehicleId:
                  deletionVehicleId,
              displayName:
                  'Delete vehicle document',
              originalFileName:
                  'delete.txt',
              fileBytes:
                  IntegrationTestDataFactory
                      .createTestFileBytes(),
              category:
                  VehicleDocumentCategory
                      .other,
            );

            await deleteVehicleRepository
                .deleteVehicle(
              deletionVehicleId,
            );

            expect(
              await VehicleRepository(
                supabase:
                    deleteVehicleMemberClient,
              ).getVehicles(),
              isEmpty,
            );

            Object? deletedVehicleFileError;

            try {
              await deleteVehicleMemberClient
                  .storage
                  .from(
                    IntegrationConfig
                        .storageBucket,
                  )
                  .download(
                    deletionDocument
                        .filePath,
                  );
            } catch (error) {
              deletedVehicleFileError =
                  error;
            }

            expect(
              deletedVehicleFileError,
              isNotNull,
            );

            // ==========================================================
            // DELETE MEMBER + ADMIN ACCOUNTS
            // ==========================================================

            final sharedOwner =
                _createUniqueUser(
              'SharedOwner',
            );

            final deleteAdmin =
                _createUniqueUser(
              'DeleteAdmin',
            );

            final deleteMember =
                _createUniqueUser(
              'DeleteMember',
            );

            final sharedOwnerClient =
                await SupabaseTestClients
                    .createAuthenticatedUser(
              sharedOwner,
            );

            final deleteAdminClient =
                await SupabaseTestClients
                    .createAuthenticatedUser(
              deleteAdmin,
            );

            final deleteMemberClient =
                await SupabaseTestClients
                    .createAuthenticatedUser(
              deleteMember,
            );

            clients.addAll([
              sharedOwnerClient,
              deleteAdminClient,
              deleteMemberClient,
            ]);

            final sharedOwnerRepository =
                VehicleRepository(
              supabase:
                  sharedOwnerClient,
            );

            final sharedData =
                IntegrationTestDataFactory
                    .createVehicle();

            final sharedVehicle =
                await sharedOwnerRepository
                    .addVehicle(
              Vehicle(
                license:
                    sharedData
                        .licenseNumber,
                manufacturer:
                    'Honda',
                model:
                    'Shared',
                year:
                    2023,
                mileage:
                    1000,
              ),
            );

            final sharedVehicleId =
                sharedVehicle.id!;

            vehiclesToCleanup.add(
              MapEntry(
                sharedOwnerClient,
                sharedVehicleId,
              ),
            );

            await sharedOwnerClient
                .rpc(
              'add_vehicle_member_by_email',
              params: {
                'target_vehicle_id':
                    sharedVehicleId,
                'member_email':
                    deleteAdmin.email,
              },
            );

            await sharedOwnerClient
                .rpc(
              'add_vehicle_member_by_email',
              params: {
                'target_vehicle_id':
                    sharedVehicleId,
                'member_email':
                    deleteMember.email,
              },
            );

            final deleteAdminId =
                SupabaseTestClients
                    .requireCurrentUserId(
              deleteAdminClient,
            );

            await sharedOwnerClient
                .from(
                  IntegrationConfig
                      .vehicleMembersTable,
                )
                .update({
                  'role': 'admin',
                })
                .eq(
                  'vehicle_id',
                  sharedVehicleId,
                )
                .eq(
                  'user_id',
                  deleteAdminId,
                );

            final memberDeleteResult =
                await _invokeDeleteAccount(
              deleteMemberClient,
            );

            expect(
              memberDeleteResult.status,
              200,
            );

            expect(
              memberDeleteResult
                  .data['success'],
              true,
            );

            expect(
              await _canLogin(
                deleteMember,
              ),
              isFalse,
            );

            var membersAfterDelete =
                await sharedOwnerClient.rpc(
              'get_vehicle_members_for_owner',
              params: {
                'target_vehicle_id':
                    sharedVehicleId,
              },
            ) as List<dynamic>;

            expect(
              membersAfterDelete.any(
                (row) =>
                    row['email'] ==
                    deleteMember.email,
              ),
              isFalse,
            );

            // Delete Admin account.
            final adminDeleteResult =
                await _invokeDeleteAccount(
              deleteAdminClient,
            );

            expect(
              adminDeleteResult.status,
              200,
            );

            expect(
              adminDeleteResult
                  .data['success'],
              true,
            );

            expect(
              await _canLogin(
                deleteAdmin,
              ),
              isFalse,
            );

            membersAfterDelete =
                await sharedOwnerClient.rpc(
              'get_vehicle_members_for_owner',
              params: {
                'target_vehicle_id':
                    sharedVehicleId,
              },
            ) as List<dynamic>;

            expect(
              membersAfterDelete.length,
              1,
            );

            expect(
              (await sharedOwnerRepository
                      .getVehicles())
                  .any(
                (vehicle) =>
                    vehicle.id ==
                    sharedVehicleId,
              ),
              isTrue,
            );

            // ==========================================================
            // DELETE SOLE OWNER ACCOUNT
            // ==========================================================

            final soleOwner =
                _createUniqueUser(
              'SoleOwner',
            );

            final soleOwnerClient =
                await SupabaseTestClients
                    .createAuthenticatedUser(
              soleOwner,
            );

            clients.add(
              soleOwnerClient,
            );

            final soleRepository =
                VehicleRepository(
              supabase:
                  soleOwnerClient,
            );

            final soleDocRepository =
                VehicleDocumentRepository(
              supabase:
                  soleOwnerClient,
            );

            final soleData =
                IntegrationTestDataFactory
                    .createVehicle();

            final soleVehicle =
                await soleRepository
                    .addVehicle(
              Vehicle(
                license:
                    soleData
                        .licenseNumber,
                manufacturer:
                    'Mazda',
                model:
                    'Solo',
                year:
                    2024,
                mileage:
                    500,
              ),
            );

            await soleDocRepository
                .uploadDocument(
              vehicleId:
                  soleVehicle.id!,
              displayName:
                  'Solo document',
              originalFileName:
                  'solo.txt',
              fileBytes:
                  IntegrationTestDataFactory
                      .createTestFileBytes(),
              category:
                  VehicleDocumentCategory
                      .other,
            );

            final soleDeleteResult =
                await _invokeDeleteAccount(
              soleOwnerClient,
            );

            expect(
              soleDeleteResult.status,
              200,
            );

            expect(
              soleDeleteResult
                  .data['success'],
              true,
            );

            expect(
              await _canLogin(
                soleOwner,
              ),
              isFalse,
            );

            // ==========================================================
            // SHARED OWNER ACCOUNT MUST BE BLOCKED
            // ==========================================================

            final blockedOwner =
                _createUniqueUser(
              'BlockedOwner',
            );

            final blockedMember =
                _createUniqueUser(
              'BlockedMember',
            );

            final blockedOwnerClient =
                await SupabaseTestClients
                    .createAuthenticatedUser(
              blockedOwner,
            );

            final blockedMemberClient =
                await SupabaseTestClients
                    .createAuthenticatedUser(
              blockedMember,
            );

            clients.addAll([
              blockedOwnerClient,
              blockedMemberClient,
            ]);

            final blockedRepository =
                VehicleRepository(
              supabase:
                  blockedOwnerClient,
            );

            final blockedData =
                IntegrationTestDataFactory
                    .createVehicle();

            final blockedVehicle =
                await blockedRepository
                    .addVehicle(
              Vehicle(
                license:
                    blockedData
                        .licenseNumber,
                manufacturer:
                    'Ford',
                model:
                    'Blocked',
                year:
                    2020,
                mileage:
                    20000,
              ),
            );

            vehiclesToCleanup.add(
              MapEntry(
                blockedOwnerClient,
                blockedVehicle.id!,
              ),
            );

            await blockedOwnerClient
                .rpc(
              'add_vehicle_member_by_email',
              params: {
                'target_vehicle_id':
                    blockedVehicle.id!,
                'member_email':
                    blockedMember.email,
              },
            );

            final blockedDeleteResult =
                await _invokeDeleteAccount(
              blockedOwnerClient,
            );

            expect(
              blockedDeleteResult.status,
              409,
            );

            expect(
              blockedDeleteResult
                  .data['success'],
              false,
            );

            expect(
              blockedDeleteResult
                  .data['code'],
              'OWNERSHIP_TRANSFER_REQUIRED',
            );

            // Account still exists.
            final stillExistingUser =
                await blockedOwnerClient
                    .auth
                    .getUser();

            expect(
              stillExistingUser.user,
              isNotNull,
            );

            expect(
              (await blockedRepository
                      .getVehicles())
                  .any(
                (vehicle) =>
                    vehicle.id ==
                    blockedVehicle.id,
              ),
              isTrue,
            );
          } finally {
            for (final entry
                in vehiclesToCleanup.reversed) {
              try {
                await VehicleRepository(
                  supabase:
                      entry.key,
                ).deleteVehicle(
                  entry.value,
                );
              } catch (_) {}
            }

            await SupabaseTestClients
                .signOutAll(
              clients,
            );
          }
        },
      );
    },
  );
}