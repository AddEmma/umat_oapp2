// services/database_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member.dart';
import '../models/meeting.dart';
import '../models/attendance_record.dart';

class DatabaseService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Members
  Stream<List<Member>> getMembers() {
    return _db.collection('members').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Member.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addMember(Member member) async {
    await _db.collection('members').add(member.toMap());
    notifyListeners();
  }

  Future<void> updateMember(Member member) async {
    await _db.collection('members').doc(member.id).update(member.toMap());
    notifyListeners();
  }

  Future<void> deleteMember(String memberId) async {
    await _db.collection('members').doc(memberId).delete();
    notifyListeners();
  }

  // Meetings
  Stream<List<Meeting>> getMeetings() {
    return _db
        .collection('meetings')
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Meeting.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> addMeeting(Meeting meeting) async {
    await _db.collection('meetings').add(meeting.toMap());
    notifyListeners();
  }

  Future<void> updateMeetingRSVP(
    String meetingId,
    String userId,
    String response,
  ) async {
    await _db.collection('meetings').doc(meetingId).update({
      'rsvp.$userId': response,
    });
    notifyListeners();
  }

  // Attendance Records
  Future<void> saveAttendanceRecord(AttendanceRecord record) async {
    // Create a unique document ID based on member, date, and event type
    String docId =
        '${record.memberId}_${record.date.toIso8601String().split('T')[0]}_${record.eventType.replaceAll(' ', '_')}';

    // Store the record with both timestamp and date string for flexible querying
    Map<String, dynamic> recordData = record.toMap();
    recordData['dateTimestamp'] = Timestamp.fromDate(record.date);
    recordData['dateString'] = record.date.toIso8601String().split('T')[0];

    await _db.collection('attendance_records').doc(docId).set(recordData);
    notifyListeners();
  }

  Future<Map<String, AttendanceRecord>> getAttendanceForDate(
    DateTime date,
    String eventType,
  ) async {
    String dateStr = date.toIso8601String().split('T')[0];

    QuerySnapshot snapshot = await _db
        .collection('attendance_records')
        .where('dateString', isEqualTo: dateStr)
        .where('eventType', isEqualTo: eventType)
        .get();

    Map<String, AttendanceRecord> attendanceMap = {};

    for (var doc in snapshot.docs) {
      AttendanceRecord record = AttendanceRecord.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
      attendanceMap[record.memberId] = record;
    }

    return attendanceMap;
  }

  // Simplified attendance records query to avoid complex composite indexes
  Stream<List<AttendanceRecord>> getAttendanceRecords({
    String? memberId,
    String? eventType,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _db.collection('attendance_records');

    // Primary filter - use the most selective filter first
    if (memberId != null) {
      // Member-specific query
      query = query.where('memberId', isEqualTo: memberId);

      // Add date range if specified
      if (startDate != null && endDate != null) {
        query = query
            .where(
              'dateTimestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where(
              'dateTimestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate),
            );
      } else if (startDate != null) {
        query = query.where(
          'dateTimestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      } else if (endDate != null) {
        query = query.where(
          'dateTimestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      return query.orderBy('dateTimestamp', descending: true).snapshots().map((
        snapshot,
      ) {
        List<AttendanceRecord> records = snapshot.docs
            .map(
              (doc) => AttendanceRecord.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();

        // Filter by event type in memory if specified
        if (eventType != null) {
          records = records
              .where((record) => record.eventType == eventType)
              .toList();
        }

        return records;
      });
    } else {
      // General query without member filter
      if (startDate != null && endDate != null) {
        query = query
            .where(
              'dateTimestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where(
              'dateTimestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate),
            );
      } else if (startDate != null) {
        query = query.where(
          'dateTimestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      } else if (endDate != null) {
        query = query.where(
          'dateTimestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      return query
          .orderBy('dateTimestamp', descending: true)
          .limit(1000)
          .snapshots()
          .map((snapshot) {
            List<AttendanceRecord> records = snapshot.docs
                .map(
                  (doc) => AttendanceRecord.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ),
                )
                .toList();

            // Filter by event type in memory if specified
            if (eventType != null) {
              records = records
                  .where((record) => record.eventType == eventType)
                  .toList();
            }

            return records;
          });
    }
  }

  // Alternative method for event-specific queries (if you want to create a simple index)
  Stream<List<AttendanceRecord>> getAttendanceRecordsByEventType(
    String eventType, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _db
        .collection('attendance_records')
        .where('eventType', isEqualTo: eventType);

    // Add date range if both dates are provided
    if (startDate != null && endDate != null) {
      query = query
          .where(
            'dateTimestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where(
            'dateTimestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          );
    }

    return query.orderBy('dateTimestamp', descending: true).snapshots().map((
      snapshot,
    ) {
      List<AttendanceRecord> records = snapshot.docs
          .map(
            (doc) => AttendanceRecord.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      // If only one date boundary was provided, filter in memory
      if ((startDate != null && endDate == null) ||
          (startDate == null && endDate != null)) {
        records = records.where((record) {
          if (startDate != null && record.date.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && record.date.isAfter(endDate)) return false;
          return true;
        }).toList();
      }

      return records;
    });
  }

  Future<List<AttendanceRecord>> getAttendanceRecordsForMember(
    String memberId,
  ) async {
    QuerySnapshot snapshot = await _db
        .collection('attendance_records')
        .where('memberId', isEqualTo: memberId)
        .orderBy('dateTimestamp', descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => AttendanceRecord.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();
  }

  Future<Map<String, dynamic>> getAttendanceStats({
    String? eventType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = _db.collection('attendance_records');

    // Apply date range filters
    if (startDate != null && endDate != null) {
      query = query
          .where(
            'dateTimestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where(
            'dateTimestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          );
    } else if (startDate != null) {
      query = query.where(
        'dateTimestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    } else if (endDate != null) {
      query = query.where(
        'dateTimestamp',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    QuerySnapshot snapshot = await query.get();

    int totalRecords = 0;
    int presentCount = 0;
    int absentCount = 0;

    Map<String, int> memberAttendanceCount = {};
    Map<String, int> eventTypeCount = {};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      bool isPresent = data['isPresent'] ?? false;
      String memberId = data['memberId'] ?? '';
      String event = data['eventType'] ?? '';

      // Filter by event type if specified (in memory)
      if (eventType != null && event != eventType) {
        continue;
      }

      totalRecords++;

      if (isPresent) {
        presentCount++;
        memberAttendanceCount[memberId] =
            (memberAttendanceCount[memberId] ?? 0) + 1;
      } else {
        absentCount++;
      }

      eventTypeCount[event] = (eventTypeCount[event] ?? 0) + 1;
    }

    return {
      'totalRecords': totalRecords,
      'presentCount': presentCount,
      'absentCount': absentCount,
      'attendanceRate': totalRecords > 0
          ? (presentCount / totalRecords * 100).toStringAsFixed(1)
          : '0.0',
      'memberAttendanceCount': memberAttendanceCount,
      'eventTypeCount': eventTypeCount,
    };
  }

  Future<void> deleteAttendanceRecord(String recordId) async {
    await _db.collection('attendance_records').doc(recordId).delete();
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getMemberAttendanceSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Get all members
    QuerySnapshot memberSnapshot = await _db.collection('members').get();
    List<Member> members = memberSnapshot.docs
        .map(
          (doc) => Member.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();

    // Get attendance records with date filtering
    Query attendanceQuery = _db.collection('attendance_records');

    if (startDate != null && endDate != null) {
      attendanceQuery = attendanceQuery
          .where(
            'dateTimestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where(
            'dateTimestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          );
    } else if (startDate != null) {
      attendanceQuery = attendanceQuery.where(
        'dateTimestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    } else if (endDate != null) {
      attendanceQuery = attendanceQuery.where(
        'dateTimestamp',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    QuerySnapshot attendanceSnapshot = await attendanceQuery.get();

    // Process attendance data
    Map<String, Map<String, dynamic>> memberStats = {};

    for (Member member in members) {
      memberStats[member.id] = {
        'member': member,
        'totalEvents': 0,
        'presentCount': 0,
        'absentCount': 0,
        'attendanceRate': 0.0,
      };
    }

    for (var doc in attendanceSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String memberId = data['memberId'] ?? '';
      bool isPresent = data['isPresent'] ?? false;

      if (memberStats.containsKey(memberId)) {
        memberStats[memberId]!['totalEvents']++;
        if (isPresent) {
          memberStats[memberId]!['presentCount']++;
        } else {
          memberStats[memberId]!['absentCount']++;
        }
      }
    }

    // Calculate attendance rates
    for (String memberId in memberStats.keys) {
      int total = memberStats[memberId]!['totalEvents'];
      int present = memberStats[memberId]!['presentCount'];
      memberStats[memberId]!['attendanceRate'] = total > 0
          ? (present / total * 100)
          : 0.0;
    }

    return memberStats.values.toList();
  }

  // Migration method to update existing records (run once)
  Future<void> migrateAttendanceRecords() async {
    QuerySnapshot snapshot = await _db.collection('attendance_records').get();

    WriteBatch batch = _db.batch();
    int batchCount = 0;

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;

      // Check if migration is needed
      if (!data.containsKey('dateTimestamp') ||
          !data.containsKey('dateString')) {
        String dateString = data['date'] as String;
        DateTime date = DateTime.parse(dateString);

        // Update with new fields
        batch.update(doc.reference, {
          'dateTimestamp': Timestamp.fromDate(date),
          'dateString': date.toIso8601String().split('T')[0],
        });

        batchCount++;

        // Firestore batch limit is 500
        if (batchCount >= 500) {
          await batch.commit();
          batch = _db.batch();
          batchCount = 0;
        }
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }
  }
}
