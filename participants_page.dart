/// Structured prize system.
///
/// Replaces the old free-text "prizeType / prizeDescription" prize model.
/// Every prize is now one of three well-defined kinds, and any prize that
/// references concrete products always points at real items from the
/// existing menu (the `products` Firestore collection) instead of
/// hardcoded/typed-in product names.
enum PrizeKind { discount, buyXGetY, freeItem }

PrizeKind prizeKindFromString(String? raw) {
  switch (raw) {
    case 'discount':
      return PrizeKind.discount;
    case 'buyXGetY':
      return PrizeKind.buyXGetY;
    case 'freeItem':
      return PrizeKind.freeItem;
    default:
      return PrizeKind.freeItem;
  }
}

/// Lightweight reference to a real menu item (from the `products`
/// collection). We snapshot the name/price at the time the prize is
/// configured so historical matches keep showing what was actually offered
/// even if the menu item is renamed/removed later.
class MenuItemRef {
  final String id;
  final String name;
  final double price;

  const MenuItemRef({required this.id, required this.name, this.price = 0});

  factory MenuItemRef.fromMap(Map<String, dynamic> map) => MenuItemRef(
    id: map['id']?.toString() ?? '',
    name: map['name']?.toString() ?? '',
    price: (map['price'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'price': price};
}

String _fmtNum(num n) {
  if (n == n.roundToDouble()) return n.toInt().toString();
  return n.toStringAsFixed(2);
}

class PrizePosition {
  final int position;
  final PrizeKind kind;

  // --- Discount fields ---
  /// 'percentage' or 'fixed'
  final String discountType;
  final double discountValue;

  // --- Buy X Get Y fields ---
  final List<MenuItemRef> requiredItems;

  // --- Buy X Get Y (free item) / Free Item fields ---
  final MenuItemRef? freeItem;

  /// Legacy data support: matches created before this prize system was
  /// introduced stored a free-text prizeType/prizeDescription instead of a
  /// structured prize. We keep that text around so old matches still
  /// display correctly instead of breaking.
  final String? _legacyType;
  final String? _legacyDescription;

  const PrizePosition({
    required this.position,
    required this.kind,
    this.discountType = 'percentage',
    this.discountValue = 0,
    this.requiredItems = const [],
    this.freeItem,
    String? legacyType,
    String? legacyDescription,
  }) : _legacyType = legacyType,
       _legacyDescription = legacyDescription;

  factory PrizePosition.discount({
    required int position,
    required String discountType,
    required double discountValue,
  }) => PrizePosition(
    position: position,
    kind: PrizeKind.discount,
    discountType: discountType,
    discountValue: discountValue,
  );

  factory PrizePosition.buyXGetY({
    required int position,
    required List<MenuItemRef> requiredItems,
    required MenuItemRef freeItem,
  }) => PrizePosition(
    position: position,
    kind: PrizeKind.buyXGetY,
    requiredItems: requiredItems,
    freeItem: freeItem,
  );

  factory PrizePosition.freeItem({
    required int position,
    required MenuItemRef item,
  }) => PrizePosition(
    position: position,
    kind: PrizeKind.freeItem,
    freeItem: item,
  );

  factory PrizePosition.fromMap(Map<String, dynamic> map) {
    final position = (map['position'] as num?)?.toInt() ?? 1;
    final kindRaw = map['prizeKind']?.toString();

    if (kindRaw == null) {
      // Legacy document written before the structured prize system existed.
      return PrizePosition(
        position: position,
        kind: PrizeKind.freeItem,
        legacyType: map['prizeType']?.toString() ?? '',
        legacyDescription: map['prizeDescription']?.toString() ?? '',
      );
    }

    final requiredItems = (map['requiredItems'] is List)
        ? (map['requiredItems'] as List)
              .whereType<Map>()
              .map((e) => MenuItemRef.fromMap(Map<String, dynamic>.from(e)))
              .toList()
        : <MenuItemRef>[];

    final freeItemMap = map['freeItem'];
    final freeItem = (freeItemMap is Map)
        ? MenuItemRef.fromMap(Map<String, dynamic>.from(freeItemMap))
        : null;

    return PrizePosition(
      position: position,
      kind: prizeKindFromString(kindRaw),
      discountType: map['discountType']?.toString() ?? 'percentage',
      discountValue: (map['discountValue'] as num?)?.toDouble() ?? 0,
      requiredItems: requiredItems,
      freeItem: freeItem,
    );
  }

  Map<String, dynamic> toMap() => {
    'position': position,
    'prizeKind': kind.name,
    'discountType': discountType,
    'discountValue': discountValue,
    'requiredItems': requiredItems.map((e) => e.toMap()).toList(),
    'freeItem': freeItem?.toMap(),
    // Human-readable snapshot kept alongside the structured data so any
    // other reader (player-facing app, exports, older code) keeps
    // working without changes.
    'prizeType': prizeType,
    'prizeDescription': prizeDescription,
  };

  /// Arabic human-readable label of the prize kind.
  String get prizeType {
    if (_legacyType != null && _legacyType!.isNotEmpty) return _legacyType!;
    switch (kind) {
      case PrizeKind.discount:
        return 'خصم';
      case PrizeKind.buyXGetY:
        return 'اشترِ واحصل على';
      case PrizeKind.freeItem:
        return 'صنف مجاني';
    }
  }

  /// Arabic human-readable description of the prize, built from the
  /// selected real menu items / discount value.
  String get prizeDescription {
    if (_legacyDescription != null && _legacyDescription!.isNotEmpty) {
      return _legacyDescription!;
    }
    switch (kind) {
      case PrizeKind.discount:
        final valueStr = discountType == 'fixed'
            ? '${_fmtNum(discountValue)} ج.م'
            : '${_fmtNum(discountValue)}%';
        return 'خصم $valueStr على الفاتورة';
      case PrizeKind.buyXGetY:
        final req = requiredItems.isEmpty
            ? '—'
            : requiredItems.map((e) => e.name).join('، ');
        final free = freeItem?.name ?? '—';
        return 'اشترِ: $req ← مجاناً: $free';
      case PrizeKind.freeItem:
        return 'صنف مجاني: ${freeItem?.name ?? '—'}';
    }
  }

  String get medal {
    switch (position) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '🏅';
    }
  }
}
