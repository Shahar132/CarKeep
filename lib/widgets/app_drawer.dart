import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback onVehiclesTap;
  final VoidCallback onAccountTap;

  final bool vehiclesSelected;
  final bool accountSelected;

  // Optional values mainly useful for testing.
  // When they are not supplied, the drawer
  // continues reading the current Supabase user.
  final String? userName;
  final String? userEmail;

  const AppDrawer({
    super.key,
    required this.onVehiclesTap,
    required this.onAccountTap,
    this.vehiclesSelected = false,
    this.accountSelected = false,
    this.userName,
    this.userEmail,
  });

  String getUserName() {
    if (userName != null) {
      final trimmedName =
          userName!.trim();

      if (trimmedName.isNotEmpty) {
        return trimmedName;
      }

      return 'משתמש';
    }

    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return 'משתמש';
    }

    final name =
        user.userMetadata?['name'];

    if (name != null &&
        name.toString().trim().isNotEmpty) {
      return name.toString().trim();
    }

    return 'משתמש';
  }

  String getUserEmail() {
    if (userEmail != null) {
      return userEmail!.trim();
    }

    return Supabase
            .instance
            .client
            .auth
            .currentUser
            ?.email ??
        '';
  }

  Widget buildMenuItem({
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      child: Material(
        color: selected
            ? AppTheme.interactiveSurface
            : Colors.transparent,
        borderRadius:
            BorderRadius.circular(12),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.iconBackground
                        : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: selected
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                    size: 23,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),

                if (selected)
                  const Icon(
                    Icons.circle,
                    size: 8,
                    color: AppTheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedUserName =
        getUserName();

    final displayedEmail =
        getUserEmail();

    return Drawer(
      backgroundColor:
          AppTheme.background,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration:
                        BoxDecoration(
                      color:
                          AppTheme.iconBackground,
                      shape:
                          BoxShape.circle,
                      border:
                          Border.all(
                        color:
                            AppTheme.interactiveBorder,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 30,
                      color:
                          AppTheme.primary,
                    ),
                  ),

                  const SizedBox(
                    width: 14,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayedUserName,
                          style:
                              const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                AppTheme.textPrimary,
                          ),
                        ),

                        if (displayedEmail
                            .isNotEmpty) ...[
                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            displayedEmail,
                            textDirection:
                                TextDirection.ltr,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                const TextStyle(
                              fontSize: 13,
                              color:
                                  AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            const SizedBox(
              height: 8,
            ),

            buildMenuItem(
              icon:
                  Icons.directions_car_outlined,
              title:
                  'הרכבים שלי',
              selected:
                  vehiclesSelected,
              onTap:
                  onVehiclesTap,
            ),

            buildMenuItem(
              icon:
                  Icons.person_outline,
              title:
                  'החשבון שלי',
              selected:
                  accountSelected,
              onTap:
                  onAccountTap,
            ),

            const Spacer(),

            const Padding(
              padding:
                  EdgeInsets.all(16),
              child: Text(
                'CarKeep',
                style:
                    TextStyle(
                  fontSize: 12,
                  color:
                      AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}