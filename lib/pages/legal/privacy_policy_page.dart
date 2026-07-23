import 'package:flutter/material.dart';

import 'legal_document_page.dart';

/// NOTE: This content is technically accurate to what the app actually
/// collects and does with data as of the date below, drafted from the
/// codebase itself. It has NOT been reviewed by a lawyer and does not cover
/// jurisdiction-specific requirements (e.g. naming a GDPR representative,
/// a Data Protection Officer, or region-specific retention rules). Get this
/// reviewed by counsel before relying on it for a public launch.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentPage(
      title: 'Privacy Policy',
      lastUpdated: '2026-07-02',
      sections: [
        LegalSection(
          'What this app is',
          'Wrenta is a workforce-management app used by your employer to '
          'schedule shifts, track working time, and manage absences. Your '
          'employer (the "organization") is the data controller; the data '
          'described below is collected to operate the employment '
          'relationship, not for advertising or resale.',
        ),
        LegalSection(
          'Account & profile data',
          'Name, email address, phone number, department, job title, and '
          'profile photo, entered by you or by your organization\'s '
          'administrators.',
        ),
        LegalSection(
          'Employment records',
          'Where enabled by your organization, this may include a personnel '
          'number, start date, probation end date, contract end date, '
          'qualification notes, and — only where your organization\'s HR '
          'process requires it — a social security number. These fields are '
          'configured by your organization and are visible only to '
          'authorized administrators, not to other employees.',
        ),
        LegalSection(
          'Location data',
          'When you clock in or out, the app captures your device\'s GPS '
          'location once, at that moment, to confirm you were at an '
          'authorized work location. We do not track your location in the '
          'background or between clock events. Location logs are retained '
          'for a limited period (default 90 days) and then automatically '
          'deleted.',
        ),
        LegalSection(
          'Biometric authentication',
          'If you enable Face ID / Touch ID / fingerprint unlock for '
          'clock-in, that check is performed entirely by your device\'s '
          'operating system. Your biometric data never leaves your device '
          'and is never sent to us or stored on our servers — we only '
          'receive a yes/no confirmation that your device authenticated '
          'you.',
        ),
        LegalSection(
          'Time & schedule data',
          'Clock-in/out timestamps, breaks, assigned shifts, and schedule '
          'changes, used to calculate worked hours and generate timesheets.',
        ),
        LegalSection(
          'Absence & leave data',
          'Vacation and sick-leave requests, including dates and leave '
          'type, and any documents you choose to attach (e.g. a doctor\'s '
          'note).',
        ),
        LegalSection(
          'Documents',
          'Files you or your organization upload to your employee profile '
          '(e.g. contracts, certifications).',
        ),
        LegalSection(
          'Messages',
          'Chat messages sent within the app are visible to their intended '
          'recipients and to your organization\'s administrators for '
          'workplace-communication oversight.',
        ),
        LegalSection(
          'Who can see your data',
          'Your data is only visible within your employing organization — '
          'never shared with other organizations using this app, and never '
          'sold to third parties. Within your organization, visibility '
          'follows role: managers and admins can see employee records '
          'needed to run scheduling and payroll; co-workers see only what\'s '
          'needed for shift coordination (e.g. names on a shared schedule).',
        ),
        LegalSection(
          'How long we keep it',
          'Data is kept for as long as your account is active, plus any '
          'retention period required by employment or tax law in your '
          'organization\'s jurisdiction. GPS location logs are purged '
          'automatically after a limited period regardless of account '
          'status.',
        ),
        LegalSection(
          'Your rights',
          'You can export a complete copy of everything we hold about you, '
          'and request deletion of your account, at any time from '
          'Profile → Privacy in this app. Account deletion anonymizes your '
          'personal data; some records (e.g. time worked) may be retained '
          'in de-identified form where required for legal/tax compliance.',
        ),
        LegalSection(
          'Contact',
          'Questions about your data should go to your organization\'s '
          'administrator, who controls what is collected and why.',
        ),
      ],
    );
  }
}
