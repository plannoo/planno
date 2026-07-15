import 'package:flutter/material.dart';

import 'legal_document_page.dart';

/// NOTE: Drafted from the app's actual functionality, not reviewed by a
/// lawyer. Get this reviewed by counsel before relying on it for a public
/// launch — in particular liability limitation and governing-law clauses are
/// jurisdiction-specific and need real legal input.
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentPage(
      title: 'Terms of Service',
      lastUpdated: '2026-07-02',
      sections: [
        LegalSection(
          'Who this is for',
          'This app is provided to you by your employer for work-related '
          'scheduling, time tracking, and communication. Your access is tied '
          'to your employment or engagement with that organization.',
        ),
        LegalSection(
          'Your account',
          'You\'re responsible for keeping your login credentials and clock-in '
          'PIN confidential, and for any activity recorded under your '
          'account. Tell your administrator immediately if you suspect '
          'unauthorized access.',
        ),
        LegalSection(
          'Accurate use',
          'Time and location data recorded through this app (clock-in/out, '
          'GPS confirmation, biometric checks) may be used by your '
          'organization for payroll, scheduling, and attendance records. '
          'Submitting false clock records is a violation of these terms and '
          'may also violate your employment agreement.',
        ),
        LegalSection(
          'Acceptable use',
          'Don\'t use the in-app chat or any feature of this app to harass, '
          'threaten, or discriminate against colleagues, or to share content '
          'unrelated to work that violates your organization\'s policies.',
        ),
        LegalSection(
          'Availability',
          'We aim to keep the service available, but scheduled maintenance '
          "or unplanned outages can happen. We're not liable for lost time or "
          "inconvenience caused by service interruptions, though we'll work "
          'to resolve them promptly.',
        ),
        LegalSection(
          'Changes to the service',
          'Features may be added, changed, or removed over time as the app '
          'evolves. We\'ll aim to communicate material changes that affect how '
          'you use the app.',
        ),
        LegalSection(
          'Ending access',
          'Your access to this app ends when your employment or engagement '
          'with the organization ends, or if your organization removes your '
          'account. You can also request deletion of your own account at '
          'any time from Profile → Privacy.',
        ),
        LegalSection(
          'Questions',
          'For questions about these terms, contact your organization\'s '
          'administrator.',
        ),
      ],
    );
  }
}
