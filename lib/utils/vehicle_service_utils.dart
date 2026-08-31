import '../models/vehicle.dart';
import '../models/vehicle_event.dart';

class VehicleServiceUtils {
  static DateTime? getNextServiceDate(
    Vehicle vehicle,
  ) {
    final lastServiceDate =
        vehicle.lastServiceDate;

    if (lastServiceDate == null) {
      return null;
    }

    final nextYear =
        lastServiceDate.year + 1;

    final lastDayOfMonth = DateTime(
      nextYear,
      lastServiceDate.month + 1,
      0,
    ).day;

    final day =
        lastServiceDate.day >
                lastDayOfMonth
            ? lastDayOfMonth
            : lastServiceDate.day;

    return DateTime(
      nextYear,
      lastServiceDate.month,
      day,
    );
  }

  static int? getNextServiceMileage(
    Vehicle vehicle,
  ) {
    final lastServiceMileage =
        vehicle.lastServiceMileage;

    final serviceIntervalKm =
        vehicle.serviceIntervalKm;

    if (lastServiceMileage == null ||
        serviceIntervalKm == null) {
      return null;
    }

    return lastServiceMileage +
        serviceIntervalKm;
  }

  static VehicleEvent?
      getLatestServiceEvent(
    List<VehicleEvent> events,
  ) {
    final serviceEvents = events
        .where(
          (event) =>
              event.type ==
              VehicleEventType.service,
        )
        .toList();

    if (serviceEvents.isEmpty) {
      return null;
    }

    serviceEvents.sort(
      (a, b) =>
          b.date.compareTo(a.date),
    );

    return serviceEvents.first;
  }

  static void
      updateCurrentServiceFromHistory(
    Vehicle vehicle,
  ) {
    final latestService =
        getLatestServiceEvent(
      vehicle.events,
    );

    if (latestService == null) {
      vehicle.lastServiceDate = null;
      vehicle.lastServiceMileage = null;
      vehicle.serviceIntervalKm = null;
      return;
    }

    vehicle.lastServiceDate =
        latestService.date;

    vehicle.lastServiceMileage =
        latestService.mileage;

    vehicle.serviceIntervalKm =
        latestService.serviceIntervalKm;
  }
}