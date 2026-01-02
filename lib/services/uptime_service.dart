import 'package:http/http.dart' as http;
import '../models/site.dart';

class UptimeService {
  // Persistent client to reuse connections (skips DNS/TCP/TLS after first request)
  final http.Client _client = http.Client();

  Future<StatusCheck> checkSite(String url) async {
    final stopwatch = Stopwatch()..start();

    try {
      final uri = Uri.parse(url);
      // Use HEAD request - smaller response, measures server response time more accurately
      final response = await _client.head(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      stopwatch.stop();
      final responseTime = stopwatch.elapsedMilliseconds;

      final isUp = response.statusCode >= 200 && response.statusCode < 400;

      return StatusCheck(
        timestamp: DateTime.now(),
        isUp: isUp,
        responseTimeMs: responseTime,
        errorMessage: isUp ? null : 'HTTP ${response.statusCode}',
      );
    } catch (e) {
      stopwatch.stop();
      return StatusCheck(
        timestamp: DateTime.now(),
        isUp: false,
        responseTimeMs: stopwatch.elapsedMilliseconds,
        errorMessage: e.toString(),
      );
    }
  }

  void dispose() {
    _client.close();
  }

  Future<void> checkAndUpdateSite(Site site, [int retentionDays = 30]) async {
    final result = await checkSite(site.url);

    site.isUp = result.isUp;
    site.lastChecked = result.timestamp;
    site.responseTimeMs = result.responseTimeMs;
    site.statusHistory.add(result);

    // Prune checks older than retention period
    site.pruneOldChecks(retentionDays);
  }
}
