import 'vehicle_insurance.dart';

enum VehicleEventType {
  service,
  test,
  vehicleLicense,
  insurance,
  repair,
  other,
}

extension VehicleEventTypeDisplayName on VehicleEventType {
  String get displayName {
    switch (this) {
      case VehicleEventType.service:
        return 'טיפול';

      case VehicleEventType.test:
        return 'טסט';

      case VehicleEventType.vehicleLicense:
        return 'רישיון רכב';

      case VehicleEventType.insurance:
        return 'ביטוח';

      case VehicleEventType.repair:
        return 'תיקון';

      case VehicleEventType.other:
        return 'אחר';
    }
  }

  String get databaseValue {
    switch (this) {
      case VehicleEventType.service:
        return 'service';

      case VehicleEventType.test:
        return 'test';

      case VehicleEventType.vehicleLicense:
        return 'vehicle_license';

      case VehicleEventType.insurance:
        return 'insurance';

      case VehicleEventType.repair:
        return 'repair';

      case VehicleEventType.other:
        return 'other';
    }
  }
}

class VehicleEvent {
  final String? id;
  final String? vehicleId;

  final VehicleEventType type;

  DateTime date;
  String title;

  int? mileage;
  double? cost;
  String? notes;

  int? serviceIntervalKm;

  InsuranceType? insuranceType;

  VehicleEvent({
    this.id,
    this.vehicleId,
    required this.type,
    required this.date,
    required this.title,
    this.mileage,
    this.cost,
    this.notes,
    this.serviceIntervalKm,
    this.insuranceType,
  });

  factory VehicleEvent.fromMap(
    Map<String, dynamic> map,
  ) {
    return VehicleEvent(
      id: map['id'] as String?,
      vehicleId: map['vehicle_id'] as String?,
      type: _eventTypeFromDatabase(
        map['type'] as String,
      ),
      date: DateTime.parse(
        map['event_date'].toString(),
      ),
      title: map['title'] as String,
      mileage:
          (map['mileage'] as num?)?.toInt(),
      cost:
          (map['cost'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      serviceIntervalKm:
          (map['service_interval_km'] as num?)
              ?.toInt(),
      insuranceType:
          _insuranceTypeFromDatabase(
        map['insurance_type'] as String?,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (vehicleId != null)
        'vehicle_id': vehicleId,
      'type': type.databaseValue,
      'title': title,
      'event_date': _dateToString(date),
      'mileage': mileage,
      'cost': cost,
      'notes': notes,
      'service_interval_km':
          serviceIntervalKm,
      'insurance_type':
          insuranceType?.databaseValue,
    };
  }

  static VehicleEventType
      _eventTypeFromDatabase(
    String value,
  ) {
    switch (value) {
      case 'service':
        return VehicleEventType.service;

      case 'test':
        return VehicleEventType.test;

      case 'vehicle_license':
        return VehicleEventType.vehicleLicense;

      case 'insurance':
        return VehicleEventType.insurance;

      case 'repair':
        return VehicleEventType.repair;

      case 'other':
        return VehicleEventType.other;

      default:
        throw ArgumentError(
          'Unknown vehicle event type: $value',
        );
    }
  }

  static InsuranceType?
      _insuranceTypeFromDatabase(
    String? value,
  ) {
    if (value == null) {
      return null;
    }

    switch (value) {
      case 'mandatory':
        return InsuranceType.mandatory;

      case 'comprehensive':
        return InsuranceType.comprehensive;

      case 'third_party':
        return InsuranceType.thirdParty;

      default:
        throw ArgumentError(
          'Unknown insurance type: $value',
        );
    }
  }

  static String _dateToString(
    DateTime date,
  ) {
    final month =
        date.month.toString().padLeft(2, '0');

    final day =
        date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}