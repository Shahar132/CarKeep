import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../models/vehicle_event.dart';
import '../models/vehicle_member.dart';
import '../repositories/vehicle_repository.dart';
import '../theme/app_theme.dart';
import '../utils/vehicle_service_utils.dart';
import '../widgets/app_drawer.dart';
import 'account_screen.dart';
import 'manage_insurances_screen.dart';
import 'manage_service_screen.dart';
import 'manage_test_screen.dart';
import 'manage_vehicle_license_screen.dart';
import 'manage_vehicle_members_screen.dart';
import 'vehicle_documents_screen.dart';
import 'vehicle_history_screen.dart';

enum _VehicleMenuAction {
  manageMembers,
  deleteVehicle,
}

class VehicleDetailsScreen extends StatefulWidget {
  final Vehicle vehicle;

  // Optional dependency for tests.
  final VehicleRepository? repository;

  // Optional drawer values for tests.
  final String? drawerUserName;
  final String? drawerUserEmail;

  const VehicleDetailsScreen({
    super.key,
    required this.vehicle,
    this.repository,
    this.drawerUserName,
    this.drawerUserEmail,
  });

  @override
  State<VehicleDetailsScreen> createState() =>
      _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState
    extends State<VehicleDetailsScreen> {
     VehicleRepository? _vehicleRepository;

    VehicleRepository get vehicleRepository =>
    widget.repository ??
    (_vehicleRepository ??=
        VehicleRepository());

  int selectedIndex = 0;

  bool isDeletingVehicle = false;

  bool get isOwner =>
      widget.vehicle.currentUserRole ==
      VehicleMemberRole.owner;

  String getCurrentUserRoleText() {
    return widget.vehicle.currentUserRole
            ?.displayName ??
        'לא ידוע';
  }

  String formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Widget buildInteractiveIcon(
    IconData icon,
  ) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.iconBackground,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: AppTheme.primary,
        size: 24,
      ),
    );
  }

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

  void openVehiclesFromDrawer() {
    Navigator.pop(context);
    Navigator.pop(context);
  }

  Future<void> openAccountFromDrawer() async {
    Navigator.pop(context);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const AccountScreen(),
      ),
    );
  }

  Future<void> openManageMembers() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ManageVehicleMembersScreen(
          vehicle: widget.vehicle,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> openManageTest() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ManageTestScreen(
          vehicle: widget.vehicle,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void>
      openManageVehicleLicense() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ManageVehicleLicenseScreen(
          vehicle: widget.vehicle,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void>
      openManageInsurances() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ManageInsurancesScreen(
          vehicle: widget.vehicle,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void>
      openManageService() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ManageServiceScreen(
          vehicle: widget.vehicle,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> openHistory(
    VehicleEventType eventType,
    String title,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VehicleHistoryScreen(
          vehicle: widget.vehicle,
          eventType: eventType,
          title: title,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<bool>
      showDeleteVehicleConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'מחיקת רכב',
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'האם אתה בטוח שברצונך למחוק את '
                '${widget.vehicle.manufacturer} '
                '${widget.vehicle.model}?',
              ),

              const SizedBox(height: 8),

              Text(
                'מספר רישוי: '
                '${widget.vehicle.license}',
              ),

              const SizedBox(height: 16),

              const Text(
                'מחיקת הרכב תמחק את המידע '
                'המשויך אליו, כולל היסטוריית '
                'טיפולים, טסטים, רישיונות רכב, '
                'ביטוחים ומסמכים.',
              ),

              const SizedBox(height: 12),

              const Text(
                'פעולה זו אינה ניתנת לביטול.',
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

            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'מחק רכב',
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> deleteVehicle() async {
    if (!isOwner) {
      showMessage(
        'רק בעל הרכב יכול למחוק אותו.',
      );
      return;
    }

    final vehicleId =
        widget.vehicle.id;

    if (vehicleId == null) {
      showMessage(
        'לא הצלחנו לזהות את הרכב. נסה שוב.',
      );
      return;
    }

    final confirmed =
        await showDeleteVehicleConfirmation();

    if (!confirmed) {
      return;
    }

    setState(() {
      isDeletingVehicle = true;
    });

    try {
      await vehicleRepository
          .deleteVehicle(
        vehicleId,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        true,
      );
    } catch (error) {
      debugPrint(
        'Error deleting vehicle: $error',
      );

      if (!mounted) {
        return;
      }

      showMessage(
        'לא הצלחנו למחוק את הרכב. נסה שוב.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isDeletingVehicle = false;
        });
      }
    }
  }

  void handleVehicleMenuAction(
    _VehicleMenuAction action,
  ) {
    switch (action) {
      case _VehicleMenuAction.manageMembers:
        openManageMembers();
        break;

      case _VehicleMenuAction.deleteVehicle:
        deleteVehicle();
        break;
    }
  }

  String getTestExpiryDateText() {
    final date =
        widget.vehicle.testExpiryDate;

    if (date == null) {
      return 'לא הוגדר';
    }

    return formatDate(date);
  }

  String getVehicleLicenseExpiryDateText() {
    final date =
        widget.vehicle
            .vehicleLicenseExpiryDate;

    if (date == null) {
      return 'לא הוגדר';
    }

    return formatDate(date);
  }

  String getNextServiceText() {
    final nextDate =
        VehicleServiceUtils
            .getNextServiceDate(
      widget.vehicle,
    );

    final nextMileage =
        VehicleServiceUtils
            .getNextServiceMileage(
      widget.vehicle,
    );

    if (nextDate == null) {
      return 'לא הוגדר';
    }

    final dateText =
        formatDate(nextDate);

    if (nextMileage == null) {
      return dateText;
    }

    return '$dateText או $nextMileage ק"מ';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
            onVehiclesTap:
                openVehiclesFromDrawer,
            onAccountTap:
                openAccountFromDrawer,
            userName:
                widget.drawerUserName,
            userEmail:
                widget.drawerUserEmail,
          ),

      appBar: AppBar(
        title: Text(
          '${widget.vehicle.manufacturer} '
          '${widget.vehicle.model}',
        ),

        actions: [
          if (isOwner)
            isDeletingVehicle
                ? const Padding(
                    padding:
                        EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  )
                : PopupMenuButton<
                    _VehicleMenuAction>(
                    onSelected:
                        handleVehicleMenuAction,
                    itemBuilder:
                        (context) => [
                      const PopupMenuItem(
                        value:
                            _VehicleMenuAction
                                .manageMembers,
                        child: Row(
                          children: [
                            Icon(
                              Icons
                                  .group_outlined,
                            ),
                            SizedBox(
                              width: 12,
                            ),
                            Text(
                              'ניהול משתמשים',
                            ),
                          ],
                        ),
                      ),

                      const PopupMenuDivider(),

                      const PopupMenuItem(
                        value:
                            _VehicleMenuAction
                                .deleteVehicle,
                        child: Row(
                          children: [
                            Icon(
                              Icons
                                  .delete_outline,
                            ),
                            SizedBox(
                              width: 12,
                            ),
                            Text(
                              'מחיקת רכב',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
        ],
      ),

      body: getSelectedScreen(),

      bottomNavigationBar:
          NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon: Icon(
              Icons.home,
            ),
            label: 'סקירה',
          ),

          NavigationDestination(
            icon: Icon(
              Icons
                  .description_outlined,
            ),
            selectedIcon: Icon(
              Icons.description,
            ),
            label: 'מסמכים',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.history,
            ),
            label: 'היסטוריה',
          ),
        ],
      ),
    );
  }

  Widget getSelectedScreen() {
    switch (selectedIndex) {
      case 0:
        return buildOverview();

      case 1:
        return VehicleDocumentsScreen(
          vehicle: widget.vehicle,
          embedded: true,
        );

      case 2:
        return buildHistoryCategories();

      default:
        return buildOverview();
    }
  }

  Widget buildOverview() {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
  crossAxisAlignment:
      CrossAxisAlignment.start,
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.vehicle.manufacturer} '
            '${widget.vehicle.model}',
            style: const TextStyle(
              fontSize: 26,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

                    Text(
                      'התפקיד שלך: '
                      '${getCurrentUserRoleText()}',
                      style: const TextStyle(
                        color:
                            AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(
                  Icons.directions_car_outlined,
                  size: 20,
                ),
                label: const Text(
                  'לכל הרכבים',
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 28,
          ),

            
            // Text(
            //   '${widget.vehicle.manufacturer} '
            //   '${widget.vehicle.model}',
            //   style: const TextStyle(
            //     fontSize: 26,
            //     fontWeight:
            //         FontWeight.bold,
            //   ),
            // ),

            // const SizedBox(height: 4),

            // Text(
            //   'התפקיד שלך: '
            //   '${getCurrentUserRoleText()}',
            //   style: const TextStyle(
            //     color:
            //         AppTheme.textSecondary,
            //   ),
            // ),

            // const SizedBox(height: 28),

            // ----------------------------------------------
            // Test
            // ----------------------------------------------

            Card(
              color:
                  AppTheme.interactiveSurface,
              shape:
                  interactiveCardShape,
              child: ListTile(
                leading:
                    buildInteractiveIcon(
                  Icons.fact_check_outlined,
                ),
                title: const Text(
                  'טסט',
                ),
                subtitle: Text(
                  widget.vehicle
                              .testExpiryDate ==
                          null
                      ? 'לא הוגדר'
                      : 'בתוקף עד ${getTestExpiryDateText()}',
                ),
                trailing: const Icon(
                  Icons.chevron_left,
                  color: AppTheme.primary,
                ),
                onTap:
                    openManageTest,
              ),
            ),

            const SizedBox(height: 12),

            // ----------------------------------------------
            // Vehicle license
            // ----------------------------------------------

            Card(
              color:
                  AppTheme.interactiveSurface,
              shape:
                  interactiveCardShape,
              child: ListTile(
                leading:
                    buildInteractiveIcon(
                  Icons.badge_outlined,
                ),
                title: const Text(
                  'רישיון רכב',
                ),
                subtitle: Text(
                  widget.vehicle
                              .vehicleLicenseExpiryDate ==
                          null
                      ? 'לא הוגדר'
                      : 'בתוקף עד ${getVehicleLicenseExpiryDateText()}',
                ),
                trailing: const Icon(
                  Icons.chevron_left,
                  color: AppTheme.primary,
                ),
                onTap:
                    openManageVehicleLicense,
              ),
            ),

            const SizedBox(height: 12),

            // ----------------------------------------------
            // Insurance
            // ----------------------------------------------

            Card(
              color:
                  AppTheme.interactiveSurface,
              shape:
                  interactiveCardShape,
              child: ListTile(
                leading:
                    buildInteractiveIcon(
                  Icons.shield_outlined,
                ),
                title: const Text(
                  'ביטוחים',
                ),
                subtitle: Text(
                  widget.vehicle.insurances
                          .isEmpty
                      ? 'לא הוגדר'
                      : '${widget.vehicle.insurances.length} ביטוחים',
                ),
                trailing: const Icon(
                  Icons.chevron_left,
                  color: AppTheme.primary,
                ),
                onTap:
                    openManageInsurances,
              ),
            ),

            const SizedBox(height: 12),

            // ----------------------------------------------
            // Service
            // ----------------------------------------------

            Card(
              color:
                  AppTheme.interactiveSurface,
              shape:
                  interactiveCardShape,
              child: ListTile(
                leading:
                    buildInteractiveIcon(
                  Icons.build_outlined,
                ),
                title: const Text(
                  'טיפול הבא',
                ),
                subtitle: Text(
                  getNextServiceText(),
                ),
                trailing: const Icon(
                  Icons.chevron_left,
                  color: AppTheme.primary,
                ),
                onTap:
                    openManageService,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHistoryCategories() {
    return ListView(
      padding:
          const EdgeInsets.all(16),
      children: [
        Card(
          color:
              AppTheme.interactiveSurface,
          shape:
              interactiveCardShape,
          child: ListTile(
            leading:
                buildInteractiveIcon(
              Icons.build_outlined,
            ),
            title: const Text(
              'היסטוריית טיפולים',
            ),
            trailing: const Icon(
              Icons.chevron_left,
              color: AppTheme.primary,
            ),
            onTap: () {
              openHistory(
                VehicleEventType.service,
                'היסטוריית טיפולים',
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        Card(
          color:
              AppTheme.interactiveSurface,
          shape:
              interactiveCardShape,
          child: ListTile(
            leading:
                buildInteractiveIcon(
              Icons.fact_check_outlined,
            ),
            title: const Text(
              'היסטוריית טסטים',
            ),
            trailing: const Icon(
              Icons.chevron_left,
              color: AppTheme.primary,
            ),
            onTap: () {
              openHistory(
                VehicleEventType.test,
                'היסטוריית טסטים',
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        Card(
          color:
              AppTheme.interactiveSurface,
          shape:
              interactiveCardShape,
          child: ListTile(
            leading:
                buildInteractiveIcon(
              Icons.badge_outlined,
            ),
            title: const Text(
              'היסטוריית רישיונות רכב',
            ),
            trailing: const Icon(
              Icons.chevron_left,
              color: AppTheme.primary,
            ),
            onTap: () {
              openHistory(
                VehicleEventType
                    .vehicleLicense,
                'היסטוריית רישיונות רכב',
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        Card(
          color:
              AppTheme.interactiveSurface,
          shape:
              interactiveCardShape,
          child: ListTile(
            leading:
                buildInteractiveIcon(
              Icons.shield_outlined,
            ),
            title: const Text(
              'היסטוריית ביטוחים',
            ),
            trailing: const Icon(
              Icons.chevron_left,
              color: AppTheme.primary,
            ),
            onTap: () {
              openHistory(
                VehicleEventType.insurance,
                'היסטוריית ביטוחים',
              );
            },
          ),
        ),
      ],
    );
  }
}