import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Centralized Firestore configuration handling database instances.
class FirestoreConfig {
  static FirebaseFirestore? _cachedDb;

  static FirebaseFirestore get db {
    if (_cachedDb != null) return _cachedDb!;

    try {
      // Try database 'mselectricals' configured in firebase.json
      _cachedDb = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'mselectricals',
      );
    } catch (e) {
      debugPrint('Firestore database fallback to (default): $e');
      _cachedDb = FirebaseFirestore.instance;
    }
    return _cachedDb!;
  }
}
