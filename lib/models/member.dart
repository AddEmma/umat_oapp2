class Member {
  final String id;
  final String name;
  // final String email;
  final String phone;
  final String year;
  final String department;
  final String localCongregation;
  final String location;
  final String hostel;
  final bool isBaptized;
  final String ministryRole;
  final String? photoUrl;
  final DateTime dateAdded;
  final Map<String, dynamic> attendanceRecord;

  Member({
    required this.id,
    required this.name,
    // required this.email,
    required this.phone,
    required this.year,
    required this.department,
    this.localCongregation = '',
    this.location = '',
    this.hostel = '',
    required this.isBaptized,
    required this.ministryRole,
    this.photoUrl,
    required this.dateAdded,
    this.attendanceRecord = const {},
  });

  factory Member.fromMap(Map<String, dynamic> map, String id) {
    return Member(
      id: id,
      name: map['name'] ?? '',
      // email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      year: map['year'] ?? '',
      department: map['department'] ?? '',
      localCongregation: map['localCongregation'] ?? '',
      location: map['location'] ?? '',
      hostel: map['hostel'] ?? '',
      isBaptized: map['isBaptized'] ?? false,
      ministryRole: map['ministryRole'] ?? '',
      photoUrl: (map['photoUrl'] as String?)?.isEmpty == true
          ? null
          : map['photoUrl'],
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
      // 'email': email,
      'phone': phone,
      'year': year,
      'department': department,
      'localCongregation': localCongregation,
      'location': location,
      'hostel': hostel,
      'isBaptized': isBaptized,
      'ministryRole': ministryRole,
      'photoUrl': photoUrl,
      'dateAdded': dateAdded.toIso8601String(),
      'attendanceRecord': attendanceRecord,
    };
  }

  /// ✅ Explicitly added copyWith
  Member copyWith({
    String? id,
    String? name,
    // String? email,
    String? phone,
    String? year,
    String? department,
    String? localCongregation,
    String? location,
    String? hostel,
    bool? isBaptized,
    String? ministryRole,
    String? photoUrl,
    DateTime? dateAdded,
    Map<String, dynamic>? attendanceRecord,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      // email: email ?? this.email,
      phone: phone ?? this.phone,
      year: year ?? this.year,
      department: department ?? this.department,
      localCongregation: localCongregation ?? this.localCongregation,
      location: location ?? this.location,
      hostel: hostel ?? this.hostel,
      isBaptized: isBaptized ?? this.isBaptized,
      ministryRole: ministryRole ?? this.ministryRole,
      photoUrl: photoUrl ?? this.photoUrl,
      dateAdded: dateAdded ?? this.dateAdded,
      attendanceRecord: attendanceRecord ?? this.attendanceRecord,
    );
  }

  @override
  String toString() {
    return 'Member{id: $id, name: $name, phone: $phone, year: $year, department: $department, localCongregation: $localCongregation, location: $location, hostel: $hostel, isBaptized: $isBaptized, ministryRole: $ministryRole, dateAdded: $dateAdded}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Member &&
        other.id == id &&
        other.name == name &&
        // other.email == email &&
        other.phone == phone &&
        other.year == year &&
        other.department == department &&
        other.localCongregation == localCongregation &&
        other.location == location &&
        other.hostel == hostel &&
        other.isBaptized == isBaptized &&
        other.ministryRole == ministryRole &&
        other.dateAdded == dateAdded;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        // email.hashCode ^
        phone.hashCode ^
        year.hashCode ^
        department.hashCode ^
        localCongregation.hashCode ^
        location.hashCode ^
        hostel.hashCode ^
        isBaptized.hashCode ^
        ministryRole.hashCode ^
        dateAdded.hashCode;
  }
}
