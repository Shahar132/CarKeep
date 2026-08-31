import 'package:supabase_flutter/supabase_flutter.dart';

import 'integration_config.dart';
import 'test_users.dart';

class SupabaseTestClients {
  SupabaseTestClients._();

  /// Creates a completely separate Supabase client.
  ///
  /// We intentionally do not use Supabase.instance.client here because
  /// integration tests need multiple independent authenticated users
  /// at the same time:
  ///
  /// User A -> Owner
  /// User B -> Admin
  /// User C -> Member
  /// User D -> Outsider
static SupabaseClient createClient() {
  IntegrationConfig.validate();

  return SupabaseClient(
    IntegrationConfig.supabaseUrl,
    IntegrationConfig.supabaseAnonKey,
    authOptions: const AuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );
}

  static Future<AuthResponse> signUp(
    SupabaseClient client,
    IntegrationTestUser user,
  ) {
    return client.auth.signUp(
      email: user.email,
      password: user.password,
      data: {
        'name': user.name,
      },
    );
  }

  static Future<AuthResponse> signIn(
    SupabaseClient client,
    IntegrationTestUser user, {
    String? password,
  }) {
    return client.auth.signInWithPassword(
      email: user.email,
      password: password ?? user.password,
    );
  }

  /// Used by integration tests that are not specifically testing
  /// the signup screen itself.
  ///
  /// It creates the user and requires an authenticated session.
  ///
  /// If local email confirmation is enabled and Supabase does not return
  /// a session immediately, this method throws a clear error instead of
  /// silently continuing with an unauthenticated client.
  static Future<SupabaseClient> createAuthenticatedUser(
    IntegrationTestUser user,
  ) async {
    final client = createClient();

    final signUpResponse = await signUp(
      client,
      user,
    );

    if (signUpResponse.session != null &&
        client.auth.currentUser != null) {
      return client;
    }

    try {
      final signInResponse = await signIn(
        client,
        user,
      );

      if (signInResponse.session == null ||
          client.auth.currentUser == null) {
        throw StateError(
          'User ${user.label} was created but no authenticated '
          'session was returned.',
        );
      }

      return client;
    } on AuthException catch (error) {
      throw StateError(
        'Could not create an authenticated integration-test user '
        'for ${user.label}.\n'
        'Local email confirmation may be enabled.\n'
        'Auth error: ${error.message}',
      );
    }
  }

  static String requireCurrentUserId(
    SupabaseClient client,
  ) {
    final userId = client.auth.currentUser?.id;

    if (userId == null || userId.isEmpty) {
      throw StateError(
        'Expected an authenticated Supabase user, '
        'but the client has no current user.',
      );
    }

    return userId;
  }

  static Future<void> signOut(
    SupabaseClient client,
  ) async {
    await client.auth.signOut();
  }

  static Future<void> signOutQuietly(
    SupabaseClient client,
  ) async {
    try {
      await client.auth.signOut();
    } catch (_) {
      // Cleanup should not hide the actual test result.
    }
  }

  static Future<void> signOutAll(
    Iterable<SupabaseClient> clients,
  ) async {
    for (final client in clients) {
      await signOutQuietly(client);
    }
  }
}