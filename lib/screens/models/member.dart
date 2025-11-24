class Member {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String year;
  final String department;
  final bool isBaptized;
  final String ministryRole;
  final DateTime dateAdded;
  final Map<String, dynamic> attendanceRecord;

  Member({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.year,
    required this.department,
    required this.isBaptized,
    required this.ministryRole,
    required this.dateAdded,
    this.attendanceRecord = const {},
  });

  factory Member.fromMap(Map<String, dynamic> map, String id) {
    return Member(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      year: map['year'] ?? '',
      department: map['department'] ?? '',
      isBaptized: map['isBaptized'] ?? false,
      ministryRole: map['ministryRole'] ?? '',
      dateAdded: DateTime.parse(
        map['dateAdded'] ?? DateTime.now().toIso8601String(),
      ),
      attendanceRecord: Map<String, dynamic>.from(
        map['attendanceRecord'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'year': year,
      'department': department,
      'isBaptized': isBaptized,
      'ministryRole': ministryRole,
      'dateAdded': dateAdded.toIso8601String(),
      'attendanceRecord': attendanceRecord,
    };
  }

  /// ✅ Explicitly added copyWith
  Member copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? year,
    String? department,
    bool? isBaptized,
    String? ministryRole,
    DateTime? dateAdded,
    Map<String, dynamic>? attendanceRecord,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      year: year ?? this.year,
      department: department ?? this.department,
      isBaptized: isBaptized ?? this.isBaptized,
      ministryRole: ministryRole ?? this.ministryRole,
      dateAdded: dateAdded ?? this.dateAdded,
      attendanceRecord: attendanceRecord ?? this.attendanceRecord,
    );
  }

  @override
  String toString() {
    return 'Member{id: $id, name: $name, email: $email, phone: $phone, year: $year, department: $department, isBaptized: $isBaptized, ministryRole: $ministryRole, dateAdded: $dateAdded}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Member &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        other.year == year &&
        other.department == department &&
        other.isBaptized == isBaptized &&
        other.ministryRole == ministryRole &&
        other.dateAdded == dateAdded;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        year.hashCode ^
        department.hashCode ^
        isBaptized.hashCode ^
        ministryRole.hashCode ^
        dateAdded.hashCode;
  }
}
