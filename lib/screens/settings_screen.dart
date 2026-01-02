import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService storageService;
  final VoidCallback onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.storageService,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _pollIntervalSeconds;
  late int _dataRetentionDays;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final settings = widget.storageService.getSettings();
    _pollIntervalSeconds = settings.pollIntervalSeconds;
    _dataRetentionDays = settings.dataRetentionDays;
  }

  Future<void> _saveSettings() async {
    final settings = AppSettings(
      pollIntervalSeconds: _pollIntervalSeconds,
      dataRetentionDays: _dataRetentionDays,
    );
    await widget.storageService.updateSettings(settings);
    widget.onSettingsChanged();
    setState(() => _hasChanges = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Settings saved'),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  String _formatPollInterval(int seconds) {
    if (seconds < 60) {
      return '$seconds seconds';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '$minutes minute${minutes == 1 ? '' : 's'}';
    } else {
      final hours = seconds ~/ 3600;
      return '$hours hour${hours == 1 ? '' : 's'}';
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Settings',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveSettings,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Poll Interval Section
          _buildSectionHeader('Monitoring', Icons.timer_outlined),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Poll Interval',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatPollInterval(_pollIntervalSeconds),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'How often to check each site',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Slider(
                  value: _pollIntervalSeconds.toDouble(),
                  min: AppSettings.minPollSeconds.toDouble(),
                  max: AppSettings.maxPollSeconds.toDouble(),
                  divisions: 35,
                  activeColor: Colors.blue,
                  inactiveColor: const Color(0xFF27272A),
                  onChanged: (value) {
                    setState(() {
                      _pollIntervalSeconds = value.round();
                      _hasChanges = true;
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '10s',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      Text(
                        '1h',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Data Retention Section
          _buildSectionHeader('Data Storage', Icons.storage_outlined),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Data Retention',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_dataRetentionDays day${_dataRetentionDays == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'How long to keep status history',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Slider(
                  value: _dataRetentionDays.toDouble(),
                  min: AppSettings.minRetentionDays.toDouble(),
                  max: AppSettings.maxRetentionDays.toDouble(),
                  divisions: 364,
                  activeColor: Colors.blue,
                  inactiveColor: const Color(0xFF27272A),
                  onChanged: (value) {
                    setState(() {
                      _dataRetentionDays = value.round();
                      _hasChanges = true;
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '1 day',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      Text(
                        '365 days',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick presets
          _buildSectionHeader('Quick Presets', Icons.flash_on_outlined),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPresetButton(
                  'Light',
                  '5 min poll\n7 days',
                  () {
                    setState(() {
                      _pollIntervalSeconds = 300;
                      _dataRetentionDays = 7;
                      _hasChanges = true;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPresetButton(
                  'Default',
                  '30s poll\n30 days',
                  () {
                    setState(() {
                      _pollIntervalSeconds = 30;
                      _dataRetentionDays = 30;
                      _hasChanges = true;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPresetButton(
                  'Intensive',
                  '10s poll\n90 days',
                  () {
                    setState(() {
                      _pollIntervalSeconds = 10;
                      _dataRetentionDays = 90;
                      _hasChanges = true;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey[500],
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetButton(String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
