import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/site.dart';
import '../services/storage_service.dart';
import '../services/uptime_service.dart';
import '../widgets/pulsing_status_circle.dart';
import '../widgets/site_list_item.dart';
import '../widgets/add_site_dialog.dart';
import '../widgets/status_history_bar.dart';
import 'site_detail_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storageService;

  const HomeScreen({super.key, required this.storageService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UptimeService _uptimeService = UptimeService();
  Timer? _refreshTimer;
  bool _isChecking = false;
  String? _selectedSiteId;

  @override
  void initState() {
    super.initState();
    _checkAllSites();
    _startPolling();
  }

  void _startPolling() {
    _refreshTimer?.cancel();
    final settings = widget.storageService.getSettings();
    _refreshTimer = Timer.periodic(
      Duration(seconds: settings.pollIntervalSeconds),
      (_) => _checkAllSites(),
    );
  }

  void _onSettingsChanged() {
    _startPolling(); // Restart polling with new interval
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _uptimeService.dispose();
    super.dispose();
  }

  Future<void> _checkAllSites() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);

    final settings = widget.storageService.getSettings();
    final sites = widget.storageService.getAllSites();
    for (final site in sites) {
      await _uptimeService.checkAndUpdateSite(site, settings.dataRetentionDays);
      await widget.storageService.updateSite(site);
    }

    setState(() => _isChecking = false);
  }

  Future<void> _addSite() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const AddSiteDialog(),
    );

    if (result != null) {
      final site = Site(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: result['name']!,
        url: result['url']!,
      );

      await widget.storageService.addSite(site);
      await _uptimeService.checkAndUpdateSite(site);
      await widget.storageService.updateSite(site);

      setState(() {
        _selectedSiteId = site.id;
      });
    }
  }

  List<Site> _sortSites(List<Site> sites) {
    final sorted = List<Site>.from(sites);
    sorted.sort((a, b) {
      // Pinned items first
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      // Then by sort order
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return sorted;
  }

  Future<void> _togglePin(Site site) async {
    site.isPinned = !site.isPinned;
    await widget.storageService.updateSite(site);
    setState(() {});
  }

  Future<void> _reorderSites(int oldIndex, int newIndex) async {
    final sites = _sortSites(widget.storageService.getAllSites());
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final site = sites.removeAt(oldIndex);
    sites.insert(newIndex, site);

    // Update sort orders
    for (int i = 0; i < sites.length; i++) {
      sites[i].sortOrder = i;
      await widget.storageService.updateSite(sites[i]);
    }
    setState(() {});
  }

  Future<void> _deleteSite(Site site) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF27272A)),
        ),
        title: const Text('Delete Site'),
        content: Text('Are you sure you want to delete "${site.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (_selectedSiteId == site.id) {
        setState(() => _selectedSiteId = null);
      }
      await widget.storageService.deleteSite(site.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF27272A)),
                ),
              ),
              child: ValueListenableBuilder<Box<Site>>(
                valueListenable: widget.storageService.sitesBox.listenable(),
                builder: (context, box, _) {
                  final sites = box.values.toList();
                  final upCount =
                      sites.where((s) => s.lastChecked != null && s.isUp).length;
                  final downCount =
                      sites.where((s) => s.lastChecked != null && !s.isUp).length;

                  return Row(
                    children: [
                      const Icon(
                        Icons.monitor_heart_outlined,
                        size: 18,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Echo Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_isChecking)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Text(
                              '$upCount',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF22C55E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$downCount',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          size: 20,
                          color: Colors.grey[500],
                        ),
                        color: const Color(0xFF18181B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFF27272A)),
                        ),
                        onSelected: (value) {
                          if (value == 'settings') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SettingsScreen(
                                  storageService: widget.storageService,
                                  onSettingsChanged: _onSettingsChanged,
                                ),
                              ),
                            );
                          } else if (value == 'about') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AboutScreen(),
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'settings',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.settings_outlined,
                                  size: 18,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(width: 12),
                                const Text('Settings'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'about',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(width: 12),
                                const Text('About'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            // Main content
            Expanded(
              child: ValueListenableBuilder<Box<Site>>(
                valueListenable: widget.storageService.sitesBox.listenable(),
                builder: (context, box, _) {
                  final unsortedSites = box.values.toList();

                  if (unsortedSites.isEmpty) {
                    return _buildEmptyState();
                  }

                  final sites = _sortSites(unsortedSites);

                  // Select first site if none selected
                  if (_selectedSiteId == null && sites.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() => _selectedSiteId = sites.first.id);
                    });
                  }

                  final selectedSite = sites.firstWhere(
                    (s) => s.id == _selectedSiteId,
                    orElse: () => sites.first,
                  );

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // Use side-by-side layout on wider screens
                      if (constraints.maxWidth > 600) {
                        return _buildWideLayout(sites, selectedSite);
                      }
                      return _buildNarrowLayout(sites, selectedSite);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSite,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.monitor_heart_outlined,
            size: 80,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            'No sites monitored',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add a site',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(List<Site> sites, Site selectedSite) {
    return Row(
      children: [
        // Left side - Big circle
        Expanded(
          child: _buildSelectedSiteDisplay(selectedSite),
        ),

        // Right side - Monitor list
        Container(
          width: 220,
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: Color(0xFF27272A)),
            ),
          ),
          child: _buildSiteList(sites),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(List<Site> sites, Site selectedSite) {
    return Column(
      children: [
        // Top - Big circle
        Expanded(
          flex: 3,
          child: _buildSelectedSiteDisplay(selectedSite),
        ),

        // Bottom - Monitor list
        Expanded(
          flex: 2,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF27272A)),
              ),
            ),
            child: _buildHorizontalSiteList(sites),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedSiteDisplay(Site site) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SiteDetailScreen(
              site: site,
              storageService: widget.storageService,
              uptimeService: _uptimeService,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing circle
            Flexible(
              flex: 3,
              child: PulsingStatusCircle(site: site),
            ),
            const SizedBox(height: 12),

            // Monitor info
            Text(
              site.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              site.url,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStat(
                  'Uptime (30d)',
                  '${site.uptimePercentage30Days.toStringAsFixed(1)}%',
                  site.isUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: const Color(0xFF27272A),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                _buildStat(
                  'Response',
                  '${site.responseTimeMs ?? 0}ms',
                  Colors.grey[400]!,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 30-day status history bar
            StatusHistoryBar(site: site),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSiteList(List<Site> sites) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ALL MONITORS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              ),
              GestureDetector(
                onTap: _isChecking ? null : _checkAllSites,
                child: Icon(
                  Icons.refresh,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: sites.length,
            onReorder: _reorderSites,
            proxyDecorator: (child, index, animation) {
              return Material(
                color: Colors.transparent,
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.3),
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final site = sites[index];
              return SiteListItem(
                key: ValueKey(site.id),
                site: site,
                isSelected: site.id == _selectedSiteId,
                onTap: () => setState(() => _selectedSiteId = site.id),
                onDelete: () => _deleteSite(site),
                onTogglePin: () => _togglePin(site),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalSiteList(List<Site> sites) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ALL MONITORS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              ),
              GestureDetector(
                onTap: _isChecking ? null : _checkAllSites,
                child: Icon(
                  Icons.refresh,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: sites.length,
            onReorder: _reorderSites,
            proxyDecorator: (child, index, animation) {
              return Material(
                color: Colors.transparent,
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.3),
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final site = sites[index];
              return Container(
                key: ValueKey(site.id),
                width: 140,
                margin: const EdgeInsets.only(right: 8),
                child: SiteListItem(
                  site: site,
                  isSelected: site.id == _selectedSiteId,
                  onTap: () => setState(() => _selectedSiteId = site.id),
                  onDelete: () => _deleteSite(site),
                  onTogglePin: () => _togglePin(site),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
