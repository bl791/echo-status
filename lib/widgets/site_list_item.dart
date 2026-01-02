import 'package:flutter/material.dart';
import '../models/site.dart';

class SiteListItem extends StatefulWidget {
  final Site site;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onTogglePin;

  const SiteListItem({
    super.key,
    required this.site,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    this.onTogglePin,
  });

  @override
  State<SiteListItem> createState() => _SiteListItemState();
}

class _SiteListItemState extends State<SiteListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    if (widget.site.lastChecked == null) return Colors.grey;
    return widget.site.isUp
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                widget.site.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                color: Colors.blue,
              ),
              title: Text(widget.site.isPinned ? 'Unpin' : 'Pin to top'),
              onTap: () {
                Navigator.pop(context);
                widget.onTogglePin?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                widget.onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final isUp = widget.site.isUp;
    final hasData = widget.site.lastChecked != null;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: () => _showContextMenu(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? const Color(0xFF27272A)
              : const Color(0xFF18181B).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.isSelected
                ? statusColor.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Pulsing status dot
                SizedBox(
                  width: 10,
                  height: 10,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (hasData && isUp)
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Opacity(
                                opacity: _opacityAnimation.value,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.dns_outlined,
                  size: 12,
                  color: Colors.grey[600],
                ),
                const Spacer(),
                if (widget.site.isPinned)
                  GestureDetector(
                    onTap: widget.onTogglePin,
                    child: Icon(
                      Icons.push_pin,
                      size: 12,
                      color: Colors.blue.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.site.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.site.uptimePercentage.toStringAsFixed(0)}% · ${widget.site.responseTimeMs ?? 0}ms',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
