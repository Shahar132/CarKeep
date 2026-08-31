import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/vehicle.dart';
import '../models/vehicle_document.dart';
import '../models/vehicle_member.dart';
import '../repositories/vehicle_document_repository.dart';
import '../theme/app_theme.dart';

enum _DocumentAction {
  view,
  download,
}

class VehicleDocumentsScreen
    extends StatefulWidget {
  final Vehicle vehicle;
  final bool embedded;

  // Optional dependencies for Widget Tests.
  // If not supplied, the real app continues
  // using Supabase exactly as before.
  final SupabaseClient? supabaseClient;

  final VehicleDocumentRepository?
      documentRepository;

  final Future<List<VehicleDocument>>
      Function(
    String vehicleId,
  )? documentsLoader;

  const VehicleDocumentsScreen({
    super.key,
    required this.vehicle,
    this.embedded = false,
    this.supabaseClient,
    this.documentRepository,
    this.documentsLoader,
  });

  @override
  State<VehicleDocumentsScreen>
      createState() =>
          _VehicleDocumentsScreenState();
}

class _VehicleDocumentsScreenState
    extends State<VehicleDocumentsScreen> {
  SupabaseClient get supabase =>
      widget.supabaseClient ??
      Supabase.instance.client;

  VehicleDocumentRepository?
      _vehicleDocumentRepository;

  VehicleDocumentRepository get
      vehicleDocumentRepository =>
          widget.documentRepository ??
          (_vehicleDocumentRepository ??=
              VehicleDocumentRepository(
            supabase:
                widget.supabaseClient,
          ));

  List<VehicleDocument> documents = [];

  bool isLoading = true;
  bool isUploading = false;
  bool isDeleting = false;
  bool isOpening = false;
  bool isDownloading = false;

  String? errorMessage;

  bool get canEditVehicle =>
      widget.vehicle.currentUserRole
          ?.canEditVehicle ??
      false;

  bool get isBusy =>
      isUploading ||
      isDeleting ||
      isOpening ||
      isDownloading;

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

    loadDocuments();
  }

  Future<void> loadDocuments() async {
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
      late final List<VehicleDocument>
          loadedDocuments;

      if (widget.documentsLoader != null) {
        loadedDocuments =
            await widget.documentsLoader!(
          vehicleId,
        );
      } else {
        final data = await supabase
            .from('documents')
            .select()
            .eq(
              'vehicle_id',
              vehicleId,
            )
            .order(
              'created_at',
              ascending: false,
            );

        loadedDocuments = data
            .map<VehicleDocument>(
              (map) =>
                  VehicleDocument.fromMap(
                map,
              ),
            )
            .toList();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        documents = loadedDocuments;
        isLoading = false;
        errorMessage = null;
      });
    } catch (error) {
      debugPrint(
        'Error loading documents: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        errorMessage =
            'לא הצלחנו לטעון את המסמכים.';
      });
    }
  }

  Future<void>
      pickAndUploadDocument() async {
    if (!canEditVehicle || isBusy) {
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

    try {
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

      final file =
          result.files.single;

      final Uint8List? fileBytes =
          file.bytes;

      if (fileBytes == null) {
        showMessage(
          'לא הצלחנו לקרוא את הקובץ.',
        );
        return;
      }

      final uploadDetails =
          await askForUploadDetails(
        file.name,
      );

      if (uploadDetails == null) {
        return;
      }

      setState(() {
        isUploading = true;
      });

      try {
        await vehicleDocumentRepository
            .uploadDocument(
          vehicleId: vehicleId,
          displayName:
              uploadDetails.$1,
          originalFileName:
              file.name,
          fileBytes:
              fileBytes,
          category:
              uploadDetails.$2,
        );

        await loadDocuments();

        if (!mounted) {
          return;
        }

        showMessage(
          'המסמך הועלה בהצלחה',
        );
      } catch (error) {
        debugPrint(
          'Error uploading document: $error',
        );

        if (!mounted) {
          return;
        }

        showMessage(
          'לא הצלחנו להעלות את המסמך. נסה שוב.',
        );
      } finally {
        if (mounted) {
          setState(() {
            isUploading = false;
          });
        }
      }
    } catch (error) {
      debugPrint(
        'Error picking document: $error',
      );

      if (!mounted) {
        return;
      }

      showMessage(
        'לא הצלחנו לבחור את הקובץ.',
      );
    }
  }

  Future<
      (
        String,
        VehicleDocumentCategory,
      )?> askForUploadDetails(
    String originalFileName,
  ) async {
    String enteredName = '';

    VehicleDocumentCategory
        selectedCategory =
        VehicleDocumentCategory.other;

    final result = await showDialog<
        (
          String,
          VehicleDocumentCategory,
        )>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'פרטי המסמך',
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
                      'בחר שם וקטגוריה כדי '
                      'שהמסמך יישמר במקום הנכון.',
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      'הקובץ שנבחר: '
                      '$originalFileName',
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color:
                            AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    TextField(
                      autofocus: true,
                      onChanged: (value) {
                        enteredName = value;
                      },
                      decoration:
                          const InputDecoration(
                        labelText:
                            'שם המסמך',
                        hintText:
                            'לדוגמה: ביטוח חובה 2027',
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    DropdownButtonFormField<
                        VehicleDocumentCategory>(
                      initialValue:
                          selectedCategory,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'קטגוריה',
                      ),
                      items:
                          VehicleDocumentCategory
                              .values
                              .map(
                        (category) {
                          return DropdownMenuItem<
                              VehicleDocumentCategory>(
                            value:
                                category,
                            child: Text(
                              category
                                  .displayName,
                            ),
                          );
                        },
                      ).toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedCategory =
                              value;
                        });
                      },
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
                  child: const Text(
                    'ביטול',
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value =
                        enteredName.trim();

                    if (value.isEmpty) {
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      (
                        value,
                        selectedCategory,
                      ),
                    );
                  },
                  child: const Text(
                    'המשך',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  Future<void> showDocumentActions(
    VehicleDocument document,
  ) async {
    if (isBusy) {
      return;
    }

    final action =
        await showModalBottomSheet<
            _DocumentAction>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.visibility_outlined,
                  color:
                      AppTheme.primary,
                ),
                title: const Text(
                  'צפה במסמך',
                ),
                onTap: () {
                  Navigator.pop(
                    sheetContext,
                    _DocumentAction.view,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.download_outlined,
                  color:
                      AppTheme.primary,
                ),
                title: const Text(
                  'הורד מחדש',
                ),
                onTap: () {
                  Navigator.pop(
                    sheetContext,
                    _DocumentAction.download,
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _DocumentAction.view:
        await openDocument(
          document,
        );
        break;

      case _DocumentAction.download:
        await downloadDocument(
          document,
        );
        break;
    }
  }

  Future<void> openDocument(
    VehicleDocument document,
  ) async {
    if (isBusy) {
      return;
    }

    setState(() {
      isOpening = true;
    });

    try {
      final signedUrl =
          await supabase.storage
              .from(
                'vehicle-documents',
              )
              .createSignedUrl(
        document.filePath,
        600,
      );

      final uri =
          Uri.parse(signedUrl);

      final opened =
          await launchUrl(
        uri,
        mode:
            LaunchMode.platformDefault,
      );

      if (!opened && mounted) {
        showMessage(
          'לא הצלחנו לפתוח את המסמך.',
        );
      }
    } catch (error) {
      debugPrint(
        'Error opening document: $error',
      );

      if (!mounted) {
        return;
      }

      showMessage(
        'לא הצלחנו לפתוח את המסמך. נסה שוב.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isOpening = false;
        });
      }
    }
  }

  Future<void> downloadDocument(
    VehicleDocument document,
  ) async {
    if (isBusy) {
      return;
    }

    setState(() {
      isDownloading = true;
    });

    try {
      final bytes =
          await supabase.storage
              .from(
                'vehicle-documents',
              )
              .download(
        document.filePath,
      );

      if (!mounted) {
        return;
      }

      final fileName =
          buildDownloadFileName(
        document,
      );

      final result =
          await FilePicker.platform.saveFile(
        dialogTitle:
            'שמור מסמך',
        fileName:
            fileName,
        bytes:
            bytes,
      );

      if (!mounted) {
        return;
      }

      if (result != null) {
        showMessage(
          'המסמך נשמר בהצלחה',
        );
      }
    } catch (error) {
      debugPrint(
        'Error downloading document: $error',
      );

      if (!mounted) {
        return;
      }

      showMessage(
        'לא הצלחנו להוריד את המסמך. נסה שוב.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isDownloading = false;
        });
      }
    }
  }

  String buildDownloadFileName(
    VehicleDocument document,
  ) {
    final original =
        document.originalFileName ??
        '';

    String extension = '';

    final dotIndex =
        original.lastIndexOf('.');

    if (dotIndex != -1 &&
        dotIndex <
            original.length - 1) {
      extension =
          original.substring(
        dotIndex,
      );
    }

    var name =
        document.displayName.trim();

    name = name.replaceAll(
      RegExp(
        r'[\\/:*?"<>|]',
      ),
      '_',
    );

    if (extension.isNotEmpty &&
        !name.toLowerCase().endsWith(
              extension.toLowerCase(),
            )) {
      name += extension;
    }

    if (name.isEmpty) {
      return original.isEmpty
          ? 'document'
          : original;
    }

    return name;
  }

  Future<bool>
      showDeleteConfirmation(
    VehicleDocument document,
  ) async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'מחיקת מסמך',
          ),
          content: Text(
            'האם למחוק את '
            '"${document.displayName}"?',
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

  Future<void> deleteDocument(
    VehicleDocument document,
  ) async {
    if (!canEditVehicle || isBusy) {
      return;
    }

    if (document.id == null) {
      showMessage(
        'לא הצלחנו לזהות את המסמך.',
      );
      return;
    }

    final confirmed =
        await showDeleteConfirmation(
      document,
    );

    if (!confirmed) {
      return;
    }

    setState(() {
      isDeleting = true;
    });

    try {
      await vehicleDocumentRepository
          .deleteDocument(
        document,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        documents.removeWhere(
          (item) =>
              item.id ==
              document.id,
        );
      });

      showMessage(
        'המסמך נמחק',
      );
    } catch (error) {
      debugPrint(
        'Error deleting document: $error',
      );

      if (!mounted) {
        return;
      }

      showMessage(
        'לא הצלחנו למחוק את המסמך. נסה שוב.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isDeleting = false;
        });
      }
    }
  }

  IconData getDocumentIcon(
    VehicleDocument document,
  ) {
    final fileName =
        document.originalFileName
                ?.toLowerCase() ??
            '';

    if (fileName.endsWith('.pdf')) {
      return Icons.picture_as_pdf_outlined;
    }

    if (fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.png')) {
      return Icons.image_outlined;
    }

    return Icons.description_outlined;
  }

  IconData getCategoryIcon(
    VehicleDocumentCategory category,
  ) {
    switch (category) {
      case VehicleDocumentCategory
            .vehicleLicense:
        return Icons.badge_outlined;

      case VehicleDocumentCategory.test:
        return Icons.fact_check_outlined;

      case VehicleDocumentCategory
            .insurance:
        return Icons.shield_outlined;

      case VehicleDocumentCategory.service:
        return Icons.build_outlined;

      case VehicleDocumentCategory.other:
        return Icons.folder_outlined;
    }
  }

  Widget buildDocumentIcon(
    VehicleDocument document,
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
        getDocumentIcon(
          document,
        ),
        color:
            AppTheme.primary,
        size: 24,
      ),
    );
  }

  Widget buildViewOnlyIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color:
            AppTheme.iconBackground,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.visibility_outlined,
        color:
            AppTheme.primary,
        size: 24,
      ),
    );
  }

  Widget buildCategoryHeader({
    required VehicleDocumentCategory
        category,
    required int count,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        top: 8,
        bottom: 10,
      ),
      child: Row(
        children: [
          Icon(
            getCategoryIcon(
              category,
            ),
            color:
                AppTheme.primary,
            size: 22,
          ),
          const SizedBox(
            width: 8,
          ),
          Expanded(
            child: Text(
              category.displayName,
              style:
                  const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w700,
                color:
                    AppTheme.textPrimary,
              ),
            ),
          ),
          Text(
            '$count',
            style:
                const TextStyle(
              color:
                  AppTheme.textSecondary,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDocumentCard(
    VehicleDocument document,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      color:
          AppTheme.interactiveSurface,
      shape:
          interactiveCardShape,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        onTap:
            isBusy
                ? null
                : () {
                    showDocumentActions(
                      document,
                    );
                  },
        leading:
            buildDocumentIcon(
          document,
        ),
        title: Text(
          document.displayName,
          maxLines: 2,
          overflow:
              TextOverflow.ellipsis,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w600,
            color:
                AppTheme.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding:
              const EdgeInsets.only(
            top: 5,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              if (document
                      .originalFileName !=
                  null)
                Text(
                  document
                      .originalFileName!,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 13,
                    color:
                        AppTheme.textSecondary,
                  ),
                ),
              const SizedBox(
                height: 3,
              ),
              const Text(
                'לחץ לצפייה או הורדה',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      AppTheme.primary,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        trailing:
            canEditVehicle
                ? Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.chevron_left,
                        color:
                            AppTheme.primary,
                      ),
                      IconButton(
                        onPressed:
                            isBusy
                                ? null
                                : () {
                                    deleteDocument(
                                      document,
                                    );
                                  },
                        tooltip:
                            'מחיקה',
                        icon:
                            const Icon(
                          Icons.delete_outline,
                          color:
                              AppTheme.danger,
                        ),
                      ),
                    ],
                  )
                : const Icon(
                    Icons.chevron_left,
                    color:
                        AppTheme.primary,
                  ),
      ),
    );
  }

  List<Widget>
      buildDocumentSections() {
    final widgets =
        <Widget>[];

    for (final category
        in VehicleDocumentCategory.values) {
      final categoryDocuments =
          documents
              .where(
                (document) =>
                    document.category ==
                    category,
              )
              .toList();

      if (categoryDocuments.isEmpty) {
        continue;
      }

      widgets.add(
        buildCategoryHeader(
          category: category,
          count:
              categoryDocuments.length,
        ),
      );

      widgets.addAll(
        categoryDocuments.map(
          buildDocumentCard,
        ),
      );

      widgets.add(
        const SizedBox(
          height: 8,
        ),
      );
    }

    return widgets;
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

                  loadDocuments();
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

    return RefreshIndicator(
      onRefresh:
          loadDocuments,
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
                  'ניתן לצפות במסמכי הרכב, '
                  'אך לא להעלות או למחוק אותם.',
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
          if (documents.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(
                top: 80,
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.folder_open_outlined,
                    size: 56,
                    color:
                        AppTheme.textSecondary,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  const Text(
                    'עדיין אין מסמכים לרכב',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          AppTheme.textPrimary,
                    ),
                  ),
                  if (canEditVehicle) ...[
                    const SizedBox(
                      height: 8,
                    ),
                    const Text(
                      'אפשר להעלות PDF או תמונה.',
                      style: TextStyle(
                        color:
                            AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            ...buildDocumentSections(),
        ],
      ),
    );
  }

  Widget buildFloatingButton() {
    return FloatingActionButton.extended(
      onPressed:
          isBusy
              ? null
              : pickAndUploadDocument,
      icon: const Icon(
        Icons.upload_file_outlined,
      ),
      label: const Text(
        'העלה מסמך',
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar:
          widget.embedded
              ? null
              : AppBar(
                  title:
                      const Text(
                    'מסמכי הרכב',
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
      body: Column(
        children: [
          if (widget.embedded &&
              isBusy)
            const LinearProgressIndicator(),
          Expanded(
            child:
                buildBody(),
          ),
        ],
      ),
      floatingActionButton:
          canEditVehicle &&
                  !isLoading &&
                  errorMessage == null
              ? buildFloatingButton()
              : null,
    );
  }
}