import '../models/vehicle_event.dart';

class VehicleEventUtils {
  static DateTime? getLatestEventDate(
    List<VehicleEvent> events,
    VehicleEventType type,
  ) {
    final matchingEvents = events.where(
      (event) => event.type == type,
    );

    if (matchingEvents.isEmpty) {
      return null;
    }

    DateTime? latestDate;

    for (final event in matchingEvents) {
      if (latestDate == null ||
          event.date.isAfter(latestDate)) {
        latestDate = event.date;
      }
    }

    return latestDate;
  }
}