// TODO: Замените на реальные значения из Firebase Console
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // Web конфигурация
      return const FirebaseOptions(
        apiKey: 'AIzaSyA4oGeHJskSehcxspne0u1AR1eXA_hrIws',
        appId: '1:521663540366:web:a26f8f93d56093ccdfeddf',
        messagingSenderId: '521663540366',
        projectId: 'smart-fridge-9a7c1',
        authDomain: 'smart-fridge-9a7c1.firebaseapp.com',
        storageBucket: 'smart-fridge-9a7c1.appspot.com',
      );
    } else {
      // Android/iOS конфигурация
      return const FirebaseOptions(
        apiKey: 'AIzaSyA4oGeHJskSehcxspne0u1AR1eXA_hrIws',
        appId: '1:521663540366:android:a26f8f93d56093ccdfeddf',
        messagingSenderId: '521663540366',
        projectId: 'smart-fridge-9a7c1',
      );
    }
  }
}
