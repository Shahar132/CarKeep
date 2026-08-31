import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../lib/models/vehicle.dart';
import '../lib/models/vehicle_event.dart';
import '../lib/models/vehicle_insurance.dart';
import '../lib/repositories/vehicle_repository.dart';

import 'helpers/integration_config.dart';
import 'helpers/supabase_test_clients.dart';
import 'helpers/test_data_factory.dart';
import 'helpers/test_users.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group(
    'CarKeep Vehicle Lifecycle Integration Tests',
    () {
      testWidgets(
        'license test insurance and service history persist and recalculate correctly',
        (tester) async {
          IntegrationConfig.validate();

          final client =
              await SupabaseTestClients
                  .createAuthenticatedUser(
            IntegrationTestUsers.owner,
          );

          final repository =
              VehicleRepository(
            supabase: client,
          );

          String? vehicleId;

          try {
            final data =
                IntegrationTestDataFactory
                    .createVehicle();

            var vehicle =
                await repository
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

            // ==========================================================
            // VEHICLE LICENSE
            // ==========================================================

            final license2027 =
                DateTime(2027, 8, 31);

            vehicle.vehicleLicenseExpiryDate =
                license2027;

            vehicle.showVehicleLicenseOnHome =
                true;

            await repository
                .updateVehicle(
              vehicle,
            );

            final licenseEvent2027 =
                await repository
                    .addVehicleEvent(
              VehicleEvent(
                vehicleId:
                    vehicleId,
                type:
                    VehicleEventType
                        .vehicleLicense,
                date:
                    license2027,
                title:
                    'רישיון רכב 2027',
              ),
            );

            vehicle =
                (await repository
                        .getVehicles())
                    .singleWhere(
              (item) =>
                  item.id ==
                  vehicleId,
            );

            expect(
              vehicle.vehicleLicenseExpiryDate,
              license2027,
            );

            expect(
              vehicle.showVehicleLicenseOnHome,
              isTrue,
            );

            expect(
              vehicle.events.any(
                (event) =>
                    event.id ==
                        licenseEvent2027.id &&
                    event.type ==
                        VehicleEventType
                            .vehicleLicense,
              ),
              isTrue,
            );

            // Toggle off.
            vehicle.showVehicleLicenseOnHome =
                false;

            await repository
                .updateVehicle(
              vehicle,
            );

            vehicle =
                (await repository
                        .getVehicles())
                    .singleWhere(
              (item) =>
                  item.id ==
                  vehicleId,
            );

            expect(
              vehicle.showVehicleLicenseOnHome,
              isFalse,
            );

            // Renew -> 2028.
            final license2028 =
                DateTime(2028, 8, 31);

            vehicle.vehicleLicenseExpiryDate =
                license2028;

            await repository
                .updateVehicle(
              vehicle,
            );

            final licenseEvent2028 =
                await repository
                    .addVehicleEvent(
              VehicleEvent(
                vehicleId:
                    vehicleId,
                type:
                    VehicleEventType
                        .vehicleLicense,
                date:
                    license2028,
                title:
                    'רישיון רכב 2028',
              ),
            );

            vehicle =
                (await repository
                        .getVehicles())
                    .singleWhere(
              (item) =>
                  item.id ==
                  vehicleId,
            );

            expect(
              vehicle.vehicleLicenseExpiryDate,
              license2028,
            );

            final licenseEvents =
                vehicle.events
                    .where(
                      (event) =>
                          event.type ==
                          VehicleEventType
                              .vehicleLicense,
                    )
                    .toList();

            expect(
              licenseEvents.length,
              2,
            );

            // Delete latest -> current returns to 2027.
            await repository
                .deleteVehicleEvent(
              licenseEvent2028.id!,
            );

            final remainingLicenseEvents =
                (await repository
                        .getVehicleEvents(
                  vehicleId,
                ))
                    .where(
                      (event) =>
                          event.type ==
                          VehicleEventType
                              .vehicleLicense,
                    )
                    .toList();

            vehicle.vehicleLicenseExpiryDate =
                remainingLicenseEvents
                    .first
                    .date;

            await repository
                .updateVehicle(
              vehicle,
            );

            vehicle =
                (await repository
                        .getVehicles())
                    .singleWhere(
              (item) =>
                  item.id ==
                  vehicleId,
            );

            expect(
              vehicle.vehicleLicenseExpiryDate,
              license2027,
            );

            // Delete last license event -> null.
            await repository
                .deleteVehicleEvent(
              licenseEvent2027.id!,
            );

            vehicle.vehicleLicenseExpiryDate =
                null;

            await repository
                .updateVehicle(
              vehicle,
            );

            vehicle =
                (await repository
                        .getVehicles())
                    .singleWhere(
              (item) =>
                  item.id ==
                  vehicleId,
            );

            expect(
              vehicle.vehicleLicenseExpiryDate,
              isNull,
            );

            // ==========================================================
            // TEST
            // ==========================================================

            final test2027 =
                DateTime(2027, 8, 31);

            vehicle.testExpiryDate =
                test2027;

            vehicle.showTestOnHome =
                true;

            await repository
                .updateVehicle(
              vehicle,
            );

            final testEvent2027 =
                await repository
                    .addVehicleEvent(
              VehicleEvent(
                vehicleId:
                    vehicleId,
                type:
                    VehicleEventType.test,
                date:
                    test2027,
                title:
                    'טסט 2027',
              ),
            );

            final test2028 =
                DateTime(2028, 8, 31);

            vehicle.testExpiryDate =
                test2028;

            await repository
                .updateVehicle(
              vehicle,
            );

            final testEvent2028 =
                await repository
                    .addVehicleEvent(
              VehicleEvent(
                vehicleId:
                    vehicleId,
                type:
                    VehicleEventType.test,
                date:
                    test2028,
                title:
                    'טסט 2028',
              ),
            );

            vehicle =
                (await repository
                        .getVehicles())
                    .singleWhere(
              (item) =>
                  item.id ==
                  vehicleId,
            );

            expect(
              vehicle.testExpiryDate,
              test2028,
            );

            expect(
              vehicle.showTestOnHome,
              isTrue,
            );

            await repository
                .deleteVehicleEvent(
              testEvent2028.id!,
            );

            final remainingTests =
                (await repository
                        .getVehicleEvents(
                  vehicleId,
                ))
                    .where(
                      (event) =>
                          event.type ==
                          VehicleEventType
                              .test,
                    )
                    .toList();

            vehicle.testExpiryDate =
                remainingTests.first.date;

            await repository
                .updateVehicle(
              vehicle,
            );

            vehicle =
                (await repository
                        .getVehicles())
                    .singleWhere(
              (item) =>
                  item.id ==
                  vehicleId,
            );

            expect(
              vehicle.testExpiryDate,
              test2027,
            );

            await repository
                .deleteVehicleEvent(
              testEvent2027.id!,
            );

            vehicle.testExpiryDate =
                null;

            await repository
                .updateVehicle(
              vehicle,
            );

            vehicle =
                (await repository
                        .getVehicles())
                    .singleWhere(
              (item) =>
                  item.id ==
                  vehicleId,
            );

            expect(
              vehicle.testExpiryDate,
              isNull,
            );

            // ==========================================================
            // INSURANCES
            // ==========================================================

            final mandatory =
                await repository
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

            final comprehensive =
                await repository
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
                    false,
              ),
            );

            await repository
                .saveInsurance(
              VehicleInsurance(
                vehicleId:
                    vehicleId,
                type:
                    InsuranceType
                        .thirdParty,
                expiryDate:
                    DateTime(2027, 7, 1),
                showOnHome:
                    false,
              ),
            );

            await repository
                .addVehicleEvent(
              VehicleEvent(
                vehicleId:
                    vehicleId,
                type:
                    VehicleEventType
                        .insurance,
                insuranceType:
                    InsuranceType
                        .mandatory,
                date:
                    DateTime(2027, 5, 1),
                title:
                    'ביטוח חובה 2027',
              ),
            );

            await repository
                .addVehicleEvent(
              VehicleEvent(
                vehicleId:
                    vehicleId,
                type:
                    VehicleEventType
                        .insurance,
                insuranceType:
                    InsuranceType
                        .comprehensive,
                date:
                    DateTime(2027, 6, 15),
                title:
                    'ביטוח מקיף 2027',
              ),
            );

            await repository
                .addVehicleEvent(
              VehicleEvent(
                vehicleId:
                    vehicleId,
                type:
                    VehicleEventType
                        .insurance,
                insuranceType:
                    InsuranceType
                        .thirdParty,
                date:
                    DateTime(2027, 7, 1),
                title:
                    'ביטוח צד ג׳ 2027',
              ),
            );

            var insurances =
                await repository
                    .getVehicleInsurances(
              vehicleId,
            );

            expect(
              insurances.length,
              3,
            );

            expect(
              insurances
                  .where(
                    (item) =>
                        item.showOnHome,
                  )
                  .length,
              1,
            );

            expect(
              insurances
                  .singleWhere(
                    (item) =>
                        item.type ==
                        InsuranceType
                            .mandatory,
                  )
                  .showOnHome,
              isTrue,
            );

            // Enable comprehensive too.
            comprehensive.showOnHome =
                true;

            await repository
                .saveInsurance(
              comprehensive,
            );

            insurances =
                await repository
                    .getVehicleInsurances(
              vehicleId,
            );

            expect(
              insurances
                  .where(
                    (item) =>
                        item.showOnHome,
                  )
                  .length,
              2,
            );

            // Update mandatory.
            mandatory.expiryDate =
                DateTime(2028, 5, 1);

            final updatedMandatory =
                await repository
                    .saveInsurance(
              mandatory,
            );

            expect(
              updatedMandatory.id,
              mandatory.id,
            );

            await repository
                .addVehicleEvent(
              VehicleEvent(
                vehicleId:
                    vehicleId,
                type:
                    VehicleEventType
                        .insurance,
                insuranceType:
                    InsuranceType
                        .mandatory,
                date:
                    DateTime(2028, 5, 1),
                title:
                    'ביטוח חובה 2028',
              ),
            );

            insurances =
                await repository
                    .getVehicleInsurances(
              vehicleId,
            );

            expect(
              insurances.length,
              3,
              reason:
                  'Insurance upsert must update the existing type rather than create a duplicate.',
            );

            expect(
              insurances
                  .singleWhere(
                    (item) =>
                        item.type ==
                        InsuranceType
                            .mandatory,
                  )
                  .expiryDate,
              DateTime(2028, 5, 1),
            );

            // ==========================================================
            // SERVICE
            // ==========================================================

            final firstServiceDate =
                DateTime(2026, 8, 30);

            final firstServiceEvent =
                await repository
                    .addVehicleEvent(
              VehicleEvent(
                vehicleId:
                    vehicleId,
                type:
                    VehicleEventType
                        .service,
                date:
                    firstServiceDate,
                title:
                    'טיפול 60,000 ק"מ',
                mileage:
                    60000,
                serviceIntervalKm:
                    15000,
              ),
            );

            vehicle.lastServiceDate =
                firstServiceDate;

            vehicle.lastServiceMileage =
                60000;

            vehicle.serviceIntervalKm =
                15000;

            vehicle.showServiceOnHome =
                true;

            await repository
                .updateVehicle(
              vehicle,
            );

            vehicle =
                (await repository
                        .getVehicles())
                    .singleWhere(
              (item) =>
                  item.id ==
                  vehicleId,
            );

            expect(
              vehicle.lastServiceDate,
              firstServiceDate,
            );

            expect(
              vehicle.lastServiceMileage,
              60000,
            );

            expect(
              vehicle.serviceIntervalKm,
              15000,
            );

            final nextServiceDate =
                DateTime(
              vehicle.lastServiceDate!.year +
                  1,
              vehicle.lastServiceDate!.month,
              vehicle.lastServiceDate!.day,
            );

            final nextServiceMileage =
                vehicle.lastServiceMileage! +
                    vehicle.serviceIntervalKm!;

            expect(
              nextServiceDate,
              DateTime(2027, 8, 30),
            );

            expect(
              nextServiceMileage,
              75000,
            );

            // Second service becomes current.
            final secondServiceDate =
                DateTime(2027, 3, 1);

            final secondServiceEvent =
                await repository
                    .addVehicleEvent(
              VehicleEvent(
                vehicleId:
                    vehicleId,
                type:
                    VehicleEventType
                        .service,
                date:
                    secondServiceDate,
                title:
                    'טיפול 70,000 ק"מ',
                mileage:
                    70000,
                serviceIntervalKm:
                    15000,
              ),
            );

            vehicle.lastServiceDate =
                secondServiceDate;

            vehicle.lastServiceMileage =
                70000;

            vehicle.serviceIntervalKm =
                15000;

            await repository
                .updateVehicle(
              vehicle,
            );

            vehicle =
                (await repository
                        .getVehicles())
                    .singleWhere(
              (item) =>
                  item.id ==
                  vehicleId,
            );

            expect(
              vehicle.lastServiceDate,
              secondServiceDate,
            );

            expect(
              vehicle.lastServiceMileage,
              70000,
            );

            // Delete latest service -> restore first.
            await repository
                .deleteVehicleEvent(
              secondServiceEvent.id!,
            );

            final remainingServices =
                (await repository
                        .getVehicleEvents(
                  vehicleId,
                ))
                    .where(
                      (event) =>
                          event.type ==
                          VehicleEventType
                              .service,
                    )
                    .toList();

            final restoredService =
                remainingServices.first;

            vehicle.lastServiceDate =
                restoredService.date;

            vehicle.lastServiceMileage =
                restoredService.mileage;

            vehicle.serviceIntervalKm =
                restoredService
                    .serviceIntervalKm;

            await repository
                .updateVehicle(
              vehicle,
            );

            vehicle =
                (await repository
                        .getVehicles())
                    .singleWhere(
              (item) =>
                  item.id ==
                  vehicleId,
            );

            expect(
              vehicle.lastServiceDate,
              firstServiceDate,
            );

            expect(
              vehicle.lastServiceMileage,
              60000,
            );

            expect(
              vehicle.serviceIntervalKm,
              15000,
            );

            // Delete all service history -> current becomes null.
            await repository
                .deleteVehicleEvent(
              firstServiceEvent.id!,
            );

            vehicle.lastServiceDate =
                null;

            vehicle.lastServiceMileage =
                null;

            vehicle.serviceIntervalKm =
                null;

            await repository
                .updateVehicle(
              vehicle,
            );

            vehicle =
                (await repository
                        .getVehicles())
                    .singleWhere(
              (item) =>
                  item.id ==
                  vehicleId,
            );

            expect(
              vehicle.lastServiceDate,
              isNull,
            );

            expect(
              vehicle.lastServiceMileage,
              isNull,
            );

            expect(
              vehicle.serviceIntervalKm,
              isNull,
            );

            await repository
                .deleteVehicle(
              vehicleId,
            );

            vehicleId = null;
          } finally {
            if (vehicleId != null) {
              try {
                await repository
                    .deleteVehicle(
                  vehicleId,
                );
              } catch (_) {}
            }

            await SupabaseTestClients
                .signOutQuietly(
              client,
            );
          }
        },
      );
    },
  );
}