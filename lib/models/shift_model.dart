import 'package:intl/intl.dart';

class ShiftModel {
  const ShiftModel({
    required this.id,
    required this.role,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.notes,
    this.breakMinutes,
    this.roleColor,
    this.label,
    this.hashtags = const [],
  });

  final String       id;
  final String       role;
  final DateTime     date;
  final DateTime     startTime;
  final DateTime     endTime;
  final String       location;
  final String       address;
  final double       latitude;
  final double       longitude;
  final String?      notes;
  final int?         breakMinutes;
  final String?      roleColor;
  final String?      label;
  final List<String> hashtags;

  Duration get duration    => endTime.difference(startTime);
  bool     get isToday     => _sameDay(date, DateTime.now());

  String get formattedStartTime => _fmt(startTime);
  String get formattedEndTime   => _fmt(endTime);
  String get timeRange          => '$formattedStartTime - $formattedEndTime';

  String _fmt(DateTime t) => DateFormat.jm(Intl.defaultLocale).format(t);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  factory ShiftModel.fromJson(Map<String, dynamic> j) {
    // `location` and `address` can be either a plain string or a nested object
    // (the general shifts endpoint embeds the full location object).
    String loc(dynamic v) {
      if (v is String) return v;
      if (v is Map) return (v['name'] as String?) ?? (v['address'] as String?) ?? '';
      return '';
    }
    String addr(dynamic v) {
      if (v is String) return v;
      if (v is Map) return (v['address'] as String?) ?? (v['name'] as String?) ?? '';
      return '';
    }
    double num_(dynamic v) => (v as num?)?.toDouble() ?? 0;
    return ShiftModel(
      id:           j['id']        as String,
      role:         (j['role']     as String?) ?? '',
      date:         DateTime.parse((j['date'] as String?) ?? DateTime.now().toIso8601String()),
      startTime:    DateTime.parse(j['startTime'] as String),
      endTime:      DateTime.parse(j['endTime']   as String),
      location:     loc(j['location']),
      address:      addr(j['address'] ?? j['shiftAddress']),
      latitude:     num_(j['latitude']),
      longitude:    num_(j['longitude']),
      notes:        j['notes']     as String?,
      breakMinutes: j['breakMinutes'] as int?,
      roleColor:    j['roleColor'] as String?,
      label:        j['label']     as String?,
      hashtags:     (j['hashtags'] as List<dynamic>?)
                        ?.map((e) => e as String).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'role': role,
    'date':      date.toIso8601String().split('T').first,
    'startTime': startTime.toIso8601String(),
    'endTime':   endTime.toIso8601String(),
    'location':  location, 'address': address,
    'latitude':  latitude, 'longitude': longitude,
    'notes':     notes,
  };

  ShiftModel copyWith({
    String? id, String? role, DateTime? date,
    DateTime? startTime, DateTime? endTime,
    String? location, String? address,
    double? latitude, double? longitude, String? notes,
  }) => ShiftModel(
    id: id ?? this.id, role: role ?? this.role,
    date: date ?? this.date,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    location: location ?? this.location,
    address:  address  ?? this.address,
    latitude: latitude ?? this.latitude, longitude: longitude ?? this.longitude,
    notes: notes ?? this.notes,
  );
}
