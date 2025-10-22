import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_storage.dart';

final appStorageProvider = FutureProvider<AppStorage>((ref) async {
  return await AppStorage.create();
});

final recentFoldersProvider = FutureProvider<List<String>>((ref) async {
  final storage = await ref.watch(appStorageProvider.future);
  return storage.getRecentFolders();
});
