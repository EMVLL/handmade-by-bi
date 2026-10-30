const productStatuses = ['disponibile', 'su_ordinazione', 'venduto', 'nascosto'];


class ProductOption {
  const ProductOption(this.name, this.values);

  factory ProductOption.fromMap(Map<String, dynamic> map) => ProductOption(
        (map['name'] as String?) ?? '',
        ((map['values'] as List?) ?? const []).map((v) => v.toString()).toList(),
      );

  final String name;
  final List<String> values;

  Map<String, dynamic> toMap() => {'name': name, 'values': values};
}

class Product {
  const Product({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.price,
    required this.compareAtPrice,
    required this.status,
    required this.photos,
    required this.options,
    required this.vintedUrl,
    required this.deletedAt,
    required this.categoryIds,
  });

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] as String,
        slug: map['slug'] as String,
        title: map['title'] as String,
        description: (map['description'] as String?) ?? '',
        price: (map['price'] as num?)?.toDouble(),
        compareAtPrice: (map['compare_at_price'] as num?)?.toDouble(),
        status: (map['status'] as String?) ?? 'disponibile',
        photos: ((map['photos'] as List?) ?? const []).map((p) => p.toString()).toList(),
        options: ((map['options'] as List?) ?? const [])
            .map((o) => ProductOption.fromMap(Map<String, dynamic>.from(o as Map)))
            .toList(),
        vintedUrl: map['vinted_url'] as String?,
        deletedAt: map['deleted_at'] == null ? null : DateTime.tryParse(map['deleted_at'] as String),
        categoryIds: ((map['product_collections'] as List?) ?? const [])
            .map((pc) => (pc as Map)['collection_id'] as String)
            .toList(),
      );

  final String id;
  final String slug;
  final String title;
  final String description;
  final double? price;
  final double? compareAtPrice;
  final String status;
  final List<String> photos;
  final List<ProductOption> options;
  final String? vintedUrl;
  final DateTime? deletedAt;

  /// Categorie scelte da Benedetta (tabella product_collections).
  final List<String> categoryIds;
}

/// Una categoria del negozio (tabella "collections").
/// "Pronta consegna" e "Altro" non sono qui: il sito le calcola da solo.
class ShopCategory {
  const ShopCategory({
    required this.id,
    required this.slug,
    required this.name,
    required this.position,
    this.description = '',
    this.coverPath,
  });

  factory ShopCategory.fromMap(Map<String, dynamic> map) => ShopCategory(
        id: map['id'] as String,
        slug: map['slug'] as String,
        name: map['name'] as String,
        position: (map['position'] as num?)?.toInt() ?? 0,
        description: (map['description'] as String?) ?? '',
        coverPath: map['cover_path'] as String?,
      );

  final String id;
  final String slug;
  final String name;
  final int position;
  final String description;
  final String? coverPath;
}

/// Indirizzi riservati alle due categorie automatiche del sito.
const reservedCategorySlugs = {'altro', 'pronta-consegna'};

/// Tipo di sezione disponibile (tabella block_types): nome e schema dei campi.
class BlockType {
  const BlockType({required this.type, required this.label, required this.schema});

  factory BlockType.fromMap(Map<String, dynamic> map) => BlockType(
        type: map['type'] as String,
        label: map['label'] as String,
        schema: Map<String, dynamic>.from(map['schema'] as Map),
      );

  final String type;
  final String label;
  final Map<String, dynamic> schema;
}

/// Una sezione di una pagina (tabella blocks).
class PageBlock {
  const PageBlock({
    required this.id,
    required this.type,
    required this.position,
    required this.visible,
    required this.props,
  });

  factory PageBlock.fromMap(Map<String, dynamic> map) => PageBlock(
        id: map['id'] as String,
        type: map['type'] as String,
        position: (map['position'] as num).toInt(),
        visible: map['visible'] as bool? ?? true,
        props: Map<String, dynamic>.from((map['props'] as Map?) ?? const {}),
      );

  final String id;
  final String type;
  final int position;
  final bool visible;
  final Map<String, dynamic> props;
}
