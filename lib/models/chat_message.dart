// models/chat_message.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final String chatRoom;

  // Reply fields
  final String? replyToId;
  final String? replyToMessage;
  final String? replyToSenderName;

  // Mentions field - list of mentioned user IDs
  final List<String> mentions;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.chatRoom,
    this.replyToId,
    this.replyToMessage,
    this.replyToSenderName,
    this.mentions = const [],
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    try {
      // Handle timestamp conversion properly
      DateTime parsedTimestamp;
      final timestampField = map['timestamp'];

      if (timestampField is Timestamp) {
        // Convert Firestore Timestamp to DateTime
        parsedTimestamp = timestampField.toDate();
      } else if (timestampField is String) {
        // Handle string timestamps (legacy format)
        parsedTimestamp = DateTime.parse(timestampField);
      } else if (timestampField == null) {
        // Handle null timestamps (server timestamp not yet populated)
        print(
          'Warning: Null timestamp found for message $id, using current time',
        );
        parsedTimestamp = DateTime.now();
      } else {
        // Handle unexpected timestamp types
        print(
          'Warning: Unexpected timestamp type ${timestampField.runtimeType} for message $id',
        );
        parsedTimestamp = DateTime.now();
      }

      // Parse mentions list
      List<String> mentionsList = [];
      if (map['mentions'] != null) {
        mentionsList = List<String>.from(map['mentions']);
      }

      return ChatMessage(
        id: id,
        senderId: map['senderId']?.toString() ?? '',
        senderName: map['senderName']?.toString() ?? 'Unknown User',
        message: map['message']?.toString() ?? '',
        timestamp: parsedTimestamp,
        chatRoom: map['chatRoom']?.toString() ?? '',
        replyToId: map['replyToId']?.toString(),
        replyToMessage: map['replyToMessage']?.toString(),
        replyToSenderName: map['replyToSenderName']?.toString(),
        mentions: mentionsList,
      );
    } catch (e, stackTrace) {
      print('Error creating ChatMessage from map: $e');
      print('Map data: $map');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'chatRoom': chatRoom,
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToMessage != null) 'replyToMessage': replyToMessage,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      if (mentions.isNotEmpty) 'mentions': mentions,
    };
  }

  // Alternative toMap method for server timestamp (recommended for new messages)
  Map<String, dynamic> toMapWithServerTimestamp() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'chatRoom': chatRoom,
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToMessage != null) 'replyToMessage': replyToMessage,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      if (mentions.isNotEmpty) 'mentions': mentions,
    };
  }

  /// Check if this message has a reply
  bool get hasReply => replyToId != null && replyToId!.isNotEmpty;

  /// Check if this message has mentions
  bool get hasMentions => mentions.isNotEmpty;

  @override
  String toString() {
    return 'ChatMessage(id: $id, senderId: $senderId, senderName: $senderName, message: $message, timestamp: $timestamp, chatRoom: $chatRoom, replyToId: $replyToId, mentions: $mentions)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.id == id &&
        other.senderId == senderId &&
        other.senderName == senderName &&
        other.message == message &&
        other.timestamp == timestamp &&
        other.chatRoom == chatRoom &&
        other.replyToId == replyToId &&
        other.replyToMessage == replyToMessage &&
        other.replyToSenderName == replyToSenderName;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      senderId,
      senderName,
      message,
      timestamp,
      chatRoom,
      replyToId,
      replyToMessage,
      replyToSenderName,
    );
  }
}
