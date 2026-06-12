enum DiaperSize { newborn, size1, size2, size3, size4, size5 }

extension DiaperSizeExt on DiaperSize {
  String get label {
    switch (this) {
      case DiaperSize.newborn:
        return 'Recién nacido';
      case DiaperSize.size1:
        return 'Talla 1';
      case DiaperSize.size2:
        return 'Talla 2';
      case DiaperSize.size3:
        return 'Talla 3';
      case DiaperSize.size4:
        return 'Talla 4';
      case DiaperSize.size5:
        return 'Talla 5';
    }
  }

  String get weightRange {
    switch (this) {
      case DiaperSize.newborn:
        return '< 3 kg';
      case DiaperSize.size1:
        return '3–5 kg';
      case DiaperSize.size2:
        return '5–8 kg';
      case DiaperSize.size3:
        return '8–11 kg';
      case DiaperSize.size4:
        return '11–14 kg';
      case DiaperSize.size5:
        return '14–17 kg';
    }
  }
}

enum StockStatus { inStock, lowStock, outOfStock }

extension StockStatusExt on StockStatus {
  String get label {
    switch (this) {
      case StockStatus.inStock:
        return 'Disponible';
      case StockStatus.lowStock:
        return 'Pocas unidades';
      case StockStatus.outOfStock:
        return 'Agotado';
    }
  }
}

class Product {
  final String id;
  final String name;
  final String brand;
  final String description;
  final double packPrice;
  final int unitsPerPack;
  final DiaperSize size;
  final StockStatus stockStatus;
  final String emoji;
  final String? imageUrl; // ← nuevo

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.description,
    required this.packPrice,
    required this.unitsPerPack,
    required this.size,
    required this.stockStatus,
    required this.emoji,
    this.imageUrl,       // ← nuevo
  });

  double get pricePerUnit =>
      unitsPerPack > 0 ? packPrice / unitsPerPack : 0.0;
}