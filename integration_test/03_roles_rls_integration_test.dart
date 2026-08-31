import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';


import '../lib/models/vehicle.dart';
import '../lib/models/vehicle_event.dart';
import '../lib/models/vehicle_member.dart';
import '../lib/repositories/vehicle_repository.dart';

import 'helpers/integration_config.dart';
import 'helpers/supabase_test_clients.dart';
import 'helpers/test_data_factory.dart';
import 'helpers/test_users.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group(
    'CarKeep Roles and RLS Integration Tests',
    () {
      testWidgets(
        'Owner Admin Member and Outsider permissions are enforced by Supabase',
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

            final adminUserId =
                SupabaseTestClients
                    .requireCurrentUserId(
              adminClient,
            );

            final memberUserId =
                SupabaseTestClients
                    .requireCurrentUserId(
              memberClient,
            );

            // ----------------------------------------------------------
            // Owner adds B and C
            // ----------------------------------------------------------

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

            // Promote B -> Admin
            final promoted =
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
                      adminUserId,
                    )
                    .select();

            expect(
              promoted.length,
              1,
            );

            // ----------------------------------------------------------
            // Role resolution
            // ----------------------------------------------------------

            expect(
              await ownerRepository
                  .getCurrentUserVehicleRole(
                vehicleId,
              ),
              VehicleMemberRole.owner,
            );

            expect(
              await adminRepository
                  .getCurrentUserVehicleRole(
                vehicleId,
              ),
              VehicleMemberRole.admin,
            );

            expect(
              await memberRepository
                  .getCurrentUserVehicleRole(
                vehicleId,
              ),
              VehicleMemberRole.member,
            );

            expect(
              await outsiderRepository
                  .getCurrentUserVehicleRole(
                vehicleId,
              ),
              isNull,
            );

            // ----------------------------------------------------------
            // SELECT permissions
            // ----------------------------------------------------------

            expect(
              (await ownerRepository
                      .getVehicles())
                  .any(
                (item) =>
                    item.id ==
                    vehicleId,
              ),
              isTrue,
            );

            expect(
              (await adminRepository
                      .getVehicles())
                  .any(
                (item) =>
                    item.id ==
                    vehicleId,
              ),
              isTrue,
            );

            expect(
              (await memberRepository
                      .getVehicles())
                  .any(
                (item) =>
                    item.id ==
                    vehicleId,
              ),
              isTrue,
            );

            expect(
              (await outsiderRepository
                      .getVehicles())
                  .any(
                (item) =>
                    item.id ==
                    vehicleId,
              ),
              isFalse,
            );

            // ----------------------------------------------------------
            // Owner can update vehicle
            // ----------------------------------------------------------

            var ownerVehicle =
                (await ownerRepository
                        .getVehicles())
                    .singleWhere(
              (item) =>
                  item.id ==
                  vehicleId,
            );

            ownerVehicle.mileage =
                61000;

            await ownerRepository
                .updateVehicle(
              ownerVehicle,
            );

            expect(
              (await ownerRepository
                      .getVehicles())
                  .singleWhere(
                    (item) =>
                        item.id ==
                        vehicleId,
                  )
                  .mileage,
              61000,
            );

            // ----------------------------------------------------------
            // Admin can update vehicle
            // ----------------------------------------------------------

            var adminVehicle =
                (await adminRepository
                        .getVehicles())
                    .singleWhere(
              (item) =>
                  item.id ==
                  vehicleId,
            );

            adminVehicle.mileage =
                62000;

            await adminRepository
                .updateVehicle(
              adminVehicle,
            );

            expect(
              (await ownerRepository
                      .getVehicles())
                  .singleWhere(
                    (item) =>
                        item.id ==
                        vehicleId,
                  )
                  .mileage,
              62000,
            );

            // ----------------------------------------------------------
            // Member cannot update vehicle
            //
            // UPDATE blocked by RLS can result in zero affected rows
            // rather than an exception.
            // ----------------------------------------------------------

            final memberUpdateRows =
                await memberClient
                    .from(
                      IntegrationConfig
                          .vehiclesTable,
                    )
                    .update({
                      'mileage': 63000,
                    })
                    .eq(
                      'id',
                      vehicleId,
                    )
                    .select('id');

            expect(
              memberUpdateRows,
              isEmpty,
            );

            expect(
              (await ownerRepository
                      .getVehicles())
                  .singleWhere(
                    (item) =>
                        item.id ==
                        vehicleId,
                  )
                  .mileage,
              62000,
            );

            // Outsider cannot update either.
            final outsiderUpdateRows =
                await outsiderClient
                    .from(
                      IntegrationConfig
                          .vehiclesTable,
                    )
                    .update({
                      'mileage': 99999,
                    })
                    .eq(
                      'id',
                      vehicleId,
                    )
                    .select('id');

            expect(
              outsiderUpdateRows,
              isEmpty,
            );

            // ----------------------------------------------------------
            // Owner + Admin can create Events
            // ----------------------------------------------------------

            final ownerEvent =
                await ownerRepository
                    .addVehicleEvent(
              VehicleEvent(
                vehicleId:
                    vehicleId,
                type:
                    VehicleEventType.other,
                date:
                    DateTime(2026, 8, 31),
                title:
                    'Owner event',
              ),
            );

            final adminEvent =
                await adminRepository
                    .addVehicleEvent(
              VehicleEvent(
                vehicleId:
                    vehicleId,
                type:
                    VehicleEventType.repair,
                date:
                    DateTime(2026, 9, 1),
                title:
                    'Admin event',
              ),
            );

            expect(
              ownerEvent.id,
              isNotNull,
            );

            expect(
              adminEvent.id,
              isNotNull,
            );

            // ----------------------------------------------------------
            // Member cannot create Event
            // ----------------------------------------------------------

            Object? memberEventError;

            try {
              await memberRepository
                  .addVehicleEvent(
                VehicleEvent(
                  vehicleId:
                      vehicleId,
                  type:
                      VehicleEventType.other,
                  date:
                      DateTime(2026, 9, 2),
                  title:
                      'Member forbidden event',
                ),
              );
            } catch (error) {
              memberEventError =
                  error;
            }

            expect(
              memberEventError,
              isNotNull,
            );

            // Outsider cannot create Event.
            Object? outsiderEventError;

            try {
              await outsiderRepository
                  .addVehicleEvent(
                VehicleEvent(
                  vehicleId:
                      vehicleId,
                  type:
                      VehicleEventType.other,
                  date:
                      DateTime(2026, 9, 3),
                  title:
                      'Outsider forbidden event',
                ),
              );
            } catch (error) {
              outsiderEventError =
                  error;
            }

            expect(
              outsiderEventError,
              isNotNull,
            );

            // Member can read events.
            final memberEvents =
                await memberRepository
                    .getVehicleEvents(
              vehicleId,
            );

            expect(
              memberEvents.length,
              2,
            );

            // Outsider cannot read events.
            final outsiderEvents =
                await outsiderRepository
                    .getVehicleEvents(
              vehicleId,
            );

            expect(
              outsiderEvents,
              isEmpty,
            );

            // ----------------------------------------------------------
            // History is immutable:
            // even Owner/Admin have no UPDATE policy.
            // ----------------------------------------------------------

            final ownerHistoryUpdate =
                await ownerClient
                    .from(
                      IntegrationConfig
                          .vehicleEventsTable,
                    )
                    .update({
                      'title':
                          'Forbidden history edit',
                    })
                    .eq(
                      'id',
                      ownerEvent.id!,
                    )
                    .select('id');

            expect(
              ownerHistoryUpdate,
              isEmpty,
            );

            final adminHistoryUpdate =
                await adminClient
                    .from(
                      IntegrationConfig
                          .vehicleEventsTable,
                    )
                    .update({
                      'title':
                          'Forbidden admin edit',
                    })
                    .eq(
                      'id',
                      adminEvent.id!,
                    )
                    .select('id');

            expect(
              adminHistoryUpdate,
              isEmpty,
            );

            final unchangedEvent =
                await ownerClient
                    .from(
                      IntegrationConfig
                          .vehicleEventsTable,
                    )
                    .select(
                      'title',
                    )
                    .eq(
                      'id',
                      ownerEvent.id!,
                    )
                    .single();

            expect(
              unchangedEvent['title'],
              'Owner event',
            );

            // ----------------------------------------------------------
            // Only Owner may manage members
            // ----------------------------------------------------------

            Object? adminAddMemberError;

            try {
              await adminClient.rpc(
                'add_vehicle_member_by_email',
                params: {
                  'target_vehicle_id':
                      vehicleId,
                  'member_email':
                      IntegrationTestUsers
                          .outsider
                          .email,
                },
              );
            } catch (error) {
              adminAddMemberError =
                  error;
            }

            expect(
              adminAddMemberError,
              isNotNull,
            );

            final adminRoleChange =
                await adminClient
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
                      memberUserId,
                    )
                    .select();

            expect(
              adminRoleChange,
              isEmpty,
            );

            final adminRemoveMember =
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
                      memberUserId,
                    )
                    .select();

            expect(
              adminRemoveMember,
              isEmpty,
            );

            // Owner can change a non-owner member role.
            final ownerRoleChange =
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
                      memberUserId,
                    )
                    .select();

            expect(
              ownerRoleChange.length,
              1,
            );

            // Restore C -> Member.
            await ownerClient
                .from(
                  IntegrationConfig
                      .vehicleMembersTable,
                )
                .update({
                  'role': 'member',
                })
                .eq(
                  'vehicle_id',
                  vehicleId,
                )
                .eq(
                  'user_id',
                  memberUserId,
                );

            // Owner RPC can view full member list.
            final ownerMembers =
                await ownerClient.rpc(
              'get_vehicle_members_for_owner',
              params: {
                'target_vehicle_id':
                    vehicleId,
              },
            ) as List<dynamic>;

            expect(
              ownerMembers.length,
              3,
            );

            // Admin cannot use Owner-only member RPC.
            Object? adminMemberListError;

            try {
              await adminClient.rpc(
                'get_vehicle_members_for_owner',
                params: {
                  'target_vehicle_id':
                      vehicleId,
                },
              );
            } catch (error) {
              adminMemberListError =
                  error;
            }

            expect(
              adminMemberListError,
              isNotNull,
            );

            // Outsider sees no membership rows.
            final outsiderMemberships =
                await outsiderClient
                    .from(
                      IntegrationConfig
                          .vehicleMembersTable,
                    )
                    .select()
                    .eq(
                      'vehicle_id',
                      vehicleId,
                    );

            expect(
              outsiderMemberships,
              isEmpty,
            );

            await ownerRepository
                .deleteVehicle(
              vehicleId,
            );

            vehicleId = null;
          } finally {
            if (vehicleId != null) {
              try {
                await ownerRepository
                    .deleteVehicle(
                  vehicleId,
                );
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