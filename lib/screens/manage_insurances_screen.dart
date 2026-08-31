import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vehicle.dart';
import '../models/vehicle_document.dart';
import '../models/vehicle_event.dart';
import '../models/vehicle_insurance.dart';
import '../models/vehicle_member.dart';
import '../repositories/vehicle_document_repository.dart';
import '../repositories/vehicle_repository.dart';
import '../theme/app_theme.dart';
import '../utils/vehicle_document_name_utils.dart';
import '../widgets/vehicle_setting_card.dart';
import 'vehicle_history_screen.dart';

class ManageInsurancesScreen
    extends StatefulWidget {
  final Vehicle vehicle;

  final VehicleRepository? repository;
  final VehicleDocumentRepository?
      documentRepository;

  final Future<PlatformFile?> Function(
    InsuranceType type,
  )? documentPicker;

  final Future<List<VehicleEvent>> Function(
    String vehicleId,
  )? historyEventsLoader;

  const ManageInsurancesScreen({
    super.key,
    required this.vehicle,
    this.repository,
    this.documentRepository,
    this.documentPicker,
    this.historyEventsLoader,
  });

  @override
  State<ManageInsurancesScreen>
      createState() =>
          _ManageInsurancesScreenState();
}

class _ManageInsurancesScreenState
    extends State<ManageInsurancesScreen> {
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

  final Set<InsuranceType>
      savingTypes = {};

  final Set<InsuranceType>
      pickingDocumentTypes = {};

  final Map<InsuranceType, String>
      selectedFileNames = {};

  final Map<InsuranceType, Uint8List>
      selectedFileBytes = {};

  bool get canEditVehicle =>
      widget.vehicle.currentUserRole
          ?.canEditVehicle ??
      false;

  bool isTypeBusy(
    InsuranceType type,
  ) {
    return savingTypes.contains(type) ||
        pickingDocumentTypes.contains(type);
  }

  VehicleInsurance? getInsurance(
    InsuranceType type,
  ) {
    for (final insurance
        in widget.vehicle.insurances) {
      if (insurance.type == type) {
        return insurance;
      }
    }

    return null;
  }

  String formatDate(
    DateTime? date,
  ) {
    if (date == null) {
      return 'לא הוגדר';
    }

    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
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

  void replaceInsurance(
    VehicleInsurance insurance,
  ) {
    final index =
        widget.vehicle.insurances
            .indexWhere(
      (item) =>
          item.type ==
          insurance.type,
    );

    if (index == -1) {
      widget.vehicle.insurances.add(
        insurance,
      );
    } else {
      widget.vehicle.insurances[index] =
          insurance;
    }
  }

  Future<void>
      pickInsuranceDocument(
    InsuranceType type,
  ) async {
    if (!canEditVehicle ||
        isTypeBusy(type)) {
      return;
    }

    setState(() {
      pickingDocumentTypes.add(type);
    });

    try {
      PlatformFile? file;

      if (widget.documentPicker != null) {
        file =
            await widget.documentPicker!(
          type,
        );
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
        selectedFileNames[type] =
            file!.name;

        selectedFileBytes[type] =
            bytes;
      });
    } catch (error) {
      debugPrint(
        'Error picking insurance '
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
          pickingDocumentTypes.remove(
            type,
          );
        });
      }
    }
  }

  void removeSelectedDocument(
    InsuranceType type,
  ) {
    if (isTypeBusy(type)) {
      return;
    }

    setState(() {
      selectedFileNames.remove(type);
      selectedFileBytes.remove(type);
    });
  }

  Future<bool> showSaveConfirmation({
    required InsuranceType type,
    required DateTime expiryDate,
  }) async {
    final selectedFileName =
        selectedFileNames[type];

    final result =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'אישור פרטי הביטוח',
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'לפני שהביטוח נשמר בהיסטוריה, '
                'בדוק שהפרטים נכונים.',
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                'סוג: ${type.displayName}',
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                'תוקף עד: '
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

  Future<void> selectExpiryDate(
    InsuranceType type,
  ) async {
    if (!canEditVehicle ||
        isTypeBusy(type)) {
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

    final existingInsurance =
        getInsurance(type);

    final selectedDate =
        await showDatePicker(
      context: context,
      initialDate:
          existingInsurance?.expiryDate ??
              DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );

    if (selectedDate == null) {
      return;
    }

    final confirmed =
        await showSaveConfirmation(
      type: type,
      expiryDate: selectedDate,
    );

    if (!confirmed) {
      return;
    }

    await saveNewInsurance(
      type: type,
      expiryDate: selectedDate,
      existingInsurance:
          existingInsurance,
    );
  }

  Future<void> saveNewInsurance({
    required InsuranceType type,
    required DateTime expiryDate,
    required VehicleInsurance?
        existingInsurance,
  }) async {
    if (!canEditVehicle ||
        isTypeBusy(type)) {
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

    setState(() {
      savingTypes.add(type);
    });

    VehicleEvent? savedEvent;
    VehicleDocument? savedDocument;

    try {
      final newEvent =
          VehicleEvent(
        vehicleId: vehicleId,
        type:
            VehicleEventType.insurance,
        date: expiryDate,
        title: type.displayName,
        insuranceType: type,
      );

      savedEvent =
          await vehicleRepository
              .addVehicleEvent(
        newEvent,
      );

      final selectedFileName =
          selectedFileNames[type];

      final selectedBytes =
          selectedFileBytes[type];

      if (selectedFileName != null &&
          selectedBytes != null) {
        savedDocument =
            await vehicleDocumentRepository
                .uploadDocument(
          vehicleId: vehicleId,
          eventId: savedEvent.id,
          displayName:
              VehicleDocumentNameUtils
                  .insurance(
            insuranceType:
                type.displayName,
            expiryDate:
                expiryDate,
          ),
          originalFileName:
              selectedFileName,
          fileBytes:
              selectedBytes,
          category:
              VehicleDocumentCategory
                  .insurance,
        );
      }

      final insurance =
          VehicleInsurance(
        id: existingInsurance?.id,
        vehicleId: vehicleId,
        type: type,
        expiryDate: expiryDate,
        showOnHome:
            existingInsurance
                    ?.showOnHome ??
                false,
      );

      final savedInsurance =
          await vehicleRepository
              .saveInsurance(
        insurance,
      );

      widget.vehicle.events.add(
        savedEvent,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        replaceInsurance(
          savedInsurance,
        );

        selectedFileNames.remove(type);
        selectedFileBytes.remove(type);
      });

      showMessage(
        'הביטוח נשמר בהצלחה',
      );
    } on PostgrestException catch (error) {
      debugPrint(
        'Supabase insurance error: '
        '${error.code} - ${error.message}',
      );

      await rollbackInsuranceSave(
        event: savedEvent,
        document: savedDocument,
      );

      if (!mounted) {
        return;
      }

      if (error.code == '42501') {
        showMessage(
          'אין לך הרשאה לעדכן את הביטוח.',
        );
      } else {
        showMessage(
          'לא הצלחנו לשמור את הביטוח. נסה שוב.',
        );
      }
    } catch (error) {
      debugPrint(
        'Unexpected insurance error: '
        '$error',
      );

      await rollbackInsuranceSave(
        event: savedEvent,
        document: savedDocument,
      );

      if (!mounted) {
        return;
      }

      showMessage(
        'לא הצלחנו לשמור את הביטוח. '
        'בדוק את החיבור ונסה שוב.',
      );
    } finally {
      if (mounted) {
        setState(() {
          savingTypes.remove(type);
        });
      }
    }
  }

  Future<void> rollbackInsuranceSave({
    required VehicleEvent? event,
    required VehicleDocument? document,
  }) async {
    if (document != null) {
      try {
        await vehicleDocumentRepository
            .deleteDocument(
          document,
        );
      } catch (error) {
        debugPrint(
          'Error rolling back insurance '
          'document: $error',
        );
      }
    }

    if (event?.id == null) {
      return;
    }

    try {
      await vehicleRepository
          .deleteVehicleEvent(
        event!.id!,
      );
    } catch (error) {
      debugPrint(
        'Error rolling back insurance '
        'event: $error',
      );
    }
  }

  Future<void> updateShowOnHome(
    InsuranceType type,
    bool value,
  ) async {
    if (!canEditVehicle ||
        isTypeBusy(type)) {
      return;
    }

    final vehicleId =
        widget.vehicle.id;

    final existingInsurance =
        getInsurance(type);

    if (vehicleId == null ||
        existingInsurance == null) {
      return;
    }

    final updatedInsurance =
        VehicleInsurance(
      id: existingInsurance.id,
      vehicleId: vehicleId,
      type:
          existingInsurance.type,
      expiryDate:
          existingInsurance.expiryDate,
      showOnHome: value,
    );

    setState(() {
      savingTypes.add(type);
    });

    try {
      final savedInsurance =
          await vehicleRepository
              .saveInsurance(
        updatedInsurance,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        replaceInsurance(
          savedInsurance,
        );
      });

      showMessage(
        value
            ? '${type.displayName} יוצג במסך הבית'
            : '${type.displayName} הוסר ממסך הבית',
      );
    } catch (error) {
      debugPrint(
        'Error updating showOnHome: '
        '$error',
      );

      if (!mounted) {
        return;
      }

      showMessage(
        'לא הצלחנו לעדכן את ההגדרה. נסה שוב.',
      );
    } finally {
      if (mounted) {
        setState(() {
          savingTypes.remove(type);
        });
      }
    }
  }

  Future<void>
      openInsuranceHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VehicleHistoryScreen(
          vehicle: widget.vehicle,
          eventType:
              VehicleEventType.insurance,
          title:
              'היסטוריית ביטוחים',
          eventsLoader:
              widget.historyEventsLoader,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
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

  Widget buildDocumentContent(
    InsuranceType type,
  ) {
    final selectedFileName =
        selectedFileNames[type];

    final isPicking =
        pickingDocumentTypes.contains(
      type,
    );

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'מסמך ביטוח',
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
                isTypeBusy(type)
                    ? null
                    : () {
                        pickInsuranceDocument(
                          type,
                        );
                      },
            icon: isPicking
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
                    selectedFileName,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed:
                      isTypeBusy(type)
                          ? null
                          : () {
                              removeSelectedDocument(
                                type,
                              );
                            },
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
          'במסך מסמכי הרכב תחת ביטוחים.',
          style: TextStyle(
            fontSize: 13,
            color:
                AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget buildInsuranceCard(
    InsuranceType type,
  ) {
    final insurance =
        getInsurance(type);

    final hasInsurance =
        insurance != null &&
            insurance.expiryDate != null;

    final isSaving =
        savingTypes.contains(type);

    final busy =
        isTypeBusy(type);

    return VehicleSettingCard(
      icon: Icons.shield_outlined,
      title: type.displayName,
      subtitle:
          'תוקף: ${formatDate(
        insurance?.expiryDate,
      )}',
      actionText:
          canEditVehicle
              ? hasInsurance
                  ? 'חידוש'
                  : 'הוסף'
              : null,
      onActionPressed:
          canEditVehicle && !busy
              ? () {
                  selectExpiryDate(
                    type,
                  );
                }
              : null,
      isActionLoading:
          isSaving,
      showOnHome:
          insurance?.showOnHome ??
              false,
      onShowOnHomeChanged:
          canEditVehicle &&
                  hasInsurance &&
                  !busy
              ? (value) {
                  updateShowOnHome(
                    type,
                    value,
                  );
                }
              : null,
      homeDescription:
          hasInsurance
              ? 'הצג את תוקף הביטוח בכרטיס הרכב'
              : 'יש להוסיף ביטוח לפני שניתן '
                  'להציג אותו במסך הבית',
      content:
          canEditVehicle
              ? buildDocumentContent(
                  type,
                )
              : null,
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
          'היסטוריית ביטוחים',
          style: TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),
        subtitle: const Text(
          'צפייה בביטוחים קודמים',
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
            savingTypes.isNotEmpty
                ? null
                : openInsuranceHistory,
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
          'ביטוחים',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
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
                  'את פרטי הביטוחים.',
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
          buildInsuranceCard(
            InsuranceType.mandatory,
          ),
          const SizedBox(
            height: 12,
          ),
          buildInsuranceCard(
            InsuranceType.comprehensive,
          ),
          const SizedBox(
            height: 12,
          ),
          buildInsuranceCard(
            InsuranceType.thirdParty,
          ),
          const SizedBox(
            height: 12,
          ),
          buildHistoryCard(),
        ],
      ),
    );
  }
}