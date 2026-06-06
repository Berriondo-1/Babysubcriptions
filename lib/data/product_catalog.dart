import 'package:baby_subscription/models/product.dart';

class ProductCatalog {
  ProductCatalog._();

  static const List<Product> all = [
    // Recién nacido
    Product(
      id: 'nb-001',
      name: 'Pequeñín Recién Nacido',
      brand: 'Pequeñín',
      description:
          'Pañal ultrasuave con cobertura especial para ombligo, ideal para recién nacidos colombianos.',
      pricePerUnit: 950.0,
      unitsPerPack: 40,
      size: DiaperSize.newborn,
      stockStatus: StockStatus.inStock,
      emoji: '🌿',
    ),
    Product(
      id: 'nb-002',
      name: 'Winnie Recién Nacido',
      brand: 'Winnie',
      description:
          'Pañal suave con indicador de humedad, perfecto para piel sensible de neonatos.',
      pricePerUnit: 880.0,
      unitsPerPack: 44,
      size: DiaperSize.newborn,
      stockStatus: StockStatus.lowStock,
      emoji: '💛',
    ),

    // Talla 1
    Product(
      id: 's1-001',
      name: 'Pequeñín Talla 1',
      brand: 'Pequeñín',
      description:
          'Alta absorción con capa interior suave. La marca más vendida en Colombia.',
      pricePerUnit: 1050.0,
      unitsPerPack: 40,
      size: DiaperSize.size1,
      stockStatus: StockStatus.inStock,
      emoji: '🌿',
    ),
    Product(
      id: 's1-002',
      name: 'Pampers Swaddlers T1',
      brand: 'Pampers',
      description:
          'Protección hasta 12 horas con tecnología Dry Max. Disponible en grandes superficies.',
      pricePerUnit: 1280.0,
      unitsPerPack: 36,
      size: DiaperSize.size1,
      stockStatus: StockStatus.inStock,
      emoji: '🌙',
    ),
    Product(
      id: 's1-003',
      name: 'Huggies Natural Care T1',
      brand: 'Huggies',
      description:
          'Con aloe vera y vitamina E. Ajuste en 360° para mayor movilidad del bebé.',
      pricePerUnit: 1180.0,
      unitsPerPack: 38,
      size: DiaperSize.size1,
      stockStatus: StockStatus.lowStock,
      emoji: '♻️',
    ),

    // Talla 2
    Product(
      id: 's2-001',
      name: 'Pequeñín Talla 2',
      brand: 'Pequeñín',
      description:
          'Doble barrera de protección contra fugas. Económico y confiable.',
      pricePerUnit: 1150.0,
      unitsPerPack: 38,
      size: DiaperSize.size2,
      stockStatus: StockStatus.inStock,
      emoji: '🌿',
    ),
    Product(
      id: 's2-002',
      name: 'Pampers Baby-Dry T2',
      brand: 'Pampers',
      description:
          'Microcápsulas absorbentes que mantienen la piel seca hasta 12 horas.',
      pricePerUnit: 1320.0,
      unitsPerPack: 40,
      size: DiaperSize.size2,
      stockStatus: StockStatus.inStock,
      emoji: '💛',
    ),
    Product(
      id: 's2-003',
      name: 'Huggies Ultraconfort T2',
      brand: 'Huggies',
      description:
          'Diseño anatómico con elásticos suaves. Excelente ajuste para bebés activos.',
      pricePerUnit: 1250.0,
      unitsPerPack: 34,
      size: DiaperSize.size2,
      stockStatus: StockStatus.outOfStock,
      emoji: '🌙',
    ),

    // Talla 3
    Product(
      id: 's3-001',
      name: 'Pequeñín Talla 3',
      brand: 'Pequeñín',
      description:
          'Máxima absorción para bebés en etapa de gateo. Cobertura total.',
      pricePerUnit: 1250.0,
      unitsPerPack: 36,
      size: DiaperSize.size3,
      stockStatus: StockStatus.inStock,
      emoji: '🌿',
    ),
    Product(
      id: 's3-002',
      name: 'Winnie Active T3',
      brand: 'Winnie',
      description:
          'Pañal flexible con bandas elásticas que se adaptan al movimiento del bebé.',
      pricePerUnit: 1200.0,
      unitsPerPack: 36,
      size: DiaperSize.size3,
      stockStatus: StockStatus.inStock,
      emoji: '♻️',
    ),
    Product(
      id: 's3-003',
      name: 'Huggies Ultraconfort T3',
      brand: 'Huggies',
      description:
          'Con loción de aloe vera. Suave para la piel y seguro para el juego diario.',
      pricePerUnit: 1350.0,
      unitsPerPack: 38,
      size: DiaperSize.size3,
      stockStatus: StockStatus.lowStock,
      emoji: '💛',
    ),

    // Talla 4
    Product(
      id: 's4-001',
      name: 'Pequeñín Talla 4',
      brand: 'Pequeñín',
      description:
          'Para bebés más activos. Sistema antifugas de triple barrera.',
      pricePerUnit: 1350.0,
      unitsPerPack: 34,
      size: DiaperSize.size4,
      stockStatus: StockStatus.inStock,
      emoji: '🌿',
    ),
    Product(
      id: 's4-002',
      name: 'Pampers Active Baby T4',
      brand: 'Pampers',
      description:
          'Pañal con núcleo absorbente de gel. Ideal para niños que ya dan sus primeros pasos.',
      pricePerUnit: 1580.0,
      unitsPerPack: 30,
      size: DiaperSize.size4,
      stockStatus: StockStatus.inStock,
      emoji: '🌙',
    ),

    // Talla 5
    Product(
      id: 's5-001',
      name: 'Pequeñín Talla 5',
      brand: 'Pequeñín',
      description:
          'Mayor cobertura para bebés grandes. Ajuste seguro y cómodo todo el día.',
      pricePerUnit: 1450.0,
      unitsPerPack: 32,
      size: DiaperSize.size5,
      stockStatus: StockStatus.inStock,
      emoji: '🌿',
    ),
    Product(
      id: 's5-002',
      name: 'Huggies Natural Care T5',
      brand: 'Huggies',
      description:
          'Pañal premium con aloe y vitamina E. El preferido para bebés en etapa de aprendizaje.',
      pricePerUnit: 1620.0,
      unitsPerPack: 32,
      size: DiaperSize.size5,
      stockStatus: StockStatus.lowStock,
      emoji: '♻️',
    ),
  ];

  static List<Product> bySize(DiaperSize size) =>
      all.where((p) => p.size == size).toList();
}
