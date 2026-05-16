import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/product.dart';
import '../models/variant.dart';

class SyncService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Descarga todos los productos con sus variantes desde Supabase.
  /// Retorna null silenciosamente si no hay internet o falla la conexión.
  Future<List<Product>?> pullFromCloud() async {
    try {
      final response = await _client
          .from('products')
          .select('*, variants(*)')
          .order('fecha_creacion', ascending: false);

      final List<Product> products = [];

      for (final row in response as List) {
        final variantsList = row['variants'] as List? ?? [];
        final variants = variantsList
            .map((v) => Variant(
                  id: v['id'] as String,
                  talla: v['talla'] as String,
                  color: v['color'] as String,
                  cantidad: v['cantidad'] as int? ?? 0,
                  codigoQR: v['codigo_qr'] as String?,
                ))
            .toList();

        final product = Product(
          id: row['id'] as String,
          nombre: row['nombre'] as String,
          descripcion: row['descripcion'] as String?,
          precio: (row['precio'] as num?)?.toDouble() ?? 0.0,
          variantes: variants,
        )..fechaCreacion = row['fecha_creacion'] != null
            ? DateTime.parse(row['fecha_creacion'] as String)
            : DateTime.now();

        products.add(product);
      }

      return products;
    } catch (_) {
      // Sin internet u otro error → retorna null silenciosamente
      return null;
    }
  }

  /// Sube (upsert) un producto y todas sus variantes a Supabase.
  /// Falla silenciosamente si no hay internet.
  Future<void> pushProduct(Product product) async {
    try {
      await _client.from('products').upsert({
        'id': product.id,
        'nombre': product.nombre,
        'descripcion': product.descripcion,
        'precio': product.precio,
        'fecha_creacion': product.fechaCreacion.toIso8601String(),
      });

      // Eliminar variantes previas para manejar variantes borradas
      await _client
          .from('variants')
          .delete()
          .eq('product_id', product.id);

      // Insertar variantes actuales
      if (product.variantes.isNotEmpty) {
        final variantsData = product.variantes
            .map((v) => {
                  'id': v.id,
                  'product_id': product.id,
                  'talla': v.talla,
                  'color': v.color,
                  'cantidad': v.cantidad,
                  'codigo_qr': v.codigoQR,
                })
            .toList();

        await _client.from('variants').insert(variantsData);
      }
    } catch (_) {
      // Falla silenciosamente si no hay internet
    }
  }

  /// Elimina un producto de la nube (las variantes se borran por CASCADE).
  Future<void> deleteProductFromCloud(String productId) async {
    try {
      await _client.from('products').delete().eq('id', productId);
    } catch (_) {
      // Falla silenciosamente
    }
  }
}
