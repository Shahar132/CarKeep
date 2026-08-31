import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vehicle.dart';
import '../models/vehicle_insurance.dart';
import '../repositories/vehicle_repository.dart';
import '../theme/app_theme.dart';
import '../utils/vehicle_date_utils.dart';
import '../utils/vehicle_service_utils.dart';
import '../widgets/app_drawer.dart';
import 'account_screen.dart';
import 'add_vehicle_screen.dart';
import 'vehicle_details_screen.dart';

class HomeScreen extends StatefulWidget {
  // Optional dependencies for Widget Tests.
  //
  // In the real app, when these values are
  // not supplied, HomeScreen continues using
  // the real repository, Supabase and screens.
  final VehicleRepository? repository;

  final Future<List<Vehicle>> Function()?
      vehiclesLoader;

  final String? userDisplayName;

  final String? drawerUserName;
  final String? drawerUserEmail;

  final Widget Function()?
      addVehicleScreenBuilder;

  final Widget Function(Vehicle vehicle)?
      vehicleDetailsScreenBuilder;

  final Widget Function()?
      accountScreenBuilder;

  const HomeScreen({
    super.key,
    this.repository,
    this.vehiclesLoader,
    this.userDisplayName,
    this.drawerUserName,
    this.drawerUserEmail,
    this.addVehicleScreenBuilder,
    this.vehicleDetailsScreenBuilder,
    this.accountScreenBuilder,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  VehicleRepository? _vehicleRepository;

  VehicleRepository get vehicleRepository =>
      widget.repository ??
      (_vehicleRepository ??=
          VehicleRepository());

  List<Vehicle> vehicles = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    loadVehicles();
  }

  String getUserDisplayName() {
    // Widget Tests can provide a value directly
    // so the screen does not access Supabase.
    if (widget.userDisplayName != null) {
      return widget.userDisplayName!.trim();
    }

    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return '';
    }

    final name = user.userMetadata?['name'];

    if (name != null &&
        name.toString().trim().isNotEmpty) {
      return name.toString().trim();
    }

    return user.email ?? '';
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
        errorMessage = null;
        isLoading = false;
      });
    } catch (error) {
      debugPrint(
        'Error loading vehicles: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage =
            'שגיאה בטעינת הרכבים';

        isLoading = false;
      });
    }
  }

  Future<void> openAddVehicleScreen() async {
    final result =
        await Navigator.push<Vehicle>(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (widget.addVehicleScreenBuilder !=
              null) {
            return widget
                .addVehicleScreenBuilder!();
          }

          return const AddVehicleScreen();
        },
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      vehicles.add(result);
    });
  }

  Future<void> openVehicleDetails(
    Vehicle vehicle,
  ) async {
    final wasDeleted =
        await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (widget
                  .vehicleDetailsScreenBuilder !=
              null) {
            return widget
                .vehicleDetailsScreenBuilder!(
              vehicle,
            );
          }

          return VehicleDetailsScreen(
            vehicle: vehicle,
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    if (wasDeleted == true) {
      setState(() {
        vehicles.removeWhere(
          (item) =>
              item.id == vehicle.id,
        );
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'הרכב נמחק בהצלחה',
          ),
        ),
      );

      return;
    }

    setState(() {});
  }

  void openVehiclesFromDrawer() {
    Navigator.pop(context);
  }

  Future<void> openAccountFromDrawer() async {
    Navigator.pop(context);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (widget.accountScreenBuilder !=
              null) {
            return widget
                .accountScreenBuilder!();
          }

          return const AccountScreen();
        },
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  String formatDate(
    DateTime date,
  ) {
    final day =
        date.day.toString().padLeft(
              2,
              '0',
            );

    final month =
        date.month.toString().padLeft(
              2,
              '0',
            );

    return '$day/$month/${date.year}';
  }

  String getNextServiceText(
    Vehicle vehicle,
  ) {
    final nextDate =
        VehicleServiceUtils
            .getNextServiceDate(
      vehicle,
    );

    final nextMileage =
        VehicleServiceUtils
            .getNextServiceMileage(
      vehicle,
    );

    if (nextDate == null) {
      return 'לא הוגדר';
    }

    final dateText =
        formatDate(nextDate);

    if (nextMileage == null) {
      return dateText;
    }

    return '$dateText או '
        '$nextMileage ק"מ';
  }

  Widget buildVehicleIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color:
            AppTheme.iconBackground,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.directions_car_outlined,
        color:
            AppTheme.primary,
        size: 27,
      ),
    );
  }

  Widget buildInfoRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color:
              AppTheme.primary,
        ),
        const SizedBox(
          width: 8,
        ),
        Expanded(
          child: Text(
            text,
            style:
                const TextStyle(
              fontSize: 15,
              color:
                  AppTheme.textPrimary,
            ),
          ),
        ),
      ],
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
                onPressed:
                    loadVehicles,
                child: const Text(
                  'נסה שוב',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (vehicles.isEmpty) {
      return const Center(
        child: Text(
          'עדיין לא הוספת רכבים',
        ),
      );
    }

    return ListView.builder(
      padding:
          const EdgeInsets.all(16),
      itemCount:
          vehicles.length,
      itemBuilder: (
        context,
        index,
      ) {
        final vehicle =
            vehicles[index];

        final homeInsurances =
            vehicle.insurances
                .where(
                  (insurance) =>
                      insurance.showOnHome &&
                      insurance.expiryDate !=
                          null,
                )
                .toList();

        final hasTest =
            vehicle.showTestOnHome;

        final hasVehicleLicense =
            vehicle
                .showVehicleLicenseOnHome;

        final hasInsurances =
            homeInsurances.isNotEmpty;

        final hasService =
            vehicle.showServiceOnHome;

        final hasHomeInformation =
            hasTest ||
            hasVehicleLicense ||
            hasInsurances ||
            hasService;

        return Card(
          margin:
              const EdgeInsets.only(
            bottom: 14,
          ),
          color:
              AppTheme.interactiveSurface,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
            side:
                const BorderSide(
              color:
                  AppTheme.interactiveBorder,
              width: 1.2,
            ),
          ),
          child: InkWell(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
            onTap: () {
              openVehicleDetails(
                vehicle,
              );
            },
            child: Padding(
              padding:
                  const EdgeInsets.all(
                16,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.center,
                    children: [
                      buildVehicleIcon(),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              '${vehicle.manufacturer} '
                              '${vehicle.model}',
                              style:
                                  const TextStyle(
                                fontSize: 21,
                                fontWeight:
                                    FontWeight.bold,
                                color:
                                    AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(
                              height: 3,
                            ),
                            Text(
                              vehicle.license,
                              style:
                                  const TextStyle(
                                fontSize: 15,
                                color:
                                    AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_left,
                        color:
                            AppTheme.primary,
                        size: 28,
                      ),
                    ],
                  ),

                  if (hasHomeInformation) ...[
                    const SizedBox(
                      height: 18,
                    ),
                    const Divider(),
                    const SizedBox(
                      height: 14,
                    ),
                  ],

                  // Test
                  if (hasTest) ...[
                    buildInfoRow(
                      icon:
                          Icons.fact_check_outlined,
                      text:
                          'טסט: ${VehicleDateUtils.getExpiryText(
                        vehicle.testExpiryDate,
                      )}',
                    ),
                  ],

                  // Vehicle license
                  if (hasVehicleLicense) ...[
                    if (hasTest)
                      const SizedBox(
                        height: 12,
                      ),
                    buildInfoRow(
                      icon:
                          Icons.badge_outlined,
                      text:
                          'רישיון רכב: '
                          '${VehicleDateUtils.getExpiryText(
                        vehicle.vehicleLicenseExpiryDate,
                      )}',
                    ),
                  ],

                  // Insurances
                  if (hasInsurances) ...[
                    if (hasTest ||
                        hasVehicleLicense)
                      const SizedBox(
                        height: 12,
                      ),
                    ...homeInsurances.map(
                      (insurance) =>
                          Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child:
                            buildInfoRow(
                          icon:
                              Icons.shield_outlined,
                          text:
                              '${insurance.type.displayName}: '
                              '${VehicleDateUtils.getExpiryText(
                            insurance.expiryDate,
                          )}',
                        ),
                      ),
                    ),
                  ],

                  // Service
                  if (hasService) ...[
                    if (hasTest ||
                        hasVehicleLicense ||
                        hasInsurances)
                      const SizedBox(
                        height: 2,
                      ),
                    buildInfoRow(
                      icon:
                          Icons.build_outlined,
                      text:
                          'טיפול הבא: '
                          '${getNextServiceText(vehicle)}',
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final userName =
        getUserDisplayName();

    return Scaffold(
      drawer: AppDrawer(
        vehiclesSelected: true,
        onVehiclesTap:
            openVehiclesFromDrawer,
        onAccountTap:
            openAccountFromDrawer,

        // Tests can supply these values
        // so AppDrawer does not need Supabase.
        userName:
            widget.drawerUserName,
        userEmail:
            widget.drawerUserEmail,
      ),
      appBar: AppBar(
        title: const Text(
          'הרכבים שלי',
        ),
        actions: [
          if (userName.isNotEmpty)
            Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: Text(
                  userName,
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w500,
                    color:
                        AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body:
          buildBody(),
      floatingActionButton:
          FloatingActionButton(
        onPressed:
            openAddVehicleScreen,
        child: const Icon(
          Icons.add,
        ),
      ),
    );
  }
}