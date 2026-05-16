import 'package:baby_subscription/models/product.dart';

// Datos mock — reemplazar con llamada a API/Firebase cuando esté disponible
class ProductCatalog {
  ProductCatalog._();

  static const List<Product> all = [
    // Newborn
    Product(
      id: 'nb-001',
      name: 'Premium Bamboo',
      brand: 'BabyNature',
      description: 'Ultra-soft bamboo fiber, hypoallergenic and eco-friendly.',
      pricePerUnit: 0.22,
      unitsPerPack: 40,
      size: DiaperSize.newborn,
      stockStatus: StockStatus.inStock,
      emoji: '🌿',
    ),
    Product(
      id: 'nb-002',
      name: 'Sensitive Skin',
      brand: 'GentleCare',
      description: 'Fragrance-free formula for sensitive newborn skin.',
      pricePerUnit: 0.20,
      unitsPerPack: 44,
      size: DiaperSize.newborn,
      stockStatus: StockStatus.lowStock,
      emoji: '💛',
    ),

    // Size 1
    Product(
      id: 's1-001',
      name: 'Premium Bamboo',
      brand: 'BabyNature',
      description: 'Ultra-soft bamboo fiber, hypoallergenic and eco-friendly.',
      pricePerUnit: 0.24,
      unitsPerPack: 40,
      size: DiaperSize.size1,
      stockStatus: StockStatus.inStock,
      emoji: '🌿',
    ),
    Product(
      id: 's1-002',
      name: 'Overnight Plus',
      brand: 'DryNight',
      description: '12-hour overnight protection with extra absorbency.',
      pricePerUnit: 0.28,
      unitsPerPack: 36,
      size: DiaperSize.size1,
      stockStatus: StockStatus.inStock,
      emoji: '🌙',
    ),
    Product(
      id: 's1-003',
      name: 'Eco-Friendly',
      brand: 'GreenBaby',
      description: 'Made from 100% plant-based materials, biodegradable.',
      pricePerUnit: 0.26,
      unitsPerPack: 38,
      size: DiaperSize.size1,
      stockStatus: StockStatus.lowStock,
      emoji: '♻️',
    ),

    // Size 2
    Product(
      id: 's2-001',
      name: 'Premium Bamboo',
      brand: 'BabyNature',
      description: 'Ultra-soft bamboo fiber, hypoallergenic and eco-friendly.',
      pricePerUnit: 0.26,
      unitsPerPack: 38,
      size: DiaperSize.size2,
      stockStatus: StockStatus.inStock,
      emoji: '🌿',
    ),
    Product(
      id: 's2-002',
      name: 'Sensitive Skin',
      brand: 'GentleCare',
      description: 'Fragrance-free formula, dermatologist tested.',
      pricePerUnit: 0.24,
      unitsPerPack: 40,
      size: DiaperSize.size2,
      stockStatus: StockStatus.inStock,
      emoji: '💛',
    ),
    Product(
      id: 's2-003',
      name: 'Overnight Plus',
      brand: 'DryNight',
      description: '12-hour overnight protection with extra absorbency.',
      pricePerUnit: 0.30,
      unitsPerPack: 34,
      size: DiaperSize.size2,
      stockStatus: StockStatus.outOfStock,
      emoji: '🌙',
    ),

    // Size 3
    Product(
      id: 's3-001',
      name: 'Premium Bamboo',
      brand: 'BabyNature',
      description: 'Ultra-soft bamboo fiber, hypoallergenic and eco-friendly.',
      pricePerUnit: 0.28,
      unitsPerPack: 36,
      size: DiaperSize.size3,
      stockStatus: StockStatus.inStock,
      emoji: '🌿',
    ),
    Product(
      id: 's3-002',
      name: 'Eco-Friendly',
      brand: 'GreenBaby',
      description: 'Made from 100% plant-based materials, biodegradable.',
      pricePerUnit: 0.27,
      unitsPerPack: 36,
      size: DiaperSize.size3,
      stockStatus: StockStatus.inStock,
      emoji: '♻️',
    ),
    Product(
      id: 's3-003',
      name: 'Sensitive Skin',
      brand: 'GentleCare',
      description: 'Fragrance-free formula, dermatologist tested.',
      pricePerUnit: 0.26,
      unitsPerPack: 38,
      size: DiaperSize.size3,
      stockStatus: StockStatus.lowStock,
      emoji: '💛',
    ),

    // Size 4
    Product(
      id: 's4-001',
      name: 'Premium Bamboo',
      brand: 'BabyNature',
      description: 'Ultra-soft bamboo fiber, hypoallergenic and eco-friendly.',
      pricePerUnit: 0.30,
      unitsPerPack: 34,
      size: DiaperSize.size4,
      stockStatus: StockStatus.inStock,
      emoji: '🌿',
    ),
    Product(
      id: 's4-002',
      name: 'Overnight Plus',
      brand: 'DryNight',
      description: '12-hour overnight protection with extra absorbency.',
      pricePerUnit: 0.34,
      unitsPerPack: 30,
      size: DiaperSize.size4,
      stockStatus: StockStatus.inStock,
      emoji: '🌙',
    ),

    // Size 5
    Product(
      id: 's5-001',
      name: 'Premium Bamboo',
      brand: 'BabyNature',
      description: 'Ultra-soft bamboo fiber, hypoallergenic and eco-friendly.',
      pricePerUnit: 0.32,
      unitsPerPack: 32,
      size: DiaperSize.size5,
      stockStatus: StockStatus.inStock,
      emoji: '🌿',
    ),
    Product(
      id: 's5-002',
      name: 'Eco-Friendly',
      brand: 'GreenBaby',
      description: 'Made from 100% plant-based materials, biodegradable.',
      pricePerUnit: 0.31,
      unitsPerPack: 32,
      size: DiaperSize.size5,
      stockStatus: StockStatus.lowStock,
      emoji: '♻️',
    ),
  ];

  static List<Product> bySize(DiaperSize size) =>
      all.where((p) => p.size == size).toList();
}