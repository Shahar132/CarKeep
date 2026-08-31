import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../lib/models/vehicle_document.dart';
import '../../lib/repositories/vehicle_document_repository.dart';

void main() {
  late SupabaseClient testSupabase;
  late VehicleDocumentRepository repository;

  setUp(() {
    testSupabase = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
    );

    repository =
        VehicleDocumentRepository(
      supabase: testSupabase,
    );
  });

  group(
    'VehicleDocumentRepository.deleteDocument',
    () {
      test(
        'throws ArgumentError when document id is null',
        () async {
          const document =
              VehicleDocument(
            displayName: 'מסמך בדיקה',
            filePath:
                'vehicle-1/test.pdf',
          );

          expect(
            () => repository
                .deleteDocument(document),
            throwsArgumentError,
          );
        },
      );
    },
  );
}