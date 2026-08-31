enum VehicleDocumentCategory {
  vehicleLicense,
  test,
  insurance,
  service,
  other,
}

extension VehicleDocumentCategoryExtension
    on VehicleDocumentCategory {
  String get displayName {
    switch (this) {
      case VehicleDocumentCategory.vehicleLicense:
        return 'רישיונות רכב';

      case VehicleDocumentCategory.test:
        return 'טסטים';

      case VehicleDocumentCategory.insurance:
        return 'ביטוחים';

      case VehicleDocumentCategory.service:
        return 'טיפולים';

      case VehicleDocumentCategory.other:
        return 'מסמכים אחרים';
    }
  }

  String get databaseValue {
    switch (this) {
      case VehicleDocumentCategory.vehicleLicense:
        return 'vehicle_license';

      case VehicleDocumentCategory.test:
        return 'test';

      case VehicleDocumentCategory.insurance:
        return 'insurance';

      case VehicleDocumentCategory.service:
        return 'service';

      case VehicleDocumentCategory.other:
        return 'other';
    }
  }
}

class VehicleDocument {
  final String? id;
  final String? vehicleId;
  final String? eventId;

  final String displayName;
  final String? originalFileName;
  final String filePath;

  final VehicleDocumentCategory category;

  final String? uploadedBy;
  final DateTime? createdAt;

  const VehicleDocument({
    this.id,
    this.vehicleId,
    this.eventId,
    required this.displayName,
    this.originalFileName,
    required this.filePath,
    this.category = VehicleDocumentCategory.other,
    this.uploadedBy,
    this.createdAt,
  });

  factory VehicleDocument.fromMap(
    Map<String, dynamic> map,
  ) {
    return VehicleDocument(
      id: map['id'] as String?,
      vehicleId:
          map['vehicle_id'] as String?,
      eventId:
          map['event_id'] as String?,
      displayName:
          map['display_name'] as String,
      originalFileName:
          map['original_file_name']
              as String?,
      filePath:
          map['file_path'] as String,
      category:
          _categoryFromDatabase(
        map['category'] as String?,
      ),
      uploadedBy:
          map['uploaded_by'] as String?,
      createdAt:
          map['created_at'] == null
              ? null
              : DateTime.tryParse(
                  map['created_at']
                      .toString(),
                ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (vehicleId != null)
        'vehicle_id': vehicleId,

      if (eventId != null)
        'event_id': eventId,

      'display_name': displayName,
      'original_file_name':
          originalFileName,
      'file_path': filePath,
      'category':
          category.databaseValue,
      'uploaded_by': uploadedBy,
    };
  }

  static VehicleDocumentCategory
      _categoryFromDatabase(
    String? value,
  ) {
    switch (value) {
      case 'vehicle_license':
        return VehicleDocumentCategory
            .vehicleLicense;

      case 'test':
        return VehicleDocumentCategory.test;

      case 'insurance':
        return VehicleDocumentCategory
            .insurance;

      case 'service':
        return VehicleDocumentCategory
            .service;

      case 'other':
      case null:
        return VehicleDocumentCategory.other;

      default:
        return VehicleDocumentCategory.other;
    }
  }
}