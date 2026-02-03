import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../models/member.dart';
import '../models/meeting.dart';
import '../models/attendance_record.dart';
import '../models/church.dart';

class DatabaseService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _churchId;
  String? get churchId => _churchId;

  void setChurchId(String? id) {
    _churchId = id;
    notifyListeners();
  }

  // Helper to get collection reference based on churchId
  CollectionReference _getCollection(String collectionName) {
    if (_churchId != null && _churchId!.isNotEmpty) {
      return _db
          .collection('churches')
          .doc(_churchId)
          .collection(collectionName);
    }
    // Fallback for legacy/root level data (or if no church selected)
    return _db.collection(collectionName);
  }

  // Church Management
  Future<void> createChurch(Church church) async {
    await _db.collection('churches').doc(church.id).set(church.toMap());
    // Also set the current user as admin of this church immediately
    await _db.collection('users').doc(church.adminId).update({
      'churchId': church.id,
      'role': 'admin',
    });
    setChurchId(church.id); // Update local state
  }

  Future<Church?> getChurch(String id) async {
    DocumentSnapshot doc = await _db.collection('churches').doc(id).get();
    if (doc.exists && doc.data() != null) {
      return Church.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<Church?> getChurchByCode(String code) async {
    QuerySnapshot snapshot = await _db
        .collection('churches')
        .where('churchCode', isEqualTo: code)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var doc = snapshot.docs.first;
      return Church.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<void> joinChurch(String userId, String churchId) async {
    await _db.collection('users').doc(userId).update({
      'churchId': churchId,
      'role': 'viewer', // Default role for joiners
    });
    setChurchId(churchId);
  }

  String generateChurchCode([String? churchName]) {
    String prefix = 'CHUR';
    if (churchName != null) {
      String cleanName = churchName
          .replaceAll(RegExp(r'[^a-zA-Z]'), '')
          .toUpperCase();
      prefix = cleanName.length >= 4
          ? cleanName.substring(0, 4)
          : cleanName.padRight(4, 'X');
    }

    // Generate 4 random digits
    String pin = (1000 + DateTime.now().microsecondsSinceEpoch % 9000)
        .toString();
    return '$prefix$pin';
  }

  // Users & Roles
  Future<void> createUserProfile(
    String uid,
    String email,
    String name,
    String role, {
    String? phoneNumber,
    String? photoUrl,
    String? churchId,
  }) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'name': name,
      'role': role,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'churchId': churchId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> uploadProfileImage(String uid, File imageFile) async {
    try {
      final currentUser = _auth.currentUser;
      print('DEBUG: Current authenticated user UID: ${currentUser?.uid}');
      print(
        'DEBUG: Uploading image to bucket: ${_storage.app.options.storageBucket}',
      );

      if (!await imageFile.exists()) {
        throw Exception('Source file does not exist: ${imageFile.path}');
      }

      // Use church ID in path if available to organize storage
      String path = 'user_profiles';
      if (_churchId != null) {
        path = 'churches/$_churchId/user_profiles';
      }

      final ref = _storage.ref().child(path).child('$uid.jpg');
      print('DEBUG: Target Storage path: ${ref.fullPath}');

      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading profile image: $e');
      if (e is FirebaseException) {
        print('Firebase Storage Error Code: ${e.code}');
        print('Firebase Storage Error Message: ${e.message}');
      }
      throw Exception('Failed to upload profile image: $e');
    }
  }

  Future<String?> getUserRole(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return (doc.data() as Map<String, dynamic>)['role'] as String?;
    }
    return null;
  }

  Future<String?> getUserChurchId(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return (doc.data() as Map<String, dynamic>)['churchId'] as String?;
    }
    return null;
  }

  // Members
  Stream<List<Member>> getMembers() {
    return _getCollection('members').snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => Member.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    });
  }

  Stream<List<Member>> getRecentMembersStream({int limit = 5}) {
    return _getCollection('members')
        .orderBy('dateAdded', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    Member.fromMap(doc.data() as Map<String, dynamic>, doc.id),
              )
              .toList();
        });
  }

  Future<void> addMember(Member member, {File? imageFile}) async {
    final docRef = _getCollection('members').doc();
    String? photoUrl = member.photoUrl;

    if (imageFile != null) {
      try {
        photoUrl = await uploadProfileImage(docRef.id, imageFile);
      } catch (e) {
        print('Error uploading member photo: $e');
        // Continue without photo if upload fails, or we could rethrow
      }
    }

    final finalMember = member.copyWith(photoUrl: photoUrl);
    await docRef.set(finalMember.toMap());
    notifyListeners();
  }

  Future<void> updateMember(Member member) async {
    await _getCollection('members').doc(member.id).update(member.toMap());
    notifyListeners();
  }

  Future<void> deleteMember(String memberId) async {
    await _getCollection('members').doc(memberId).delete();
    notifyListeners();
  }

  // Meetings
  Stream<List<Meeting>> getMeetings() {
    return _getCollection(
      'meetings',
    ).orderBy('dateTime', descending: false).snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                Meeting.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    });
  }

  Future<void> addMeeting(Meeting meeting) async {
    await _getCollection('meetings').add(meeting.toMap());
    notifyListeners();
  }

  Future<void> updateMeetingRSVP(
    String meetingId,
    String userId,
    String response,
  ) async {
    await _getCollection(
      'meetings',
    ).doc(meetingId).update({'rsvp.$userId': response});
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

    await _getCollection('attendance_records').doc(docId).set(recordData);
    notifyListeners();
  }

  Future<Map<String, AttendanceRecord>> getAttendanceForDate(
    DateTime date,
    String eventType,
  ) async {
    String dateStr = date.toIso8601String().split('T')[0];

    QuerySnapshot snapshot = await _getCollection('attendance_records')
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
    Query query = _getCollection('attendance_records');

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

  // Stream of session summaries (unique Date + Event Type)
  Stream<List<Map<String, dynamic>>> getAttendanceSessions() {
    return _getCollection(
      'attendance_records',
    ).orderBy('dateTimestamp', descending: true).snapshots().map((snapshot) {
      final Map<String, Map<String, dynamic>> sessions = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final dateStr = data['dateString'] ?? '';
        final eventType = data['eventType'] ?? '';
        final key = '${dateStr}_$eventType';

        if (!sessions.containsKey(key)) {
          sessions[key] = {
            'date': (data['dateTimestamp'] as Timestamp).toDate(),
            'dateString': dateStr,
            'eventType': eventType,
            'presentCount': 0,
            'absentCount': 0,
            'totalMembers': 0,
          };
        }

        sessions[key]!['totalMembers']++;
        if (data['isPresent'] == true) {
          sessions[key]!['presentCount']++;
        } else {
          sessions[key]!['absentCount']++;
        }
      }

      return sessions.values.toList()..sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
      );
    });
  }

  // Alternative method for event-specific queries (if you want to create a simple index)
  Stream<List<AttendanceRecord>> getAttendanceRecordsByEventType(
    String eventType, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _getCollection(
      'attendance_records',
    ).where('eventType', isEqualTo: eventType);

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
    QuerySnapshot snapshot = await _getCollection('attendance_records')
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
    Query query = _getCollection('attendance_records');

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
    await _getCollection('attendance_records').doc(recordId).delete();
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getMemberAttendanceSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Get all members
    QuerySnapshot memberSnapshot = await _getCollection('members').get();
    List<Member> members = memberSnapshot.docs
        .map(
          (doc) => Member.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();

    // Get attendance records with date filtering
    Query attendanceQuery = _getCollection('attendance_records');

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
    QuerySnapshot snapshot = await _getCollection('attendance_records').get();

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

  // Announcements
  Future<void> postAnnouncement(
    String title,
    String body,
    String senderName, {
    String? senderId,
    String? senderPhotoUrl,
  }) async {
    await _getCollection('announcements').add({
      'title': title,
      'body': body,
      'senderName': senderName,
      'senderId': senderId,
      'senderPhotoUrl': senderPhotoUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getAnnouncements() {
    return _getCollection(
      'announcements',
    ).orderBy('timestamp', descending: true).snapshots();
  }

  // Get stream of latest announcement for unread check
  Stream<QuerySnapshot> getLatestAnnouncementStream() {
    return _getCollection(
      'announcements',
    ).orderBy('timestamp', descending: true).limit(1).snapshots();
  }

  // Update user's last read time
  Future<void> updateLastAnnouncementRead(String userId) async {
    await _db.collection('users').doc(userId).update({
      'lastAnnouncementRead': FieldValue.serverTimestamp(),
    });
  }

  // Get user's profile stream to check lastRead
  Stream<DocumentSnapshot> getUserProfileStream(String userId) {
    return _db.collection('users').doc(userId).snapshots();
  }

  // Batch save attendance records
  Future<void> batchSaveAttendanceRecords(
    List<AttendanceRecord> records,
  ) async {
    WriteBatch batch = _db.batch();
    int batchCount = 0;

    for (var record in records) {
      DocumentReference docRef;
      if (record.id != null) {
        docRef = _getCollection('attendance_records').doc(record.id);
      } else {
        docRef = _getCollection('attendance_records').doc();
      }

      // Ensure ID is set in the record if it was generated
      Map<String, dynamic> data = record.toMap();
      if (record.id == null) {
        // If we are generating a new ID, we don't necessarily update the record object here easily
        // but for set() with new doc ref, it works.
      }

      batch.set(docRef, data);
      batchCount++;

      if (batchCount >= 500) {
        await batch.commit();
        batch = _db.batch();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }
    notifyListeners();
  }
}
