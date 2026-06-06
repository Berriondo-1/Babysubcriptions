import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminService {
  AdminService._internal();
  static final AdminService instance = AdminService._internal();

  static const String _adminCode = 'Admin2024*';

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _catalog => _db.collection('catalog');

  bool validateAdminCode(String code) => code == _adminCode;

  // ── Subir imagen a Firebase Storage ──────────────────────────
  Future<String> uploadProductImage(File imageFile, String productName) async {
    final fileName =
        '${productName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('catalog/$fileName');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  // ── CRUD catálogo ─────────────────────────────────────────────
  Future<void> addProduct(Map<String, dynamic> data) async {
    await _catalog.add({...data, 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> updateProduct(String docId, Map<String, dynamic> data) async {
    await _catalog.doc(docId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProduct(String docId) async {
    await _catalog.doc(docId).delete();
  }

  Stream<QuerySnapshot> getProductsStream() {
    return _catalog.orderBy('createdAt', descending: false).snapshots();
  }
}