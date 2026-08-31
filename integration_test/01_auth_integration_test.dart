import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/integration_config.dart';
import 'helpers/supabase_test_clients.dart';
import 'helpers/test_users.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group(
    'CarKeep Auth Integration Tests',
    () {
      testWidgets(
        'signup creates Auth user and profile, logout works, invalid login fails and valid login succeeds',
        (tester) async {
          IntegrationConfig.validate();

          final client =
              SupabaseTestClients.createClient();

          final testUser =
              IntegrationTestUsers.owner;

          try {
            // ----------------------------------------------------------
            // 1. Sign up
            // ----------------------------------------------------------

            final signUpResponse =
                await SupabaseTestClients.signUp(
              client,
              testUser,
            );

            final createdUser =
                signUpResponse.user;

            expect(
              createdUser,
              isNotNull,
            );

            expect(
              createdUser!.email,
              testUser.email,
            );

            expect(
              createdUser.userMetadata?['name'],
              testUser.name,
            );

            // Local automated integration testing expects
            // email confirmation to be disabled.
            expect(
              signUpResponse.session,
              isNotNull,
              reason:
                  'Supabase Local should return a session after signup.',
            );

            expect(
              client.auth.currentUser?.id,
              createdUser.id,
            );

            // ----------------------------------------------------------
            // 2. Verify Auth user
            // ----------------------------------------------------------

            final userResponse =
                await client.auth.getUser();

            expect(
              userResponse.user?.id,
              createdUser.id,
            );

            expect(
              userResponse.user?.email,
              testUser.email,
            );

            // ----------------------------------------------------------
            // 3. Verify automatic profile trigger
            // ----------------------------------------------------------

            final profile =
                await client
                    .from(
                      IntegrationConfig
                          .profilesTable,
                    )
                    .select(
                      'id, name',
                    )
                    .eq(
                      'id',
                      createdUser.id,
                    )
                    .single();

            expect(
              profile['id'],
              createdUser.id,
            );

            expect(
              profile['name'],
              testUser.name,
            );

            // ----------------------------------------------------------
            // 4. Logout
            // ----------------------------------------------------------

            await client.auth.signOut();

            expect(
              client.auth.currentSession,
              isNull,
            );

            expect(
              client.auth.currentUser,
              isNull,
            );

            // ----------------------------------------------------------
            // 5. Wrong password must fail
            // ----------------------------------------------------------

            Object? wrongPasswordError;

            try {
              await client.auth
                  .signInWithPassword(
                email: testUser.email,
                password:
                    'DefinitelyWrongPassword!123',
              );
            } catch (error) {
              wrongPasswordError = error;
            }

            expect(
              wrongPasswordError,
              isNotNull,
            );

            expect(
              client.auth.currentSession,
              isNull,
            );

            // ----------------------------------------------------------
            // 6. Correct login
            // ----------------------------------------------------------

            final loginResponse =
                await SupabaseTestClients.signIn(
              client,
              testUser,
            );

            expect(
              loginResponse.session,
              isNotNull,
            );

            expect(
              loginResponse.user?.id,
              createdUser.id,
            );

            expect(
              client.auth.currentUser?.id,
              createdUser.id,
            );

            // ----------------------------------------------------------
            // 7. Profile persists after logout/login
            // ----------------------------------------------------------

            final profileAfterLogin =
                await client
                    .from(
                      IntegrationConfig
                          .profilesTable,
                    )
                    .select(
                      'id, name',
                    )
                    .eq(
                      'id',
                      createdUser.id,
                    )
                    .single();

            expect(
              profileAfterLogin['id'],
              createdUser.id,
            );

            expect(
              profileAfterLogin['name'],
              testUser.name,
            );
          } finally {
            await SupabaseTestClients
                .signOutQuietly(
              client,
            );
          }
        },
      );
    },
  );
}