enum VehicleMemberRole {
  owner,
  admin,
  member,
}

extension VehicleMemberRoleExtension on VehicleMemberRole {
  String get displayName {
    switch (this) {
      case VehicleMemberRole.owner:
        return 'בעלים';

      case VehicleMemberRole.admin:
        return 'מנהל';

      case VehicleMemberRole.member:
        return 'משתמש';
    }
  }

  String get databaseValue {
    switch (this) {
      case VehicleMemberRole.owner:
        return 'owner';

      case VehicleMemberRole.admin:
        return 'admin';

      case VehicleMemberRole.member:
        return 'member';
    }
  }

  bool get canEditVehicle {
    return this == VehicleMemberRole.owner ||
        this == VehicleMemberRole.admin;
  }

  bool get canManageMembers {
    return this == VehicleMemberRole.owner;
  }

  bool get canDeleteVehicle {
    return this == VehicleMemberRole.owner;
  }
}

VehicleMemberRole vehicleMemberRoleFromDatabase(
  String value,
) {
  switch (value) {
    case 'owner':
      return VehicleMemberRole.owner;

    case 'admin':
      return VehicleMemberRole.admin;

    case 'member':
    default:
      return VehicleMemberRole.member;
  }
}