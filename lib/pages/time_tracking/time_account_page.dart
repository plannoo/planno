import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../absence/new_absence_page.dart';

class TimeAccountPage extends StatefulWidget {
  const TimeAccountPage({super.key});

  @override
  State<TimeAccountPage> createState() => _TimeAccountPageState();
}

class _TimeAccountPageState extends State<TimeAccountPage> {
  final Set<int> _expanded = {0};

  bool   _loading      = true;
  String _totalBalance = '00:00h';
  List<_MonthRecord> _months = [];
  List<({String label, double hours})> _barData = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Backend exposes the running overtime balance here. (The monthly
      // breakdown / trend aren't aggregated server-side yet, so those stay
      // empty — but the headline balance now reflects real data.)
      final raw = await ApiClient.instance.get('/api/overtime-balances/me');
      final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
      final inner = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;

      // Balance
      final balanceMin = (inner['balanceMinutes'] as num?)?.toInt()
          ?? (inner['balance'] as num?)?.toInt();
      if (balanceMin != null) {
        final sign = balanceMin >= 0 ? '+' : '-';
        final abs  = balanceMin.abs();
        _totalBalance = '$sign${(abs ~/ 60).toString().padLeft(2,'0')}:${(abs % 60).toString().padLeft(2,'0')}h';
      } else {
        _totalBalance = inner['balanceLabel'] as String? ?? '00:00h';
      }

      // Monthly records
      final rawMonths = (inner['months'] ?? inner['monthlyRecords'] ?? []) as List? ?? [];
      _months = rawMonths.map((m) {
        final mo      = m as Map<String, dynamic>;
        final target  = (mo['targetHours']  as num? ?? 0).toDouble();
        final actual  = (mo['actualHours']  as num? ?? 0).toDouble();
        final rawEnt  = (mo['entries'] ?? []) as List? ?? [];
        return _MonthRecord(
          month:       mo['month']      as String? ?? '',
          shortLabel:  mo['shortLabel'] as String? ?? '',
          targetHours: target,
          actualHours: actual,
          entries: rawEnt.map((e) {
            final en = e as Map<String, dynamic>;
            final pos = (en['positive'] as bool?) ?? true;
            return _ActivityEntry(
              date:     en['date']  as String? ?? '',
              type:     en['type']  as String? ?? '',
              delta:    en['delta'] as String? ?? '',
              positive: pos,
            );
          }).toList(),
        );
      }).toList();

      // Bar chart (last 6 months)
      final rawBar = (inner['trend'] ?? inner['barData'] ?? []) as List? ?? [];
      _barData = rawBar.take(6).map((b) {
        final bm = b as Map<String, dynamic>;
        return (
          label: bm['label'] as String? ?? '',
          hours: (bm['hours'] as num? ?? 0).toDouble(),
        );
      }).toList();
    } catch (_) {
      // keep empty state on error
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text('Time Account', style: AppTextStyles.h5),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded,
                size: 20, color: AppColors.slate600),
            onPressed: () => _showInfoSheet(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        physics: Theme.of(context).platform == TargetPlatform.iOS
            ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
            : const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePaddingH,
          vertical: AppDimensions.spacingMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Total balance card ───────────────────────────────────────
            _BalanceCard(balance: _totalBalance),
            const SizedBox(height: AppDimensions.spacingMd),

            // ── Monthly trend chart ──────────────────────────────────────
            _TrendCard(barData: _barData),
            const SizedBox(height: AppDimensions.spacingXl),

            // ── Activity details header ──────────────────────────────────
            Text(
              'ACTIVITY DETAILS',
              style: AppTextStyles.overline.copyWith(
                color: AppColors.slate400,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingSm),

            // ── Month cards ──────────────────────────────────────────────
            ..._months.asMap().entries.map((e) => _MonthCard(
                  record:     e.value,
                  isExpanded: _expanded.contains(e.key),
                  onToggle:   () => setState(() {
                    _expanded.contains(e.key)
                        ? _expanded.remove(e.key)
                        : _expanded.add(e.key);
                  }),
                )),

            const SizedBox(height: AppDimensions.spacingXxl),
          ],
        ),
      ),
    );
  }

  void _showInfoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.slate200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('About Time Account', style: AppTextStyles.h5),
            const SizedBox(height: 12),
            Text(
              'Your time account tracks overtime and under-time hours. Positive hours are accumulated overtime that can be paid out or used as additional time off.',
              style: AppTextStyles.bodySmall.copyWith(height: 1.5),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Balance card ──────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});
  final String balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'TOTAL OVERTIME BALANCE',
            style: AppTextStyles.overline.copyWith(
                color: AppColors.slate400, fontSize: 11, letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),
          Text(
            balance,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              height: 1.0,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: AppDimensions.buttonHeightMd,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payout requests are handled by your manager.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('Request Payout'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: AppDimensions.buttonHeightMd,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NewAbsenceScreen()),
                    ),
                    child: const Text('Apply Time Off'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Monthly trend bar chart ───────────────────────────────────────────────────

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.barData});
  final List<({String label, double hours})> barData;

  @override
  Widget build(BuildContext context) {
    final maxHours = barData.fold(0.0, (m, b) => b.hours > m ? b.hours : m);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Trend', style: AppTextStyles.h5),
              Text('Last 6 Months',
                  style: AppTextStyles.caption.copyWith(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: barData.map((b) {
                final isLast = b.label == barData.last.label;
                final ratio  = maxHours > 0 ? b.hours / maxHours : 0.0;
                final barH   = (80 * ratio).clamp(6.0, 80.0);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isLast)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${b.hours.toStringAsFixed(1)}h',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      width: 28,
                      height: barH,
                      decoration: BoxDecoration(
                        color: isLast ? AppColors.primary : AppColors.primaryLight,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      b.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isLast ? FontWeight.w700 : FontWeight.w500,
                        color: isLast ? AppColors.primary : AppColors.slate400,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Month card (expandable) ───────────────────────────────────────────────────

class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.record,
    required this.isExpanded,
    required this.onToggle,
  });

  final _MonthRecord record;
  final bool         isExpanded;
  final VoidCallback onToggle;

  String get _deltaLabel {
    final diff = record.actualHours - record.targetHours;
    final sign = diff >= 0 ? '+' : '-';
    final abs  = diff.abs();
    final h    = abs.truncate();
    final m    = ((abs - h) * 60).round();
    return '$sign${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}h';
  }

  bool get _isPositive => record.actualHours >= record.targetHours;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
      decoration: BoxDecoration(
        color: isExpanded ? AppColors.primaryLighter : cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? AppColors.primaryLight : cs.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.vertical(
              top:    const Radius.circular(16),
              bottom: isExpanded ? Radius.zero : const Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(record.month,
                            style: AppTextStyles.bodyBold
                                .copyWith(fontSize: 15)),
                        const SizedBox(height: 3),
                        Text(
                          '${record.targetHours.toStringAsFixed(1)}h Target  ·  ${record.actualHours.toStringAsFixed(1)}h Actual',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.slate500),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _deltaLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _isPositive
                          ? AppColors.primary
                          : AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isExpanded
                          ? AppColors.primary
                          : AppColors.slate300,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded entries
          if (isExpanded) ...[
            const Divider(height: 1, color: AppColors.primaryLight),
            ...record.entries.map((e) => _ActivityRow(entry: e)),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});
  final _ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Left icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: entry.positive
                      ? AppColors.successLight
                      : AppColors.errorLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  entry.positive
                      ? Icons.add_circle_outline_rounded
                      : Icons.remove_circle_outline_rounded,
                  size: 18,
                  color: entry.positive ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.date,
                        style: AppTextStyles.labelMedium
                            .copyWith(fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(entry.type,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.slate400)),
                  ],
                ),
              ),

              Text(
                entry.delta,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: entry.positive ? AppColors.primary : AppColors.error,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 64, color: AppColors.primaryLight),
      ],
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _MonthRecord {
  const _MonthRecord({
    required this.month,
    required this.shortLabel,
    required this.targetHours,
    required this.actualHours,
    required this.entries,
  });

  final String              month;
  final String              shortLabel;
  final double              targetHours;
  final double              actualHours;
  final List<_ActivityEntry> entries;
}

class _ActivityEntry {
  const _ActivityEntry({
    required this.date,
    required this.type,
    required this.delta,
    required this.positive,
  });

  final String date;
  final String type;
  final String delta;
  final bool   positive;
}