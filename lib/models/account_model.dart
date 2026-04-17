import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип аккаунта
enum AccountType { personal, family }

/// Модель аккаунта
class AccountModel {
  final String id;
  final String name;
  final AccountType type;
  final String ownerId; // ID владельца аккаунта
  final List<String> memberIds; // Список ID членов (для семейного аккаунта)
  final DateTime createdAt;

  AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.ownerId,
    required this.memberIds,
    required this.createdAt,
  });

  factory AccountModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AccountModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: AccountType.values[data['type'] ?? 0],
      ownerId: data['ownerId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type.index,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Проверяет, является ли пользователь членом аккаунта
  bool isMember(String userId) {
    return ownerId == userId || memberIds.contains(userId);
  }
}
