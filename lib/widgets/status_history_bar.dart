import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/site.dart';
import '../screens/incidents_screen.dart';

class StatusHistoryBar extends StatelessWidget {
  final Site site;
  final bool clickable;

  const StatusHistoryBar({
    super.key,
    required this.site,
    this.clickable = true,
  });

  @override
  Widget build(BuildContext context) {
    final dailyStatus = site.dailyStatusHistory;
    final incidents = site.downtimeIncidents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '30 days ago',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Today',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Status bars - clickable
        GestureDetector(
          onTap: clickable
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => IncidentsScreen(site: site),
                    ),
                  );
                }
              : null,
          child: SizedBox(
            height: 24,
            child: Row(
              children: dailyStatus.map((day) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Tooltip(
                      message: _getTooltipMessage(day),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getStatusColor(day.status),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Legend + incidents count
        Row(
          children: [
            _buildLegendItem('Up', const Color(0xFF22C55E)),
            const SizedBox(width: 12),
            _buildLegendItem('Degraded', const Color(0xFFF59E0B)),
            const SizedBox(width: 12),
            _buildLegendItem('Down', const Color(0xFFEF4444)),
            const Spacer(),
            if (clickable)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => IncidentsScreen(site: site),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      '${incidents.length} incident${incidents.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 10,
                        color: incidents.isEmpty
                            ? Colors.grey[600]
                            : const Color(0xFFEF4444),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(DayStatus status) {
    switch (status) {
      case DayStatus.up:
        return const Color(0xFF22C55E);
      case DayStatus.degraded:
        return const Color(0xFFF59E0B);
      case DayStatus.down:
        return const Color(0xFFEF4444);
      case DayStatus.noData:
        return const Color(0xFF3F3F46);
    }
  }

  String _getTooltipMessage(DailyStatus day) {
    final dateFormat = DateFormat('MMM d');
    final dateStr = dateFormat.format(day.date);

    switch (day.status) {
      case DayStatus.up:
        return '$dateStr: ${day.uptimePercent?.toStringAsFixed(1)}% uptime';
      case DayStatus.degraded:
        return '$dateStr: ${day.uptimePercent?.toStringAsFixed(1)}% uptime (degraded)';
      case DayStatus.down:
        return '$dateStr: ${day.uptimePercent?.toStringAsFixed(1)}% uptime (down)';
      case DayStatus.noData:
        return '$dateStr: No data';
    }
  }
}
