import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/account_model.dart';

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
}
