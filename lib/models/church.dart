import 'package:cloud_firestore/cloud_firestore.dart';

class Church {
  final String id;
  final String name;
  final String address;
  final String adminId;
  final DateTime createdAt;
  final String? logoUrl;
  final String? churchCode; // For joining

  Church({
    required this.id,
    required this.name,
    required this.address,
    required this.adminId,
    required this.createdAt,
    this.logoUrl,
    this.churchCode,
  });

  factory Church.fromMap(Map<String, dynamic> data, String id) {
    return Church(
      id: id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      adminId: data['adminId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      logoUrl: data['logoUrl'],
      churchCode: data['churchCode'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'adminId': adminId,
      'createdAt': Timestamp.fromDate(createdAt),
      'logoUrl': logoUrl,
      'churchCode': churchCode,
    };
  }

  Church copyWith({
    String? name,
    String? address,
    String? adminId,
    String? logoUrl,
    String? churchCode,
  }) {
    return Church(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      adminId: adminId ?? this.adminId,
      createdAt: createdAt,
      logoUrl: logoUrl ?? this.logoUrl,
      churchCode: churchCode ?? this.churchCode,
    );
  }
}
