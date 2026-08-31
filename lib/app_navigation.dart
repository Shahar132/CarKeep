import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

class AppNavigation extends StatelessWidget {
  // Optional dependencies for Widget Tests.
  //
  // In the real app, when they are not supplied,
  // AppNavigation continues using Supabase Auth.
  final Stream<Object?>? authStateStream;

  final bool Function()?
      isAuthenticatedProvider;

  final Widget Function()?
      authScreenBuilder;

  final Widget Function()?
      homeScreenBuilder;

  const AppNavigation({
    super.key,
    this.authStateStream,
    this.isAuthenticatedProvider,
    this.authScreenBuilder,
    this.homeScreenBuilder,
  });

  Stream<Object?> getAuthStateStream() {
    if (authStateStream != null) {
      return authStateStream!;
    }

    return Supabase.instance.client.auth
        .onAuthStateChange;
  }

  bool isAuthenticated() {
    if (isAuthenticatedProvider != null) {
      return isAuthenticatedProvider!();
    }

    return Supabase.instance.client.auth
            .currentSession !=
        null;
  }

  Widget buildAuthScreen() {
    if (authScreenBuilder != null) {
      return authScreenBuilder!();
    }

    return const AuthScreen();
  }

  Widget buildHomeScreen() {
    if (homeScreenBuilder != null) {
      return homeScreenBuilder!();
    }

    return const HomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'CarKeep',

      theme: AppTheme.lightTheme,

      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },

      home: StreamBuilder<Object?>(
        stream: getAuthStateStream(),
        builder: (context, snapshot) {
          if (!isAuthenticated()) {
            return buildAuthScreen();
          }

          return buildHomeScreen();
        },
      ),
    );
  }
}