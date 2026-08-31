import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../lib/models/vehicle.dart';
import '../lib/models/vehicle_document.dart';
import '../lib/models/vehicle_event.dart';
import '../lib/repositories/vehicle_document_repository.dart';
import '../lib/repositories/vehicle_repository.dart';

import 'helpers/integration_config.dart';
import 'helpers/supabase_test_clients.dart';
import 'helpers/test_data_factory.dart';
import 'helpers/test_users.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group(
    'CarKeep Documents and Storage Integration Tests',
    () {
      testWidgets(
        'documents storage event linking RLS SET NULL and rollback work correctly',
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

          final ownerVehicleRepository =
              VehicleRepository(
            supabase: ownerClient,
          );

          final ownerDocumentRepository =
              VehicleDocumentRepository(
            supabase: ownerClient,
          );

          final adminDocumentRepository =
              VehicleDocumentRepository(
            supabase: adminClient,
          );

          final memberDocumentRepository =
              VehicleDocumentRepository(
            supabase: memberClient,
          );

          final outsiderDocumentRepository =
              VehicleDocumentRepository(
            supabase: outsiderClient,
          );

          String? vehicleId;

          try {
            final data =
                IntegrationTestDataFactory
                    .createVehicle();

            final vehicle =
                await ownerVehicleRepository
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

            final adminId =
                SupabaseTestClients
                    .requireCurrentUserId(
              adminClient,
            );

            // Share with B + C.
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

            // ==========================================================
            // GENERAL DOCUMENT UPLOAD
            // ==========================================================

            final generalDocument =
                await ownerDocumentRepository
                    .uploadDocument(
              vehicleId:
                  vehicleId,
              displayName:
                  'ביטוח ישן',
              originalFileName:
                  'old_insurance.txt',
              fileBytes:
                  IntegrationTestDataFactory
                      .createTestFileBytes(),
              category:
                  VehicleDocumentCategory
                      .insurance,
            );

            expect(
              generalDocument.id,
              isNotNull,
            );

            expect(
              generalDocument.vehicleId,
              vehicleId,
            );

            expect(
              generalDocument.category,
              VehicleDocumentCategory
                  .insurance,
            );

            expect(
              generalDocument.eventId,
              isNull,
            );

            expect(
              generalDocument.uploadedBy,
              SupabaseTestClients
                  .requireCurrentUserId(
                ownerClient,
              ),
            );

            final dbDocument =
                await ownerClient
                    .from(
                      IntegrationConfig
                          .documentsTable,
                    )
                    .select()
                    .eq(
                      'id',
                      generalDocument.id!,
                    )
                    .single();

            expect(
              dbDocument['vehicle_id'],
              vehicleId,
            );

            expect(
              dbDocument['category'],
              'insurance',
            );

            expect(
              dbDocument['display_name'],
              'ביטוח ישן',
            );

            // ==========================================================
            // MEMBERS CAN DOWNLOAD
            // ==========================================================

            final ownerBytes =
                await ownerClient.storage
                    .from(
                      IntegrationConfig
                          .storageBucket,
                    )
                    .download(
                      generalDocument
                          .filePath,
                    );

            final adminBytes =
                await adminClient.storage
                    .from(
                      IntegrationConfig
                          .storageBucket,
                    )
                    .download(
                      generalDocument
                          .filePath,
                    );

            final memberBytes =
                await memberClient.storage
                    .from(
                      IntegrationConfig
                          .storageBucket,
                    )
                    .download(
                      generalDocument
                          .filePath,
                    );

            expect(
              ownerBytes,
              isNotEmpty,
            );

            expect(
              adminBytes,
              isNotEmpty,
            );

            expect(
              memberBytes,
              isNotEmpty,
            );

            // Outsider cannot even see the document row.
            final outsiderRows =
                await outsiderClient
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
              outsiderRows,
              isEmpty,
            );

            Object? outsiderDownloadError;

            try {
              await outsiderClient.storage
                  .from(
                    IntegrationConfig
                        .storageBucket,
                  )
                  .download(
                    generalDocument
                        .filePath,
                  );
            } catch (error) {
              outsiderDownloadError =
                  error;
            }

            expect(
              outsiderDownloadError,
              isNotNull,
            );

            // ==========================================================
            // MEMBER CANNOT UPLOAD
            // ==========================================================

            Object? memberUploadError;

            try {
              await memberDocumentRepository
                  .uploadDocument(
                vehicleId:
                    vehicleId,
                displayName:
                    'Forbidden Member Upload',
                originalFileName:
                    'member.txt',
                fileBytes:
                    IntegrationTestDataFactory
                        .createTestFileBytes(),
                category:
                    VehicleDocumentCategory
                        .other,
              );
            } catch (error) {
              memberUploadError =
                  error;
            }

            expect(
              memberUploadError,
              isNotNull,
            );

            // ==========================================================
            // ADMIN CAN UPLOAD
            // ==========================================================

            final adminDocument =
                await adminDocumentRepository
                    .uploadDocument(
              vehicleId:
                  vehicleId,
              displayName:
                  'Admin document',
              originalFileName:
                  'admin.txt',
              fileBytes:
                  IntegrationTestDataFactory
                      .createTestFileBytes(),
              category:
                  VehicleDocumentCategory
                      .other,
            );

            expect(
              adminDocument.id,
              isNotNull,
            );

            // ==========================================================
            // MEMBER CANNOT DELETE
            // ==========================================================

            await memberDocumentRepository
                .deleteDocument(
              generalDocument,
            );

            final afterMemberDelete =
                await ownerClient
                    .from(
                      IntegrationConfig
                          .documentsTable,
                    )
                    .select()
                    .eq(
                      'id',
                      generalDocument.id!,
                    )
                    .maybeSingle();

            expect(
              afterMemberDelete,
              isNotNull,
              reason:
                  'Member deletion attempt must not remove the document row.',
            );

            // Outsider cannot delete either.
            await outsiderDocumentRepository
                .deleteDocument(
              generalDocument,
            );

            final afterOutsiderDelete =
                await ownerClient
                    .from(
                      IntegrationConfig
                          .documentsTable,
                    )
                    .select()
                    .eq(
                      'id',
                      generalDocument.id!,
                    )
                    .maybeSingle();

            expect(
              afterOutsiderDelete,
              isNotNull,
            );

            // ==========================================================
            // EVENT-LINKED DOCUMENT
            // ==========================================================

            final licenseEvent =
                await ownerVehicleRepository
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

            final linkedDocument =
                await ownerDocumentRepository
                    .uploadDocument(
              vehicleId:
                  vehicleId,
              eventId:
                  licenseEvent.id,
              displayName:
                  'רישיון רכב 2027 - 31/08/2027',
              originalFileName:
                  'vehicle_license.txt',
              fileBytes:
                  IntegrationTestDataFactory
                      .createTestFileBytes(),
              category:
                  VehicleDocumentCategory
                      .vehicleLicense,
            );

            expect(
              linkedDocument.eventId,
              licenseEvent.id,
            );

            expect(
              linkedDocument.category,
              VehicleDocumentCategory
                  .vehicleLicense,
            );

            expect(
              linkedDocument.displayName,
              'רישיון רכב 2027 - 31/08/2027',
            );

            // ==========================================================
            // ON DELETE SET NULL
            // ==========================================================

            await ownerVehicleRepository
                .deleteVehicleEvent(
              licenseEvent.id!,
            );

            final afterEventDelete =
                await ownerClient
                    .from(
                      IntegrationConfig
                          .documentsTable,
                    )
                    .select()
                    .eq(
                      'id',
                      linkedDocument.id!,
                    )
                    .single();

            expect(
              afterEventDelete['event_id'],
              isNull,
            );

            expect(
              afterEventDelete['category'],
              'vehicle_license',
            );

            expect(
              afterEventDelete[
                  'display_name'],
              'רישיון רכב 2027 - 31/08/2027',
            );

            final linkedFileStillExists =
                await ownerClient.storage
                    .from(
                      IntegrationConfig
                          .storageBucket,
                    )
                    .download(
                      linkedDocument
                          .filePath,
                    );

            expect(
              linkedFileStillExists,
              isNotEmpty,
            );

            // ==========================================================
            // ADMIN CAN DELETE DOCUMENT
            // ==========================================================

            await adminDocumentRepository
                .deleteDocument(
              adminDocument,
            );

            final deletedAdminRow =
                await ownerClient
                    .from(
                      IntegrationConfig
                          .documentsTable,
                    )
                    .select()
                    .eq(
                      'id',
                      adminDocument.id!,
                    )
                    .maybeSingle();

            expect(
              deletedAdminRow,
              isNull,
            );

            Object? deletedAdminFileError;

            try {
              await ownerClient.storage
                  .from(
                    IntegrationConfig
                        .storageBucket,
                  )
                  .download(
                    adminDocument
                        .filePath,
                  );
            } catch (error) {
              deletedAdminFileError =
                  error;
            }

            expect(
              deletedAdminFileError,
              isNotNull,
            );

            // ==========================================================
            // UPLOAD ROLLBACK
            //
            // Storage succeeds first, then the documents INSERT fails
            // because event_id does not exist. Repository must remove
            // the just-uploaded Storage object.
            // ==========================================================

            final filesBefore =
                await ownerClient.storage
                    .from(
                      IntegrationConfig
                          .storageBucket,
                    )
                    .list(
                      path: vehicleId,
                    );

            Object? rollbackError;

            try {
              await ownerDocumentRepository
                  .uploadDocument(
                vehicleId:
                    vehicleId,
                eventId:
                    '00000000-0000-0000-0000-000000000001',
                displayName:
                    'Rollback test',
                originalFileName:
                    'rollback.txt',
                fileBytes:
                    IntegrationTestDataFactory
                        .createTestFileBytes(),
                category:
                    VehicleDocumentCategory
                        .other,
              );
            } catch (error) {
              rollbackError =
                  error;
            }

            expect(
              rollbackError,
              isNotNull,
            );

            final filesAfter =
                await ownerClient.storage
                    .from(
                      IntegrationConfig
                          .storageBucket,
                    )
                    .list(
                      path: vehicleId,
                    );

            expect(
              filesAfter.length,
              filesBefore.length,
              reason:
                  'Failed document insert must not leave an orphan Storage file.',
            );

            await ownerVehicleRepository
                .deleteVehicle(
              vehicleId,
            );

            vehicleId = null;
          } finally {
            if (vehicleId != null) {
              try {
                await ownerVehicleRepository
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