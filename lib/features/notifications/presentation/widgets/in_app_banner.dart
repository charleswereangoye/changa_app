import 'dart:async';

import 'package:flutter/material.dart';

import 'package:changa_app/features/notifications/domain/entities/app_notification.dart';

/// Slides into view and dismisses automatically after four seconds.
class InAppBanner extends StatefulWidget {
  const InAppBanner({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
    this.displayDuration = const Duration(seconds: 4),
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final Duration displayDuration;

  @override
  State<InAppBanner> createState() => _InAppBannerState();
}

class _InAppBannerState extends State<InAppBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  Timer? _timer;
  bool _handled = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(curve);

    _fade = Tween<double>(begin: 0, end: 1).animate(curve);

    _start();
  }

  @override
  void didUpdateWidget(covariant InAppBanner oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.notification.id != widget.notification.id ||
        oldWidget.displayDuration != widget.displayDuration) {
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    _handled = false;
    _controller.forward(from: 0);

    _timer = Timer(widget.displayDuration, () => _runOnce(widget.onDismiss));
  }

  void _runOnce(VoidCallback callback) {
    if (!mounted || _handled) return;

    _handled = true;
    _timer?.cancel();
    callback();
  }

  IconData get _icon => switch (widget.notification.type) {
    'nudge' => Icons.send_rounded,
    'newExpense' => Icons.receipt_long_outlined,
    'settled' => Icons.check_circle_outline_rounded,
    'swapRequest' || 'swapResponse' => Icons.swap_horiz_rounded,
    _ => Icons.notifications_outlined,
  };

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Semantics(
          container: true,
          liveRegion: true,
          child: Material(
            color: colors.surface,
            elevation: 8,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    key: const Key('notification-banner-open'),
                    onTap: () => _runOnce(widget.onTap),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: colors.primaryContainer,
                            foregroundColor: colors.onPrimaryContainer,
                            child: Icon(_icon, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.notification.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.notification.body,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('notification-banner-dismiss'),
                  tooltip: 'Dismiss notification',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () => _runOnce(widget.onDismiss),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
