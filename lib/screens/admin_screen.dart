import 'package:baby_subscription/services/admin_service.dart';
import 'package:baby_subscription/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Panel Admin — Catálogo'),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Agregar producto',
            onPressed: () => _showProductSheet(context, null, null),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: AdminService.instance.getProductsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📦', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text(
                    'No hay productos aún',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showProductSheet(context, null, null),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Agregar producto'),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              return _AdminProductCard(
                docId: doc.id,
                data: data,
                onEdit: () => _showProductSheet(context, doc.id, data),
                onDelete: () => _confirmDelete(context, doc.id, data['name'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }

  void _showProductSheet(
    BuildContext context,
    String? docId,
    Map<String, dynamic>? existing,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductFormSheet(docId: docId, existing: existing),
    );
  }

  void _confirmDelete(BuildContext context, String docId, String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 30),
            ),
            const SizedBox(height: 16),
            Text('Eliminar producto',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '¿Eliminar "$name" del catálogo? Esta acción no se puede deshacer.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await AdminService.instance.deleteProduct(docId);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Sí, eliminar'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta de producto en admin ──────────────────────────────────────────────

class _AdminProductCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminProductCard({
    required this.docId,
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                data['emoji'] ?? '📦',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? '',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${data['brand'] ?? ''}  ·  Talla: ${data['size'] ?? ''}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${(data['packPrice'] ?? 0).toStringAsFixed(2)}  ·  ${data['unitsPerPack'] ?? 0} uds',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.primary,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: AppColors.primary, size: 20),
                onPressed: onEdit,
                tooltip: 'Editar',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error, size: 20),
                onPressed: onDelete,
                tooltip: 'Eliminar',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Formulario agregar/editar producto ────────────────────────────────────────

class _ProductFormSheet extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existing;
  const _ProductFormSheet({this.docId, this.existing});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _unitsCtrl;
  late final TextEditingController _emojiCtrl;
  String _selectedSize = 'size1';
  String _selectedStock = 'inStock';
  bool _isSaving = false;
  File? _imageFile;
  String? _existingImageUrl;

  final _sizes = ['newborn', 'size1', 'size2', 'size3', 'size4', 'size5'];
  final _stocks = ['inStock', 'lowStock', 'outOfStock'];
  final _stockLabels = {
    'inStock': 'Disponible',
    'lowStock': 'Stock bajo',
    'outOfStock': 'Agotado',
  };
  final _sizeLabels = {
    'newborn': 'Newborn', 'size1': 'Size 1', 'size2': 'Size 2',
    'size3': 'Size 3', 'size4': 'Size 4', 'size5': 'Size 5',
  };

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?['name'] ?? '');
    _brandCtrl = TextEditingController(text: e?['brand'] ?? '');
    _descCtrl = TextEditingController(text: e?['description'] ?? '');
    _priceCtrl = TextEditingController(
        text: e?['packPrice'] != null ? e!['packPrice'].toString() : '');
    _unitsCtrl = TextEditingController(
        text: e?['unitsPerPack'] != null ? e!['unitsPerPack'].toString() : '');
    _emojiCtrl = TextEditingController(text: e?['emoji'] ?? '🍼');
    _selectedSize = e?['size'] ?? 'size1';
    _selectedStock = e?['stockStatus'] ?? 'inStock';
    _existingImageUrl = e?['imageUrl'];
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _brandCtrl.dispose(); _descCtrl.dispose();
    _priceCtrl.dispose(); _unitsCtrl.dispose(); _emojiCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 800,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      String? imageUrl = _existingImageUrl;

      // Subir imagen si se seleccionó una nueva
      if (_imageFile != null) {
        imageUrl = await AdminService.instance.uploadProductImage(
          _imageFile!,
          _nameCtrl.text.trim(),
        );
      }

      final data = {
        'name': _nameCtrl.text.trim(),
        'brand': _brandCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'packPrice': double.tryParse(_priceCtrl.text) ?? 0.0,
        'unitsPerPack': int.tryParse(_unitsCtrl.text) ?? 0,
        'emoji': _emojiCtrl.text.trim(),
        'size': _selectedSize,
        'stockStatus': _selectedStock,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

      if (widget.docId != null) {
        await AdminService.instance.updateProduct(widget.docId!, data);
      } else {
        await AdminService.instance.addProduct(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.docId != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isEdit ? 'Editar producto' : 'Nuevo producto',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),

                // Selector de imagen
                _label('Imagen del producto'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : _existingImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  _existingImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _imagePlaceholder(),
                                ),
                              )
                            : _imagePlaceholder(),
                  ),
                ),
                const SizedBox(height: 14),

                // Emoji
                _label('Emoji (se muestra si no hay imagen)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emojiCtrl,
                  decoration: const InputDecoration(hintText: '🍼'),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 14),

                // Nombre
                _label('Nombre del producto'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(hintText: 'Ej: Pampers Premium'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 14),

                // Marca
                _label('Marca'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _brandCtrl,
                  decoration: const InputDecoration(hintText: 'Ej: Pampers'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 14),

                // Descripción
                _label('Descripción'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      hintText: 'Breve descripción del producto'),
                ),
                const SizedBox(height: 14),

                // Precio y unidades
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Precio del pack'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '9.99'),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Requerido' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Unidades por pack'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _unitsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '50'),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Requerido' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Talla
                _label('Talla'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedSize,
                  decoration: const InputDecoration(),
                  items: _sizes
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(_sizeLabels[s] ?? s),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedSize = v!),
                ),
                const SizedBox(height: 14),

                // Stock
                _label('Estado de stock'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedStock,
                  decoration: const InputDecoration(),
                  items: _stocks
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(_stockLabels[s] ?? s),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedStock = v!),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(isEdit ? 'Guardar cambios' : 'Agregar producto'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_photo_alternate_outlined,
            size: 36, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(
          'Toca para agregar imagen',
          style: TextStyle(
              fontSize: 13, color: AppColors.primary,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary),
      );
}