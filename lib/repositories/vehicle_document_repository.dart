import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vehicle_document.dart';

class VehicleDocumentRepository {
  final SupabaseClient? _injectedSupabase;

  VehicleDocumentRepository({
    SupabaseClient? supabase,
  }) : _injectedSupabase = supabase;

  SupabaseClient get supabase =>
      _injectedSupabase ??
      Supabase.instance.client;

  Future<VehicleDocument> uploadDocument({
    required String vehicleId,
    required String displayName,
    required String originalFileName,
    required Uint8List fileBytes,
    required VehicleDocumentCategory category,
    String? eventId,
  }) async {
    String? uploadedFilePath;
    String? insertedDocumentId;

    try {
      final safeFileName =
          _sanitizeFileName(
        originalFileName,
      );

      final timestamp =
          DateTime.now()
              .microsecondsSinceEpoch;

      uploadedFilePath =
          '$vehicleId/'
          '${timestamp}_$safeFileName';

      await supabase.storage
          .from('vehicle-documents')
          .uploadBinary(
        uploadedFilePath,
        fileBytes,
        fileOptions:
            const FileOptions(
          upsert: false,
        ),
      );

      final userId =
          supabase.auth.currentUser?.id;

      final insertedDocument =
          await supabase
              .from('documents')
              .insert({
                'vehicle_id':
                    vehicleId,
                'event_id':
                    eventId,
                'display_name':
                    displayName,
                'original_file_name':
                    originalFileName,
                'file_path':
                    uploadedFilePath,
                'category':
                    category.databaseValue,
                'uploaded_by':
                    userId,
              })
              .select()
              .single();

      insertedDocumentId =
          insertedDocument['id']
              as String?;

      return VehicleDocument.fromMap(
        insertedDocument,
      );
    } catch (error) {
      if (insertedDocumentId != null) {
        try {
          await supabase
              .from('documents')
              .delete()
              .eq(
                'id',
                insertedDocumentId,
              );
        } catch (rollbackError) {
          debugPrint(
            'Error rolling back document row: '
            '$rollbackError',
          );
        }
      }

      if (uploadedFilePath != null) {
        try {
          await supabase.storage
              .from(
                'vehicle-documents',
              )
              .remove([
            uploadedFilePath,
          ]);
        } catch (rollbackError) {
          debugPrint(
            'Error rolling back document file: '
            '$rollbackError',
          );
        }
      }

      rethrow;
    }
  }

  Future<void> deleteDocument(
    VehicleDocument document,
  ) async {
    final documentId =
        document.id;

    if (documentId == null) {
      throw ArgumentError(
        'Document id is required.',
      );
    }

    await supabase
        .from('documents')
        .delete()
        .eq(
          'id',
          documentId,
        );

    try {
      await supabase.storage
          .from('vehicle-documents')
          .remove([
        document.filePath,
      ]);
    } catch (error) {
      debugPrint(
        'Document row deleted, but Storage '
        'cleanup failed: $error',
      );
    }
  }

  String _sanitizeFileName(
    String fileName,
  ) {
    return fileName.replaceAll(
      RegExp(
        r'[^a-zA-Z0-9._-]',
      ),
      '_',
    );
  }
}