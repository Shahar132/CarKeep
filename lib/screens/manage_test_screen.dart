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
import '../utils/vehicle_event_utils.dart';
import '../widgets/vehicle_setting_card.dart';
import 'vehicle_history_screen.dart';

class ManageTestScreen
    extends StatefulWidget {
  final Vehicle vehicle;

  final VehicleRepository? repository;
  final VehicleDocumentRepository?
      documentRepository;

  final Future<PlatformFile?> Function()?
      documentPicker;

  final Future<List<VehicleEvent>> Function(
    String vehicleId,
  )? historyEventsLoader;

  const ManageTestScreen({
    super.key,
    required this.vehicle,
    this.repository,
    this.documentRepository,
    this.documentPicker,
    this.historyEventsLoader,
  });

  @override
  State<ManageTestScreen> createState() =>
      _ManageTestScreenState();
}

class _ManageTestScreenState
    extends State<ManageTestScreen> {
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

  String? selectedFileName;
  Uint8List? selectedFileBytes;

  bool isSavingTest = false;
  bool isPickingDocument = false;
  bool isUpdatingHomeSetting = false;

  bool get canEditVehicle =>
      widget.vehicle.currentUserRole
          ?.canEditVehicle ??
      false;

  bool get isBusy =>
      isSavingTest ||
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

  String getTestExpiryText() {
    final date =
        widget.vehicle.testExpiryDate;

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

  Future<void> pickTestDocument() async {
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
        'Error picking test document: '
        '$error',
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

  Future<bool>
      showTestSaveConfirmation(
    DateTime expiryDate,
  ) async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'אישור פרטי הטסט',
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'לפני שהטסט נשמר בהיסטוריה, '
                'בדוק שהפרטים נכונים.',
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                'תוקף הטסט: '
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

  Future<void> addNewTest() async {
    if (!canEditVehicle || isBusy) {
      return;
    }

    final selectedDate =
        await showDatePicker(
      context: context,
      initialDate:
          widget.vehicle.testExpiryDate ??
              DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );

    if (selectedDate == null) {
      return;
    }

    final confirmed =
        await showTestSaveConfirmation(
      selectedDate,
    );

    if (!confirmed) {
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

    final previousDate =
        widget.vehicle.testExpiryDate;

    VehicleEvent? savedEvent;
    VehicleDocument? savedDocument;

    setState(() {
      isSavingTest = true;
    });

    try {
      final newEvent =
          VehicleEvent(
        vehicleId: vehicleId,
        type:
            VehicleEventType.test,
        date: selectedDate,
        title: 'טסט',
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
              VehicleDocumentNameUtils.test(
            selectedDate,
          ),
          originalFileName:
              selectedFileName!,
          fileBytes:
              selectedFileBytes!,
          category:
              VehicleDocumentCategory.test,
        );
      }

      updateCurrentTestFromHistory();

      await vehicleRepository
          .updateVehicle(
        widget.vehicle,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        selectedFileName = null;
        selectedFileBytes = null;
      });

      showMessage(
        'הטסט נשמר בהצלחה',
      );
    } catch (error) {
      debugPrint(
        'Error saving test: $error',
      );

      if (savedDocument != null) {
        try {
          await vehicleDocumentRepository
              .deleteDocument(
            savedDocument,
          );
        } catch (rollbackError) {
          debugPrint(
            'Error rolling back test '
            'document: $rollbackError',
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
            'Error rolling back test: '
            '$rollbackError',
          );
        }
      }

      widget.vehicle.testExpiryDate =
          previousDate;

      if (!mounted) {
        return;
      }

      showMessage(
        'לא הצלחנו לשמור את הטסט. נסה שוב.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isSavingTest = false;
        });
      }
    }
  }

  void updateCurrentTestFromHistory() {
    widget.vehicle.testExpiryDate =
        VehicleEventUtils.getLatestEventDate(
      widget.vehicle.events,
      VehicleEventType.test,
    );
  }

  Future<void> updateShowOnHome(
    bool value,
  ) async {
    if (!canEditVehicle ||
        isUpdatingHomeSetting ||
        isSavingTest) {
      return;
    }

    final previousValue =
        widget.vehicle.showTestOnHome;

    setState(() {
      widget.vehicle.showTestOnHome =
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
            ? 'הטסט יוצג במסך הבית'
            : 'הטסט הוסר ממסך הבית',
      );
    } catch (error) {
      debugPrint(
        'Error updating test home '
        'setting: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        widget.vehicle.showTestOnHome =
            previousValue;
      });

      showMessage(
        'לא הצלחנו לעדכן את ההגדרה. נסה שוב.',
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
              VehicleEventType.test,
          title:
              'היסטוריית טסטים',
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

  Widget buildDocumentContent() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'מסמך הטסט',
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
                    : pickTestDocument,
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
          'אם תצרף אותו, הוא יישמר גם '
          'במסך מסמכי הרכב תחת טסטים.',
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
          'היסטוריית טסטים',
          style: TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),
        subtitle: const Text(
          'צפייה בטסטים קודמים',
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
            isBusy
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
          'טסט',
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
                    'אין לך הרשאה להוסיף '
                    'או לשנות טסטים.',
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
                  Icons.fact_check_outlined,
              title:
                  'טסט נוכחי',
              subtitle:
                  'תוקף: ${getTestExpiryText()}',
              actionText:
                  canEditVehicle
                      ? 'טסט חדש'
                      : null,
              onActionPressed:
                  canEditVehicle
                      ? addNewTest
                      : null,
              isActionLoading:
                  isSavingTest,
              showOnHome:
                  widget.vehicle
                      .showTestOnHome,
              onShowOnHomeChanged:
                  canEditVehicle &&
                          !isBusy
                      ? updateShowOnHome
                      : null,
              homeDescription:
                  'הצג את תוקף הטסט בכרטיס הרכב',
              content:
                  canEditVehicle
                      ? buildDocumentContent()
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