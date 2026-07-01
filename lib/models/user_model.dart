/// Represents the authenticated employee returned by `GET /api/users/me`.
///
/// JSON shape expected from the API:
/// ```json
/// {
///   "id": "u-001",
///   "email": "alex@aplano.io",
///   "first_name": "Alex",
///   "last_name": "Johnson",
///   "role": "employee",
///   "avatar_url": "https://...",
///   "phone": "+49 170 1234567",
///   "assigned_location_ids": ["loc-1", "loc-2"]
/// }
/// ```


class Wrapped<T> {
  const Wrapped.value(this.value);
  final T value;
}

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.avatarUrl,
    this.phone,
    this.assignedLocationIds = const [],
  });

  /// Unique server-side identifier.
  final String id;

  /// Work email address — also used as the login credential.
  final String email;

  final String firstName;
  final String lastName;

  /// Role string as returned by the API, e.g. `"employee"`, `"manager"`, `"admin"`.
  final String role;

  /// Remote URL of the user's profile picture. May be null.
  final String? avatarUrl;

  /// Optional contact phone number.
  final String? phone;

  /// IDs of the workplace locations this user is assigned to.
  final List<String> assignedLocationIds;

  // ── Derived properties ──────────────────────────────────────────────────────

  String get fullName    => '$firstName $lastName';
  String get initials    => '${firstName.isNotEmpty ? firstName[0] : ''}'
                            '${lastName.isNotEmpty  ? lastName[0]  : ''}'
                            .toUpperCase();
  // ── Serialisation ───────────────────────────────────────────────────────────

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Extract location IDs from either locations array of objects or flat id list
    final locationIds = (json['locations'] as List<dynamic>?)
            ?.map((e) => e is Map ? e['id'] as String? ?? '' : e as String)
            .where((id) => id.isNotEmpty)
            .toList() ??
        (json['assigned_location_ids'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const <String>[];

    return UserModel(
      id:                  json['id']          as String,
      email:               json['email']        as String,
      firstName:           (json['firstName']   ?? json['first_name'])  as String,
      lastName:            (json['lastName']    ?? json['last_name'])   as String,
      role:                ((json['role']        as String?) ?? 'employee').toLowerCase(),
      avatarUrl:           (json['avatarUrl']   ?? json['avatar_url'])  as String?,
      phone:               json['phone']        as String?,
      assignedLocationIds: locationIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id':                    id,
        'email':                 email,
        'firstName':             firstName,
        'lastName':              lastName,
        'role':                  role,
        'avatarUrl':             avatarUrl,
        'phone':                 phone,
        'assignedLocationIds':   assignedLocationIds,
      };
      

  // ── copyWith ─────────────────────────────────────────────────────────────────

  UserModel copyWith({
    String?       id,
    String?       email,
    String?       firstName,
    String?       lastName,
    String?       role,
     Wrapped<String?>? avatarUrl,
     Wrapped<String?>? phone,
    List<String>? assignedLocationIds,
  }) =>
      UserModel(
        id:                  id                  ?? this.id,
        email:               email               ?? this.email,
        firstName:           firstName           ?? this.firstName,
        lastName:            lastName            ?? this.lastName,
        role:                role                ?? this.role,
        avatarUrl: avatarUrl != null ? avatarUrl.value : this.avatarUrl,
        phone: phone != null ? phone.value : this.phone,
        assignedLocationIds: assignedLocationIds ?? this.assignedLocationIds,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'UserModel(id: $id, email: $email, role: $role)';
}