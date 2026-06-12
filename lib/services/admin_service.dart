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

  /// Obtener todos los productos una sola vez (para el dropdown de suscripción)
  Future<List<Map<String, dynamic>>> getProductsOnce() async {
    final snap = await _catalog.orderBy('createdAt', descending: false).get();
    return snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      data['docId'] = d.id;
      return data;
    }).toList();
  }

  /// Stream de productos disponibles (stockQuantity > 0)
  Stream<QuerySnapshot> getAvailableProductsStream() {
    return _catalog
        .where('stockQuantity', isGreaterThan: 0)
        .snapshots();
  }

  /// Decrementar stock de un producto después de confirmar suscripción
  Future<void> decrementStock(String docId, int quantity) async {
    await _db.runTransaction((tx) async {
      final ref = _catalog.doc(docId);
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final current = (data['stockQuantity'] as num?)?.toInt() ?? 0;
      final newQty = (current - quantity).clamp(0, 999999);

      // Auto-actualizar stockStatus según la nueva cantidad
      String newStatus;
      if (newQty <= 0) {
        newStatus = 'outOfStock';
      } else if (newQty <= 10) {
        newStatus = 'lowStock';
      } else {
        newStatus = 'inStock';
      }

      tx.update(ref, {
        'stockQuantity': newQty,
        'stockStatus': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
