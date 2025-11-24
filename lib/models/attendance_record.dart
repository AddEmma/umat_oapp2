// models/attendance_record.dart
class AttendanceRecord {
  final String? id;
  final String memberId;
  final String eventType;
  final DateTime date;
  final bool isPresent;
  final DateTime? arrivalTime;

  AttendanceRecord({
    this.id,
    required this.memberId,
    required this.eventType,
    required this.date,
    required this.isPresent,
    this.arrivalTime,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceRecord(
      id: id,
      memberId: map['memberId'] ?? '',
      eventType: map['eventType'] ?? '',
      date: DateTime.parse(map['date']),
      isPresent: map['isPresent'] ?? false,
      arrivalTime: map['arrivalTime'] != null
          ? DateTime.parse(map['arrivalTime'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'eventType': eventType,
      'date': date.toIso8601String(),
      'isPresent': isPresent,
      'arrivalTime': arrivalTime?.toIso8601String(),
    };
  }

  AttendanceRecord copyWith({
    String? id,
    String? memberId,
    String? eventType,
    DateTime? date,
    bool? isPresent,
    DateTime? arrivalTime,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      eventType: eventType ?? this.eventType,
      date: date ?? this.date,
      isPresent: isPresent ?? this.isPresent,
      arrivalTime: arrivalTime ?? this.arrivalTime,
    );
  }

  @override
  String toString() {
    return 'AttendanceRecord{id: $id, memberId: $memberId, eventType: $eventType, date: $date, isPresent: $isPresent, arrivalTime: $arrivalTime}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttendanceRecord &&
        other.id == id &&
        other.memberId == memberId &&
        other.eventType == eventType &&
        other.date == date &&
        other.isPresent == isPresent &&
        other.arrivalTime == arrivalTime;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        memberId.hashCode ^
        eventType.hashCode ^
        date.hashCode ^
        isPresent.hashCode ^
        arrivalTime.hashCode;
  }
}
