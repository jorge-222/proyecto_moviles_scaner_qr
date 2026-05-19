import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/variant.dart';
import '../services/product_service.dart';
import 'add_product_screen.dart';
import 'qr_generator_screen.dart';
import 'qr_scanner_screen.dart';
import 'update_quantity_screen.dart';
import 'history_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  int _currentIndex = 0;

  // Filtros
  String _searchQuery = '';
  String? _selectedTalla;
  String? _selectedColor;

  final List<String> _tallasDisponibles = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  final List<String> _coloresDisponibles = [
    'Rojo', 'Azul', 'Negro', 'Blanco', 'Verde', 'Amarillo', 'Naranja', 'Púrpura', 'Rosa', 'Gris'
  ];

  @override
  Widget build(BuildContext context) {
    // Páginas principales
    final List<Widget> pages = [
      _buildInventoryView(context),
      const HistoryScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Inventario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Historial',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
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
            )
          : null,
    );
  }

  // ── VISTA PRINCIPAL DEL INVENTARIO ──
  Widget _buildInventoryView(BuildContext context) {
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
          // Mensaje de Bienvenida
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Hola, $firstName! 👋',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Gestiona tus productos hoy.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Botones de acción rápida
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.qr_code_scanner,
                    label: 'Escanear QR',
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

          // ── PANEL DE BÚSQUEDA Y FILTROS (SCRUM-6) ──
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Buscador por nombre/categoría
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o categoría...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Dropdowns de Talla y Color
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedTalla,
                        decoration: InputDecoration(
                          labelText: 'Talla',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Todas')),
                          ..._tallasDisponibles.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedTalla = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedColor,
                        decoration: InputDecoration(
                          labelText: 'Color',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Todos')),
                          ..._coloresDisponibles.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedColor = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Barra de progreso de sincronización
          Consumer<ProductService>(
            builder: (context, service, _) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: service.isSyncing
                    ? Column(
                        key: const ValueKey('syncing'),
                        children: [
                          LinearProgressIndicator(
                            backgroundColor: Colors.deepPurple.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                          ),
                          Container(
                            width: double.infinity,
                            color: Colors.deepPurple.withOpacity(0.05),
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                            child: const Row(
                              children: [
                                Icon(Icons.cloud_upload_outlined, size: 14, color: Colors.deepPurple),
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

          // Lista de productos filtrada
          Expanded(
            child: Consumer<ProductService>(
              builder: (context, productService, child) {
                final filteredProducts = productService.getFilteredProducts(
                  query: _searchQuery,
                  talla: _selectedTalla,
                  color: _selectedColor,
                );

                if (filteredProducts.isEmpty && !productService.isSyncing) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron productos',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _buildProductCard(context, product, productService);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── TARJETA DEL PRODUCTO E INVENTARIO EN MATRIZ (SCRUM-11) ──
  Widget _buildProductCard(
    BuildContext context,
    Product product,
    ProductService productService,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.shopping_bag, color: Colors.deepPurple),
        ),
        title: Text(
          product.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.categoria != null)
              Container(
                margin: const EdgeInsets.only(top: 2, bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  product.categoria!,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            Text(
              '${product.variantes.length} variante(s) - Total: ${product.cantidad} unidades',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                if (product.descripcion != null && product.descripcion!.isNotEmpty) ...[
                  Text(
                    'Descripción: ${product.descripcion}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Precio: \$${_formatPrice(product.precio)}',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.grid_on, size: 18, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text(
                      'Matriz de Stock (Talla × Color)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // ── CONSTRUCCIÓN DE LA MATRIZ (Talla x Color) ──
                _buildStockMatrix(context, product),
                
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '* Toca un badge de stock para actualizar cantidad o ver su QR',
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para armar la tabla de tallas y colores
  Widget _buildStockMatrix(BuildContext context, Product product) {
    if (product.variantes.isEmpty) {
      return const Text('Sin variantes configuradas.');
    }

    // Tallas y Colores únicos y ordenados
    final List<String> tallasOrder = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
    final tallas = product.variantes.map((v) => v.talla).toSet().toList()
      ..sort((a, b) {
        final indexA = tallasOrder.indexOf(a);
        final indexB = tallasOrder.indexOf(b);
        if (indexA == -1 && indexB == -1) return a.compareTo(b);
        if (indexA == -1) return 1;
        if (indexB == -1) return -1;
        return indexA.compareTo(indexB);
      });

    final colores = product.variantes.map((v) => v.color).toSet().toList()..sort();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 18,
          headingRowHeight: 44,
          dataRowMinHeight: 52,
          dataRowMaxHeight: 52,
          headingRowColor: MaterialStateProperty.all(Colors.deepPurple.shade50.withOpacity(0.5)),
          columns: [
            const DataColumn(
              label: Text(
                'Talla / Color',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
            ),
            ...colores.map((c) => DataColumn(
                  label: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _colorFromString(c),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade400, width: 0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        c,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                    ],
                  ),
                )),
          ],
          rows: tallas.map((t) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    t,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                ...colores.map((c) {
                  // Buscar si hay variante para esta talla y color
                  Variant? variant;
                  try {
                    variant = product.variantes.firstWhere(
                      (v) => v.talla == t && v.color == c,
                    );
                  } catch (_) {
                    variant = null;
                  }

                  if (variant == null) {
                    return const DataCell(
                      Center(
                        child: Text(
                          '-',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  // Lógica de colores según el stock (SCRUM-11)
                  Color badgeBgColor;
                  Color badgeTextColor;
                  if (variant.cantidad > 3) {
                    // Verde
                    badgeBgColor = Colors.green.shade50;
                    badgeTextColor = Colors.green.shade800;
                  } else if (variant.cantidad >= 1) {
                    // Naranja
                    badgeBgColor = Colors.orange.shade50;
                    badgeTextColor = Colors.orange.shade900;
                  } else {
                    // Rojo
                    badgeBgColor = Colors.red.shade50;
                    badgeTextColor = Colors.red.shade800;
                  }

                  return DataCell(
                    GestureDetector(
                      onTap: () => _showVariantActionsMenu(context, product, variant!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: badgeTextColor.withOpacity(0.3), width: 0.5),
                        ),
                        child: Text(
                          '${variant.cantidad}',
                          style: TextStyle(
                            color: badgeTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // Menú contextual para actualizar cantidad o ver el QR de la variante
  void _showVariantActionsMenu(BuildContext context, Product product, Variant variant) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _colorFromString(variant.color),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${product.nombre}  |  ${variant.talla} - ${variant.color}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.swap_vert, color: Colors.deepPurple),
                title: const Text('Registrar Entrada / Salida'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UpdateQuantityScreen(
                        product: product,
                        variant: variant,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_2, color: Colors.deepPurple),
                title: const Text('Ver / Compartir Código QR'),
                onTap: () {
                  Navigator.pop(context);
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
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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

  String _formatPrice(double price) {
    String priceStr = price.toInt().toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return priceStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
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
