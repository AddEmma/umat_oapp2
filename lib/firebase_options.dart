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
    apiKey: 'AIzaSyDsPCI-fumUklZ3y9BR0fJ4r1XEZZ2FU34',
    appId: '1:98035957466:web:7bf4d7d5901c5677fd6fe3',
    messagingSenderId: '98035957466',
    projectId: 'umat-srid-fef04',
    authDomain: 'umat-srid-fef04.firebaseapp.com',
    storageBucket: 'umat-srid-fef04.firebasestorage.app',
    measurementId: 'G-9Z5M48KLJ1',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDoRT9TMo9DVrfvYhBjXCZD3K9qAwFwx3g',
    appId: '1:98035957466:android:380775153b9e985cfd6fe3',
    messagingSenderId: '98035957466',
    projectId: 'umat-srid-fef04',
    storageBucket: 'umat-srid-fef04.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDoRT9TMo9DVrfvYhBjXCZD3K9qAwFwx3g',
    appId:
        '1:98035957466:ios:380775153b9e985cfd6fe3', // Inferred, but matches project number
    messagingSenderId: '98035957466',
    projectId: 'umat-srid-fef04',
    storageBucket: 'umat-srid-fef04.firebasestorage.app',
    iosBundleId: 'com.example.umatSridOapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDoRT9TMo9DVrfvYhBjXCZD3K9qAwFwx3g',
    appId: '1:98035957466:ios:380775153b9e985cfd6fe3',
    messagingSenderId: '98035957466',
    projectId: 'umat-srid-fef04',
    storageBucket: 'umat-srid-fef04.firebasestorage.app',
    iosBundleId: 'com.example.umatSridOapp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDsPCI-fumUklZ3y9BR0fJ4r1XEZZ2FU34',
    appId: '1:98035957466:web:7bf4d7d5901c5677fd6fe3',
    messagingSenderId: '98035957466',
    projectId: 'umat-srid-fef04',
    authDomain: 'umat-srid-fef04.firebaseapp.com',
    storageBucket: 'umat-srid-fef04.firebasestorage.app',
    measurementId: 'G-9Z5M48KLJ1',
  );
}
