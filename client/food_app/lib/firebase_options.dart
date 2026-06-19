// ┌─────────────────────────────────────────────────────────────┐
// │  IMPORTANT: Replace all placeholder values below with the  │
// │  real values from your Firebase Console.                   │
// │                                                             │
// │  How to get these values:                                  │
// │  1. Go to console.firebase.google.com                      │
// │  2. Select your project → Project Settings (gear icon)     │
// │  3. Under "Your apps" → click your Android/Web app         │
// │  4. Copy the config values into the fields below           │
// │                                                             │
// │  OR run: flutterfire configure                             │
// │  (installs automatically: dart pub global activate         │
// │   flutterfire_cli)                                         │
// └─────────────────────────────────────────────────────────────┘

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── Web Config ─────────────────────────────────────────────
  // From: Firebase Console → Project Settings → Web app
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  // ── Android Config ─────────────────────────────────────────
  // From: Firebase Console → Project Settings → Android app
  // Also download google-services.json → place in android/app/
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  // ── iOS Config ─────────────────────────────────────────────
  // From: Firebase Console → Project Settings → iOS app
  // Also download GoogleService-Info.plist → place in ios/Runner/
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.foodApp',
  );
}
