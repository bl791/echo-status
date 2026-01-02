import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/site.dart';

class IncidentsScreen extends StatelessWidget {
  final Site site;

  const IncidentsScreen({super.key, required this.site});

  @override
  Widget build(BuildContext context) {
    final incidents = site.downtimeIncidents;
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('HH:mm:ss');

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Downtime Incidents',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // Summary header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF27272A)),
              ),
            ),
            child: Row(
              children: [
                _buildSummaryCard(
                  context,
                  'Total Incidents',
                  '${incidents.length}',
                  Icons.warning_amber_rounded,
                  const Color(0xFFEF4444),
                ),
                const SizedBox(width: 12),
                _buildSummaryCard(
                  context,
                  'Total Downtime',
                  _getTotalDowntime(incidents),
                  Icons.timer_outlined,
                  const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),

          // Incidents list
          Expanded(
            child: incidents.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: incidents.length,
                    itemBuilder: (context, index) {
                      final incident = incidents[index];
                      return _buildIncidentCard(
                        context,
                        incident,
                        dateFormat,
                        timeFormat,
                        index + 1,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: const Color(0xFF22C55E).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No incidents recorded',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All systems have been operational',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(
    BuildContext context,
    DowntimeIncident incident,
    DateFormat dateFormat,
    DateFormat timeFormat,
    int number,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: incident.isOngoing
              ? const Color(0xFFEF4444).withValues(alpha: 0.5)
              : const Color(0xFF27272A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: incident.isOngoing
                  ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: incident.isOngoing
                        ? const Color(0xFFEF4444)
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  incident.isOngoing ? 'Ongoing Incident' : 'Incident #$number',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: incident.isOngoing
                        ? const Color(0xFFEF4444)
                        : Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: incident.isOngoing
                        ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                        : const Color(0xFF27272A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    incident.durationString,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: incident.isOngoing
                          ? const Color(0xFFEF4444)
                          : Colors.grey[400],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildDetailRow(
                  'Started',
                  '${dateFormat.format(incident.startTime)} at ${timeFormat.format(incident.startTime)}',
                  Icons.play_arrow_rounded,
                  const Color(0xFFEF4444),
                ),
                const SizedBox(height: 10),
                _buildDetailRow(
                  'Ended',
                  incident.isOngoing
                      ? 'Still ongoing...'
                      : '${dateFormat.format(incident.endTime!)} at ${timeFormat.format(incident.endTime!)}',
                  Icons.stop_rounded,
                  incident.isOngoing
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF22C55E),
                ),
                if (incident.errorMessage != null) ...[
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    'Error',
                    incident.errorMessage!,
                    Icons.error_outline,
                    Colors.grey[500]!,
                    isError: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    Color iconColor, {
    bool isError = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 10),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: isError ? Colors.grey[500] : Colors.white,
              fontWeight: isError ? FontWeight.normal : FontWeight.w500,
            ),
            maxLines: isError ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getTotalDowntime(List<DowntimeIncident> incidents) {
    if (incidents.isEmpty) return '0s';

    final totalDuration = incidents.fold<Duration>(
      Duration.zero,
      (total, incident) => total + incident.duration,
    );

    if (totalDuration.inDays > 0) {
      return '${totalDuration.inDays}d ${totalDuration.inHours % 24}h';
    } else if (totalDuration.inHours > 0) {
      return '${totalDuration.inHours}h ${totalDuration.inMinutes % 60}m';
    } else if (totalDuration.inMinutes > 0) {
      return '${totalDuration.inMinutes}m ${totalDuration.inSeconds % 60}s';
    } else {
      return '${totalDuration.inSeconds}s';
    }
  }
}
