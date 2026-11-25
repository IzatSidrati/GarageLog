enum InventoryType { consumable, tool }

class GarageInventoryItem {
  const GarageInventoryItem({
    required this.id,
    required this.name,
    required this.type,
    required this.quantity,
    this.minQuantity = 1,
    this.unit = 'pcs',
    this.unitPrice = 0,
    this.location = '',
    this.borrowedBy = '',
    this.borrowedDate,
    this.notes = '',
  });

  final String id;
  final String name;
  final InventoryType type;
  final int quantity;
  final int minQuantity;
  final String unit;
  final double unitPrice;
  final String location;
  final String borrowedBy;
  final DateTime? borrowedDate;
  final String notes;

  bool get isConsumable => type == InventoryType.consumable;
  bool get isTool => type == InventoryType.tool;
  bool get isOutOfStock => isConsumable && quantity <= 0;
  bool get isLowStock => isConsumable && quantity > 0 && quantity <= minQuantity;
  bool get isBorrowed => isTool && borrowedBy.trim().isNotEmpty;

  GarageInventoryItem copyWith({
    String? id,
    String? name,
    InventoryType? type,
    int? quantity,
    int? minQuantity,
    String? unit,
    double? unitPrice,
    String? location,
    String? borrowedBy,
    DateTime? borrowedDate,
    bool clearBorrowedDate = false,
    String? notes,
  }) {
    return GarageInventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      location: location ?? this.location,
      borrowedBy: borrowedBy ?? this.borrowedBy,
      borrowedDate:
          clearBorrowedDate ? null : (borrowedDate ?? this.borrowedDate),
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'location': location,
      'borrowedBy': borrowedBy,
      'borrowedDate': borrowedDate?.toIso8601String(),
      'notes': notes,
    };
  }

  factory GarageInventoryItem.fromJson(Map<String, dynamic> json) {
    return GarageInventoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      type: InventoryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => InventoryType.consumable,
      ),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      minQuantity: (json['minQuantity'] as num?)?.toInt() ?? 1,
      unit: (json['unit'] as String?) ?? 'pcs',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      location: (json['location'] as String?) ?? '',
      borrowedBy: (json['borrowedBy'] as String?) ?? '',
      borrowedDate: json['borrowedDate'] != null
          ? DateTime.tryParse(json['borrowedDate'] as String)
          : null,
      notes: (json['notes'] as String?) ?? '',
    );
  }
}
