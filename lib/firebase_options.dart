import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCZAj1er_WQab6MRyQEAUVMncPrpGCuGYM',
    appId: String.fromEnvironment('FIREBASE_WEB_APP_ID'),
    messagingSenderId: '701241608072',
    projectId: 'edutrack-phs',
    authDomain: 'edutrack-phs.firebaseapp.com',
    storageBucket: 'edutrack-phs.firebasestorage.app',
  );
}
