import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../models/absence.dart';
import '../../../models/absence_summary.dart';
import '../../../repositories/absence_repository.dart';
import '../../../widgets/common/custom_app_bar.dart';
import '../../../widgets/common/section_header.dart';
import '../../widgets/absence/absence_summary_card.dart';
import '../../widgets/absence/absence_list_card.dart';
import 'new_absence_page.dart';
import 'request_history.dart';

/// Displays upcoming and past absences with a summary quota card.
class AbsencePage extends StatefulWidget {
  const AbsencePage({super.key});

  @override
  State<AbsencePage> createState() => _AbsencePageState();
}

class _AbsencePageState extends State<AbsencePage> {
  final AbsenceRepository _repo = ApiAbsenceRepository();

  AbsenceSummaryModel? _summary;
  List<AbsenceModel> _upcoming = [];
  List<AbsenceModel> _past = [];
  bool _isLoading = true;
  bool _hasError  = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() { _isLoading = true; _hasError = false; });
    try {
      final results = await Future.wait([
        _repo.getSummary(),
        _repo.getUpcoming(),
        _repo.getPast(),
      ]);
      if (mounted) {
        setState(() {
          _summary  = results[0] as AbsenceSummaryModel;
          _upcoming = results[1] as List<AbsenceModel>;
          _past     = results[2] as List<AbsenceModel>;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.absencesTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 22),
            tooltip: l10n.requestHistoryTitle,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RequestHistoryPage()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.newAbsenceTitle,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewAbsenceScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(l10n.absenceLoadError),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadData, child: Text(l10n.retry)),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_summary != null) AbsenceSummaryCard(summary: _summary!),
          const SizedBox(height: AppDimensions.spacing4xl),
          SectionHeader(title: l10n.absencesUpcoming),
          const SizedBox(height: AppDimensions.spacingMd),
          ..._upcoming.map((a) => AbsenceListCard(absence: a, showWorkingDays: true)),
          const SizedBox(height: AppDimensions.spacingXl),
          SectionHeader(title: l10n.absencesPast),
          const SizedBox(height: AppDimensions.spacingMd),
          ..._past.map((a) => AbsenceListCard(absence: a, isExpandable: true)),
        ],
      ),
    );
  }
}