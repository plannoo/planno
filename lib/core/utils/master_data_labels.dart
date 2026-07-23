import 'package:flutter/widgets.dart';

/// The backend seeds master-data field labels in German (see
/// masterDataService.DEFAULT_FIELDS). When the app is running in English we
/// translate the known labels so the English UI doesn't show German text.
/// Unknown/custom labels are returned unchanged.
const Map<String, String> _deToEn = {
  'Straße & Hausnummer':        'Street & House No.',
  'Postleitzahl':               'Postal Code',
  'Stadt':                      'City',
  'Mobilnummer':                'Mobile Number',
  'Geburtsort':                 'Place of Birth',
  'Geburtstag':                 'Date of Birth',
  'Personalnummer':             'Personnel Number',
  'Arbeitsantritt':             'Start Date',
  'Ende Probezeit':             'End of Probation',
  'Vertragsende':               'Contract End',
  'Notiz':                      'Note',
  'Sozialversicherungsnummer':  'Social Security Number',
  'Qualifikation':              'Qualification',
  'Bewacher-ID':                'Guard ID',
};

/// Returns [label] localized to the current UI language. Only translates the
/// known German default labels into English; everything else is unchanged.
String localizedMasterDataLabel(BuildContext context, String label) {
  final isEnglish =
      Localizations.localeOf(context).languageCode.toLowerCase() == 'en';
  if (!isEnglish) return label;
  return _deToEn[label.trim()] ?? label;
}
