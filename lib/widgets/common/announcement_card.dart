import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

/// Tag type controlling the badge colour and label on an announcement card.
enum AnnouncementTag { meeting, urgent, newItem, info }

extension _AnnouncementTagStyle on AnnouncementTag {
  String get label => switch (this) {
    AnnouncementTag.meeting => 'MEETING',
    AnnouncementTag.urgent  => 'URGENT',
    AnnouncementTag.newItem => 'NEW',
    AnnouncementTag.info    => 'INFO',
  };

  Color get background => switch (this) {
    AnnouncementTag.meeting => const Color(0xFFFFE4E6), // blue-100
    AnnouncementTag.urgent  => const Color(0xFFFEE2E2), // red-100
    AnnouncementTag.newItem => const Color(0xFFDCFCE7), // green-100
    AnnouncementTag.info    => const Color(0xFFFEF3C7), // amber-100
  };

  Color get foreground => switch (this) {
    AnnouncementTag.meeting => const Color(0xFF4F46E5), // indigo-600
    AnnouncementTag.urgent  => const Color(0xFFB91C1C), // red-700
    AnnouncementTag.newItem => const Color(0xFF15803D), // green-700
    AnnouncementTag.info    => const Color(0xFFB45309), // amber-700
  };
}

/// Full-width vertical card used in the dashboard announcement list.
///
/// Shows a color-coded [tag] badge, title, body text, and an optional
/// meta line (location/time or posted-ago string).
class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({
    super.key,
    required this.tag,
    required this.title,
    required this.body,
    this.meta,
    this.metaIcon,
    this.onTap,
  });

  final AnnouncementTag tag;
  final String title;
  final String body;

  /// Optional footer line, e.g. "Conf Room B • 10:00 AM" or "Posted 2h ago".
  final String? meta;

  /// Icon shown to the left of [meta]. Defaults to [Icons.access_time_outlined].
  final IconData? metaIcon;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tag badge ──────────────────────────────────────────────────
            _TagBadge(tag: tag),
            const SizedBox(height: AppDimensions.spacingSm),

            // ── Title ──────────────────────────────────────────────────────
            Text(title, style: AppTextStyles.bodyBold.copyWith(fontSize: 16)),
            const SizedBox(height: AppDimensions.spacingXs + 2),

            // ── Body ───────────────────────────────────────────────────────
            Text(
              body,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.slate600,
                height: 1.5,
              ),
            ),

            // ── Meta footer ────────────────────────────────────────────────
            if (meta != null) ...[
              const SizedBox(height: AppDimensions.spacingSm),
              Row(
                children: [
                  Icon(
                    metaIcon ?? Icons.access_time_outlined,
                    size: 14,
                    color: AppColors.slate400,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      meta!,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.slate400,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  const _TagBadge({required this.tag});

  final AnnouncementTag tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tag.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        tag.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: tag.foreground,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}