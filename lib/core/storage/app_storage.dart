import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static const _recentFoldersKey = 'recent_folders';
  static const _maxRecentFolders = 10;

  final SharedPreferences _prefs;

  AppStorage(this._prefs);

  static Future<AppStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AppStorage(prefs);
  }

  List<String> getRecentFolders() {
    return _prefs.getStringList(_recentFoldersKey) ?? [];
  }

  Future<void> addRecentFolder(String path) async {
    final recent = getRecentFolders();
    recent.remove(path);
    recent.insert(0, path);

    if (recent.length > _maxRecentFolders) {
      recent.removeRange(_maxRecentFolders, recent.length);
    }

    await _prefs.setStringList(_recentFoldersKey, recent);
  }

  Future<void> removeRecentFolder(String path) async {
    final recent = getRecentFolders();
    recent.remove(path);
    await _prefs.setStringList(_recentFoldersKey, recent);
  }

  Future<void> clearRecentFolders() async {
    await _prefs.remove(_recentFoldersKey);
  }

  String? getLastOpenedFolder() {
    final recent = getRecentFolders();
    return recent.isEmpty ? null : recent.first;
  }
}
