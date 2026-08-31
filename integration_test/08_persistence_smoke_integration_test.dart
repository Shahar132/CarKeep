import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../lib/models/vehicle.dart';
import '../lib/models/vehicle_document.dart';
import '../lib/models/vehicle_event.dart';
import '../lib/models/vehicle_insurance.dart';
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
    'CarKeep Persistence Smoke Integration Tests',
    () {
      testWidgets(
        'complete shared vehicle state persists across fresh clients and logins',
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

          final ownerRepository =
              VehicleRepository(
            supabase: ownerClient,
          );

          final ownerDocumentRepository =
              VehicleDocumentRepository(
            supabase: ownerClient,
          );

          String? vehicleId;

          SupabaseClient? freshOwnerClient;
          SupabaseClient? freshAdminClient;
          SupabaseClient? freshMemberClient;

          try {
            // ==========================================================
            // CREATE COMPLETE VEHICLE STATE
            // ==========================================================

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
                    'Toyota',
                model:
                    'Corolla',
                year:
                    2022,
                mileage:
                    65000,
                vehicleLicenseExpiryDate:
                    DateTime(2027, 8, 31),
                showVehicleLicenseOnHome:
                    true,
                testExpiryDate:
                    DateTime(2027, 10, 1),
                showTestOnHome:
                    true,
                lastServiceDate:
                    DateTime(2026, 8, 30),
                lastServiceMileage:
                    60000,
                serviceIntervalKm:
                    15000,
                showServiceOnHome:
                    true,
              ),
            );

            vehicleId =
                vehicle.id!;

            final adminId =
                SupabaseTestClients
                    .requireCurrentUserId(
              adminClient,
            );

            // Add B + C.
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

            // History.
            await ownerRepository
                .addVehicleEvent(
              VehicleEvent(
                vehicleId:
                    vehicleId,
                type:
                    VehicleEventType
                        .vehicleLicense,
                date:
                    DateTime(2027, 8, 31),
                title:
                    'רישיון רכב 2027',
              ),
            );

            await ownerRepository
                .addVehicleEvent(
              VehicleEvent(
                vehicleId:
                    vehicleId,
                type:
                    VehicleEventType.test,
                date:
                    DateTime(2027, 10, 1),
                title:
                    'טסט 2027',
              ),
            );

            await ownerRepository
                .addVehicleEvent(
              VehicleEvent(
                vehicleId:
                    vehicleId,
                type:
                    VehicleEventType
                        .service,
                date:
                    DateTime(2026, 8, 30),
                title:
                    'טיפול 60,000 ק"מ',
                mileage:
                    60000,
                serviceIntervalKm:
                    15000,
              ),
            );

            // Two insurances.
            await ownerRepository
                .saveInsurance(
              VehicleInsurance(
                vehicleId:
                    vehicleId,
                type:
                    InsuranceType
                        .mandatory,
                expiryDate:
                    DateTime(2027, 5, 1),
                showOnHome:
                    true,
              ),
            );

            await ownerRepository
                .saveInsurance(
              VehicleInsurance(
                vehicleId:
                    vehicleId,
                type:
                    InsuranceType
                        .comprehensive,
                expiryDate:
                    DateTime(2027, 6, 15),
                showOnHome:
                    true,
              ),
            );

            // Three documents.
            await ownerDocumentRepository
                .uploadDocument(
              vehicleId:
                  vehicleId,
              displayName:
                  'רישיון רכב 2027 - 31/08/2027',
              originalFileName:
                  'license.txt',
              fileBytes:
                  IntegrationTestDataFactory
                      .createTestFileBytes(),
              category:
                  VehicleDocumentCategory
                      .vehicleLicense,
            );

            await ownerDocumentRepository
                .uploadDocument(
              vehicleId:
                  vehicleId,
              displayName:
                  'טסט 2027 - 01/10/2027',
              originalFileName:
                  'test.txt',
              fileBytes:
                  IntegrationTestDataFactory
                      .createTestFileBytes(),
              category:
                  VehicleDocumentCategory
                      .test,
            );

            await ownerDocumentRepository
                .uploadDocument(
              vehicleId:
                  vehicleId,
              displayName:
                  'ביטוח חובה 2027 - 01/05/2027',
              originalFileName:
                  'insurance.txt',
              fileBytes:
                  IntegrationTestDataFactory
                      .createTestFileBytes(),
              category:
                  VehicleDocumentCategory
                      .insurance,
            );

            // ==========================================================
            // CLOSE CURRENT SESSIONS
            // ==========================================================

            await SupabaseTestClients
                .signOutAll(
              [
                ownerClient,
                adminClient,
                memberClient,
              ],
            );

            // ==========================================================
            // CREATE COMPLETELY FRESH CLIENTS
            // ==========================================================

            freshOwnerClient =
                SupabaseTestClients
                    .createClient();

            freshAdminClient =
                SupabaseTestClients
                    .createClient();

            freshMemberClient =
                SupabaseTestClients
                    .createClient();

            await SupabaseTestClients
                .signIn(
              freshOwnerClient,
              IntegrationTestUsers.owner,
            );

            await SupabaseTestClients
                .signIn(
              freshAdminClient,
              IntegrationTestUsers.admin,
            );

            await SupabaseTestClients
                .signIn(
              freshMemberClient,
              IntegrationTestUsers.member,
            );

            final freshOwnerRepository =
                VehicleRepository(
              supabase:
                  freshOwnerClient,
            );

            final freshAdminRepository =
                VehicleRepository(
              supabase:
                  freshAdminClient,
            );

            final freshMemberRepository =
                VehicleRepository(
              supabase:
                  freshMemberClient,
            );

            // ==========================================================
            // OWNER RELOAD
            // ==========================================================

            final ownerVehicles =
                await freshOwnerRepository
                    .getVehicles();

            final reloadedVehicle =
                ownerVehicles.singleWhere(
              (item) =>
                  item.id ==
                  vehicleId,
            );

            expect(
              reloadedVehicle.license,
              data.licenseNumber,
            );

            expect(
              reloadedVehicle.manufacturer,
              'Toyota',
            );

            expect(
              reloadedVehicle.model,
              'Corolla',
            );

            expect(
              reloadedVehicle.year,
              2022,
            );

            expect(
              reloadedVehicle.mileage,
              65000,
            );

            expect(
              reloadedVehicle
                  .vehicleLicenseExpiryDate,
              DateTime(2027, 8, 31),
            );

            expect(
              reloadedVehicle.testExpiryDate,
              DateTime(2027, 10, 1),
            );

            expect(
              reloadedVehicle.lastServiceDate,
              DateTime(2026, 8, 30),
            );

            expect(
              reloadedVehicle
                  .lastServiceMileage,
              60000,
            );

            expect(
              reloadedVehicle
                  .serviceIntervalKm,
              15000,
            );

            expect(
              reloadedVehicle.currentUserRole,
              VehicleMemberRole.owner,
            );

            expect(
              reloadedVehicle.insurances.length,
              2,
            );

            expect(
              reloadedVehicle.events.length,
              3,
            );

            expect(
              reloadedVehicle.events.any(
                (event) =>
                    event.type ==
                    VehicleEventType
                        .vehicleLicense,
              ),
              isTrue,
            );

            expect(
              reloadedVehicle.events.any(
                (event) =>
                    event.type ==
                    VehicleEventType.test,
              ),
              isTrue,
            );

            expect(
              reloadedVehicle.events.any(
                (event) =>
                    event.type ==
                    VehicleEventType
                        .service,
              ),
              isTrue,
            );

            final ownerDocuments =
                await freshOwnerClient
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
              ownerDocuments.length,
              3,
            );

            // ==========================================================
            // ADMIN RELOAD
            // ==========================================================

            final adminVehicle =
                (await freshAdminRepository
                        .getVehicles())
                    .singleWhere(
              (item) =>
                  item.id ==
                  vehicleId,
            );

            expect(
              adminVehicle.mileage,
              65000,
            );

            expect(
              adminVehicle.currentUserRole,
              VehicleMemberRole.admin,
            );

            expect(
              adminVehicle.insurances.length,
              2,
            );

            expect(
              adminVehicle.events.length,
              3,
            );

            // ==========================================================
            // MEMBER RELOAD
            // ==========================================================

            final memberVehicle =
                (await freshMemberRepository
                        .getVehicles())
                    .singleWhere(
              (item) =>
                  item.id ==
                  vehicleId,
            );

            expect(
              memberVehicle.mileage,
              65000,
            );

            expect(
              memberVehicle.currentUserRole,
              VehicleMemberRole.member,
            );

            expect(
              memberVehicle.insurances.length,
              2,
            );

            expect(
              memberVehicle.events.length,
              3,
            );

            final memberDocuments =
                await freshMemberClient
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
              memberDocuments.length,
              3,
            );

            // All three clients loaded the exact same
            // persisted vehicle state from Supabase Local.
            expect(
              adminVehicle.license,
              reloadedVehicle.license,
            );

            expect(
              memberVehicle.license,
              reloadedVehicle.license,
            );

            expect(
              adminVehicle.mileage,
              reloadedVehicle.mileage,
            );

            expect(
              memberVehicle.mileage,
              reloadedVehicle.mileage,
            );

            // Fresh Owner performs cleanup.
            await freshOwnerRepository
                .deleteVehicle(
              vehicleId,
            );

            vehicleId = null;
          } finally {
            if (vehicleId != null) {
              final cleanupClient =
                  freshOwnerClient ??
                      ownerClient;

              try {
                await VehicleRepository(
                  supabase:
                      cleanupClient,
                ).deleteVehicle(
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
                if (freshOwnerClient != null)
                  freshOwnerClient,
                if (freshAdminClient != null)
                  freshAdminClient,
                if (freshMemberClient != null)
                  freshMemberClient,
              ],
            );
          }
        },
      );
    },
  );
}