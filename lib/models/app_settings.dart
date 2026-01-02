import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 2)
class AppSettings extends HiveObject {
  @HiveField(0)
  int pollIntervalSeconds;

  @HiveField(1)
  int dataRetentionDays;

  AppSettings({
    this.pollIntervalSeconds = 30,
    this.dataRetentionDays = 30,
  });

  static const int minRetentionDays = 1;
  static const int maxRetentionDays = 365;
  static const int minPollSeconds = 10;
  static const int maxPollSeconds = 3600; // 1 hour
}
