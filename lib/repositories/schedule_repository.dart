import 'dart:async';
import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/shift_model.dart';

// ── Cancel token ──────────────────────────────────────────────────────────────

class CancelToken {
  bool _cancelled = false;
  void cancel() => _cancelled = true;
  bool get isCancelled => _cancelled;
}

class CancelledError implements Exception {
  const CancelledError();
  @override
  String toString() => 'CancelledError';
}

// ── Interface ─────────────────────────────────────────────────────────────────

abstract interface class ScheduleRepository {
  /// Returns the current user's shifts for the given [month].
  /// Pass a [cancelToken] to abort an in-flight request.
  Future<List<ShiftModel>> getMyShifts(DateTime month,
      {CancelToken? cancelToken});

}

// ── API implementation ─────────────────────────────────────────────────────────

class ApiScheduleRepository implements ScheduleRepository {
  ApiScheduleRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  String _fmt(DateTime d) => d.toIso8601String().split('T').first;

  @override
  Future<List<ShiftModel>> getMyShifts(DateTime month,
      {CancelToken? cancelToken}) async {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0);

    final data = await _client.get(
      ApiConfig.shifts,
      queryParameters: {
        'from': _fmt(monthStart),
        'to':   _fmt(monthEnd),
      },
    ) as List<dynamic>;

    if (cancelToken?.isCancelled == true) throw const CancelledError();

    return data
        .map((j) => ShiftModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}

// ── Mock ──────────────────────────────────────────────────────────────────────

class MockScheduleRepository implements ScheduleRepository {
  static List<ShiftModel> _myShifts(DateTime month) {
    final shifts = <ShiftModel>[];
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      if (date.weekday == DateTime.saturday ||date.weekday == DateTime.sunday) continue;
      if (d % 7 == 0) continue;
      shifts.add(ShiftModel(
        id: 'my-$d',
        role: 'Floor Manager',
        date: date,
        startTime: date.copyWith(hour: 9),
        endTime:   date.copyWith(hour: 17),
        location: 'Berlin HQ',
        address:  'Friedrichstraße 123, 10117 Berlin',
        latitude:  52.5200,
        longitude: 13.4050,
      ));
    }
    return shifts;
  }

  @override
  Future<List<ShiftModel>> getMyShifts(DateTime month,
      {CancelToken? cancelToken}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (cancelToken?.isCancelled == true) throw const CancelledError();
    return _myShifts(month);
  }

}