import 'models.dart';
import 'supa.dart';
import 'texts/app_texts.dart';
import 'widgets/schema_form.dart';

/// Categorie, pezzi e link pronti per i moduli delle sezioni.
Future<SchemaFormData> loadFormData() async {
  final results = await Future.wait([
    supa.from('collections').select().order('position', ascending: true).order('name', ascending: true),
    supa
        .from('products')
        .select('*, product_collections(collection_id)')
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false),
  ]);
  final categories = results[0].map(ShopCategory.fromMap).toList();
  return SchemaFormData(
    categories: categories,
    products: results[1].map(Product.fromMap).toList(),
    links: [
      LinkSuggestion(t.linkAllProducts, '/prodotti'),
      for (final c in categories) LinkSuggestion(c.name, '/collezioni/${c.slug}'),
    ],
  );
}

/// Copia profonda delle props, così si può annullare senza toccare l'originale.
Map<String, dynamic> deepCopy(Map<String, dynamic> source) => {
      for (final entry in source.entries) entry.key: _copy(entry.value),
    };

dynamic _copy(dynamic value) {
  if (value is Map) return {for (final e in value.entries) e.key.toString(): _copy(e.value)};
  if (value is List) return [for (final v in value) _copy(v)];
  return value;
}
