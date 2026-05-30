import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductService>(
      builder: (context, productService, child) {
        final products = productService.products;
        int totalStock = 0;
        int totalProducts = products.length;
        int lowStockCount = 0;
        double totalValue = 0;

        for (var product in products) {
          totalStock += product.cantidad;
          totalValue += product.cantidad * product.precio;
          if (product.variantes.any((v) => v.cantidad <= 3)) {
            lowStockCount++;
          }
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              const SliverPadding(padding: EdgeInsets.all(8)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Resumen del Negocio',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildMetricCard(
                      context,
                      'Total Productos',
                      totalProducts.toString(),
                      Icons.inventory_2,
                      Colors.blue,
                    ),
                    _buildMetricCard(
                      context,
                      'Alertas Stock',
                      lowStockCount.toString(),
                      Icons.warning_amber_rounded,
                      Colors.orange,
                    ),
                    _buildMetricCard(
                      context,
                      'Unidades en Stock',
                      totalStock.toString(),
                      Icons.format_list_numbered,
                      Colors.teal,
                    ),
                    _buildMetricCard(
                      context,
                      'Valor Estimado',
                      '\$${_formatPrice(totalValue)}',
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ],
                ),
              ),
              const SliverPadding(padding: EdgeInsets.all(16)),
              if (lowStockCount > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildLowStockAlerts(context, products),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockAlerts(BuildContext context, List<Product> products) {
    final lowStockProducts = products
        .where((p) => p.variantes.any((v) => v.cantidad <= 3))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'Alertas de Stock Bajo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...lowStockProducts.map((p) {
          final lowVariants = p.variantes
              .where((v) => v.cantidad <= 3)
              .toList();
          return Card(
            color: Colors.red.shade50,
            child: ListTile(
              leading: const Icon(
                Icons.production_quantity_limits,
                color: Colors.red,
              ),
              title: Text(
                p.nombre,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                lowVariants
                    .map((v) => '${v.talla}-${v.color} (${v.cantidad})')
                    .join(', '),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  String _formatPrice(double price) {
    String priceStr = price.toInt().toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return priceStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }
}
