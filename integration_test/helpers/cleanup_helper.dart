import 'package:supabase_flutter/supabase_flutter.dart';

import 'integration_config.dart';
import 'supabase_test_clients.dart';

class IntegrationCleanupHelper {
  IntegrationCleanupHelper._();

  /// Removes files that were explicitly created by an integration test.
  ///
  /// The test should keep the Storage paths it created and pass them here.
  /// We intentionally do not delete the entire bucket.
  static Future<void> removeStorageFiles({
    required SupabaseClient client,
    required Iterable<String> paths,
  }) async {
    final filePaths = paths
        .where((path) => path.trim().isNotEmpty)
        .toList();

    if (filePaths.isEmpty) {
      return;
    }

    try {
      await client.storage
          .from(IntegrationConfig.storageBucket)
          .remove(filePaths);
    } catch (error) {
      _logCleanupWarning(
        'Could not remove Storage files',
        error,
      );
    }
  }

  /// Deletes a single row by its id.
  ///
  /// Useful for temporary rows that are not automatically removed
  /// when their parent vehicle is deleted.
  static Future<void> deleteRowById({
    required SupabaseClient client,
    required String table,
    required String id,
  }) async {
    if (id.trim().isEmpty) {
      return;
    }

    try {
      await client
          .from(table)
          .delete()
          .eq('id', id);
    } catch (error) {
      _logCleanupWarning(
        'Could not delete row $id from $table',
        error,
      );
    }
  }

  /// Deletes a test vehicle.
  ///
  /// Related database rows may be removed by the database relationships
  /// and cascade rules defined by the CarKeep schema.
  ///
  /// Storage files must be removed separately because PostgreSQL cascade
  /// deletion does not physically delete Storage objects.
  static Future<void> deleteVehicle({
    required SupabaseClient client,
    required String vehicleId,
  }) async {
    if (vehicleId.trim().isEmpty) {
      return;
    }

    try {
      await client
          .from(IntegrationConfig.vehiclesTable)
          .delete()
          .eq('id', vehicleId);
    } catch (error) {
      _logCleanupWarning(
        'Could not delete test vehicle $vehicleId',
        error,
      );
    }
  }

  /// Standard cleanup for tests that created a vehicle and Storage files.
  ///
  /// Storage is cleaned first because deleting a database row does not
  /// automatically remove the physical file from Supabase Storage.
  static Future<void> cleanupVehicleTest({
    required SupabaseClient ownerClient,
    required String? vehicleId,
    Iterable<String> storagePaths = const [],
  }) async {
    await removeStorageFiles(
      client: ownerClient,
      paths: storagePaths,
    );

    if (vehicleId != null &&
        vehicleId.trim().isNotEmpty) {
      await deleteVehicle(
        client: ownerClient,
        vehicleId: vehicleId,
      );
    }
  }

  /// Signs out all clients used by a test.
  static Future<void> cleanupClients(
    Iterable<SupabaseClient> clients,
  ) async {
    await SupabaseTestClients.signOutAll(
      clients,
    );
  }

  /// Convenience method for the common case:
  ///
  /// 1. Remove Storage files.
  /// 2. Delete the test vehicle.
  /// 3. Sign out all Supabase clients.
  static Future<void> cleanup({
    required SupabaseClient ownerClient,
    String? vehicleId,
    Iterable<String> storagePaths = const [],
    Iterable<SupabaseClient> clients = const [],
  }) async {
    await cleanupVehicleTest(
      ownerClient: ownerClient,
      vehicleId: vehicleId,
      storagePaths: storagePaths,
    );

    await cleanupClients(
      clients,
    );
  }

  static void _logCleanupWarning(
    String message,
    Object error,
  ) {
    // ignore: avoid_print
    print(
      '[Integration cleanup warning] '
      '$message: $error',
    );
  }
}