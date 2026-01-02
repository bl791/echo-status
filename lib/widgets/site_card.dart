import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/site.dart';

class SiteCard extends StatelessWidget {
  final Site site;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const SiteCard({
    super.key,
    required this.site,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final lastChecked = site.lastChecked;
    final timeAgo = lastChecked != null
        ? _formatTimeAgo(lastChecked)
        : 'Never checked';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: site.lastChecked == null
                      ? Colors.grey
                      : site.isUp
                          ? Colors.green
                          : Colors.red,
                ),
              ),
              const SizedBox(width: 16),

              // Site info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      site.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      site.url,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          timeAgo,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                        ),
                        if (site.responseTimeMs != null) ...[
                          Text(
                            ' • ',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                          Text(
                            '${site.responseTimeMs} ms',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[500],
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Uptime percentage
              if (site.statusHistory.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getUptimeColor(site.uptimePercentage)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${site.uptimePercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: _getUptimeColor(site.uptimePercentage),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  Color _getUptimeColor(double percentage) {
    if (percentage >= 99) return Colors.green;
    if (percentage >= 95) return Colors.orange;
    return Colors.red;
  }
}
