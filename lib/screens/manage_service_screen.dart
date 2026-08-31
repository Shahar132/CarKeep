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
import '../utils/vehicle_service_utils.dart';
import '../widgets/vehicle_setting_card.dart';
import 'vehicle_history_screen.dart';

class ManageServiceScreen
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

  const ManageServiceScreen({
    super.key,
    required this.vehicle,
    this.repository,
    this.documentRepository,
    this.documentPicker,
    this.historyEventsLoader,
  });

  @override
  State<ManageServiceScreen> createState() =>
      _ManageServiceScreenState();
}

class _ManageServiceScreenState
    extends State<ManageServiceScreen> {
  final formKey =
      GlobalKey<FormState>();

  final mileageController =
      TextEditingController();

  final intervalController =
      TextEditingController();

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

  DateTime? selectedServiceDate;

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
  void dispose() {
    mileageController.dispose();
    intervalController.dispose();

    super.dispose();
  }

  String formatDate(
    DateTime date,
  ) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String formatNumber(
    int value,
  ) {
    final text =
        value.toString();

    final buffer =
        StringBuffer();

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

  Widget buildIconBox(
    IconData icon,
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
        icon,
        color:
            AppTheme.primary,
        size: 24,
      ),
    );
  }

  String getLastServiceSubtitle() {
    final date =
        widget.vehicle.lastServiceDate;

    if (date == null) {
      return 'עדיין לא נשמר טיפול';
    }

    return 'טיפול אחרון: '
        '${formatDate(date)}';
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

  Future<void> updateShowOnHome(
    bool value,
  ) async {
    if (!canEditVehicle || isBusy) {
      return;
    }

    final previousValue =
        widget.vehicle.showServiceOnHome;

    setState(() {
      widget.vehicle.showServiceOnHome =
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
            ? 'הטיפול הבא יוצג במסך הבית'
            : 'הטיפול הבא הוסר ממסך הבית',
      );
    } catch (error) {
      debugPrint(
        'Error updating service home '
        'setting: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        widget.vehicle.showServiceOnHome =
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

  Future<void>
      selectServiceDate() async {
    if (!canEditVehicle || isBusy) {
      return;
    }

    final selectedDate =
        await showDatePicker(
      context: context,
      initialDate:
          selectedServiceDate ??
              DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      selectedServiceDate =
          selectedDate;
    });
  }

  Future<void>
      pickServiceDocument() async {
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

      final bytes =
          file.bytes;

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
        'Error picking service '
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
    required DateTime serviceDate,
    required int mileage,
    required int? interval,
  }) async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'אישור פרטי הטיפול',
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'לפני שהטיפול נשמר בהיסטוריה, '
                'בדוק שהפרטים נכונים.',
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                'תאריך: '
                '${formatDate(serviceDate)}',
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                'קילומטראז׳: '
                '${formatNumber(mileage)} ק"מ',
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                interval == null
                    ? 'מרווח טיפול: לא הוגדר'
                    : 'מרווח טיפול: '
                        '${formatNumber(interval)} ק"מ',
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

  Future<void> saveService() async {
    if (!canEditVehicle || isBusy) {
      return;
    }

    if (selectedServiceDate == null) {
      showMessage(
        'יש לבחור תאריך טיפול',
      );

      return;
    }

    if (!formKey.currentState!.validate()) {
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

    final mileage = int.parse(
      mileageController.text.trim(),
    );

    final intervalText =
        intervalController.text.trim();

    final interval =
        intervalText.isEmpty
            ? null
            : int.parse(
                intervalText,
              );

    final confirmed =
        await showSaveConfirmation(
      serviceDate:
          selectedServiceDate!,
      mileage: mileage,
      interval: interval,
    );

    if (!confirmed) {
      return;
    }

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
            VehicleEventType.service,
        date:
            selectedServiceDate!,
        title:
            'טיפול תקופתי',
        mileage: mileage,
        serviceIntervalKm:
            interval,
      );

      savedEvent =
          await vehicleRepository
              .addVehicleEvent(
        newEvent,
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
                  .service(
            mileage: mileage,
            serviceDate:
                selectedServiceDate!,
          ),
          originalFileName:
              selectedFileName!,
          fileBytes:
              selectedFileBytes!,
          category:
              VehicleDocumentCategory
                  .service,
        );
      }

      widget.vehicle.events.add(
        savedEvent,
      );

      updateCurrentServiceFromHistory();

      await vehicleRepository
          .updateVehicle(
        widget.vehicle,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
    } catch (error) {
      debugPrint(
        'Error saving service: $error',
      );

      if (savedDocument != null) {
        try {
          await vehicleDocumentRepository
              .deleteDocument(
            savedDocument,
          );
        } catch (rollbackError) {
          debugPrint(
            'Error rolling back service '
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

          updateCurrentServiceFromHistory();
        } catch (rollbackError) {
          debugPrint(
            'Error rolling back service: '
            '$rollbackError',
          );
        }
      }

      if (!mounted) {
        return;
      }

      showMessage(
        'לא הצלחנו לשמור את הטיפול. נסה שוב.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
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

  Future<void>
      openServiceHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VehicleHistoryScreen(
          vehicle: widget.vehicle,
          eventType:
              VehicleEventType.service,
          title:
              'היסטוריית טיפולים',
          eventsLoader:
              widget.historyEventsLoader,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Widget buildServiceForm() {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'תאריך הטיפול',
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
                      : selectServiceDate,
              icon: const Icon(
                Icons
                    .calendar_today_outlined,
              ),
              label: Text(
                selectedServiceDate == null
                    ? 'בחר תאריך'
                    : formatDate(
                        selectedServiceDate!,
                      ),
              ),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          TextFormField(
            controller:
                mileageController,
            enabled:
                !isBusy,
            keyboardType:
                TextInputType.number,
            decoration:
                const InputDecoration(
              labelText:
                  'קילומטראז׳ בזמן הטיפול',
              suffixText: 'ק"מ',
            ),
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'יש להזין קילומטראז׳';
              }

              final mileage =
                  int.tryParse(
                value.trim(),
              );

              if (mileage == null ||
                  mileage < 0) {
                return 'יש להזין קילומטראז׳ תקין';
              }

              return null;
            },
          ),
          const SizedBox(
            height: 16,
          ),
          TextFormField(
            controller:
                intervalController,
            enabled:
                !isBusy,
            keyboardType:
                TextInputType.number,
            decoration:
                const InputDecoration(
              labelText:
                  'מרווח טיפול בק"מ',
              hintText:
                  'לדוגמה: 15000',
              suffixText: 'ק"מ',
            ),
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return null;
              }

              final interval =
                  int.tryParse(
                value.trim(),
              );

              if (interval == null ||
                  interval <= 0) {
                return 'יש להזין מרווח תקין';
              }

              return null;
            },
          ),
          const SizedBox(
            height: 8,
          ),
          const Text(
            'השדה הזה אופציונלי. '
            'אם לא תמלא אותו, הטיפול הבא '
            'יחושב לפי שנה מתאריך הטיפול.',
            style: TextStyle(
              color:
                  AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          const Text(
            'מסמך טיפול',
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
                      : pickServiceDocument,
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
            'אפשר לצרף חשבונית, קבלה או '
            'מסמך מהמוסך. הוא יופיע גם '
            'במסך מסמכי הרכב תחת טיפולים.',
            style: TextStyle(
              color:
                  AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildReadOnlyServiceDetails() {
    final lastServiceDate =
        widget.vehicle.lastServiceDate;

    final lastServiceMileage =
        widget.vehicle.lastServiceMileage;

    final interval =
        widget.vehicle.serviceIntervalKm;

    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'תאריך טיפול אחרון',
              ),
            ),
            Text(
              lastServiceDate == null
                  ? 'לא הוגדר'
                  : formatDate(
                      lastServiceDate,
                    ),
              style: const TextStyle(
                color:
                    AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 12,
        ),
        Row(
          children: [
            const Expanded(
              child: Text(
                'קילומטראז׳',
              ),
            ),
            Text(
              lastServiceMileage == null
                  ? 'לא הוגדר'
                  : '${formatNumber(lastServiceMileage)} ק"מ',
              style: const TextStyle(
                color:
                    AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 12,
        ),
        Row(
          children: [
            const Expanded(
              child: Text(
                'מרווח טיפול',
              ),
            ),
            Text(
              interval == null
                  ? 'לא הוגדר'
                  : '${formatNumber(interval)} ק"מ',
              style: const TextStyle(
                color:
                    AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildReadOnlyView() {
    return ListView(
      padding:
          const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: buildIconBox(
              Icons.visibility_outlined,
            ),
            title: const Text(
              'מצב צפייה בלבד',
              style: TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'אין לך הרשאה להוסיף או לשנות טיפולים.',
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
        VehicleSettingCard(
          icon:
              Icons.build_outlined,
          title: 'טיפולים',
          subtitle:
              getLastServiceSubtitle(),
          showOnHome:
              widget.vehicle
                  .showServiceOnHome,
          onShowOnHomeChanged:
              null,
          homeDescription:
              'הצג את הטיפול הבא בכרטיס הרכב',
          content:
              buildReadOnlyServiceDetails(),
        ),
        const SizedBox(
          height: 12,
        ),
        buildHistoryCard(),
      ],
    );
  }

  Widget buildEditView() {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(16),
      child: Column(
        children: [
          VehicleSettingCard(
            icon:
                Icons.build_outlined,
            title:
                'טיפול חדש',
            subtitle:
                getLastServiceSubtitle(),
            actionText:
                'שמור',
            onActionPressed:
                isBusy
                    ? null
                    : saveService,
            isActionLoading:
                isSaving,
            showOnHome:
                widget.vehicle
                    .showServiceOnHome,
            onShowOnHomeChanged:
                isBusy
                    ? null
                    : updateShowOnHome,
            homeDescription:
                'הצג את הטיפול הבא בכרטיס הרכב',
            content:
                buildServiceForm(),
          ),
          const SizedBox(
            height: 12,
          ),
          buildHistoryCard(),
        ],
      ),
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
          'היסטוריית טיפולים',
          style: TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),
        subtitle: const Text(
          'צפייה בטיפולים קודמים',
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
                : openServiceHistory,
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
          'טיפולים',
        ),
      ),
      body:
          canEditVehicle
              ? buildEditView()
              : buildReadOnlyView(),
    );
  }
}