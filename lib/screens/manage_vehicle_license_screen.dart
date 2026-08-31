import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../models/vehicle_document.dart';
import '../models/vehicle_event.dart';
import '../models/vehicle_member.dart';
import '../repositories/vehicle_document_repository.dart';
import '../repositories/vehicle_repository.dart';
import '../theme/app_theme.dart';
import '../utils/vehicle_document_name_utils.dart';
import '../widgets/vehicle_setting_card.dart';
import 'vehicle_history_screen.dart';

class ManageVehicleLicenseScreen
    extends StatefulWidget {
  final Vehicle vehicle;

  // Optional dependencies for tests.
  final VehicleRepository? repository;
  final VehicleDocumentRepository?
      documentRepository;

  final Future<PlatformFile?> Function()?
      documentPicker;

  final Future<List<VehicleEvent>> Function(
    String vehicleId,
  )? historyEventsLoader;

  const ManageVehicleLicenseScreen({
    super.key,
    required this.vehicle,
    this.repository,
    this.documentRepository,
    this.documentPicker,
    this.historyEventsLoader,
  });

  @override
  State<ManageVehicleLicenseScreen>
      createState() =>
          _ManageVehicleLicenseScreenState();
}

class _ManageVehicleLicenseScreenState
    extends State<ManageVehicleLicenseScreen> {
  VehicleRepository? _vehicleRepository;

  VehicleDocumentRepository?
      _vehicleDocumentRepository;

  VehicleRepository get vehicleRepository =>
      widget.repository ??
      (_vehicleRepository ??=
          VehicleRepository());

  VehicleDocumentRepository get
      vehicleDocumentRepository =>
          widget.documentRepository ??
          (_vehicleDocumentRepository ??=
              VehicleDocumentRepository());

  DateTime? selectedExpiryDate;

  String? selectedFileName;
  Uint8List? selectedFileBytes;

  bool isSaving = false;
  bool isPickingDocument = false;
  bool isUpdatingHomeSetting = false;

  bool get canEditVehicle =>
      widget.vehicle.currentUserRole
          ?.canEditVehicle ??
      false;

  bool get isBusy =>
      isSaving ||
      isPickingDocument ||
      isUpdatingHomeSetting;

  String formatDate(
    DateTime date,
  ) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String getCurrentExpiryText() {
    final date =
        widget.vehicle
            .vehicleLicenseExpiryDate;

    if (date == null) {
      return 'לא הוגדר';
    }

    return formatDate(date);
  }

  Widget buildIconBox(
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

  Future<void> selectExpiryDate() async {
    if (!canEditVehicle || isBusy) {
      return;
    }

    final selectedDate =
        await showDatePicker(
      context: context,
      initialDate:
          widget.vehicle
                  .vehicleLicenseExpiryDate ??
              DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      selectedExpiryDate =
          selectedDate;
    });
  }

  Future<void>
      pickLicenseDocument() async {
    if (!canEditVehicle || isBusy) {
      return;
    }

    setState(() {
      isPickingDocument = true;
    });

    try {
      PlatformFile? file;

      if (widget.documentPicker != null) {
        file =
            await widget.documentPicker!();
      } else {
        final result =
            await FilePicker.platform
                .pickFiles(
          allowMultiple: false,
          withData: true,
          type: FileType.custom,
          allowedExtensions: [
            'pdf',
            'jpg',
            'jpeg',
            'png',
          ],
        );

        if (result == null ||
            result.files.isEmpty) {
          return;
        }

        file = result.files.single;
      }

      if (file == null) {
        return;
      }

      final bytes = file.bytes;

      if (bytes == null) {
        showMessage(
          'לא הצלחנו לקרוא את הקובץ.',
        );

        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        selectedFileName =
            file!.name;

        selectedFileBytes =
            bytes;
      });
    } catch (error) {
      debugPrint(
        'Error picking vehicle license '
        'document: $error',
      );

      if (!mounted) {
        return;
      }

      showMessage(
        'לא הצלחנו לבחור את המסמך.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isPickingDocument = false;
        });
      }
    }
  }

  void removeSelectedDocument() {
    if (isBusy) {
      return;
    }

    setState(() {
      selectedFileName = null;
      selectedFileBytes = null;
    });
  }

  Future<bool> showSaveConfirmation({
    required DateTime expiryDate,
  }) async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'אישור פרטי רישיון הרכב',
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'בדוק שהפרטים נכונים לפני '
                'השמירה.',
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                'תוקף: '
                '${formatDate(expiryDate)}',
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                selectedFileName == null
                    ? 'מסמך: לא צורף'
                    : 'מסמך: $selectedFileName',
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
                'חזור לתיקון',
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
                'אישור ושמירה',
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void>
      saveVehicleLicense() async {
    if (!canEditVehicle || isBusy) {
      return;
    }

    if (selectedExpiryDate == null) {
      showMessage(
        'יש לבחור תאריך תוקף לרישיון הרכב.',
      );

      return;
    }

    final vehicleId =
        widget.vehicle.id;

    if (vehicleId == null) {
      showMessage(
        'לא הצלחנו לזהות את הרכב.',
      );

      return;
    }

    final confirmed =
        await showSaveConfirmation(
      expiryDate:
          selectedExpiryDate!,
    );

    if (!confirmed) {
      return;
    }

    final previousExpiryDate =
        widget.vehicle
            .vehicleLicenseExpiryDate;

    VehicleEvent? savedEvent;
    VehicleDocument? savedDocument;

    setState(() {
      isSaving = true;
    });

    try {
      final newEvent =
          VehicleEvent(
        vehicleId: vehicleId,
        type:
            VehicleEventType.vehicleLicense,
        date:
            selectedExpiryDate!,
        title:
            'חידוש רישיון רכב',
      );

      savedEvent =
          await vehicleRepository
              .addVehicleEvent(
        newEvent,
      );

      widget.vehicle.events.add(
        savedEvent,
      );

      if (selectedFileName != null &&
          selectedFileBytes != null) {
        savedDocument =
            await vehicleDocumentRepository
                .uploadDocument(
          vehicleId: vehicleId,
          eventId: savedEvent.id,
          displayName:
              VehicleDocumentNameUtils
                  .vehicleLicense(
            selectedExpiryDate!,
          ),
          originalFileName:
              selectedFileName!,
          fileBytes:
              selectedFileBytes!,
          category:
              VehicleDocumentCategory
                  .vehicleLicense,
        );
      }

      widget.vehicle
              .vehicleLicenseExpiryDate =
          selectedExpiryDate;

      await vehicleRepository
          .updateVehicle(
        widget.vehicle,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        selectedExpiryDate = null;
        selectedFileName = null;
        selectedFileBytes = null;
      });

      showMessage(
        'רישיון הרכב נשמר בהצלחה',
      );
    } catch (error) {
      debugPrint(
        'Error saving vehicle license: '
        '$error',
      );

      if (savedDocument != null) {
        try {
          await vehicleDocumentRepository
              .deleteDocument(
            savedDocument,
          );
        } catch (rollbackError) {
          debugPrint(
            'Error rolling back vehicle '
            'license document: '
            '$rollbackError',
          );
        }
      }

      if (savedEvent?.id != null) {
        try {
          await vehicleRepository
              .deleteVehicleEvent(
            savedEvent!.id!,
          );

          widget.vehicle.events
              .removeWhere(
            (event) =>
                event.id ==
                savedEvent!.id,
          );
        } catch (rollbackError) {
          debugPrint(
            'Error rolling back vehicle '
            'license event: '
            '$rollbackError',
          );
        }
      }

      widget.vehicle
              .vehicleLicenseExpiryDate =
          previousExpiryDate;

      if (!mounted) {
        return;
      }

      showMessage(
        'לא הצלחנו לשמור את רישיון הרכב. '
        'נסה שוב.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> updateShowOnHome(
    bool value,
  ) async {
    if (!canEditVehicle ||
        isUpdatingHomeSetting ||
        isSaving) {
      return;
    }

    final previousValue =
        widget.vehicle
            .showVehicleLicenseOnHome;

    setState(() {
      widget.vehicle
              .showVehicleLicenseOnHome =
          value;

      isUpdatingHomeSetting = true;
    });

    try {
      await vehicleRepository
          .updateVehicle(
        widget.vehicle,
      );

      if (!mounted) {
        return;
      }

      showMessage(
        value
            ? 'רישיון הרכב יוצג במסך הבית'
            : 'רישיון הרכב הוסר ממסך הבית',
      );
    } catch (error) {
      debugPrint(
        'Error updating vehicle license '
        'home setting: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        widget.vehicle
                .showVehicleLicenseOnHome =
            previousValue;
      });

      showMessage(
        'לא הצלחנו לעדכן את ההגדרה.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingHomeSetting = false;
        });
      }
    }
  }

  Future<void> openHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VehicleHistoryScreen(
          vehicle: widget.vehicle,
          eventType:
              VehicleEventType
                  .vehicleLicense,
          title:
              'היסטוריית רישיונות רכב',
          eventsLoader:
              widget.historyEventsLoader,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Widget buildEditContent() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'תוקף רישיון הרכב',
          style: TextStyle(
            fontSize: 15,
            fontWeight:
                FontWeight.w600,
            color:
                AppTheme.textPrimary,
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed:
                isBusy
                    ? null
                    : selectExpiryDate,
            icon: const Icon(
              Icons
                  .calendar_today_outlined,
            ),
            label: Text(
              selectedExpiryDate == null
                  ? 'בחר תאריך'
                  : formatDate(
                      selectedExpiryDate!,
                    ),
            ),
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        const Text(
          'מסמך רישיון',
          style: TextStyle(
            fontSize: 15,
            fontWeight:
                FontWeight.w600,
            color:
                AppTheme.textPrimary,
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed:
                isBusy
                    ? null
                    : pickLicenseDocument,
            icon: isPickingDocument
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons
                        .upload_file_outlined,
                  ),
            label: Text(
              selectedFileName == null
                  ? 'בחר מסמך'
                  : 'החלף מסמך',
            ),
          ),
        ),
        if (selectedFileName != null) ...[
          const SizedBox(
            height: 10,
          ),
          Container(
            padding:
                const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  AppTheme.primaryLight,
              borderRadius:
                  BorderRadius.circular(12),
              border: Border.all(
                color:
                    AppTheme.interactiveBorder,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons
                      .description_outlined,
                  color:
                      AppTheme.primary,
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                    selectedFileName!,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed:
                      isBusy
                          ? null
                          : removeSelectedDocument,
                  icon: const Icon(
                    Icons.close,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(
          height: 8,
        ),
        const Text(
          'המסמך אופציונלי. '
          'אם תצרף אותו כאן, הוא יופיע גם '
          'במסך מסמכי הרכב תחת רישיונות רכב.',
          style: TextStyle(
            fontSize: 13,
            color:
                AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget buildHistoryCard() {
    return Card(
      color:
          AppTheme.interactiveSurface,
      shape:
          interactiveCardShape,
      child: ListTile(
        leading: buildIconBox(
          Icons.history,
        ),
        title: const Text(
          'היסטוריית רישיונות רכב',
          style: TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),
        subtitle: const Text(
          'צפייה בחידושי רישיון קודמים',
          style: TextStyle(
            color:
                AppTheme.textSecondary,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_left,
          color:
              AppTheme.primary,
        ),
        onTap:
            isSaving
                ? null
                : openHistory,
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
          'רישיון רכב',
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            if (!canEditVehicle) ...[
              Card(
                child: ListTile(
                  leading: buildIconBox(
                    Icons
                        .visibility_outlined,
                  ),
                  title: const Text(
                    'מצב צפייה בלבד',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'אין לך הרשאה לשנות '
                    'את פרטי רישיון הרכב.',
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
            VehicleSettingCard(
              icon:
                  Icons.badge_outlined,
              title:
                  'רישיון רכב',
              subtitle:
                  'תוקף: ${getCurrentExpiryText()}',
              actionText:
                  canEditVehicle
                      ? 'שמור'
                      : null,
              onActionPressed:
                  canEditVehicle
                      ? saveVehicleLicense
                      : null,
              isActionLoading:
                  isSaving,
              showOnHome:
                  widget.vehicle
                      .showVehicleLicenseOnHome,
              onShowOnHomeChanged:
                  canEditVehicle &&
                          !isBusy
                      ? updateShowOnHome
                      : null,
              homeDescription:
                  'הצג את תוקף רישיון הרכב '
                  'בכרטיס הרכב',
              content:
                  canEditVehicle
                      ? buildEditContent()
                      : null,
            ),
            const SizedBox(
              height: 12,
            ),
            buildHistoryCard(),
          ],
        ),
      ),
    );
  }
}