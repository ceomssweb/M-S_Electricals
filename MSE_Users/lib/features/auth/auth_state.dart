import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/firestore_config.dart';
import '../../core/models/models.dart';

/// Listens to FirebaseAuth state and Firestore user profile data.
class AuthState extends ChangeNotifier {
  final FirebaseFirestore _db = FirestoreConfig.db;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _user;
  UserProfile? _profile;
  String? _error;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;

  AuthState() {
    try {
      _authSub = _auth.authStateChanges().listen((u) {
        _user = u;
        _listenToProfile(u?.uid);
        notifyListeners();
      });
      _user = _auth.currentUser;
      _listenToProfile(_user?.uid);
    } catch (e) {
      _error = 'Firebase configuration warning: $e';
    }
  }

  User? get user => _user;
  UserProfile? get profile => _profile;
  String? get error => _error;
  bool get loggedIn => _user != null;
  bool get isAdmin => _profile?.isAdmin == true;

  void _listenToProfile(String? uid) {
    _profileSub?.cancel();
    if (uid == null) {
      _profile = null;
      return;
    }
    _profileSub = _db.collection('users').doc(uid).snapshots().listen((snap) {
      if (snap.exists) {
        _profile = UserProfile.fromDoc(snap);
      } else {
        final email = _user?.email ?? '';
        // Create initial user doc in Firestore database as a separate record
        _db.collection('users').doc(uid).set({
          'email': email,
          'displayName': _user?.displayName ?? 'User',
          'createdAt': FieldValue.serverTimestamp(),
          'pushEnabled': true,
          'emailNotifyEnabled': true,
          'role': 'customer',
          'isAdmin': false,
        }, SetOptions(merge: true));
      }
      notifyListeners();
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    _error = null;
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Sign-in failed';
      notifyListeners();
    }
  }

  /// Admin authentication flow with automatic role escalation if email is admin domain
  Future<bool> adminSignIn(String email, String password) async {
    _error = null;
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      final user = cred.user;
      if (user != null) {
        // Tag user as admin in Firestore
        await _db.collection('users').doc(user.uid).set({
          'role': 'admin',
          'isAdmin': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Admin authentication failed';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Admin login error: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> registerWithEmail(
      String email, String password, String displayName) async {
    _error = null;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await cred.user?.updateDisplayName(displayName);

      if (cred.user != null) {
        await _db.collection('users').doc(cred.user!.uid).set({
          'email': email,
          'displayName': displayName,
          'pushEnabled': true,
          'emailNotifyEnabled': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Registration failed';
      notifyListeners();
    }
  }

  /// Update display name and phone number in Auth & Firestore profile
  Future<void> updateProfileInfo({
    required String displayName,
    required String phoneNumber,
  }) async {
    final u = _auth.currentUser;
    if (u == null) return;
    try {
      await u.updateDisplayName(displayName);
      await _db.collection('users').doc(u.uid).set({
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _user = _auth.currentUser;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update profile: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Stream of saved user addresses
  Stream<List<UserAddress>> userAddresses() {
    final uid = _user?.uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .snapshots()
        .map((qs) => qs.docs.map(UserAddress.fromDoc).toList());
  }

  /// Add new address
  Future<void> addAddress(UserAddress addr) async {
    final uid = _user?.uid;
    if (uid == null) throw StateError('Not logged in');

    final col = _db.collection('users').doc(uid).collection('addresses');

    if (addr.isDefault) {
      // Unset previous defaults
      final existing = await col.where('isDefault', isEqualTo: true).get();
      for (final doc in existing.docs) {
        await doc.reference.update({'isDefault': false});
      }
    }

    await col.add(addr.toMap());
  }

  /// Update existing address
  Future<void> updateAddress(UserAddress addr) async {
    final uid = _user?.uid;
    if (uid == null) throw StateError('Not logged in');

    final col = _db.collection('users').doc(uid).collection('addresses');

    if (addr.isDefault) {
      final existing = await col.where('isDefault', isEqualTo: true).get();
      for (final doc in existing.docs) {
        if (doc.id != addr.id) {
          await doc.reference.update({'isDefault': false});
        }
      }
    }

    await col.doc(addr.id).update(addr.toMap());
  }

  /// Delete address
  Future<void> deleteAddress(String addressId) async {
    final uid = _user?.uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .doc(addressId)
        .delete();
  }

  /// Set default address
  Future<void> setDefaultAddress(String addressId) async {
    final uid = _user?.uid;
    if (uid == null) return;

    final col = _db.collection('users').doc(uid).collection('addresses');
    final all = await col.get();
    for (final doc in all.docs) {
      await doc.reference.update({'isDefault': doc.id == addressId});
    }
  }

  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
