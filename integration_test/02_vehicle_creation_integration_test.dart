import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../lib/models/vehicle.dart';
import '../lib/models/vehicle_member.dart';
import '../lib/repositories/vehicle_repository.dart';

import 'helpers/integration_config.dart';
import 'helpers/supabase_test_clients.dart';
import 'helpers/test_data_factory.dart';
import 'helpers/test_users.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group(
    'CarKeep Vehicle Creation Integration Tests',
    () {
      testWidgets(
        'vehicle creation persists data, creates exactly one owner and rejects duplicate license',
        (tester) async {
          IntegrationConfig.validate();

          final ownerClient =
              await SupabaseTestClients
                  .createAuthenticatedUser(
            IntegrationTestUsers.owner,
          );

          final ownerRepository =
              VehicleRepository(
            supabase: ownerClient,
          );

          SupabaseClient? freshClient;
          String? vehicleId;

          try {
            final data =
                IntegrationTestDataFactory
                    .createVehicle();

            final vehicle =
                Vehicle(
              license: data.licenseNumber,
              manufacturer:
                  data.manufacturer,
              model: data.model,
              year: data.year,
              mileage: data.mileage,
            );

            // ----------------------------------------------------------
            // 1. Create vehicle through the real repository
            // ----------------------------------------------------------

            final savedVehicle =
                await ownerRepository
                    .addVehicle(
              vehicle,
            );

            vehicleId =
                savedVehicle.id;

            expect(
              vehicleId,
              isNotNull,
            );

            expect(
              savedVehicle.license,
              data.licenseNumber,
            );

            expect(
              savedVehicle.manufacturer,
              'Toyota',
            );

            expect(
              savedVehicle.model,
              'Corolla',
            );

            expect(
              savedVehicle.year,
              2022,
            );

            expect(
              savedVehicle.mileage,
              60000,
            );

            expect(
              savedVehicle.currentUserRole,
              VehicleMemberRole.owner,
            );

            // ----------------------------------------------------------
            // 2. Verify vehicles row
            // ----------------------------------------------------------

            final vehicleRow =
                await ownerClient
                    .from(
                      IntegrationConfig
                          .vehiclesTable,
                    )
                    .select()
                    .eq(
                      'id',
                      vehicleId!,
                    )
                    .single();

            expect(
              vehicleRow['license'],
              data.licenseNumber,
            );

            expect(
              vehicleRow['manufacturer'],
              'Toyota',
            );

            expect(
              vehicleRow['model'],
              'Corolla',
            );

            expect(
              vehicleRow['year'],
              2022,
            );

            expect(
              vehicleRow['mileage'],
              60000,
            );

            // ----------------------------------------------------------
            // 3. Verify automatic Owner membership
            // ----------------------------------------------------------

            final ownerUserId =
                SupabaseTestClients
                    .requireCurrentUserId(
              ownerClient,
            );

            final memberships =
                await ownerClient
                    .from(
                      IntegrationConfig
                          .vehicleMembersTable,
                    )
                    .select(
                      'vehicle_id,user_id,role',
                    )
                    .eq(
                      'vehicle_id',
                      vehicleId,
                    );

            expect(
              memberships.length,
              1,
            );

            expect(
              memberships.single[
                  'user_id'],
              ownerUserId,
            );

            expect(
              memberships.single['role'],
              'owner',
            );

            final owners =
                memberships
                    .where(
                      (row) =>
                          row['role'] ==
                          'owner',
                    )
                    .toList();

            expect(
              owners.length,
              1,
              reason:
                  'A vehicle must have exactly one owner.',
            );

            // ----------------------------------------------------------
            // 4. Reload through repository
            // ----------------------------------------------------------

            final loadedVehicles =
                await ownerRepository
                    .getVehicles();

            final loadedVehicle =
                loadedVehicles.singleWhere(
              (item) =>
                  item.id == vehicleId,
            );

            expect(
              loadedVehicle.license,
              data.licenseNumber,
            );

            expect(
              loadedVehicle.currentUserRole,
              VehicleMemberRole.owner,
            );

            // ----------------------------------------------------------
            // 5. Simulate a fresh login/reload
            // ----------------------------------------------------------

            await ownerClient.auth.signOut();

            freshClient =
                SupabaseTestClients
                    .createClient();

            await SupabaseTestClients
                .signIn(
              freshClient,
              IntegrationTestUsers.owner,
            );

            final freshRepository =
                VehicleRepository(
              supabase: freshClient,
            );

            final reloadedVehicles =
                await freshRepository
                    .getVehicles();

            expect(
              reloadedVehicles.any(
                (item) =>
                    item.id ==
                    vehicleId,
              ),
              isTrue,
            );

            // ----------------------------------------------------------
            // 6. Duplicate vehicle license must fail
            // ----------------------------------------------------------

            Object? duplicateError;

            try {
              await freshRepository
                  .addVehicle(
                Vehicle(
                  license:
                      data.licenseNumber,
                  manufacturer:
                      'Duplicate',
                  model:
                      'Vehicle',
                  year: 2024,
                  mileage: 10,
                ),
              );
            } catch (error) {
              duplicateError = error;
            }

            expect(
              duplicateError,
              isNotNull,
              reason:
                  'The database UNIQUE constraint must reject duplicate vehicle licenses.',
            );

            final duplicateRows =
                await freshClient
                    .from(
                      IntegrationConfig
                          .vehiclesTable,
                    )
                    .select('id')
                    .eq(
                      'license',
                      data.licenseNumber,
                    );

            expect(
              duplicateRows.length,
              1,
            );

            // ----------------------------------------------------------
            // Cleanup
            // ----------------------------------------------------------

            await freshRepository
                .deleteVehicle(
              vehicleId,
            );

            vehicleId = null;
          } finally {
            if (vehicleId != null) {
              final cleanupClient =
                  freshClient ??
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
                if (freshClient != null)
                  freshClient,
              ],
            );
          }
        },
      );
    },
  );
}