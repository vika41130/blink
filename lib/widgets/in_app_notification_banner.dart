import 'package:blink/settings/fixed_settings.dart';
import 'package:flutter/material.dart';

void showOverlay(
  BuildContext context,
  String title,
  String body,
  VoidCallback onTap,
) {
  try {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _InAppNotificationBanner(
        title: title,
        body: body,
        onTap: () {
          if (entry.mounted) entry.remove();
          onTap();
        },
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
    });
  } catch (_) {}
}

class _InAppNotificationBanner extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _InAppNotificationBanner({
    required this.title,
    required this.body,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      top: MediaQuery.of(context).padding.top + appPaddingSmall,
      left: appPadding,
      right: appPadding,
      child: GestureDetector(
        onTap: onTap,
        onVerticalDragEnd: (_) => onDismiss(),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(appPaddingSmall),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(appPaddingSmall),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: appIconMidSize, color: theme.colorScheme.primary),
                const SizedBox(width: appPaddingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: fontSizeMedium,
                            color: theme.colorScheme.onSurface,
                          )),
                      if (body.isNotEmpty)
                        Text(body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: fontSizeSmall,
                              color: theme.colorScheme.onSurfaceVariant,
                            )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
