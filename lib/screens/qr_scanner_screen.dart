import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/variant.dart';
import '../services/product_service.dart';
import 'update_quantity_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late MobileScannerController controller;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleScannedCode(String code) {
    if (_scanned) return;
    _scanned = true;

    final productService = context.read<ProductService>();
    final parts = code.split('|');

    if (parts.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código QR inválido')),
      );
      _scanned = false;
      return;
    }

    final productId = parts[0];
    final variantId = parts[1];
    final talla = parts[2];
    final color = parts[3];

    // Buscar el producto
    final product = productService.getProductById(productId);
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto no encontrado')),
      );
      _scanned = false;
      return;
    }

    // Buscar la variante
    Variant? variant;
    try {
      variant = product.variantes.firstWhere((v) => v.id == variantId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Variante no encontrada')),
      );
      _scanned = false;
      return;
    }

    // Ir a la pantalla de actualización de cantidad
    Navigator.pop(context);
    if (variant != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UpdateQuantityScreen(
            product: product,
            variant: variant!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
        actions: [
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  default:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (_scanned) break;
            final code = barcode.rawValue ?? '';
            if (code.isNotEmpty) {
              _handleScannedCode(code);
            }
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.switchCamera();
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.flip_camera_android),
      ),
    );
  }
}
