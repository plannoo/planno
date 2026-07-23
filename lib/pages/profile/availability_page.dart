import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/scheduling_flags_provider.dart';

class AvailabilityPage extends StatefulWidget {
  const AvailabilityPage({super.key});

  @override
  State<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  final List<_DaySettings> _days = [
    _DaySettings(day: 'Monday',    slots: [_TimeSlot('09:00', '17:00')]),
    _DaySettings(day: 'Tuesday',   slots: [_TimeSlot('09:00', '17:00')]),
    _DaySettings(day: 'Wednesday', slots: [_TimeSlot('09:00', '17:00')]),
    _DaySettings(day: 'Thursday',  slots: [_TimeSlot('09:00', '17:00')]),
    _DaySettings(day: 'Friday',    slots: [_TimeSlot('09:00', '17:00')]),
    _DaySettings(day: 'Saturday',  slots: [_TimeSlot('09:00', '17:00')]),
    _DaySettings(day: 'Sunday',    slots: [_TimeSlot('09:00', '17:00')]),
  ];

  bool _isSaving  = false;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // The weekly availability template (per-day enabled/allDay/slots).
      final data = await ApiClient.instance.get('/api/availabilities/me/template');
      final raw  = data is Map<String, dynamic>
          ? data
          : <String, dynamic>{};
      final weekly = (raw['weeklySchedule'] ?? raw['availability'] ?? []) as List? ?? [];
      if (!mounted) return;
      setState(() {
        for (final item in weekly) {
          final m       = item as Map<String, dynamic>;
          final dayName = (m['day'] as String? ?? '').toLowerCase();
          final idx     = _days.indexWhere(
              (d) => d.day.toLowerCase() == dayName);
          if (idx < 0) continue;
          _days[idx].isEnabled = m['enabled'] as bool? ?? true;
          _days[idx].isAllDay  = m['allDay']  as bool? ?? false;
          final rawSlots = (m['slots'] as List?) ?? [];
          _days[idx].slots = rawSlots.map((s) {
            final sm = s as Map<String, dynamic>;
            return _TimeSlot(
              sm['start'] as String? ?? '09:00',
              sm['end']   as String? ?? '17:00',
            );
          }).toList();
          // A day marked enabled (and not all-day) needs at least one slot,
          // or the backend has nothing to persist for it and it silently
          // reverts to "unavailable" on the next save — backfill a default.
          if (_days[idx].isEnabled && !_days[idx].isAllDay && _days[idx].slots.isEmpty) {
            _days[idx].slots.add(_TimeSlot('09:00', '17:00'));
          }
        }
      });
    } catch (e) {
      // Keep the default week, but say why it is empty — silently showing a
      // blank schedule made a failed load look like "you have no availability".
      if (mounted) {
        setState(() => _loadError =
            e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectTime(
      int dayIdx, int slotIdx, bool isStart) async {
    final slot    = _days[dayIdx].slots[slotIdx];
    final initial = _parseTime(isStart ? slot.start : slot.end);
    final picked  = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (isStart) {
        _days[dayIdx].slots[slotIdx].start = formatted;
      } else {
        _days[dayIdx].slots[slotIdx].end = formatted;
      }
    });
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(
        hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final body = {
        'weeklySchedule': _days.map((d) => {
          'day':     d.day.toUpperCase(),
          'enabled': d.isEnabled,
          'allDay':  d.isAllDay,
          'slots':   d.slots.map((s) => {'start': s.start, 'end': s.end}).toList(),
        }).toList(),
      };
      await ApiClient.instance.put('/api/availabilities/me/template', data: body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).availabilitySaved),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flags = context.watch<SchedulingFlagsProvider>();
    // The weekly template writes an availability row for every enabled day and
    // an unavailability row for every disabled one, and the backend gates those
    // two separately. Mirror that here: Save is only offered when the current
    // week's selection is actually permitted, so the button can't be a dead end.
    // Until the flags have loaded we can't know, so Save stays disabled (briefly)
    // rather than defaulting to enabled and letting the first tap 403.
    final hasAvailable   = _days.any((d) => d.isEnabled);
    final hasUnavailable = _days.any((d) => !d.isEnabled);
    final saveBlockedReason = !flags.ready
        ? null
        : (hasAvailable && !flags.canEnterAvailability)
            ? AppLocalizations.of(context).availabilityEntryDisabled
            : (hasUnavailable && !flags.canEnterUnavailability)
                ? AppLocalizations.of(context).unavailabilityEntryDisabled
                : null;
    final saveEnabled = flags.ready && saveBlockedReason == null;
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
        title: Text(AppLocalizations.of(context).availabilityTitle, style: AppTextStyles.h5),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          SingleChildScrollView(
            physics: Theme.of(context).platform == TargetPlatform.iOS
                ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
                : const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.only(
              left: AppDimensions.pagePaddingH,
              right: AppDimensions.pagePaddingH,
              top: AppDimensions.spacingMd,
              bottom: 110,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_loadError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_loadError!, style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.error)),
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                ],
                // Subtitle
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLighter,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).availabilitySubtitle,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceLg),

                ..._days.asMap().entries.map(
                      (e) => _DayCard(
                        dayIdx:   e.key,
                        settings: e.value,
                        onToggleEnabled: (val) => setState(() {
                          e.value.isEnabled = val;
                          // Enabling a day with no slots and not marked
                          // all-day would silently fail to persist — give it
                          // a sensible default so Save always has something
                          // to write for this day.
                          if (val && !e.value.isAllDay && e.value.slots.isEmpty) {
                            e.value.slots.add(_TimeSlot('09:00', '17:00'));
                          }
                        }),
                        onToggleAllDay: () => setState(() {
                          e.value.isAllDay = !e.value.isAllDay;
                          if (e.value.isAllDay) {
                            e.value.slots.clear();
                          } else {
                            e.value.slots
                                .add(_TimeSlot('09:00', '17:00'));
                          }
                        }),
                        onAddSlot: () => setState(() =>
                            e.value.slots.add(_TimeSlot('09:00', '17:00'))),
                        onRemoveSlot: (si) =>
                            setState(() => e.value.slots.removeAt(si)),
                        onPickTime: (si, isStart) =>
                            _selectTime(e.key, si, isStart),
                      ),
                    ),
              ],
            ),
          ),

          // Sticky save button
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  AppDimensions.pagePaddingH,
                  AppDimensions.spacingMd,
                  AppDimensions.pagePaddingH,
                  AppDimensions.spacingMd +
                      MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (saveBlockedReason != null) ...[
                    Text(saveBlockedReason,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.error)),
                    const SizedBox(height: AppDimensions.spacingSm),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: AppDimensions.buttonHeightLg,
                    child: ElevatedButton(
                      onPressed: (_isSaving || !saveEnabled) ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(AppLocalizations.of(context).availabilitySaveRoutine),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Day card ──────────────────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.dayIdx,
    required this.settings,
    required this.onToggleEnabled,
    required this.onToggleAllDay,
    required this.onAddSlot,
    required this.onRemoveSlot,
    required this.onPickTime,
  });

  final int           dayIdx;
  final _DaySettings  settings;
  final ValueChanged<bool> onToggleEnabled;
  final VoidCallback  onToggleAllDay;
  final VoidCallback  onAddSlot;
  final ValueChanged<int> onRemoveSlot;
  final void Function(int slotIdx, bool isStart) onPickTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localizedDay = switch (settings.day) {
      'Monday'    => l10n.availabilityMonday,
      'Tuesday'   => l10n.availabilityTuesday,
      'Wednesday' => l10n.availabilityWednesday,
      'Thursday'  => l10n.availabilityThursday,
      'Friday'    => l10n.availabilityFriday,
      'Saturday'  => l10n.availabilitySaturday,
      'Sunday'    => l10n.availabilitySunday,
      _           => settings.day,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: settings.isEnabled
              ? Theme.of(context).dividerColor
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Row(
            children: [
              Text(
                localizedDay,
                style: AppTextStyles.bodyBold.copyWith(
                  color: settings.isEnabled
                      ? AppColors.slate900
                      : AppColors.slate300,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Switch.adaptive(
                value: settings.isEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: onToggleEnabled,
              ),
            ],
          ),

          if (!settings.isEnabled)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(l10n.availabilityUnavailable,
                  style: AppTextStyles.caption
                      .copyWith(fontStyle: FontStyle.italic)),
            ),

          if (settings.isEnabled) ...[
            const SizedBox(height: 10),

            // All-day toggle
            GestureDetector(
              onTap: onToggleAllDay,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: settings.isAllDay
                      ? AppColors.primaryLighter
                      : AppColors.slate50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: settings.isAllDay
                        ? AppColors.primaryLight
                        : AppColors.slate200,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      l10n.availabilityAllDay,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: settings.isAllDay
                            ? AppColors.primary
                            : AppColors.slate500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      settings.isAllDay
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: settings.isAllDay
                          ? AppColors.primary
                          : AppColors.slate300,
                    ),
                  ],
                ),
              ),
            ),

            // Time slots
            if (!settings.isAllDay) ...[
              const SizedBox(height: 10),
              ...settings.slots.asMap().entries.map((e) => _TimeSlotRow(
                    slot:          e.value,
                    onRemove:      () => onRemoveSlot(e.key),
                    onPickStart:   () => onPickTime(e.key, true),
                    onPickEnd:     () => onPickTime(e.key, false),
                  )),
              TextButton.icon(
                onPressed: onAddSlot,
                icon: const Icon(Icons.add_rounded,
                    size: 16, color: AppColors.primary),
                label: Text(l10n.availabilityAddSlot,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.primary)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TimeSlotRow extends StatelessWidget {
  const _TimeSlotRow({
    required this.slot,
    required this.onRemove,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final _TimeSlot      slot;
  final VoidCallback   onRemove;
  final VoidCallback   onPickStart;
  final VoidCallback   onPickEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _TimeBox(time: slot.start, onTap: onPickStart),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('–',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.slate400)),
          ),
          _TimeBox(time: slot.end, onTap: onPickEnd),
          const Spacer(),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  size: 16, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.time, required this.onTap});
  final String       time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.slate50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_outlined,
                size: 14, color: AppColors.slate400),
            const SizedBox(width: 6),
            Text(time,
                style: AppTextStyles.labelMedium.copyWith(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _DaySettings {
  _DaySettings({
    required this.day,
    List<_TimeSlot>? slots,
  }) : slots = slots ?? [];

  final String       day;
  bool               isEnabled = true;
  bool               isAllDay  = false;
  List<_TimeSlot>    slots;
}

class _TimeSlot {
  _TimeSlot(this.start, this.end);
  String start;
  String end;
}