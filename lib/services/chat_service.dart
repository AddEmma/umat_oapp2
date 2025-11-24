// services/chat_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<ChatMessage>> getMessages(String chatRoom) {
    print("🔍 Getting messages for room: $chatRoom");

    return _db
        .collection('chat_messages')
        .where('chatRoom', isEqualTo: chatRoom)
        .orderBy('timestamp', descending: true) // Use server-side ordering
        .limit(50)
        .snapshots()
        .map((snapshot) {
          print(
            "📨 Received ${snapshot.docs.length} messages for room: $chatRoom",
          );

          final messages = <ChatMessage>[];

          for (final doc in snapshot.docs) {
            print("📄 Document ID: ${doc.id}");
            print("📄 Document data: ${doc.data()}");

            try {
              final message = ChatMessage.fromMap(doc.data(), doc.id);
              messages.add(message);
              print("✅ Successfully parsed message: ${message.message}");
            } catch (e, stackTrace) {
              print("❌ Error parsing message ${doc.id}: $e");
              print("Stack trace: $stackTrace");
              // Continue processing other messages instead of failing completely
            }
          }

          print(
            "✅ Successfully parsed ${messages.length} out of ${snapshot.docs.length} messages",
          );
          return messages;
        });
  }

  // Alternative method with client-side ordering (if server-side ordering fails due to index issues)
  Stream<List<ChatMessage>> getMessagesWithClientOrdering(String chatRoom) {
    print("🔍 Getting messages for room: $chatRoom with client ordering");

    return _db
        .collection('chat_messages')
        .where('chatRoom', isEqualTo: chatRoom)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          print(
            "📨 Received ${snapshot.docs.length} messages for room: $chatRoom",
          );

          final messages = <ChatMessage>[];

          for (final doc in snapshot.docs) {
            try {
              final message = ChatMessage.fromMap(doc.data(), doc.id);
              messages.add(message);
            } catch (e) {
              print("❌ Error parsing message ${doc.id}: $e");
            }
          }

          // Sort messages by timestamp in descending order (newest first)
          messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          print("✅ Successfully parsed and sorted ${messages.length} messages");
          return messages;
        });
  }

  Future<void> sendMessage(String message, String chatRoom) async {
    final user = _auth.currentUser;
    print("🔐 Current user: ${user?.email} (${user?.uid})");
    print("💬 Sending message: '$message' to room: '$chatRoom'");

    if (user != null && message.trim().isNotEmpty) {
      try {
        // Use server timestamp for better consistency
        final messageData = {
          'senderId': user.uid,
          'senderName': user.displayName ?? user.email ?? 'Organizer',
          'message': message.trim(),
          'timestamp': FieldValue.serverTimestamp(),
          'chatRoom': chatRoom,
        };

        print("📤 Sending message data: $messageData");

        final docRef = await _db.collection('chat_messages').add(messageData);
        print("✅ Message sent successfully with ID: ${docRef.id}");

        notifyListeners();
      } catch (e) {
        print("❌ Error sending message: $e");
        rethrow;
      }
    } else {
      print("❌ Cannot send message - User: $user, Message: '$message'");
    }
  }

  List<String> getChatRooms() {
    return ['general', 'planning', 'follow_up', 'finance'];
  }
}
