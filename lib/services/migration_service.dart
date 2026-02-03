import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/church.dart';

class MigrationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Checks if migration is needed (i.e., user exists but has no churchId)
  Future<bool> needsMigration() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final userDoc = await _db.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return false;

    final data = userDoc.data() as Map<String, dynamic>;
    // If no churchId is set, but we have data, we might need migration
    return data['churchId'] == null;
  }

  Future<void> performMigration(
    String churchName,
    String address, {
    bool includeLegacyData = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    // 1. Create the new Church
    final churchRef = _db.collection('churches').doc();
    final newChurch = Church(
      id: churchRef.id,
      name: churchName,
      address: address,
      adminId: user.uid,
      createdAt: DateTime.now(),
      churchCode: _generateChurchCode(churchName),
    );

    await churchRef.set(newChurch.toMap());
    print('Created Church: ${newChurch.name} (${newChurch.id})');

    // 2. Migrate Collections (ONLY if requested)
    if (includeLegacyData) {
      await _migrateCollection('members', churchRef.id);
      await _migrateCollection('meetings', churchRef.id);
      await _migrateCollection('attendance_records', churchRef.id);
      await _migrateCollection('announcements', churchRef.id);
    }

    // 3. Update Current User
    await _db.collection('users').doc(user.uid).update({
      'churchId': churchRef.id,
      'role': 'admin', // Ensure the creator is admin
    });

    // 4. Update any other users if necessary (Optional: for now only migrating current user)
    // In a real scenario, you might want to find all users and assigning them,
    // but typically the first admin claims the data.
  }

  Future<void> _migrateCollection(
    String collectionName,
    String churchId,
  ) async {
    final rootCollection = _db.collection(collectionName);
    final targetCollection = _db
        .collection('churches')
        .doc(churchId)
        .collection(collectionName);

    // Get all documents from root
    final snapshot = await rootCollection.get();
    print('Migrating $collectionName: ${snapshot.size} documents found.');

    final batchSize = 500;
    var batch = _db.batch();
    var count = 0;

    for (var doc in snapshot.docs) {
      // Copy to new location
      batch.set(targetCollection.doc(doc.id), doc.data());

      // OPTIONAL: Delete from old location?
      // Safe approach: Keep old data for now, user can manually delete later or
      // we can have a simplified "cleanup" script.
      // For this implementation, we will NOT delete to prevent data loss accidents.

      count++;
      if (count >= batchSize) {
        await batch.commit();
        batch = _db.batch();
        count = 0;
      }
    }

    if (count > 0) {
      await batch.commit();
    }
    print('Finished migrating $collectionName');
  }

  String _generateChurchCode(String churchName) {
    // 1. Get first 4 characters of the name (uppercase, no spaces/special chars)
    String cleanName = churchName
        .replaceAll(RegExp(r'[^a-zA-Z]'), '')
        .toUpperCase();
    String prefix = cleanName.length >= 4
        ? cleanName.substring(0, 4)
        : cleanName.padRight(
            4,
            'X',
          ); // Padding if name is too short (e.g. "ABC" -> "ABCX")

    // 2. Generate 4 random digits
    String pin = (1000 + DateTime.now().microsecondsSinceEpoch % 9000)
        .toString();

    // Result: GRAC1234
    return '$prefix$pin';
  }
}
