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
}
