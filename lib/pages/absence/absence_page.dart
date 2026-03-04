import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/absence.dart';
import '../../../models/absence_summary.dart';
import '../../../repositories/absence_repository.dart';
import '../../../widgets/common/custom_app_bar.dart';
import '../../../widgets/common/section_header.dart';
import '../../widgets/absence/absence_summary_card.dart';
import '../../widgets/absence/absence_list_card.dart';
import 'new_absence_page.dart';

/// Displays upcoming and past absences with a summary quota card.
class AbsencePage extends StatefulWidget {
  const AbsencePage({super.key});

  @override
  State<AbsencePage> createState() => _AbsencePageState();
}

class _AbsencePageState extends State<AbsencePage> {
  final AbsenceRepository _repo = MockAbsenceRepository();

  AbsenceSummaryModel? _summary;
  List<AbsenceModel> _upcoming = [];
  List<AbsenceModel> _past = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Absences',
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewAbsenceScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_summary != null) AbsenceSummaryCard(summary: _summary!),
          const SizedBox(height: AppDimensions.spacing4xl),
          SectionHeader(title: 'Upcoming Absences'),
          const SizedBox(height: AppDimensions.spacingMd),
          ..._upcoming.map((a) => AbsenceListCard(absence: a, showWorkingDays: true)),
          const SizedBox(height: AppDimensions.spacingXl),
          SectionHeader(title: 'Past Requests'),
          const SizedBox(height: AppDimensions.spacingMd),
          ..._past.map((a) => AbsenceListCard(absence: a, isExpandable: true)),
        ],
      ),
    );
  }
}