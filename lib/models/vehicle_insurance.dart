enum InsuranceType {
  mandatory,
  comprehensive,
  thirdParty,
}

extension InsuranceTypeDisplayName on InsuranceType {
  String get displayName {
    switch (this) {
      case InsuranceType.mandatory:
        return 'ביטוח חובה';

      case InsuranceType.comprehensive:
        return 'ביטוח מקיף';

      case InsuranceType.thirdParty:
        return 'ביטוח צד ג׳';
    }
  }

  String get databaseValue {
    switch (this) {
      case InsuranceType.mandatory:
        return 'mandatory';

      case InsuranceType.comprehensive:
        return 'comprehensive';

      case InsuranceType.thirdParty:
        return 'third_party';
    }
  }
}

class VehicleInsurance {
  final String? id;
  final String? vehicleId;

  final InsuranceType type;

  DateTime? expiryDate;

  bool showOnHome;

  VehicleInsurance({
    this.id,
    this.vehicleId,
    required this.type,
    this.expiryDate,
    this.showOnHome = false,
  });

  factory VehicleInsurance.fromMap(
    Map<String, dynamic> map,
  ) {
    return VehicleInsurance(
      id: map['id'] as String?,
      vehicleId: map['vehicle_id'] as String?,
      type: _insuranceTypeFromDatabase(
        map['type'] as String,
      ),
      expiryDate: _parseDate(
        map['expiry_date'],
      ),
      showOnHome: map['show_on_home'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (vehicleId != null) 'vehicle_id': vehicleId,
      'type': type.databaseValue,
      'expiry_date': _dateToString(expiryDate),
      'show_on_home': showOnHome,
    };
  }

  static InsuranceType _insuranceTypeFromDatabase(
    String value,
  ) {
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

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }

  static String? _dateToString(DateTime? date) {
    if (date == null) {
      return null;
    }

    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}