// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDhKe92mK8diMqYywUuYjsQG2KzqieGMHY",
    authDomain: "umat-srid.firebaseapp.com",
    projectId: "umat-srid",
    storageBucket: "umat-srid.firebasestorage.app",
    messagingSenderId: "878956500215",
    appId: "1:878956500215:web:ed15355c4fb10cfddbeff2",
    measurementId: "G-SDR5JSQ832",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDoRT9TMo9DVrfvYhBjXCZD3K9qAwFwx3g',
    appId: '1:98035957466:android:380775153b9e985cfd6fe3',
    messagingSenderId: '98035957466',
    projectId: 'umat-srid-fef04',
    storageBucket: 'umat-srid-fef04.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '878956500215',
    projectId: 'umat-srid',
    storageBucket: 'umat-srid.firebasestorage.app',
    iosBundleId: 'com.example.umatSridOapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: '878956500215',
    projectId: 'umat-srid',
    storageBucket: 'umat-srid.firebasestorage.app',
    iosBundleId: 'com.example.umatSridOapp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_WINDOWS_API_KEY',
    appId: 'YOUR_WINDOWS_APP_ID',
    messagingSenderId: '878956500215',
    projectId: 'umat-srid',
    storageBucket: 'umat-srid.firebasestorage.app',
  );
}
