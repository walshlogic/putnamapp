import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage_service.dart';

/// Provider for StorageService
final storageServiceProvider = FutureProvider<StorageService>((ref) async {
  return SharedPreferencesStorageService.getInstance();
});

