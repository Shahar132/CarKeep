import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../lib/models/vehicle.dart';
import '../lib/models/vehicle_document.dart';
import '../lib/models/vehicle_event.dart';
import '../lib/models/vehicle_member.dart';
import '../lib/repositories/vehicle_document_repository.dart';
import '../lib/repositories/vehicle_repository.dart';

import 'helpers/integration_config.dart';
import 'helpers/supabase_test_clients.dart';
import 'helpers/test_data_factory.dart';
import 'helpers/test_users.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group(
    'CarKeep Sharing and Ownership Integration Tests',
    () {
      testWidgets(
        'shared data sync ownership transfer and member removal work correctly',
        (tester) async {
          IntegrationConfig.validate();

          final ownerClient =
              await SupabaseTestClients
                  .createAuthenticatedUser(
            IntegrationTestUsers.owner,
          );

          final adminClient =
              await SupabaseTestClients
                  .createAuthenticatedUser(
            IntegrationTestUsers.admin,
          );

          final memberClient =
              await SupabaseTestClients
                  .createAuthenticatedUser(
            IntegrationTestUsers.member,
          );

          final outsiderClient =
              await SupabaseTestClients
                  .createAuthenticatedUser(
            IntegrationTestUsers.outsider,
          );

          final ownerRepository =
              VehicleRepository(
            supabase: ownerClient,
          );

          final adminRepository =
              VehicleRepository(
            supabase: adminClient,
          );

          final memberRepository =
              VehicleRepository(
            supabase: memberClient,
          );

          final outsiderRepository =
              VehicleRepository(
            supabase: outsiderClient,
          );

          final adminDocumentRepository =
              VehicleDocumentRepository(
            supabase: adminClient,
          );

          String? vehicleId;

          try {
            final data =
                IntegrationTestDataFactory
                    .createVehicle();

            final vehicle =
                await ownerRepository
                    .addVehicle(
              Vehicle(
                license:
                    data.licenseNumber,
                manufacturer:
                    data.manufacturer,
                model: data.model,
                year: data.year,
                mileage: data.mileage,
              ),
            );

            vehicleId =
                vehicle.id!;

            final ownerId =
                SupabaseTestClients
                    .requireCurrentUserId(
              ownerClient,
            );

            final adminId =
                SupabaseTestClients
                    .requireCurrentUserId(
              adminClient,
            );

            final memberId =
                SupabaseTestClients
                    .requireCurrentUserId(
              memberClient,
            );

            // ==========================================================
            // SHARE VEHICLE
            // ==========================================================

            await ownerClient.rpc(
              'add_vehicle_member_by_email',
              params: {
                'target_vehicle_id':
                    vehicleId,
                'member_email':
                    IntegrationTestUsers
                        .admin
                        .email,
              },
            );

            await ownerClient.rpc(
              'add_vehicle_member_by_email',
              params: {
                'target_vehicle_id':
                    vehicleId,
                'member_email':
                    IntegrationTestUsers
                        .member
                        .email,
              },
            );

            await ownerClient
                .from(
                  IntegrationConfig
                      .vehicleMembersTable,
                )
                .update({
                  'role': 'admin',
                })
                .eq(
                  'vehicle_id',
                  vehicleId,
                )
                .eq(
                  'user_id',
                  adminId,
                );

            final fullMembers =
                await ownerClient.rpc(
              'get_vehicle_members_for_owner',
              params: {
                'target_vehicle_id':
                    vehicleId,
              },
            ) as List<dynamic>;

            expect(
              fullMembers.length,
              3,
            );

            // ==========================================================
            // SAME VEHICLE FOR A / B / C
            // ==========================================================

            expect(
              (await ownerRepository
                      .getVehicles())
                  .single
                  .id,
              vehicleId,
            );

            expect(
              (await adminRepository
                      .getVehicles())
                  .single
                  .id,
              vehicleId,
            );

            expect(
              (await memberRepository
                      .getVehicles())
                  .single
                  .id,
              vehicleId,
            );

            expect(
              await outsiderRepository
                  .getVehicles(),
              isEmpty,
            );

            // ==========================================================
            // SYNC MILEAGE
            // ==========================================================

            final ownerVehicle =
                (await ownerRepository
                        .getVehicles())
                    .single;

            ownerVehicle.mileage =
                65000;

            await ownerRepository
                .updateVehicle(
              ownerVehicle,
            );

            expect(
              (await adminRepository
                      .getVehicles())
                  .single
                  .mileage,
              65000,
            );

            expect(
              (await memberRepository
                      .getVehicles())
                  .single
                  .mileage,
              65000,
            );

            // ==========================================================
            // SYNC EVENT
            // ==========================================================

            final testEvent =
                await ownerRepository
                    .addVehicleEvent(
              VehicleEvent(
                vehicleId:
                    vehicleId,
                type:
                    VehicleEventType.test,
                date:
                    DateTime(2027, 8, 31),
                title:
                    'טסט 2027',
              ),
            );

            final memberEvents =
                await memberRepository
                    .getVehicleEvents(
              vehicleId,
            );

            expect(
              memberEvents.any(
                (event) =>
                    event.id ==
                    testEvent.id,
              ),
              isTrue,
            );

            // ==========================================================
            // ADMIN UPLOAD -> OWNER + MEMBER SEE
            // ==========================================================

            final sharedDocument =
                await adminDocumentRepository
                    .uploadDocument(
              vehicleId:
                  vehicleId,
              displayName:
                  'Shared document',
              originalFileName:
                  'shared.txt',
              fileBytes:
                  IntegrationTestDataFactory
                      .createTestFileBytes(),
              category:
                  VehicleDocumentCategory
                      .other,
            );

            final ownerDocuments =
                await ownerClient
                    .from(
                      IntegrationConfig
                          .documentsTable,
                    )
                    .select()
                    .eq(
                      'vehicle_id',
                      vehicleId,
                    );

            final memberDocuments =
                await memberClient
                    .from(
                      IntegrationConfig
                          .documentsTable,
                    )
                    .select()
                    .eq(
                      'vehicle_id',
                      vehicleId,
                    );

            expect(
              ownerDocuments.any(
                (row) =>
                    row['id'] ==
                    sharedDocument.id,
              ),
              isTrue,
            );

            expect(
              memberDocuments.any(
                (row) =>
                    row['id'] ==
                    sharedDocument.id,
              ),
              isTrue,
            );

            // ==========================================================
            // TRANSFER OWNERSHIP A -> B
            // ==========================================================

            await ownerClient.rpc(
              'transfer_vehicle_ownership',
              params: {
                'target_vehicle_id':
                    vehicleId,
                'new_owner_user_id':
                    adminId,
              },
            );

            expect(
              await ownerRepository
                  .getCurrentUserVehicleRole(
                vehicleId,
              ),
              VehicleMemberRole.admin,
            );

            expect(
              await adminRepository
                  .getCurrentUserVehicleRole(
                vehicleId,
              ),
              VehicleMemberRole.owner,
            );

            expect(
              await memberRepository
                  .getCurrentUserVehicleRole(
                vehicleId,
              ),
              VehicleMemberRole.member,
            );

            final ownerRows =
                await adminClient
                    .from(
                      IntegrationConfig
                          .vehicleMembersTable,
                    )
                    .select(
                      'user_id,role',
                    )
                    .eq(
                      'vehicle_id',
                      vehicleId,
                    )
                    .eq(
                      'role',
                      'owner',
                    );

            expect(
              ownerRows.length,
              1,
            );

            expect(
              ownerRows.single[
                  'user_id'],
              adminId,
            );

            // Previous owner is Admin.
            final oldOwnerRow =
                await adminClient
                    .from(
                      IntegrationConfig
                          .vehicleMembersTable,
                    )
                    .select(
                      'role',
                    )
                    .eq(
                      'vehicle_id',
                      vehicleId,
                    )
                    .eq(
                      'user_id',
                      ownerId,
                    )
                    .single();

            expect(
              oldOwnerRow['role'],
              'admin',
            );

            // Old Owner no longer gets Owner-only member list.
            Object? oldOwnerMemberListError;

            try {
              await ownerClient.rpc(
                'get_vehicle_members_for_owner',
                params: {
                  'target_vehicle_id':
                      vehicleId,
                },
              );
            } catch (error) {
              oldOwnerMemberListError =
                  error;
            }

            expect(
              oldOwnerMemberListError,
              isNotNull,
            );

            // New Owner does.
            final newOwnerMembers =
                await adminClient.rpc(
              'get_vehicle_members_for_owner',
              params: {
                'target_vehicle_id':
                    vehicleId,
              },
            ) as List<dynamic>;

            expect(
              newOwnerMembers.length,
              3,
            );

            // ==========================================================
            // REMOVE MEMBER C
            // ==========================================================

            final removedRows =
                await adminClient
                    .from(
                      IntegrationConfig
                          .vehicleMembersTable,
                    )
                    .delete()
                    .eq(
                      'vehicle_id',
                      vehicleId,
                    )
                    .eq(
                      'user_id',
                      memberId,
                    )
                    .select();

            expect(
              removedRows.length,
              1,
            );

            expect(
              await memberRepository
                  .getVehicles(),
              isEmpty,
            );

            expect(
              await memberRepository
                  .getVehicleEvents(
                vehicleId,
              ),
              isEmpty,
            );

            final removedMemberDocuments =
                await memberClient
                    .from(
                      IntegrationConfig
                          .documentsTable,
                    )
                    .select()
                    .eq(
                      'vehicle_id',
                      vehicleId,
                    );

            expect(
              removedMemberDocuments,
              isEmpty,
            );

            Object? removedMemberFileError;

            try {
              await memberClient.storage
                  .from(
                    IntegrationConfig
                        .storageBucket,
                  )
                  .download(
                    sharedDocument
                        .filePath,
                  );
            } catch (error) {
              removedMemberFileError =
                  error;
            }

            expect(
              removedMemberFileError,
              isNotNull,
            );

            // B is now Owner, so B deletes the test vehicle.
            await adminRepository
                .deleteVehicle(
              vehicleId,
            );

            vehicleId = null;
          } finally {
            if (vehicleId != null) {
              try {
                final adminRole =
                    await adminRepository
                        .getCurrentUserVehicleRole(
                  vehicleId,
                );

                if (adminRole ==
                    VehicleMemberRole.owner) {
                  await adminRepository
                      .deleteVehicle(
                    vehicleId,
                  );
                } else {
                  await ownerRepository
                      .deleteVehicle(
                    vehicleId,
                  );
                }
              } catch (_) {}
            }

            await SupabaseTestClients
                .signOutAll(
              [
                ownerClient,
                adminClient,
                memberClient,
                outsiderClient,
              ],
            );
          }
        },
      );
    },
  );
}