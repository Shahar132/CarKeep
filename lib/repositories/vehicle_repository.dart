import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vehicle.dart';
import '../models/vehicle_event.dart';
import '../models/vehicle_insurance.dart';
import '../models/vehicle_member.dart';

class VehicleRepository {
  final SupabaseClient? _injectedSupabase;

  VehicleRepository({
    SupabaseClient? supabase,
  }) : _injectedSupabase = supabase;

  SupabaseClient get _supabase =>
      _injectedSupabase ??
      Supabase.instance.client;

  Future<List<Vehicle>> getVehicles() async {
    final data = await _supabase
        .from('vehicles')
        .select()
        .order('created_at');

    final vehicles = data
        .map<Vehicle>(
          (map) => Vehicle.fromMap(map),
        )
        .toList();

    for (final vehicle in vehicles) {
      if (vehicle.id == null) {
        continue;
      }

      final vehicleId = vehicle.id!;

      final insurances =
          await getVehicleInsurances(
        vehicleId,
      );

      final events =
          await getVehicleEvents(
        vehicleId,
      );

      final currentUserRole =
          await getCurrentUserVehicleRole(
        vehicleId,
      );

      vehicle.insurances
        ..clear()
        ..addAll(insurances);

      vehicle.events
        ..clear()
        ..addAll(events);

      vehicle.currentUserRole =
          currentUserRole;
    }

    return vehicles;
  }

  Future<Vehicle> addVehicle(
    Vehicle vehicle,
  ) async {
    await _supabase
        .from('vehicles')
        .insert(
          vehicle.toMap(),
        );

    final data = await _supabase
        .from('vehicles')
        .select()
        .eq(
          'license',
          vehicle.license,
        )
        .single();

    final savedVehicle =
        Vehicle.fromMap(
      data,
    );

    if (savedVehicle.id != null) {
      savedVehicle.currentUserRole =
          await getCurrentUserVehicleRole(
        savedVehicle.id!,
      );
    }

    return savedVehicle;
  }

  Future<void> updateVehicle(
    Vehicle vehicle,
  ) async {
    if (vehicle.id == null) {
      throw Exception(
        'Cannot update vehicle without an id',
      );
    }

    await _supabase
        .from('vehicles')
        .update(
          vehicle.toMap(),
        )
        .eq(
          'id',
          vehicle.id!,
        );
  }

  Future<void> deleteVehicle(
    String vehicleId,
  ) async {
    final documentRows =
        await _supabase
            .from('documents')
            .select('file_path')
            .eq(
              'vehicle_id',
              vehicleId,
            );

    final filePaths = documentRows
        .map<String?>(
          (row) =>
              row['file_path']
                  as String?,
        )
        .whereType<String>()
        .where(
          (path) =>
              path.trim().isNotEmpty,
        )
        .toList();

    if (filePaths.isNotEmpty) {
      await _supabase.storage
          .from('vehicle-documents')
          .remove(
            filePaths,
          );
    }

    await _supabase
        .from('vehicles')
        .delete()
        .eq(
          'id',
          vehicleId,
        );
  }

  // -------------------------
  // Vehicle membership
  // -------------------------

  Future<VehicleMemberRole?>
      getCurrentUserVehicleRole(
    String vehicleId,
  ) async {
    final user =
        _supabase.auth.currentUser;

    if (user == null) {
      return null;
    }

    final data = await _supabase
        .from('vehicle_members')
        .select('role')
        .eq(
          'vehicle_id',
          vehicleId,
        )
        .eq(
          'user_id',
          user.id,
        )
        .maybeSingle();

    if (data == null) {
      return null;
    }

    final role =
        data['role'] as String?;

    if (role == null) {
      return null;
    }

    return vehicleMemberRoleFromDatabase(
      role,
    );
  }

  // -------------------------
  // Insurances
  // -------------------------

  Future<List<VehicleInsurance>>
      getVehicleInsurances(
    String vehicleId,
  ) async {
    final data = await _supabase
        .from('vehicle_insurances')
        .select()
        .eq(
          'vehicle_id',
          vehicleId,
        )
        .order('created_at');

    return data
        .map<VehicleInsurance>(
          (map) =>
              VehicleInsurance.fromMap(
            map,
          ),
        )
        .toList();
  }

  Future<VehicleInsurance>
      saveInsurance(
    VehicleInsurance insurance,
  ) async {
    if (insurance.vehicleId == null) {
      throw Exception(
        'Cannot save insurance without vehicle id',
      );
    }

    final data = await _supabase
        .from('vehicle_insurances')
        .upsert(
          insurance.toMap(),
          onConflict:
              'vehicle_id,type',
        )
        .select()
        .single();

    return VehicleInsurance.fromMap(
      data,
    );
  }

  Future<void> deleteInsurance(
    String insuranceId,
  ) async {
    await _supabase
        .from('vehicle_insurances')
        .delete()
        .eq(
          'id',
          insuranceId,
        );
  }

  // -------------------------
  // Vehicle events / history
  // -------------------------

  Future<List<VehicleEvent>>
      getVehicleEvents(
    String vehicleId,
  ) async {
    final data = await _supabase
        .from('vehicle_events')
        .select()
        .eq(
          'vehicle_id',
          vehicleId,
        )
        .order(
          'event_date',
          ascending: false,
        );

    return data
        .map<VehicleEvent>(
          (map) =>
              VehicleEvent.fromMap(
            map,
          ),
        )
        .toList();
  }

  Future<VehicleEvent>
      addVehicleEvent(
    VehicleEvent event,
  ) async {
    if (event.vehicleId == null) {
      throw Exception(
        'Cannot save event without vehicle id',
      );
    }

    final data = await _supabase
        .from('vehicle_events')
        .insert(
          event.toMap(),
        )
        .select()
        .single();

    return VehicleEvent.fromMap(
      data,
    );
  }

  Future<void> updateVehicleEvent(
    VehicleEvent event,
  ) async {
    if (event.id == null) {
      throw Exception(
        'Cannot update event without an id',
      );
    }

    await _supabase
        .from('vehicle_events')
        .update(
          event.toMap(),
        )
        .eq(
          'id',
          event.id!,
        );
  }

  Future<void> deleteVehicleEvent(
    String eventId,
  ) async {
    await _supabase
        .from('vehicle_events')
        .delete()
        .eq(
          'id',
          eventId,
        );
  }
}