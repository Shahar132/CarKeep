import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vehicle.dart';
import '../models/vehicle_member.dart';
import '../theme/app_theme.dart';

class ManageVehicleMembersScreen
    extends StatefulWidget {
  final Vehicle vehicle;

  // Optional dependencies for Widget Tests.
  //
  // In the real app, when they are not supplied,
  // the screen continues using Supabase.
  final Future<List<Map<String, dynamic>>> Function(
    String vehicleId,
  )? membersLoader;

  final Future<void> Function(
    String vehicleId,
    String email,
  )? addMemberAction;

  final Future<void> Function(
    String vehicleId,
    String userId,
    VehicleMemberRole newRole,
  )? changeRoleAction;

  final Future<void> Function(
    String vehicleId,
    String userId,
  )? removeMemberAction;

  final Future<void> Function(
    String vehicleId,
    String newOwnerUserId,
  )? transferOwnershipAction;

  final String? Function()?
      currentUserIdProvider;

  const ManageVehicleMembersScreen({
    super.key,
    required this.vehicle,
    this.membersLoader,
    this.addMemberAction,
    this.changeRoleAction,
    this.removeMemberAction,
    this.transferOwnershipAction,
    this.currentUserIdProvider,
  });

  @override
  State<ManageVehicleMembersScreen>
      createState() =>
          _ManageVehicleMembersScreenState();
}

class _ManageVehicleMembersScreenState
    extends State<ManageVehicleMembersScreen> {
  List<_VehicleMemberItem> members = [];

  bool isLoading = true;
  bool isBusy = false;

  String? errorMessage;

  bool get isOwner =>
      widget.vehicle.currentUserRole ==
      VehicleMemberRole.owner;

  // Supabase is accessed lazily.
  // Widget Tests that inject dependencies
  // will not touch Supabase at all.
  SupabaseClient get supabase =>
      Supabase.instance.client;

  String? getCurrentUserId() {
    if (widget.currentUserIdProvider != null) {
      return widget.currentUserIdProvider!();
    }

    return supabase.auth.currentUser?.id;
  }

  @override
  void initState() {
    super.initState();

    loadMembers();
  }

  Future<void> loadMembers() async {
    final vehicleId = widget.vehicle.id;

    if (vehicleId == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        errorMessage =
            'לא הצלחנו לזהות את הרכב.';
      });

      return;
    }

    if (!isOwner) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        errorMessage =
            'רק בעל הרכב יכול לנהל משתמשים.';
      });

      return;
    }

    try {
      late final List<Map<String, dynamic>>
          memberMaps;

      if (widget.membersLoader != null) {
        memberMaps =
            await widget.membersLoader!(
          vehicleId,
        );
      } else {
        final data = await supabase.rpc(
          'get_vehicle_members_for_owner',
          params: {
            'target_vehicle_id': vehicleId,
          },
        );

        memberMaps =
            (data as List<dynamic>)
                .map(
                  (item) =>
                      Map<String, dynamic>.from(
                    item as Map,
                  ),
                )
                .toList();
      }

      final loadedMembers =
          memberMaps
              .map(
                _VehicleMemberItem.fromMap,
              )
              .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        members = loadedMembers;
        isLoading = false;
        errorMessage = null;
      });
    } catch (error) {
      debugPrint(
        'Error loading vehicle members: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        errorMessage =
            'לא הצלחנו לטעון את משתמשי הרכב.';
      });
    }
  }

  Future<void>
    showAddMemberDialog() async {
  if (!isOwner || isBusy) {
    return;
  }

  String emailValue = '';

  final email =
      await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text(
          'הוספת משתמש',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'הזן את כתובת האימייל של '
                'המשתמש שברצונך להוסיף לרכב.',
              ),
              const SizedBox(
                height: 16,
              ),
              TextField(
                autofocus: true,
                keyboardType:
                    TextInputType.emailAddress,
                decoration:
                    const InputDecoration(
                  labelText: 'אימייל',
                ),
                onChanged: (value) {
                  emailValue = value;
                },
              ),
              const SizedBox(
                height: 12,
              ),
              const Text(
                'המשתמש יתווסף בתפקיד משתמש '
                'ותוכל להפוך אותו למנהל לאחר מכן.',
                style: TextStyle(
                  color:
                      AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
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
              );
            },
            child: const Text(
              'ביטול',
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final value =
                  emailValue.trim();

              if (value.isEmpty ||
                  !value.contains('@')) {
                return;
              }

              FocusScope.of(
                dialogContext,
              ).unfocus();

              Navigator.pop(
                dialogContext,
                value,
              );
            },
            child: const Text(
              'הוסף',
            ),
          ),
        ],
      );
    },
  );

  if (email == null) {
    return;
  }

  await addMemberByEmail(
    email,
  );
}

  Future<void> addMemberByEmail(
    String email,
  ) async {
    final vehicleId =
        widget.vehicle.id;

    if (!isOwner ||
        vehicleId == null ||
        isBusy) {
      return;
    }

    setState(() {
      isBusy = true;
    });

    try {
      if (widget.addMemberAction != null) {
        await widget.addMemberAction!(
          vehicleId,
          email.trim(),
        );
      } else {
        await supabase.rpc(
          'add_vehicle_member_by_email',
          params: {
            'target_vehicle_id':
                vehicleId,
            'member_email':
                email.trim(),
          },
        );
      }

      await loadMembers();

      if (!mounted) {
        return;
      }

      showMessage(
        'המשתמש נוסף לרכב',
      );
    } on PostgrestException catch (error) {
      debugPrint(
        'Add vehicle member error: '
        '${error.code} - ${error.message}',
      );

      if (!mounted) {
        return;
      }

      final message =
          error.message.toUpperCase();

      if (message.contains(
        'USER_NOT_FOUND',
      )) {
        showMessage(
          'לא נמצא משתמש רשום עם האימייל הזה.',
        );
      } else if (message.contains(
        'ALREADY_MEMBER',
      )) {
        showMessage(
          'המשתמש כבר משויך לרכב.',
        );
      } else if (message.contains(
        'CANNOT_ADD_SELF',
      )) {
        showMessage(
          'אתה כבר משויך לרכב.',
        );
      } else {
        showMessage(
          'לא הצלחנו להוסיף את המשתמש. נסה שוב.',
        );
      }
    } catch (error) {
      debugPrint(
        'Unexpected add member error: $error',
      );

      if (!mounted) {
        return;
      }

      showMessage(
        'לא הצלחנו להוסיף את המשתמש. נסה שוב.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isBusy = false;
        });
      }
    }
  }

  Future<void> changeMemberRole(
    _VehicleMemberItem member,
    VehicleMemberRole newRole,
  ) async {
    final vehicleId =
        widget.vehicle.id;

    if (!isOwner ||
        vehicleId == null ||
        isBusy) {
      return;
    }

    if (member.role ==
        VehicleMemberRole.owner) {
      return;
    }

    setState(() {
      isBusy = true;
    });

    try {
      if (widget.changeRoleAction != null) {
        await widget.changeRoleAction!(
          vehicleId,
          member.userId,
          newRole,
        );
      } else {
        await supabase
            .from('vehicle_members')
            .update({
              'role':
                  newRole.databaseValue,
            })
            .eq(
              'vehicle_id',
              vehicleId,
            )
            .eq(
              'user_id',
              member.userId,
            );
      }

      await loadMembers();

      if (!mounted) {
        return;
      }

      showMessage(
        newRole ==
                VehicleMemberRole.admin
            ? 'המשתמש הפך למנהל'
            : 'המנהל הפך למשתמש',
      );
    } catch (error) {
      debugPrint(
        'Error changing vehicle member role: '
        '$error',
      );

      if (!mounted) {
        return;
      }

      showMessage(
        'לא הצלחנו לשנות את התפקיד. נסה שוב.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isBusy = false;
        });
      }
    }
  }

  Future<bool>
      showRemoveConfirmation(
    _VehicleMemberItem member,
  ) async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'הסרת משתמש',
          ),
          content: Text(
            'האם להסיר את '
            '${member.displayName} מהרכב?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'ביטול',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'הסר',
                style: TextStyle(
                  color:
                      AppTheme.danger,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> removeMember(
    _VehicleMemberItem member,
  ) async {
    final vehicleId =
        widget.vehicle.id;

    if (!isOwner ||
        vehicleId == null ||
        isBusy ||
        member.role ==
            VehicleMemberRole.owner) {
      return;
    }

    final confirmed =
        await showRemoveConfirmation(
      member,
    );

    if (!confirmed) {
      return;
    }

    setState(() {
      isBusy = true;
    });

    try {
      if (widget.removeMemberAction != null) {
        await widget.removeMemberAction!(
          vehicleId,
          member.userId,
        );
      } else {
        await supabase
            .from('vehicle_members')
            .delete()
            .eq(
              'vehicle_id',
              vehicleId,
            )
            .eq(
              'user_id',
              member.userId,
            );
      }

      await loadMembers();

      if (!mounted) {
        return;
      }

      showMessage(
        'המשתמש הוסר מהרכב',
      );
    } catch (error) {
      debugPrint(
        'Error removing vehicle member: $error',
      );

      if (!mounted) {
        return;
      }

      showMessage(
        'לא הצלחנו להסיר את המשתמש. נסה שוב.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isBusy = false;
        });
      }
    }
  }

  Future<bool>
      showOwnershipTransferConfirmation(
    _VehicleMemberItem member,
  ) async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'העברת בעלות',
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'האם להעביר את הבעלות על הרכב '
                'ל${member.displayName}?',
              ),
              const SizedBox(
                height: 12,
              ),
              const Text(
                'לאחר העברת הבעלות, המשתמש '
                'שנבחר יהפוך לבעלים ואתה '
                'תהפוך למנהל.',
              ),
              const SizedBox(
                height: 12,
              ),
              const Text(
                'רק הבעלים החדש יוכל לאחר מכן '
                'לנהל משתמשים, להעביר בעלות '
                'ולמחוק את הרכב.',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
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
              child: const Text(
                'העבר בעלות',
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> transferOwnership(
    _VehicleMemberItem member,
  ) async {
    final vehicleId =
        widget.vehicle.id;

    if (!isOwner ||
        vehicleId == null ||
        isBusy ||
        member.role ==
            VehicleMemberRole.owner) {
      return;
    }

    final confirmed =
        await showOwnershipTransferConfirmation(
      member,
    );

    if (!confirmed) {
      return;
    }

    setState(() {
      isBusy = true;
    });

    try {
      if (widget.transferOwnershipAction !=
          null) {
        await widget
            .transferOwnershipAction!(
          vehicleId,
          member.userId,
        );
      } else {
        await supabase.rpc(
          'transfer_vehicle_ownership',
          params: {
            'target_vehicle_id':
                vehicleId,
            'new_owner_user_id':
                member.userId,
          },
        );
      }

      widget.vehicle.currentUserRole =
          VehicleMemberRole.admin;

      if (!mounted) {
        return;
      }

      showMessage(
        'הבעלות הועברה בהצלחה',
      );

      Navigator.pop(context);
    } catch (error) {
      debugPrint(
        'Error transferring ownership: $error',
      );

      if (!mounted) {
        return;
      }

      showMessage(
        'לא הצלחנו להעביר את הבעלות. נסה שוב.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isBusy = false;
        });
      }
    }
  }

  void showMemberActions(
    _VehicleMemberItem member,
  ) {
    if (!isOwner ||
        member.role ==
            VehicleMemberRole.owner) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(
                  member.role ==
                          VehicleMemberRole.admin
                      ? Icons.person_outline
                      : Icons
                          .admin_panel_settings_outlined,
                  color:
                      AppTheme.primary,
                ),
                title: Text(
                  member.role ==
                          VehicleMemberRole.admin
                      ? 'הפוך למשתמש'
                      : 'הפוך למנהל',
                ),
                onTap: () {
                  Navigator.pop(
                    sheetContext,
                  );

                  changeMemberRole(
                    member,
                    member.role ==
                            VehicleMemberRole.admin
                        ? VehicleMemberRole.member
                        : VehicleMemberRole.admin,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.swap_horiz,
                  color:
                      AppTheme.primary,
                ),
                title: const Text(
                  'העבר בעלות',
                ),
                onTap: () {
                  Navigator.pop(
                    sheetContext,
                  );

                  transferOwnership(
                    member,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.person_remove_outlined,
                  color:
                      AppTheme.danger,
                ),
                title: const Text(
                  'הסר מהרכב',
                  style: TextStyle(
                    color:
                        AppTheme.danger,
                  ),
                ),
                onTap: () {
                  Navigator.pop(
                    sheetContext,
                  );

                  removeMember(
                    member,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String roleText(
    VehicleMemberRole role,
  ) {
    return role.displayName;
  }

  IconData roleIcon(
    VehicleMemberRole role,
  ) {
    switch (role) {
      case VehicleMemberRole.owner:
        return Icons.star_outline;

      case VehicleMemberRole.admin:
        return Icons
            .admin_panel_settings_outlined;

      case VehicleMemberRole.member:
        return Icons.person_outline;
    }
  }

  Widget buildRoleIcon(
    VehicleMemberRole role,
  ) {
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
        roleIcon(role),
        color:
            AppTheme.primary,
        size: 24,
      ),
    );
  }

  Widget buildRoleBadge(
    VehicleMemberRole role,
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
        roleText(role),
        style: const TextStyle(
          color:
              AppTheme.primary,
          fontSize: 12,
          fontWeight:
              FontWeight.w600,
        ),
      ),
    );
  }

  void showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Text(
                errorMessage!,
                textAlign:
                    TextAlign.center,
              ),
              const SizedBox(
                height: 16,
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                  });

                  loadMembers();
                },
                child: const Text(
                  'נסה שוב',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentUserId =
        getCurrentUserId();

    return RefreshIndicator(
      onRefresh:
          loadMembers,
      child: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          Text(
            '${widget.vehicle.manufacturer} '
            '${widget.vehicle.model}',
            style:
                const TextStyle(
              fontSize: 22,
              fontWeight:
                  FontWeight.bold,
              color:
                  AppTheme.textPrimary,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            widget.vehicle.license,
            style:
                const TextStyle(
              color:
                  AppTheme.textSecondary,
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          const Text(
            'משתמשי הרכב',
            style: TextStyle(
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
          ...members.map(
            (member) {
              final isCurrentUser =
                  member.userId ==
                  currentUserId;

              return Card(
                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading:
                      buildRoleIcon(
                    member.role,
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.displayName,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w600,
                            color:
                                AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(
                          width: 6,
                        ),
                        const Text(
                          '(אתה)',
                          style:
                              TextStyle(
                            color:
                                AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 6,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        if (member.email
                            .isNotEmpty) ...[
                          Text(
                            member.email,
                            style:
                                const TextStyle(
                              color:
                                  AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                        ],
                        buildRoleBadge(
                          member.role,
                        ),
                      ],
                    ),
                  ),
                  trailing:
                      member.role ==
                              VehicleMemberRole
                                  .owner
                          ? null
                          : IconButton(
                              onPressed:
                                  isBusy
                                      ? null
                                      : () {
                                          showMemberActions(
                                            member,
                                          );
                                        },
                              tooltip:
                                  'פעולות',
                              icon:
                                  const Icon(
                                Icons.more_vert,
                                color:
                                    AppTheme.primary,
                              ),
                            ),
                ),
              );
            },
          ),
          if (members.length == 1) ...[
            const SizedBox(
              height: 8,
            ),
            const Text(
              'כרגע רק אתה משויך לרכב.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ניהול משתמשים',
        ),
        bottom:
            isBusy
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
          buildBody(),
      floatingActionButton:
          !isLoading &&
                  errorMessage == null &&
                  isOwner
              ? FloatingActionButton.extended(
                  onPressed:
                      isBusy
                          ? null
                          : showAddMemberDialog,
                  icon:
                      const Icon(
                    Icons
                        .person_add_outlined,
                  ),
                  label:
                      const Text(
                    'הוסף משתמש',
                  ),
                )
              : null,
    );
  }
}

class _VehicleMemberItem {
  final String userId;
  final String name;
  final String email;
  final VehicleMemberRole role;

  const _VehicleMemberItem({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  String get displayName {
    if (name.trim().isNotEmpty) {
      return name.trim();
    }

    if (email.trim().isNotEmpty) {
      return email.trim();
    }

    return 'משתמש';
  }

  factory _VehicleMemberItem.fromMap(
    Map<String, dynamic> map,
  ) {
    return _VehicleMemberItem(
      userId:
          map['user_id'].toString(),
      name:
          map['name']?.toString() ?? '',
      email:
          map['email']?.toString() ?? '',
      role:
          vehicleMemberRoleFromDatabase(
        map['role'].toString(),
      ),
    );
  }
}