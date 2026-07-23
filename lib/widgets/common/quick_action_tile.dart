import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Square icon + label quick-action tile for the dashboard grid.
///
/// Does NOT include [Expanded] — callers wrap each tile in [Expanded]
/// inside a [Row] so the 4 tiles share available width evenly.
class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.dotColor,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  /// When set, a coloured dot prefixes the label (e.g. green = active session).
  final Color? dotColor;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon container — 56×56 fits 4 tiles on a 360 dp screen
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),

          // Label row (dot + text)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTextStyles.labelMedium.fontSize,
                  fontWeight: FontWeight.w600,
                  color: dotColor ?? AppColors.slate700,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}