import 'package:flutter/foundation.dart';
import '../../../models/absence.dart';
import '../../../models/absence_summary.dart';
import '../../../repositories/absence_repository.dart';

enum AbsenceLoadState { initial, loading, loaded, submitting, error }

/// Manages absence list, summary quota, and new-absence form submission.
class AbsenceProvider extends ChangeNotifier {
  AbsenceProvider({required AbsenceRepository absenceRepository})
      : _repo = absenceRepository;

  final AbsenceRepository _repo;

  // ── State ──────────────────────────────────────────────────────────────────
  AbsenceLoadState    _state    = AbsenceLoadState.initial;
  AbsenceSummaryModel? _summary;
  List<AbsenceModel>  _upcoming = [];
  List<AbsenceModel>  _past     = [];
  String?             _errorMessage;

  AbsenceLoadState     get state        => _state;
  AbsenceSummaryModel? get summary      => _summary;
  List<AbsenceModel>   get upcoming     => List.unmodifiable(_upcoming);
  List<AbsenceModel>   get past         => List.unmodifiable(_past);
  String?              get errorMessage => _errorMessage;

  bool get isLoading    => _state == AbsenceLoadState.loading;
  bool get isSubmitting => _state == AbsenceLoadState.submitting;

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<void> loadAbsences() async {
    if (_state == AbsenceLoadState.loading) return;
    _setState(AbsenceLoadState.loading);
    try {
      final results = await Future.wait([
        _repo.getSummary(),
        _repo.getUpcoming(),
        _repo.getPast(),
      ]);
      _summary  = results[0] as AbsenceSummaryModel;
      _upcoming = results[1] as List<AbsenceModel>;
      _past     = results[2] as List<AbsenceModel>;
      _setState(AbsenceLoadState.loaded);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(AbsenceLoadState.error);
    }
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  /// Returns null on success, an error string on failure.
  Future<String?> submitAbsence(AbsenceModel absence) async {
    _setState(AbsenceLoadState.submitting);
    try {
      await _repo.submitAbsence(absence);
      // Optimistically prepend to upcoming list
      _upcoming = [absence, ..._upcoming];
      _setState(AbsenceLoadState.loaded);
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(AbsenceLoadState.error);
      return e.toString();
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _setState(AbsenceLoadState s) {
    _state = s;
    notifyListeners();
  }
}