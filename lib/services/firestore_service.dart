import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:baby_subscription/models/subscription.dart';
import 'package:baby_subscription/models/baby_profile.dart';

class FirestoreService {
  FirestoreService._internal();
  static final FirestoreService instance = FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference get _users => _db.collection('users');

  // ── Usuario ───────────────────────────────────────────────────
  Future<void> saveUser({
    required String email,
    String? displayName,
    String? provider,
  }) async {
    if (_userId == null) return;
    await _users.doc(_userId).set({
      'email': email,
      'displayName': displayName,
      'provider': provider ?? 'email',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Suscripciones ─────────────────────────────────────────────

  Future<void> saveSubscription(Subscription sub) async {
    if (_userId == null) return;
    await _users
        .doc(_userId)
        .collection('subscriptions')
        .doc('sub_${sub.babyProfileId}')
        .set({
      'babyProfileId': sub.babyProfileId,
      'diaperType': sub.diaperType.name,
      'quantityPerOrder': sub.quantityPerOrder,
      'frequency': sub.frequency.name,
      'isActive': sub.isActive,
      'estimatedMonthlyCost': sub.estimatedMonthlyCost,
      'createdAt': sub.createdAt.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> cancelSubscription(int babyProfileId) async {
    if (_userId == null) return;
    await _users
        .doc(_userId)
        .collection('subscriptions')
        .doc('sub_$babyProfileId')
        .update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getActiveSubscriptions() {
    if (_userId == null) return const Stream.empty();
    return _users
        .doc(_userId)
        .collection('subscriptions')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  // ── Bebés ─────────────────────────────────────────────────────

  Future<void> saveBaby(BabyProfile baby) async {
    if (_userId == null) return;
    await _users
        .doc(_userId)
        .collection('babies')
        .doc('baby_${baby.id}')
        .set({
      'localId': baby.id,
      'name': baby.name,
      'birthDate': baby.birthDate.toIso8601String(),
      'weightKg': baby.weightKg,
      'recommendedDiaperSize': baby.recommendedDiaperSize,
      'ageInMonths': baby.ageInMonths,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteBaby(int babyId) async {
    if (_userId == null) return;
    await _users
        .doc(_userId)
        .collection('babies')
        .doc('baby_$babyId')
        .delete();
  }

  Stream<QuerySnapshot> getBabies() {
    if (_userId == null) return const Stream.empty();
    return _users
        .doc(_userId)
        .collection('babies')
        .orderBy('updatedAt', descending: false)
        .snapshots();
  }

} // ← única llave de cierre de la clase