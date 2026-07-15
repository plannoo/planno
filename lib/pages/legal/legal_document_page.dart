import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

/// Renders a titled legal document (Privacy Policy, Terms of Service) from a
/// simple list of section headings + body paragraphs. Shared by
/// [PrivacyPolicyPage] and [TermsOfServicePage] so both stay visually
/// consistent without duplicating the scaffold/appbar boilerplate.
class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  final String title;
  final String lastUpdated;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.slate700),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: AppTextStyles.h5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePaddingH,
          vertical: AppDimensions.spacingMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Last updated: $lastUpdated',
                style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: AppDimensions.spaceLg),
            for (final section in sections) ...[
              Text(section.heading, style: AppTextStyles.h6),
              const SizedBox(height: 8),
              Text(section.body,
                  style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface)),
              const SizedBox(height: AppDimensions.spaceLg),
            ],
          ],
        ),
      ),
    );
  }
}

class LegalSection {
  const LegalSection(this.heading, this.body);
  final String heading;
  final String body;
}
