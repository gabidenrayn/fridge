import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/account_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _firebaseUser;
  UserModel? _userModel;
  AccountModel? _accountModel;
  bool _isLoading = false;
  bool _isReady = false;
  StreamSubscription? _userSubscription;
  StreamSubscription? _accountSubscription;

  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  AccountModel? get accountModel => _accountModel;
  bool get isLoading => _isLoading;
  bool get isReady => _isReady;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _userSubscription?.cancel();
    _accountSubscription?.cancel();
    _userSubscription = null;
    _accountSubscription = null;

    _firebaseUser = user;
    _isReady = false;
    notifyListeners();

    if (user != null) {
      try {
        _userSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((doc) {
          if (doc.exists) {
            _userModel = UserModel.fromFirestore(doc);
            _startAccountListener();
          } else {
            _userModel = null;
            _accountModel = null;
          }
          _isReady = true;
          notifyListeners();
        }, onError: (error) {
          debugPrint('User snapshot error: $error');
        });
      } catch (_) {
        _userModel = null;
        _accountModel = null;
        _isReady = true;
        notifyListeners();
      }
    } else {
      _userModel = null;
      _accountModel = null;
      _isReady = true;
      notifyListeners();
    }
  }

  void _startAccountListener() {
    if (_userModel == null) return;
    _accountSubscription?.cancel();
    _accountSubscription = null;

    _accountSubscription = FirebaseFirestore.instance
        .collection('accounts')
        .doc(_userModel!.accountId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        _accountModel = AccountModel.fromFirestore(doc);
      } else {
        _accountModel = null;
      }
      notifyListeners();
    }, onError: (error) {
      debugPrint('Account snapshot error: $error');
    });
  }

  /// Регистрация
  Future<String?> register(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.registerWithEmailAndPassword(email, password, name);
      return null;
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Вход
  Future<String?> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signInWithEmailAndPassword(email, password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Выход из приложения
  Future<void> signOut() async {
    await _authService.signOut();
  }

  /// Обновить профиль
  Future<void> reloadProfile() async {
    if (_firebaseUser == null) return;
    _isReady = false;
    notifyListeners();
    try {
      _userModel = await _authService.getUserData(_firebaseUser!.uid);
      if (_userModel != null) {
        _accountModel = await _authService.getAccount(_userModel!.accountId);
      } else {
        _accountModel = null;
      }
    } catch (_) {
      _accountModel = null;
    }
    _isReady = true;
    notifyListeners();
  }

  /// Создать семейный аккаунт
  Future<String?> createFamilyAccount(String name) async {
    if (_firebaseUser == null) return 'Пользователь не авторизован';
    try {
      final accountId = await _authService.createFamilyAccount(
        name,
        _firebaseUser!.uid,
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_firebaseUser!.uid)
          .update({'accountId': accountId});

      // Добавляем nameLower для поиска
      await FirebaseFirestore.instance
          .collection('accounts')
          .doc(accountId)
          .update({'nameLower': name.toLowerCase()});

      debugPrint('Created family account: $accountId');
      return null;
    } catch (e) {
      debugPrint('Error creating family account: $e');
      return 'Ошибка создания семейного аккаунта';
    }
  }

  /// Добавить члена семьи
  Future<String?> addFamilyMember(String memberEmail) async {
    if (_accountModel == null || _accountModel!.type != AccountType.family) {
      return 'Требуется семейный аккаунт';
    }
    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: memberEmail)
          .get();
      if (userQuery.docs.isEmpty) {
        return 'Пользователь с таким email не найден';
      }
      final memberId = userQuery.docs.first.id;
      await _authService.addFamilyMember(_accountModel!.id, memberId);
      _accountModel = await _authService.getAccount(_accountModel!.id);
      notifyListeners();
      return null;
    } catch (e) {
      return 'Ошибка добавления члена семьи';
    }
  }

  /// Удалить члена семьи
  Future<String?> removeFamilyMember(String memberId) async {
    if (_accountModel == null || _accountModel!.type != AccountType.family) {
      return 'Требуется семейный аккаунт';
    }
    try {
      await _authService.removeFamilyMember(_accountModel!.id, memberId);
      _accountModel = await _authService.getAccount(_accountModel!.id);
      notifyListeners();
      return null;
    } catch (e) {
      return 'Ошибка удаления члена семьи';
    }
  }

  /// Выйти из семейного аккаунта (стать личным)
  Future<String?> leaveFamily() async {
    final uid = _firebaseUser?.uid;
    if (uid == null) return 'Не авторизован';
    try {
      final accountId = _accountModel?.id;
      if (accountId == null) return 'Аккаунт не найден';

      debugPrint('Leaving family: uid=$uid, accountId=$accountId');

      // Убираем себя из memberIds семейного аккаунта
      await FirebaseFirestore.instance
          .collection('accounts')
          .doc(accountId)
          .update({
        'memberIds': FieldValue.arrayRemove([uid]),
      });

      debugPrint('Removed from family members');

      // Создаём новый личный аккаунт
      final personalRef =
          await FirebaseFirestore.instance.collection('accounts').add({
        'type': 'personal',
        'name': _userModel?.name ?? 'Аккаунт',
        'ownerId': uid,
        'memberIds': [],
        'nameLower': (_userModel?.name ?? '').toLowerCase(),
      });

      debugPrint('Created personal account: ${personalRef.id}');

      // Обновляем accountId у пользователя
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'accountId': personalRef.id});

      debugPrint('Updated user accountId to personal account');

      await reloadProfile();
      debugPrint('Reloaded profile after leaving family');
      return null;
    } catch (e) {
      debugPrint('Error leaving family: $e');
      return 'Ошибка выхода из семьи';
    }
  }

  /// Отправить запрос на вступление в семью
  Future<String?> sendFamilyJoinRequest({
    required String familyId,
    required String message,
  }) async {
    final uid = _firebaseUser?.uid;
    if (uid == null) return 'Не авторизован';
    try {
      final famDoc = await FirebaseFirestore.instance
          .collection('accounts')
          .doc(familyId)
          .get();
      final familyName = famDoc.data()?['name'] ?? 'Семья';

      // Проверяем нет ли уже запроса
      final existing = await FirebaseFirestore.instance
          .collection('familyRequests')
          .where('userId', isEqualTo: uid)
          .where('familyId', isEqualTo: familyId)
          .where('status', isEqualTo: 'pending')
          .get();
      if (existing.docs.isNotEmpty) {
        return 'Запрос уже отправлен';
      }

      await FirebaseFirestore.instance.collection('familyRequests').add({
        'userId': uid,
        'familyId': familyId,
        'familyName': familyName,
        'message': message,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      debugPrint('Error sending join request: $e');
      return 'Ошибка отправки запроса';
    }
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'email-already-in-use':
        return 'Email уже используется';
      case 'weak-password':
        return 'Слабый пароль';
      case 'invalid-email':
        return 'Неверный email';
      default:
        return 'Ошибка аутентификации';
    }
  }
}
