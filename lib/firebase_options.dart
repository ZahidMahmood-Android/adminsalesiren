import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    throw UnsupportedError(
      'Salesiren Admin Panel currently targets Flutter Web only.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_API_KEY',
      defaultValue: 'AIzaSyB2DMgu7ysAVNtVXzNoYx8RM3fahaXU2I0',
    ),
    appId: String.fromEnvironment(
      'FIREBASE_APP_ID',
      defaultValue: '1:508084936274:web:09afbbe5f09874ea22498b',
    ),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: '508084936274',
    ),
    projectId: String.fromEnvironment(
      'FIREBASE_PROJECT_ID',
      defaultValue: 'salesiren-5539c',
    ),
    authDomain: String.fromEnvironment(
      'FIREBASE_AUTH_DOMAIN',
      defaultValue: 'salesiren-5539c.firebaseapp.com',
    ),
    storageBucket: String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
      defaultValue: 'salesiren-5539c.firebasestorage.app',
    ),
  );
}
