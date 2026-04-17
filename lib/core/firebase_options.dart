// TODO: Замените на реальные значения из Firebase Console
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Для Android
    return const FirebaseOptions(
      apiKey: 'AIzaSyA4oGeHJskSehcxspne0u1AR1eXA_hrIws',
      appId: '1:521663540366:web:a26f8f93d56093ccdfeddf',
      messagingSenderId: '521663540366',
      projectId: 'smart-fridge-9a7c1',
    );
  }
}
