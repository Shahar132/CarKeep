import 'vehicle_event.dart';
import 'vehicle_insurance.dart';
import 'vehicle_member.dart';

class Vehicle {
  final String? id;

  final String license;
  final String manufacturer;
  final String model;
  final int year;

  int mileage;

  DateTime? testExpiryDate;

  // Controls whether the test expiry
  // is shown on the home screen.
  bool showTestOnHome;

  // Vehicle license expiry date.
  DateTime? vehicleLicenseExpiryDate;

  // Controls whether the vehicle license expiry
  // is shown on the home screen.
  bool showVehicleLicenseOnHome;

  final List<VehicleInsurance> insurances;
  final List<VehicleEvent> events;

  DateTime? lastServiceDate;
  int? lastServiceMileage;
  int? serviceIntervalKm;

  // Controls whether the next service
  // is shown on the home screen.
  bool showServiceOnHome;

  // The role of the currently logged-in user
  // for this specific vehicle.
  VehicleMemberRole? currentUserRole;

  Vehicle({
    this.id,
    required this.license,
    required this.manufacturer,
    required this.model,
    required this.year,
    required this.mileage,
    this.testExpiryDate,
    this.showTestOnHome = true,
    this.vehicleLicenseExpiryDate,
    this.showVehicleLicenseOnHome = false,
    List<VehicleInsurance>? insurances,
    List<VehicleEvent>? events,
    this.lastServiceDate,
    this.lastServiceMileage,
    this.serviceIntervalKm,
    this.showServiceOnHome = true,
    this.currentUserRole,
  })  : insurances = insurances ?? [],
        events = events ?? [];

  factory Vehicle.fromMap(
    Map<String, dynamic> map,
  ) {
    return Vehicle(
      id: map['id'] as String?,
      license: map['license'] as String,
      manufacturer:
          map['manufacturer'] as String,
      model: map['model'] as String,
      year: (map['year'] as num).toInt(),
      mileage:
          (map['mileage'] as num).toInt(),

      testExpiryDate:
          _parseDate(
        map['test_expiry_date'],
      ),

      showTestOnHome:
          map['show_test_on_home']
                  as bool? ??
              true,

      vehicleLicenseExpiryDate:
          _parseDate(
        map['vehicle_license_expiry_date'],
      ),

      showVehicleLicenseOnHome:
          map['show_vehicle_license_on_home']
                  as bool? ??
              false,

      lastServiceDate:
          _parseDate(
        map['last_service_date'],
      ),

      lastServiceMileage:
          (map['last_service_mileage']
                  as num?)
              ?.toInt(),

      serviceIntervalKm:
          (map['service_interval_km']
                  as num?)
              ?.toInt(),

      showServiceOnHome:
          map['show_service_on_home']
                  as bool? ??
              true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'license': license,
      'manufacturer': manufacturer,
      'model': model,
      'year': year,
      'mileage': mileage,

      'test_expiry_date':
          _dateToString(
        testExpiryDate,
      ),

      'show_test_on_home':
          showTestOnHome,

      'vehicle_license_expiry_date':
          _dateToString(
        vehicleLicenseExpiryDate,
      ),

      'show_vehicle_license_on_home':
          showVehicleLicenseOnHome,

      'last_service_date':
          _dateToString(
        lastServiceDate,
      ),

      'last_service_mileage':
          lastServiceMileage,

      'service_interval_km':
          serviceIntervalKm,

      'show_service_on_home':
          showServiceOnHome,
    };
  }

  static DateTime? _parseDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  static String? _dateToString(
    DateTime? date,
  ) {
    if (date == null) {
      return null;
    }

    final month =
        date.month
            .toString()
            .padLeft(2, '0');

    final day =
        date.day
            .toString()
            .padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}