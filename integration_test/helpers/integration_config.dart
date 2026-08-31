class IntegrationConfig {
  IntegrationConfig._();

  /// Unique identifier for the current integration-test process.
  ///
  /// It is used for generated users, vehicles and files so that repeated
  /// test runs do not collide with previous local test data.
  static final String runId =
      DateTime.now().microsecondsSinceEpoch.toString();

  /// Supabase Local API URL.
  ///
  /// Physical Android device:
  /// Use 127.0.0.1 together with:
  /// adb reverse tcp:54321 tcp:54321
  ///
  /// Android Emulator:
  /// Override with:
  /// --dart-define=SUPABASE_TEST_URL=http://10.0.2.2:54321
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_TEST_URL',
    defaultValue: 'http://127.0.0.1:54321',
  );

  /// Local Supabase anon/publishable key.
  ///
  /// Pass it when running the integration tests:
  ///
  /// --dart-define=SUPABASE_TEST_ANON_KEY=<local-key>
  ///
  /// Do not use a production service-role key here.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_TEST_ANON_KEY',
    defaultValue: '',
  );

  static const String storageBucket = 'vehicle-documents';

  static const String profilesTable = 'profiles';
  static const String vehiclesTable = 'vehicles';
  static const String vehicleMembersTable = 'vehicle_members';
  static const String vehicleEventsTable = 'vehicle_events';
  static const String vehicleInsurancesTable = 'vehicle_insurances';
  static const String documentsTable = 'documents';

  /// Prevents integration tests from accidentally running against
  /// the hosted production/development Supabase project.
  static void validate() {
    if (supabaseAnonKey.trim().isEmpty) {
      throw StateError(
        'SUPABASE_TEST_ANON_KEY is missing.\n'
        'Run the test with the local Supabase anon/publishable key using:\n'
        '--dart-define=SUPABASE_TEST_ANON_KEY=<local-key>',
      );
    }

    final uri = Uri.tryParse(supabaseUrl);

    if (uri == null) {
      throw StateError(
        'Invalid SUPABASE_TEST_URL: $supabaseUrl',
      );
    }

    const allowedLocalHosts = {
      '127.0.0.1',
      'localhost',
      '10.0.2.2',
    };

    if (!allowedLocalHosts.contains(uri.host)) {
      throw StateError(
        'Integration tests are allowed to run only against Supabase Local.\n'
        'Received URL: $supabaseUrl',
      );
    }

    if (uri.port != 54321) {
      throw StateError(
        'Unexpected Supabase Local port: ${uri.port}.\n'
        'Expected port 54321.',
      );
    }
  }
}