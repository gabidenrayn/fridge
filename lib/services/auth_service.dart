import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/account_model.dart';
import '../models/family_request_model.dart';

/// Сервис аутентификации
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Поток текущего пользователя
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Текущий пользователь Firebase
  User? get currentUser => _auth.currentUser;

  /// Регистрация нового пользователя
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Создаем личный аккаунт для нового пользователя
    final accountId = await _createPersonalAccount(credential.user!.uid, name);

    // Создаем документ пользователя
    final user = UserModel(
      id: credential.user!.uid,
      email: email,
      name: name,
      createdAt: DateTime.now(),
      accountId: accountId,
    );

    await _firestore.collection('users').doc(user.id).set(user.toFirestore());

    return credential;
  }

  /// Вход в систему
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Выход из системы
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Получить данные пользователя
  Future<UserModel?> getUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  /// Создать личный аккаунт
  Future<String> _createPersonalAccount(String userId, String name) async {
    final account = AccountModel(
      id: '', // Firestore сгенерирует ID
      name: '$name\'s Fridge',
      type: AccountType.personal,
      ownerId: userId,
      memberIds: [],
      createdAt: DateTime.now(),
    );

    final docRef = await _firestore
        .collection('accounts')
        .add(account.toFirestore());
    return docRef.id;
  }

  /// Создать семейный аккаунт
  Future<String> createFamilyAccount(String name, String ownerId) async {
    final account = AccountModel(
      id: '',
      name: name,
      type: AccountType.family,
      ownerId: ownerId,
      memberIds: [],
      createdAt: DateTime.now(),
    );

    final docRef = await _firestore
        .collection('accounts')
        .add(account.toFirestore());
    return docRef.id;
  }

  /// Получить аккаунт по ID
  Future<AccountModel?> getAccount(String accountId) async {
    final doc = await _firestore.collection('accounts').doc(accountId).get();
    if (doc.exists) {
      return AccountModel.fromFirestore(doc);
    }
    return null;
  }

  /// Добавить члена в семейный аккаунт
  Future<void> addFamilyMember(String accountId, String memberId) async {
    await _firestore.collection('accounts').doc(accountId).update({
      'memberIds': FieldValue.arrayUnion([memberId]),
    });

    // Обновить accountId у пользователя
    await _firestore.collection('users').doc(memberId).update({
      'accountId': accountId,
    });
  }

  /// Удалить члена из семейного аккаунта
  Future<void> removeFamilyMember(String accountId, String memberId) async {
    await _firestore.collection('accounts').doc(accountId).update({
      'memberIds': FieldValue.arrayRemove([memberId]),
    });

    // Создать новый личный аккаунт для удаленного члена
    final userDoc = await _firestore.collection('users').doc(memberId).get();
    final user = UserModel.fromFirestore(userDoc);
    final newAccountId = await _createPersonalAccount(memberId, user.name);

    await _firestore.collection('users').doc(memberId).update({
      'accountId': newAccountId,
    });
  }

  /// Send request to join family account
  Future<String> sendFamilyRequest(
    String familyAccountId,
    String requesterId,
    String requesterName,
    String requesterEmail, {
    String? message,
  }) async {
    // Get family account to find owner
    final familyDoc = await _firestore.collection('accounts').doc(familyAccountId).get();
    if (!familyDoc.exists) {
      throw Exception('Family account not found');
    }

    final family = AccountModel.fromFirestore(familyDoc);
    if (family.type != AccountType.family) {
      throw Exception('This is not a family account');
    }

    // Check if user is already a member
    if (family.isMember(requesterId)) {
      throw Exception('You are already a member of this family');
    }

    // Check if request already exists
    final existingRequests = await _firestore
        .collection('family_requests')
        .where('familyAccountId', isEqualTo: familyAccountId)
        .where('requesterId', isEqualTo: requesterId)
        .where('status', isEqualTo: FamilyRequestStatus.pending.index)
        .get();

    if (existingRequests.docs.isNotEmpty) {
      throw Exception('Request already sent');
    }

    final request = FamilyRequestModel(
      id: '', // Firestore will generate ID
      familyAccountId: familyAccountId,
      requesterId: requesterId,
      requesterName: requesterName,
      requesterEmail: requesterEmail,
      ownerId: family.ownerId,
      status: FamilyRequestStatus.pending,
      createdAt: DateTime.now(),
      message: message,
    );

    final docRef = await _firestore
        .collection('family_requests')
        .add(request.toFirestore());
    return docRef.id;
  }

  /// Get pending requests for family owner
  Future<List<FamilyRequestModel>> getPendingRequests(String ownerId) async {
    final snapshot = await _firestore
        .collection('family_requests')
        .where('ownerId', isEqualTo: ownerId)
        .where('status', isEqualTo: FamilyRequestStatus.pending.index)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => FamilyRequestModel.fromFirestore(doc))
        .toList();
  }

  /// Accept family request
  Future<void> acceptFamilyRequest(String requestId) async {
    final requestDoc = await _firestore.collection('family_requests').doc(requestId).get();
    if (!requestDoc.exists) {
      throw Exception('Request not found');
    }

    final request = FamilyRequestModel.fromFirestore(requestDoc);

    // Add user to family account
    await addFamilyMember(request.familyAccountId, request.requesterId);

    // Update request status
    await _firestore.collection('family_requests').doc(requestId).update({
      'status': FamilyRequestStatus.accepted.index,
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Reject family request
  Future<void> rejectFamilyRequest(String requestId) async {
    await _firestore.collection('family_requests').doc(requestId).update({
      'status': FamilyRequestStatus.rejected.index,
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Get user's sent requests
  Future<List<FamilyRequestModel>> getUserRequests(String userId) async {
    final snapshot = await _firestore
        .collection('family_requests')
        .where('requesterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => FamilyRequestModel.fromFirestore(doc))
        .toList();
  }

  /// Find family accounts by name or email
  Future<List<AccountModel>> searchFamilyAccounts(String query) async {
    final snapshot = await _firestore
        .collection('accounts')
        .where('type', isEqualTo: AccountType.family.index)
        .get();

    final results = <AccountModel>[];
    for (final doc in snapshot.docs) {
      final account = AccountModel.fromFirestore(doc);
      if (account.name.toLowerCase().contains(query.toLowerCase())) {
        results.add(account);
      }
    }

    return results;
  }
}
