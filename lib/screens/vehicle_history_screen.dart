import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../models/vehicle_event.dart';
import '../models/vehicle_insurance.dart';
import '../models/vehicle_member.dart';
import '../repositories/vehicle_repository.dart';
import '../theme/app_theme.dart';
import '../utils/vehicle_event_utils.dart';
import '../utils/vehicle_service_utils.dart';

class VehicleHistoryScreen extends StatefulWidget {
  final Vehicle vehicle;
  final VehicleEventType eventType;
  final String title;

  // Optional dependencies for tests.
  // In the real app, if they are not supplied,
  // the screen continues using VehicleRepository.
  final VehicleRepository? repository;

  final Future<List<VehicleEvent>> Function(
    String vehicleId,
  )? eventsLoader;

  const VehicleHistoryScreen({
    super.key,
    required this.vehicle,
    required this.eventType,
    required this.title,
    this.repository,
    this.eventsLoader,
  });

  @override
  State<VehicleHistoryScreen> createState() =>
      _VehicleHistoryScreenState();
}

class _VehicleHistoryScreenState
    extends State<VehicleHistoryScreen> {
  VehicleRepository? _vehicleRepository;

  VehicleRepository get vehicleRepository =>
      widget.repository ??
      (_vehicleRepository ??=
          VehicleRepository());

  List<VehicleEvent> events = [];

  bool isLoading = true;
  bool isDeleting = false;

  String? errorMessage;

  bool get canEditVehicle =>
      widget.vehicle.currentUserRole
          ?.canEditVehicle ??
      false;

  @override
  void initState() {
    super.initState();

    loadEvents();
  }

  Future<void> loadEvents() async {
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

    try {
      final loadedEvents =
          widget.eventsLoader != null
              ? await widget.eventsLoader!(
                  vehicleId,
                )
              : await vehicleRepository
                  .getVehicleEvents(
                  vehicleId,
                );

      if (!mounted) {
        return;
      }

      widget.vehicle.events
        ..clear()
        ..addAll(loadedEvents);

      updateFilteredEvents(
        loadedEvents,
      );

      setState(() {
        isLoading = false;
        errorMessage = null;
      });
    } catch (error) {
      debugPrint(
        'Error loading vehicle history: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        errorMessage =
            'לא הצלחנו לטעון את ההיסטוריה.';
      });
    }
  }

  void updateFilteredEvents(
    List<VehicleEvent> allEvents,
  ) {
    final filteredEvents = allEvents
        .where(
          (event) =>
              event.type ==
              widget.eventType,
        )
        .toList()
      ..sort(
        (a, b) =>
            b.date.compareTo(a.date),
      );

    events = filteredEvents;
  }

  Future<void> deleteEvent(
    VehicleEvent event,
  ) async {
    if (!canEditVehicle) {
      showMessage(
        'אין לך הרשאה למחוק פריטים מההיסטוריה.',
      );
      return;
    }

    final eventId = event.id;

    if (eventId == null) {
      showMessage(
        'לא הצלחנו לזהות את הפריט.',
      );
      return;
    }

    final shouldDelete =
        await showDeleteConfirmation();

    if (!shouldDelete) {
      return;
    }

    setState(() {
      isDeleting = true;
    });

    try {
      await vehicleRepository
          .deleteVehicleEvent(
        eventId,
      );

      final vehicleId =
          widget.vehicle.id;

      if (vehicleId == null) {
        return;
      }

      final loadedEvents =
          widget.eventsLoader != null
              ? await widget.eventsLoader!(
                  vehicleId,
                )
              : await vehicleRepository
                  .getVehicleEvents(
                  vehicleId,
                );

      widget.vehicle.events
        ..clear()
        ..addAll(loadedEvents);

      bool shouldUpdateVehicle = false;

      if (event.type ==
          VehicleEventType.service) {
        updateCurrentServiceFromHistory();

        shouldUpdateVehicle = true;
      }

      if (event.type ==
          VehicleEventType.test) {
        updateCurrentTestFromHistory();

        shouldUpdateVehicle = true;
      }

      if (event.type ==
          VehicleEventType.vehicleLicense) {
        updateCurrentVehicleLicenseFromHistory();

        shouldUpdateVehicle = true;
      }

      if (event.type ==
          VehicleEventType.insurance) {
        await updateCurrentInsuranceFromHistory(
          event.insuranceType,
        );
      }

      if (shouldUpdateVehicle) {
        await vehicleRepository.updateVehicle(
          widget.vehicle,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        updateFilteredEvents(
          loadedEvents,
        );
      });

      showMessage(
        'הפריט נמחק',
      );
    } catch (error) {
      debugPrint(
        'Error deleting event: $error',
      );

      if (!mounted) {
        return;
      }

      showMessage(
        'לא הצלחנו למחוק את הפריט. נסה שוב.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isDeleting = false;
        });
      }
    }
  }

  void updateCurrentServiceFromHistory() {
    VehicleServiceUtils
        .updateCurrentServiceFromHistory(
      widget.vehicle,
    );
  }

  void updateCurrentTestFromHistory() {
    widget.vehicle.testExpiryDate =
        VehicleEventUtils.getLatestEventDate(
      widget.vehicle.events,
      VehicleEventType.test,
    );
  }

  void updateCurrentVehicleLicenseFromHistory() {
    widget.vehicle.vehicleLicenseExpiryDate =
        VehicleEventUtils.getLatestEventDate(
      widget.vehicle.events,
      VehicleEventType.vehicleLicense,
    );
  }

  Future<void>
      updateCurrentInsuranceFromHistory(
    InsuranceType? insuranceType,
  ) async {
    if (insuranceType == null) {
      return;
    }

    final vehicleId =
        widget.vehicle.id;

    if (vehicleId == null) {
      return;
    }

    final insuranceEvents =
        widget.vehicle.events
            .where(
              (event) =>
                  event.type ==
                      VehicleEventType.insurance &&
                  event.insuranceType ==
                      insuranceType,
            )
            .toList()
          ..sort(
            (a, b) =>
                b.date.compareTo(a.date),
          );

    final currentInsuranceIndex =
        widget.vehicle.insurances
            .indexWhere(
      (insurance) =>
          insurance.type ==
          insuranceType,
    );

    VehicleInsurance?
        currentInsurance;

    if (currentInsuranceIndex != -1) {
      currentInsurance =
          widget.vehicle.insurances[
              currentInsuranceIndex];
    }

    if (insuranceEvents.isEmpty) {
      if (currentInsurance?.id != null) {
        await vehicleRepository
            .deleteInsurance(
          currentInsurance!.id!,
        );
      }

      if (currentInsuranceIndex != -1) {
        widget.vehicle.insurances
            .removeAt(
          currentInsuranceIndex,
        );
      }

      return;
    }

    final latestInsuranceEvent =
        insuranceEvents.first;

    final updatedInsurance =
        VehicleInsurance(
      id: currentInsurance?.id,
      vehicleId: vehicleId,
      type: insuranceType,
      expiryDate:
          latestInsuranceEvent.date,
      showOnHome:
          currentInsurance
                  ?.showOnHome ??
              false,
    );

    final savedInsurance =
        await vehicleRepository
            .saveInsurance(
      updatedInsurance,
    );

    if (currentInsuranceIndex == -1) {
      widget.vehicle.insurances.add(
        savedInsurance,
      );
    } else {
      widget.vehicle.insurances[
              currentInsuranceIndex] =
          savedInsurance;
    }
  }

  Future<bool>
      showDeleteConfirmation() async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'מחיקת פריט',
          ),
          content: const Text(
            'האם אתה בטוח שברצונך למחוק '
            'את הפריט מההיסטוריה?',
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
                'מחק',
                style: TextStyle(
                  color: AppTheme.danger,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  String formatDate(DateTime date) {
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

  String formatNumber(int value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (int i = 0;
        i < text.length;
        i++) {
      if (i > 0 &&
          (text.length - i) % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(text[i]);
    }

    return buffer.toString();
  }

  String buildEventDetails(
    VehicleEvent event,
  ) {
    final details = <String>[
      formatDate(event.date),
    ];

    if (event.mileage != null) {
      details.add(
        '${formatNumber(event.mileage!)} ק"מ',
      );
    }

    if (event.serviceIntervalKm != null) {
      details.add(
        'מרווח: '
        '${formatNumber(event.serviceIntervalKm!)} ק"מ',
      );
    }

    if (event.cost != null) {
      details.add(
        'עלות: '
        '${event.cost!.toStringAsFixed(2)} ₪',
      );
    }

    return details.join(' • ');
  }

  IconData getEventIcon(
    VehicleEvent event,
  ) {
    switch (event.type) {
      case VehicleEventType.service:
        return Icons.build_outlined;

      case VehicleEventType.test:
        return Icons.fact_check_outlined;

      case VehicleEventType.vehicleLicense:
        return Icons.badge_outlined;

      case VehicleEventType.insurance:
        return Icons.shield_outlined;

      case VehicleEventType.repair:
        return Icons.handyman_outlined;

      case VehicleEventType.other:
        return Icons.description_outlined;
    }
  }

  Widget buildEventIcon(
    VehicleEvent event,
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
        getEventIcon(event),
        color: AppTheme.primary,
        size: 23,
      ),
    );
  }

  Widget buildViewOnlyIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.iconBackground,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.visibility_outlined,
        color: AppTheme.primary,
        size: 23,
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

                  loadEvents();
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

    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.history,
                size: 46,
                color:
                    AppTheme.textSecondary,
              ),
              const SizedBox(
                height: 12,
              ),
              Text(
                'עדיין אין פריטים ב${widget.title}',
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  color:
                      AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadEvents,
      child: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          if (!canEditVehicle) ...[
            Card(
              child: ListTile(
                leading:
                    buildViewOnlyIcon(),
                title: const Text(
                  'מצב צפייה בלבד',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'ניתן לצפות בהיסטוריה, '
                  'אך לא למחוק ממנה פריטים.',
                  style: TextStyle(
                    color:
                        AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 12,
            ),
          ],
          ...events.map(
            (event) {
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
                      buildEventIcon(
                    event,
                  ),
                  title: Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                      color:
                          AppTheme.textPrimary,
                    ),
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
                        Text(
                          buildEventDetails(
                            event,
                          ),
                          style:
                              const TextStyle(
                            color:
                                AppTheme.textSecondary,
                          ),
                        ),
                        if (event.notes != null &&
                            event.notes!
                                .trim()
                                .isNotEmpty) ...[
                          const SizedBox(
                            height: 6,
                          ),
                          Text(
                            event.notes!,
                            style:
                                const TextStyle(
                              color:
                                  AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  trailing:
                      canEditVehicle
                          ? IconButton(
                              onPressed:
                                  isDeleting
                                      ? null
                                      : () {
                                          deleteEvent(
                                            event,
                                          );
                                        },
                              tooltip:
                                  'מחיקה',
                              icon:
                                  const Icon(
                                Icons
                                    .delete_outline,
                                color:
                                    AppTheme.danger,
                              ),
                            )
                          : null,
                ),
              );
            },
          ),
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
        title: Text(
          widget.title,
        ),
        bottom:
            isDeleting
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
      body: buildBody(),
    );
  }
}