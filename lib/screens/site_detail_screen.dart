import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/site.dart';
import '../services/storage_service.dart';
import '../services/uptime_service.dart';
import '../widgets/pulsing_status_circle.dart';
import '../widgets/status_history_bar.dart';

class SiteDetailScreen extends StatefulWidget {
  final Site site;
  final StorageService storageService;
  final UptimeService uptimeService;

  const SiteDetailScreen({
    super.key,
    required this.site,
    required this.storageService,
    required this.uptimeService,
  });

  @override
  State<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends State<SiteDetailScreen> {
  bool _isChecking = false;

  Future<void> _checkNow() async {
    setState(() => _isChecking = true);
    await widget.uptimeService.checkAndUpdateSite(widget.site);
    await widget.storageService.updateSite(widget.site);
    setState(() => _isChecking = false);
  }

  Color _getStatusColor() {
    if (widget.site.lastChecked == null) return Colors.grey;
    return widget.site.isUp
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final site = widget.site;
    final dateFormat = DateFormat('MMM d, HH:mm:ss');
    final statusColor = _getStatusColor();

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          site.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_isChecking)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, size: 22),
              onPressed: _checkNow,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  PulsingStatusCircle(site: site),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      site.isUp ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Stats grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF27272A)),
                ),
                child: Column(
                  children: [
                    _buildStatRow(
                      'URL',
                      site.url,
                      Icons.link,
                    ),
                    _buildDivider(),
                    _buildStatRow(
                      'Uptime',
                      '${site.uptimePercentage.toStringAsFixed(1)}%',
                      Icons.trending_up,
                      valueColor: statusColor,
                    ),
                    _buildDivider(),
                    _buildStatRow(
                      'Response Time',
                      '${site.responseTimeMs ?? 0}ms',
                      Icons.speed,
                    ),
                    _buildDivider(),
                    _buildStatRow(
                      'Last Checked',
                      site.lastChecked != null
                          ? dateFormat.format(site.lastChecked!)
                          : 'Never',
                      Icons.access_time,
                    ),
                    _buildDivider(),
                    _buildStatRow(
                      'Total Checks',
                      '${site.statusHistory.length}',
                      Icons.analytics_outlined,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 30-day status bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF27272A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '30-DAY STATUS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[500],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StatusHistoryBar(site: site),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // History section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'RECENT CHECKS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (site.statusHistory.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      child: Text(
                        'No history yet',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: site.statusHistory.length > 20
                            ? 20
                            : site.statusHistory.length,
                        separatorBuilder: (_, __) => _buildDivider(),
                        itemBuilder: (context, index) {
                          final check = site.statusHistory[
                              site.statusHistory.length - 1 - index];
                          final checkColor = check.isUp
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444);

                          return Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: checkColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dateFormat.format(check.timestamp),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (check.errorMessage != null)
                                        Text(
                                          check.errorMessage!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.red[400],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                if (check.responseTimeMs != null)
                                  Text(
                                    '${check.responseTimeMs}ms',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      color: Color(0xFF27272A),
    );
  }
}
