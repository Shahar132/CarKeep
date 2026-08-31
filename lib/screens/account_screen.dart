import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vehicle.dart';
import '../models/vehicle_member.dart';
import '../repositories/vehicle_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

enum AccountDeleteResult {
  success,
  ownershipTransferRequired,
  failure,
}

class AccountScreen extends StatefulWidget {
  // Optional dependencies for Widget Tests.
  //
  // When they are not supplied, the screen
  // continues using the real Supabase services.
  final VehicleRepository? repository;

  final Future<List<Vehicle>> Function()?
      vehiclesLoader;

  final String? userName;
  final String? userEmail;
  final String? userId;

  final Future<void> Function(
    String newName,
  )? changeNameAction;

  final Future<void> Function(
    String currentPassword,
    String newPassword,
  )? changePasswordAction;

  final Future<void> Function()?
      signOutAction;

  final Future<int> Function(
    String vehicleId,
  )? memberCountLoader;

  final Future<AccountDeleteResult>
      Function()? deleteAccountAction;

  const AccountScreen({
    super.key,
    this.repository,
    this.vehiclesLoader,
    this.userName,
    this.userEmail,
    this.userId,
    this.changeNameAction,
    this.changePasswordAction,
    this.signOutAction,
    this.memberCountLoader,
    this.deleteAccountAction,
  });

  @override
  State<AccountScreen> createState() =>
      _AccountScreenState();
}

class _AccountScreenState
    extends State<AccountScreen> {
  VehicleRepository? _vehicleRepository;

  VehicleRepository get vehicleRepository =>
      widget.repository ??
      (_vehicleRepository ??=
          VehicleRepository());

  // Supabase is lazy so Widget Tests that
  // provide dependencies do not touch it.
  SupabaseClient get supabase =>
      Supabase.instance.client;

  bool isLoading = false;
  bool isLoadingVehicles = true;

  String? vehiclesError;

  List<Vehicle> vehicles = [];

  ShapeBorder get interactiveCardShape {
    return RoundedRectangleBorder(
      borderRadius:
          BorderRadius.circular(16),
      side: const BorderSide(
        color:
            AppTheme.interactiveBorder,
        width: 1.2,
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    loadVehicles();
  }

  String? getCurrentUserId() {
    if (widget.userId != null) {
      return widget.userId;
    }

    return supabase.auth.currentUser?.id;
  }

  String getUserName() {
    if (widget.userName != null) {
      final name =
          widget.userName!.trim();

      if (name.isNotEmpty) {
        return name;
      }

      return 'משתמש';
    }

    final user =
        supabase.auth.currentUser;

    if (user == null) {
      return '';
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
    if (widget.userEmail != null) {
      return widget.userEmail!.trim();
    }

    return supabase.auth.currentUser?.email ??
        '';
  }

  Future<void> loadVehicles() async {
    try {
      final loadedVehicles =
          widget.vehiclesLoader != null
              ? await widget.vehiclesLoader!()
              : await vehicleRepository
                  .getVehicles();

      if (!mounted) {
        return;
      }

      setState(() {
        vehicles = loadedVehicles;
        vehiclesError = null;
        isLoadingVehicles = false;
      });
    } catch (error) {
      debugPrint(
        'Error loading account vehicles: '
        '$error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        vehiclesError =
            'לא הצלחנו לטעון את תפקידי הרכבים.';
        isLoadingVehicles = false;
      });
    }
  }

  void openVehiclesFromDrawer() {
    Navigator.pop(context);

    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
  }

  void openAccountFromDrawer() {
    Navigator.pop(context);
  }

  Future<void> changeName() async {
    final userId =
        getCurrentUserId();

    if (userId == null) {
      return;
    }

    String enteredName =
        getUserName();

    final newName =
        await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'שינוי שם',
          ),
          content: TextFormField(
            initialValue:
                enteredName,
            autofocus: true,
            decoration:
                const InputDecoration(
              labelText: 'שם',
            ),
            onChanged: (value) {
              enteredName =
                  value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusScope.of(
                  dialogContext,
                ).unfocus();

                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text(
                'ביטול',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name =
                    enteredName.trim();

                if (name.isEmpty) {
                  return;
                }

                FocusScope.of(
                  dialogContext,
                ).unfocus();

                Navigator.pop(
                  dialogContext,
                  name,
                );
              },
              child:
                  const Text(
                'שמור',
              ),
            ),
          ],
        );
      },
    );

    if (newName == null ||
        newName.trim().isEmpty) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (widget.changeNameAction !=
          null) {
        await widget.changeNameAction!(
          newName.trim(),
        );
      } else {
        final user =
            supabase.auth.currentUser;

        if (user == null) {
          return;
        }

        await supabase.auth.updateUser(
          UserAttributes(
            data: {
              'name':
                  newName.trim(),
            },
          ),
        );

        await supabase
            .from('profiles')
            .update({
              'name':
                  newName.trim(),
            })
            .eq(
              'id',
              user.id,
            );
      }

      if (!mounted) {
        return;
      }

      setState(() {});

      showMessage(
        'השם עודכן בהצלחה',
      );
    } catch (error) {
      debugPrint(
        'Error updating user name: $error',
      );

      if (!mounted) {
        return;
      }

      showMessage(
        'לא הצלחנו לעדכן את השם. נסה שוב.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> changePassword() async {
    final userId =
        getCurrentUserId();

    final email =
        getUserEmail();

    if (userId == null ||
        email.isEmpty) {
      return;
    }

    final formKey =
        GlobalKey<FormState>();

    String currentPassword = '';
    String newPassword = '';

    final shouldChange =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text(
            'שינוי סיסמה',
          ),
          content:
              SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    TextFormField(
                      obscureText: true,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'סיסמה נוכחית',
                        prefixIcon:
                            Icon(
                          Icons
                              .lock_outline,
                        ),
                      ),
                      onChanged:
                          (value) {
                        currentPassword =
                            value;
                      },
                      validator:
                          (value) {
                        if (value ==
                                null ||
                            value
                                .isEmpty) {
                          return 'יש להזין את הסיסמה הנוכחית';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    TextFormField(
                      obscureText: true,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'סיסמה חדשה',
                        prefixIcon:
                            Icon(
                          Icons
                              .password_outlined,
                        ),
                      ),
                      onChanged:
                          (value) {
                        newPassword =
                            value;
                      },
                      validator:
                          (value) {
                        if (value ==
                                null ||
                            value
                                .isEmpty) {
                          return 'יש להזין סיסמה חדשה';
                        }

                        if (value
                                .length <
                            6) {
                          return 'הסיסמה צריכה להכיל לפחות 6 תווים';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    TextFormField(
                      obscureText: true,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'אימות סיסמה חדשה',
                        prefixIcon:
                            Icon(
                          Icons
                              .verified_user_outlined,
                        ),
                      ),
                      validator:
                          (value) {
                        if (value ==
                                null ||
                            value
                                .isEmpty) {
                          return 'יש לאמת את הסיסמה החדשה';
                        }

                        if (value !=
                            newPassword) {
                          return 'הסיסמאות אינן תואמות';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusScope.of(
                  dialogContext,
                ).unfocus();

                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text(
                'ביטול',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey
                    .currentState!
                    .validate()) {
                  return;
                }

                FocusScope.of(
                  dialogContext,
                ).unfocus();

                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
                  const Text(
                'שנה סיסמה',
              ),
            ),
          ],
        );
      },
    );

    if (shouldChange != true) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (widget.changePasswordAction !=
          null) {
        await widget
            .changePasswordAction!(
          currentPassword,
          newPassword,
        );
      } else {
        // Verify current password.
        await supabase.auth
            .signInWithPassword(
          email: email,
          password:
              currentPassword,
        );

        // Update password.
        await supabase.auth.updateUser(
          UserAttributes(
            password:
                newPassword,
          ),
        );
      }

      if (!mounted) {
        return;
      }

      showMessage(
        'הסיסמה עודכנה בהצלחה',
      );
    } on AuthException {
      if (!mounted) {
        return;
      }

      showMessage(
        'הסיסמה הנוכחית אינה נכונה.',
      );
    } catch (error) {
      debugPrint(
        'Error changing password: $error',
      );

      if (!mounted) {
        return;
      }

      showMessage(
        'לא הצלחנו לשנות את הסיסמה. נסה שוב.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> performSignOut() async {
    if (widget.signOutAction != null) {
      await widget.signOutAction!();
      return;
    }

    await supabase.auth.signOut();
  }

  Future<void> signOut() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text(
            'התנתקות',
          ),
          content:
              const Text(
            'האם אתה בטוח שברצונך להתנתק?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text(
                'ביטול',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
                  const Text(
                'התנתק',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await performSignOut();

      if (!mounted) {
        return;
      }

      Navigator.of(context).popUntil(
        (route) => route.isFirst,
      );
    } catch (error) {
      debugPrint(
        'Error signing out: $error',
      );

      if (!mounted) {
        return;
      }

      showMessage(
        'לא הצלחנו להתנתק. נסה שוב.',
      );
    }
  }

  Future<int> getVehicleMemberCount(
    String vehicleId,
  ) async {
    if (widget.memberCountLoader !=
        null) {
      return widget.memberCountLoader!(
        vehicleId,
      );
    }

    final data =
        await supabase
            .from('vehicle_members')
            .select('user_id')
            .eq(
              'vehicle_id',
              vehicleId,
            );

    return data.length;
  }

  Future<AccountDeleteResult>
      performDeleteAccount() async {
    if (widget.deleteAccountAction !=
        null) {
      return widget
          .deleteAccountAction!();
    }

    final response =
        await supabase.functions.invoke(
      'delete-account',
    );

    final responseData =
        response.data;

    if (response.status < 200 ||
        response.status >= 300) {
      if (responseData is Map &&
          responseData['code'] ==
              'OWNERSHIP_TRANSFER_REQUIRED') {
        return AccountDeleteResult
            .ownershipTransferRequired;
      }

      return AccountDeleteResult.failure;
    }

    return AccountDeleteResult.success;
  }

  Future<void> deleteAccount() async {
    if (isLoading) {
      return;
    }

    final sharedOwnedVehicles =
        <Vehicle>[];

    final soloOwnedVehicles =
        <Vehicle>[];

    setState(() {
      isLoading = true;
    });

    try {
      for (final vehicle in vehicles) {
        if (vehicle.currentUserRole !=
                VehicleMemberRole.owner ||
            vehicle.id == null) {
          continue;
        }

        final memberCount =
            await getVehicleMemberCount(
          vehicle.id!,
        );

        if (memberCount > 1) {
          sharedOwnedVehicles.add(
            vehicle,
          );
        } else {
          soloOwnedVehicles.add(
            vehicle,
          );
        }
      }

      if (!mounted) {
        return;
      }

      if (sharedOwnedVehicles.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title:
                  const Text(
                'יש להעביר בעלות',
              ),
              content:
                  SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'לא ניתן למחוק את החשבון כרגע. '
                      'אתה הבעלים של רכב משותף.',
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    ...sharedOwnedVehicles
                        .map(
                      (vehicle) =>
                          Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 6,
                        ),
                        child: Text(
                          '• ${vehicle.manufacturer} '
                          '${vehicle.model} '
                          '(${vehicle.license})',
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    const Text(
                      'לפני מחיקת החשבון יש להעביר '
                      'את הבעלות על הרכב למשתמש אחר.',
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child:
                      const Text(
                    'הבנתי',
                  ),
                ),
              ],
            );
          },
        );

        return;
      }

      final confirmed =
          await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title:
                const Text(
              'מחיקת חשבון',
            ),
            content:
                SingleChildScrollView(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'האם אתה בטוח שברצונך למחוק '
                    'את החשבון?',
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  if (soloOwnedVehicles
                      .isNotEmpty) ...[
                    const Text(
                      'שים לב: הרכבים שבהם אתה '
                      'הבעלים היחיד יימחקו יחד עם '
                      'כל המידע שלהם:',
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    ...soloOwnedVehicles
                        .map(
                      (vehicle) =>
                          Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 5,
                        ),
                        child: Text(
                          '• ${vehicle.manufacturer} '
                          '${vehicle.model} '
                          '(${vehicle.license})',
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),
                  ],

                  const Text(
                    'פעולה זו אינה ניתנת לביטול.',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color:
                          AppTheme.danger,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    false,
                  );
                },
                child:
                    const Text(
                  'ביטול',
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                },
                child:
                    const Text(
                  'מחק חשבון',
                ),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return;
      }

      final deleteResult =
          await performDeleteAccount();

      if (!mounted) {
        return;
      }

      if (deleteResult ==
          AccountDeleteResult
              .ownershipTransferRequired) {
        showMessage(
          'יש להעביר בעלות על הרכב לפני מחיקת החשבון.',
        );

        return;
      }

      if (deleteResult ==
          AccountDeleteResult.failure) {
        showMessage(
          'לא הצלחנו למחוק את החשבון. נסה שוב.',
        );

        return;
      }

      try {
        await performSignOut();
      } catch (error) {
        debugPrint(
          'Local sign out after account deletion: '
          '$error',
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).popUntil(
        (route) => route.isFirst,
      );
    } catch (error) {
      debugPrint(
        'Error deleting account: $error',
      );

      if (!mounted) {
        return;
      }

      showMessage(
        'לא הצלחנו למחוק את החשבון. נסה שוב.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  Widget buildIconBox(
    IconData icon, {
    Color color =
        AppTheme.primary,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color:
            AppTheme.iconBackground,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  Widget buildRoleBadge(
    VehicleMemberRole? role,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color:
            AppTheme.primaryLight,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              AppTheme.interactiveBorder,
        ),
      ),
      child: Text(
        role?.displayName ??
            'לא ידוע',
        style:
            const TextStyle(
          fontSize: 12,
          fontWeight:
              FontWeight.w600,
          color:
              AppTheme.primary,
        ),
      ),
    );
  }

  Widget buildVehicleRolesSection() {
    if (isLoadingVehicles) {
      return const Card(
        child: Padding(
          padding:
              EdgeInsets.all(24),
          child: Center(
            child:
                CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (vehiclesError != null) {
      return Card(
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                vehiclesError!,
                textAlign:
                    TextAlign.center,
              ),
              const SizedBox(
                height: 12,
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    isLoadingVehicles =
                        true;
                  });

                  loadVehicles();
                },
                child:
                    const Text(
                  'נסה שוב',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (vehicles.isEmpty) {
      return Card(
        child: ListTile(
          leading:
              buildIconBox(
            Icons
                .directions_car_outlined,
          ),
          title:
              const Text(
            'אין רכבים המשויכים לחשבון',
          ),
        ),
      );
    }

    return Column(
      children:
          vehicles.map(
        (vehicle) {
          final role =
              vehicle.currentUserRole;

          return Card(
            margin:
                const EdgeInsets.only(
              bottom: 12,
            ),
            child:
                ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading:
                  buildIconBox(
                Icons
                    .directions_car_outlined,
              ),
              title:
                  Text(
                '${vehicle.manufacturer} '
                '${vehicle.model}',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                  color:
                      AppTheme.textPrimary,
                ),
              ),
              subtitle:
                  Padding(
                padding:
                    const EdgeInsets.only(
                  top: 4,
                ),
                child:
                    Text(
                  vehicle.license,
                  style:
                      const TextStyle(
                    color:
                        AppTheme.textSecondary,
                  ),
                ),
              ),
              trailing:
                  buildRoleBadge(
                role,
              ),
            ),
          );
        },
      ).toList(),
    );
  }

  Widget buildInteractiveCard({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
  }) {
    return Card(
      color:
          AppTheme.interactiveSurface,
      shape:
          interactiveCardShape,
      child:
          ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading:
            buildIconBox(
          icon,
        ),
        title: Text(
          title,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w600,
            color:
                AppTheme.textPrimary,
          ),
        ),
        trailing:
            const Icon(
          Icons.chevron_left,
          color:
              AppTheme.primary,
        ),
        onTap:
            onTap,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final userName =
        getUserName();

    final email =
        getUserEmail();

    return Scaffold(
      drawer: AppDrawer(
        accountSelected: true,
        onVehiclesTap:
            openVehiclesFromDrawer,
        onAccountTap:
            openAccountFromDrawer,

        // Avoid Supabase access in tests.
        userName:
            widget.userName,
        userEmail:
            widget.userEmail,
      ),
      appBar:
          AppBar(
        title:
            const Text(
          'החשבון שלי',
        ),
        bottom: isLoading
            ? const PreferredSize(
                preferredSize:
                    Size.fromHeight(
                  2,
                ),
                child:
                    LinearProgressIndicator(),
              )
            : null,
      ),
      body:
          ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          // ==================================================
          // User information
          // ==================================================

          Card(
            child:
                Padding(
              padding:
                  const EdgeInsets.all(
                20,
              ),
              child:
                  Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
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
                    child:
                        const Icon(
                      Icons
                          .person_outline,
                      size: 32,
                      color:
                          AppTheme.primary,
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          userName,
                          style:
                              const TextStyle(
                            fontSize:
                                20,
                            fontWeight:
                                FontWeight
                                    .bold,
                            color:
                                AppTheme.textPrimary,
                          ),
                        ),
                        if (email
                            .isNotEmpty) ...[
                          const SizedBox(
                            height:
                                4,
                          ),
                          Text(
                            email,
                            textDirection:
                                TextDirection
                                    .ltr,
                            style:
                                const TextStyle(
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
          ),

          const SizedBox(
            height: 24,
          ),

          // ==================================================
          // Vehicle roles
          // ==================================================

          const Text(
            'התפקידים שלי',
            style:
                TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
              color:
                  AppTheme.textPrimary,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          buildVehicleRolesSection(),

          const SizedBox(
            height: 24,
          ),

          // ==================================================
          // Account actions
          // ==================================================

          const Text(
            'הגדרות חשבון',
            style:
                TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
              color:
                  AppTheme.textPrimary,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          buildInteractiveCard(
            icon:
                Icons.badge_outlined,
            title:
                'שינוי שם',
            onTap: isLoading
                ? null
                : changeName,
          ),

          const SizedBox(
            height: 12,
          ),

          buildInteractiveCard(
            icon:
                Icons.lock_outline,
            title:
                'שינוי סיסמה',
            onTap: isLoading
                ? null
                : changePassword,
          ),

          const SizedBox(
            height: 12,
          ),

          buildInteractiveCard(
            icon:
                Icons.logout,
            title:
                'התנתקות',
            onTap: isLoading
                ? null
                : signOut,
          ),

          const SizedBox(
            height: 24,
          ),

          // ==================================================
          // Dangerous action
          // ==================================================

          Card(
            color:
                AppTheme.surface,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
              side:
                  const BorderSide(
                color:
                    AppTheme.danger,
                width: 1.2,
              ),
            ),
            child:
                ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading:
                  Container(
                width: 44,
                height: 44,
                decoration:
                    BoxDecoration(
                  color:
                      AppTheme.surface,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                  border:
                      Border.all(
                    color:
                        AppTheme.danger,
                  ),
                ),
                child:
                    const Icon(
                  Icons.delete_outline,
                  color:
                      AppTheme.danger,
                ),
              ),
              title:
                  const Text(
                'מחיקת חשבון',
                style:
                    TextStyle(
                  color:
                      AppTheme.danger,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
              subtitle:
                  const Text(
                'מחיקה מלאה של החשבון',
                style:
                    TextStyle(
                  color:
                      AppTheme.textSecondary,
                ),
              ),
              trailing:
                  const Icon(
                Icons.chevron_left,
                color:
                    AppTheme.danger,
              ),
              onTap: isLoading
                  ? null
                  : deleteAccount,
            ),
          ),
        ],
      ),
    );
  }
}