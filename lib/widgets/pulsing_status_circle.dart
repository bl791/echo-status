import 'package:flutter/material.dart';
import '../models/site.dart';

class PulsingStatusCircle extends StatefulWidget {
  final Site? site;

  const PulsingStatusCircle({super.key, this.site});

  @override
  State<PulsingStatusCircle> createState() => _PulsingStatusCircleState();
}

class _PulsingStatusCircleState extends State<PulsingStatusCircle>
    with TickerProviderStateMixin {
  late AnimationController _pulseController1;
  late AnimationController _pulseController2;
  late Animation<double> _scaleAnimation1;
  late Animation<double> _opacityAnimation1;
  late Animation<double> _scaleAnimation2;
  late Animation<double> _opacityAnimation2;

  @override
  void initState() {
    super.initState();

    _pulseController1 = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _pulseController2 = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _pulseController2.repeat();
      }
    });

    _scaleAnimation1 = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController1, curve: Curves.easeOut),
    );
    _opacityAnimation1 = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController1, curve: Curves.easeOut),
    );

    _scaleAnimation2 = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController2, curve: Curves.easeOut),
    );
    _opacityAnimation2 = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController2, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController1.dispose();
    _pulseController2.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    if (widget.site == null || widget.site!.lastChecked == null) {
      return Colors.grey;
    }
    return widget.site!.isUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final isUp = widget.site?.isUp ?? false;
    final hasData = widget.site?.lastChecked != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final circleSize = size.clamp(80.0, 180.0);
        final innerSize = circleSize * 0.67;
        final iconSize = circleSize * 0.31;

        return SizedBox(
          width: circleSize,
          height: circleSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing rings (only when up)
              if (hasData && isUp) ...[
                AnimatedBuilder(
                  animation: _pulseController1,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation1.value,
                      child: Opacity(
                        opacity: _opacityAnimation1.value,
                        child: Container(
                          width: circleSize,
                          height: circleSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: _pulseController2,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation2.value,
                      child: Opacity(
                        opacity: _opacityAnimation2.value,
                        child: Container(
                          width: circleSize,
                          height: circleSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],

              // Outer ring
              Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withValues(alpha: 0.2),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 3,
                  ),
                ),
              ),

              // Inner circle
              Container(
                width: innerSize,
                height: innerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                ),
                child: Icon(
                  Icons.dns_rounded,
                  size: iconSize,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
