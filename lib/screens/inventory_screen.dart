import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'add_product_screen.dart';
import 'qr_generator_screen.dart';
import 'qr_scanner_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata;
    final String fullName = metadata?['full_name'] ?? metadata?['name'] ?? 'Usuario';
    final String firstName = fullName.split(' ')[0];
    final String? avatarUrl = metadata?['avatar_url'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('StyleStock QR'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          tooltip: 'Cerrar Sesión',
          onPressed: () async {
            await Supabase.instance.client.auth.signOut();
          },
        ),
        actions: [
          if (avatarUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(avatarUrl),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Mensaje de Bienvenida Personalizado ──
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, $firstName! 👋',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Gestiona tus productos hoy.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
          
          // ── Botones de acción rápida ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.qr_code_scanner,
                    label: 'Escanear',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.cloud_sync,
                    label: 'Sincronizar',
                    onPressed: () => context.read<ProductService>().syncNow(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 40, thickness: 1, indent: 20, endIndent: 20),

          // ── Barra de progreso de sincronización ──
          Consumer<ProductService>(
            builder: (context, service, _) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: service.isSyncing
                    ? Column(
                        key: const ValueKey('syncing'),
                        children: [
                          LinearProgressIndicator(
                            backgroundColor:
                                Colors.deepPurple.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.deepPurple),
                          ),
                          Container(
                            width: double.infinity,
                            color: Colors.deepPurple.withOpacity(0.05),
                            padding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 16),
                            child: const Row(
                              children: [
                                Icon(Icons.cloud_upload_outlined,
                                    size: 14, color: Colors.deepPurple),
                                SizedBox(width: 6),
                                Text(
                                  'Sincronizando con la nube...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(key: ValueKey('idle')),
              );
            },
          ),

          // ── Lista de productos ──
          Expanded(
            child: Consumer<ProductService>(
              builder: (context, productService, child) {
                if (productService.products.isEmpty && !productService.isSyncing) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay productos registrados',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddProductScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Registrar Producto'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: productService.products.length,
                  itemBuilder: (context, index) {
                    final product = productService.products[index];
                    return _buildProductCard(context, product, productService);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddProductScreen(),
            ),
          );
        },
        tooltip: 'Agregar Producto',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    Product product,
    ProductService productService,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: ExpansionTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.shopping_bag, color: Colors.deepPurple),
        ),
        title: Text(product.nombre),
        subtitle: Text(
            '${product.variantes.length} variante(s) - Total: ${product.cantidad} unidades'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Editar'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProductScreen(product: product),
                  ),
                );
              },
            ),
            PopupMenuItem(
              child: const Text('Eliminar'),
              onTap: () {
                _deleteProduct(context, product, productService);
              },
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.descripcion != null &&
                    product.descripcion!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Descripción: ${product.descripcion}'),
                      const SizedBox(height: 8),
                    ],
                  ),
                Text('Precio: \$${product.precio.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                const Text(
                  'Variantes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: product.variantes.length,
                  itemBuilder: (context, index) {
                    final variant = product.variantes[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _colorFromString(variant.color),
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child:
                                Text('${variant.talla} - ${variant.color}'),
                          ),
                          Text(
                            'Qty: ${variant.cantidad}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.qr_code_2,
                                color: Colors.deepPurple),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QRGeneratorScreen(
                                    product: product,
                                    variant: variant,
                                  ),
                                ),
                              );
                            },
                            tooltip: 'Ver QR',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFromString(String colorName) {
    final colors = {
      'Rojo': Colors.red,
      'Azul': Colors.blue,
      'Negro': Colors.black,
      'Blanco': Colors.grey[300],
      'Verde': Colors.green,
      'Amarillo': Colors.yellow,
      'Naranja': Colors.orange,
      'Púrpura': Colors.purple,
      'Rosa': Colors.pink,
      'Gris': Colors.grey,
    };
    return colors[colorName] ?? Colors.grey[400]!;
  }

  void _deleteProduct(
    BuildContext context,
    Product product,
    ProductService productService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Deseas eliminar "${product.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              productService.deleteProduct(product.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Producto eliminado')),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple.shade50,
        foregroundColor: Colors.deepPurple,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
