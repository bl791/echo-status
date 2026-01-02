import 'package:hive/hive.dart';

part 'site.g.dart';

@HiveType(typeId: 0)
class Site extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String url;

  @HiveField(3)
  bool isUp;

  @HiveField(4)
  DateTime? lastChecked;

  @HiveField(5)
  int? responseTimeMs;

  @HiveField(6)
  List<StatusCheck> statusHistory;

  @HiveField(7)
  bool isPinned;

  @HiveField(8)
  int sortOrder;

  Site({
    required this.id,
    required this.name,
    required this.url,
    this.isUp = false,
    this.lastChecked,
    this.responseTimeMs,
    List<StatusCheck>? statusHistory,
    this.isPinned = false,
    this.sortOrder = 0,
  }) : statusHistory = statusHistory ?? [];

  double get uptimePercentage {
    if (statusHistory.isEmpty) return 0;
    final upCount = statusHistory.where((s) => s.isUp).length;
    return (upCount / statusHistory.length) * 100;
  }

  /// Get uptime percentage for last 30 days
  double get uptimePercentage30Days {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentChecks = statusHistory.where(
      (s) => s.timestamp.isAfter(thirtyDaysAgo),
    ).toList();
    if (recentChecks.isEmpty) return 0;
    final upCount = recentChecks.where((s) => s.isUp).length;
    return (upCount / recentChecks.length) * 100;
  }

  /// Get daily status summaries for past 30 days (for status bar)
  List<DailyStatus> get dailyStatusHistory {
    final now = DateTime.now();
    final result = <DailyStatus>[];

    for (int i = 29; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final nextDate = date.add(const Duration(days: 1));

      final checksForDay = statusHistory.where((s) =>
        s.timestamp.isAfter(date) && s.timestamp.isBefore(nextDate)
      ).toList();

      if (checksForDay.isEmpty) {
        result.add(DailyStatus(date: date, status: DayStatus.noData));
      } else {
        final upCount = checksForDay.where((s) => s.isUp).length;
        final percentage = upCount / checksForDay.length;

        if (percentage >= 0.99) {
          result.add(DailyStatus(date: date, status: DayStatus.up, uptimePercent: percentage * 100));
        } else if (percentage >= 0.9) {
          result.add(DailyStatus(date: date, status: DayStatus.degraded, uptimePercent: percentage * 100));
        } else {
          result.add(DailyStatus(date: date, status: DayStatus.down, uptimePercent: percentage * 100));
        }
      }
    }

    return result;
  }

  /// Prune old status checks based on retention period
  void pruneOldChecks([int retentionDays = 30]) {
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    statusHistory.removeWhere((s) => s.timestamp.isBefore(cutoff));
  }

  /// Get list of downtime incidents (consecutive down periods)
  List<DowntimeIncident> get downtimeIncidents {
    if (statusHistory.isEmpty) return [];

    final incidents = <DowntimeIncident>[];
    final sortedChecks = List<StatusCheck>.from(statusHistory)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    DateTime? incidentStart;
    String? lastError;

    for (int i = 0; i < sortedChecks.length; i++) {
      final check = sortedChecks[i];

      if (!check.isUp) {
        // Site is down
        if (incidentStart == null) {
          incidentStart = check.timestamp;
          lastError = check.errorMessage;
        }
      } else {
        // Site is up - close any open incident
        if (incidentStart != null) {
          incidents.add(DowntimeIncident(
            startTime: incidentStart,
            endTime: check.timestamp,
            errorMessage: lastError,
          ));
          incidentStart = null;
          lastError = null;
        }
      }
    }

    // Handle ongoing incident (still down)
    if (incidentStart != null) {
      incidents.add(DowntimeIncident(
        startTime: incidentStart,
        endTime: null, // Still ongoing
        errorMessage: lastError,
      ));
    }

    // Return most recent first
    return incidents.reversed.toList();
  }
}

class DowntimeIncident {
  final DateTime startTime;
  final DateTime? endTime; // null if still ongoing
  final String? errorMessage;

  DowntimeIncident({
    required this.startTime,
    this.endTime,
    this.errorMessage,
  });

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  bool get isOngoing => endTime == null;

  String get durationString {
    final d = duration;
    if (d.inDays > 0) {
      return '${d.inDays}d ${d.inHours % 24}h ${d.inMinutes % 60}m';
    } else if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    } else if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds % 60}s';
    } else {
      return '${d.inSeconds}s';
    }
  }
}

enum DayStatus { up, degraded, down, noData }

class DailyStatus {
  final DateTime date;
  final DayStatus status;
  final double? uptimePercent;

  DailyStatus({
    required this.date,
    required this.status,
    this.uptimePercent,
  });
}

@HiveType(typeId: 1)
class StatusCheck {
  @HiveField(0)
  final DateTime timestamp;

  @HiveField(1)
  final bool isUp;

  @HiveField(2)
  final int? responseTimeMs;

  @HiveField(3)
  final String? errorMessage;

  StatusCheck({
    required this.timestamp,
    required this.isUp,
    this.responseTimeMs,
    this.errorMessage,
  });
}
