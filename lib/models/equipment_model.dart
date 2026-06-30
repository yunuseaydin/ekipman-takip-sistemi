import 'package:cloud_firestore/cloud_firestore.dart';

class EquipmentModel {
  final String id;
  final String name;
  final String category;
  final String status;
  final String? assignedTo;
  final DateTime? createdAt;

  EquipmentModel({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    this.assignedTo,
    this.createdAt,
  });

  factory EquipmentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return EquipmentModel(
      id: documentId,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      status: map['status'] ?? 'Mevcut',
      assignedTo: map['assigned_to'],
      createdAt: map['created_at'] != null
          ? (map['created_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'status': status,
      'assigned_to': assignedTo,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
