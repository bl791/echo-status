import 'package:hive_flutter/hive_flutter.dart';
import '../models/site.dart';
import '../models/app_settings.dart';

class StorageService {
  static const String _sitesBoxName = 'sites';
  static const String _settingsBoxName = 'settings';
  static const String _settingsKey = 'app_settings';

  late Box<Site> _sitesBox;
  late Box<AppSettings> _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(SiteAdapter());
    Hive.registerAdapter(StatusCheckAdapter());
    Hive.registerAdapter(AppSettingsAdapter());
    _sitesBox = await Hive.openBox<Site>(_sitesBoxName);
    _settingsBox = await Hive.openBox<AppSettings>(_settingsBoxName);

    // Initialize default settings if not exists
    if (_settingsBox.get(_settingsKey) == null) {
      await _settingsBox.put(_settingsKey, AppSettings());
    }
  }

  Box<Site> get sitesBox => _sitesBox;

  List<Site> getAllSites() {
    return _sitesBox.values.toList();
  }

  Future<void> addSite(Site site) async {
    await _sitesBox.put(site.id, site);
  }

  Future<void> updateSite(Site site) async {
    await site.save();
  }

  Future<void> deleteSite(String id) async {
    await _sitesBox.delete(id);
  }

  Site? getSite(String id) {
    return _sitesBox.get(id);
  }

  // Settings methods
  AppSettings getSettings() {
    return _settingsBox.get(_settingsKey) ?? AppSettings();
  }

  Future<void> updateSettings(AppSettings settings) async {
    await _settingsBox.put(_settingsKey, settings);
  }

  Box<AppSettings> get settingsBox => _settingsBox;
}
