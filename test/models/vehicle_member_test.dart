import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/vehicle_member.dart';

void main() {
  group('VehicleMemberRole', () {
    test(
      'has correct Hebrew display names',
      () {
        expect(
          VehicleMemberRole.owner.displayName,
          'בעלים',
        );

        expect(
          VehicleMemberRole.admin.displayName,
          'מנהל',
        );

        expect(
          VehicleMemberRole.member.displayName,
          'משתמש',
        );
      },
    );

    test(
      'converts roles to correct database values',
      () {
        expect(
          VehicleMemberRole.owner.databaseValue,
          'owner',
        );

        expect(
          VehicleMemberRole.admin.databaseValue,
          'admin',
        );

        expect(
          VehicleMemberRole.member.databaseValue,
          'member',
        );
      },
    );

    test(
      'owner has full permissions',
      () {
        const role =
            VehicleMemberRole.owner;

        expect(
          role.canEditVehicle,
          isTrue,
        );

        expect(
          role.canManageMembers,
          isTrue,
        );

        expect(
          role.canDeleteVehicle,
          isTrue,
        );
      },
    );

    test(
      'admin can edit but cannot manage members or delete vehicle',
      () {
        const role =
            VehicleMemberRole.admin;

        expect(
          role.canEditVehicle,
          isTrue,
        );

        expect(
          role.canManageMembers,
          isFalse,
        );

        expect(
          role.canDeleteVehicle,
          isFalse,
        );
      },
    );

    test(
      'member is read only',
      () {
        const role =
            VehicleMemberRole.member;

        expect(
          role.canEditVehicle,
          isFalse,
        );

        expect(
          role.canManageMembers,
          isFalse,
        );

        expect(
          role.canDeleteVehicle,
          isFalse,
        );
      },
    );

    test(
      'reads all known roles from database',
      () {
        expect(
          vehicleMemberRoleFromDatabase(
            'owner',
          ),
          VehicleMemberRole.owner,
        );

        expect(
          vehicleMemberRoleFromDatabase(
            'admin',
          ),
          VehicleMemberRole.admin,
        );

        expect(
          vehicleMemberRoleFromDatabase(
            'member',
          ),
          VehicleMemberRole.member,
        );
      },
    );

    test(
      'unknown database role defaults to member',
      () {
        expect(
          vehicleMemberRoleFromDatabase(
            'unknown',
          ),
          VehicleMemberRole.member,
        );
      },
    );
  });
}