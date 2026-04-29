import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of family request
enum FamilyRequestStatus { pending, accepted, rejected }

/// Model for family join requests
class FamilyRequestModel {
  final String id;
  final String familyAccountId; // ID of the family account
  final String requesterId; // ID of the user who wants to join
  final String requesterName; // Name of the requester
  final String requesterEmail; // Email of the requester
  final String ownerId; // ID of the family account owner
  final FamilyRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? message; // Optional message from requester

  FamilyRequestModel({
    required this.id,
    required this.familyAccountId,
    required this.requesterId,
    required this.requesterName,
    required this.requesterEmail,
    required this.ownerId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.message,
  });

  factory FamilyRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyRequestModel(
      id: doc.id,
      familyAccountId: data['familyAccountId'] ?? '',
      requesterId: data['requesterId'] ?? '',
      requesterName: data['requesterName'] ?? '',
      requesterEmail: data['requesterEmail'] ?? '',
      ownerId: data['ownerId'] ?? '',
      status: FamilyRequestStatus.values[data['status'] ?? 0],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null 
          ? (data['respondedAt'] as Timestamp).toDate() 
          : null,
      message: data['message'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'familyAccountId': familyAccountId,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterEmail': requesterEmail,
      'ownerId': ownerId,
      'status': status.index,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null 
          ? Timestamp.fromDate(respondedAt!) 
          : null,
      'message': message,
    };
  }

  /// Create a copy with updated status
  FamilyRequestModel copyWith({
    FamilyRequestStatus? status,
    DateTime? respondedAt,
  }) {
    return FamilyRequestModel(
      id: id,
      familyAccountId: familyAccountId,
      requesterId: requesterId,
      requesterName: requesterName,
      requesterEmail: requesterEmail,
      ownerId: ownerId,
      status: status ?? this.status,
      createdAt: createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      message: message,
    );
  }
}
