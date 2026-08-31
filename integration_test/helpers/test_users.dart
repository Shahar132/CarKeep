import 'integration_config.dart';

class IntegrationTestUser {
  final String label;
  final String name;
  final String email;
  final String password;
  final String expectedVehicleRole;

  const IntegrationTestUser({
    required this.label,
    required this.name,
    required this.email,
    required this.password,
    required this.expectedVehicleRole,
  });

  @override
  String toString() {
    return '$label ($email)';
  }
}

class IntegrationTestUsers {
  IntegrationTestUsers._();

  static final String _runId = IntegrationConfig.runId;

  /// User A
  /// Expected to become the vehicle owner.
  static final IntegrationTestUser owner = IntegrationTestUser(
    label: 'User A',
    name: 'CarKeep Test Owner',
    email: 'carkeep.owner.$_runId@example.com',
    password: 'CarKeepTest!2026Owner',
    expectedVehicleRole: 'owner',
  );

  /// User B
  /// Initially created as a normal user.
  /// The Owner will later add this user to the vehicle and promote
  /// the membership to admin.
  static final IntegrationTestUser admin = IntegrationTestUser(
    label: 'User B',
    name: 'CarKeep Test Admin',
    email: 'carkeep.admin.$_runId@example.com',
    password: 'CarKeepTest!2026Admin',
    expectedVehicleRole: 'admin',
  );

  /// User C
  /// Expected to remain a read-only vehicle member.
  static final IntegrationTestUser member = IntegrationTestUser(
    label: 'User C',
    name: 'CarKeep Test Member',
    email: 'carkeep.member.$_runId@example.com',
    password: 'CarKeepTest!2026Member',
    expectedVehicleRole: 'member',
  );

  /// User D
  /// Must never be added to the tested vehicle.
  /// This user is used for outsider/RLS security tests.
  static final IntegrationTestUser outsider = IntegrationTestUser(
    label: 'User D',
    name: 'CarKeep Test Outsider',
    email: 'carkeep.outsider.$_runId@example.com',
    password: 'CarKeepTest!2026Outsider',
    expectedVehicleRole: 'outsider',
  );

  /// Password used by the password-change integration test.
  static const String updatedPassword = 'CarKeepTest!2026Updated';

  static List<IntegrationTestUser> get all => [
        owner,
        admin,
        member,
        outsider,
      ];
}