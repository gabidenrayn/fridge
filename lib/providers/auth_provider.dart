import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/account_model.dart';
import '../services/auth_service.dart';

/// Провайдер аутентификации
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _firebaseUser;
  UserModel? _userModel;
  AccountModel? _accountModel;
  bool _isLoading = false;
  bool _isReady = false;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<DocumentSnapshot>? _accountSubscription;

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
    // Отписаться от предыдущих слушателей
    _userSubscription?.cancel();
    _accountSubscription?.cancel();
    _userSubscription = null;
    _accountSubscription = null;

    _firebaseUser = user;
    _isReady = false;
    notifyListeners();

    if (user != null) {
      try {
        // Real-time слушатель для пользователя
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

    // Real-time слушатель для аккаунта
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

  /// Выход
  Future<void> signOut() async {
    await _authService.signOut();
  }

  /// Обновить данные профиля и аккаунта
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

      // Обновить accountId пользователя в Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_firebaseUser!.uid)
          .update({'accountId': accountId});

      debugPrint('Created family account: $accountId, updated user accountId');
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
      // Найти пользователя по email
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: memberEmail)
          .get();

      if (userQuery.docs.isEmpty) {
        return 'Пользователь с таким email не найден';
      }

      final memberId = userQuery.docs.first.id;
      await _authService.addFamilyMember(_accountModel!.id, memberId);

      // Обновить аккаунт
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
