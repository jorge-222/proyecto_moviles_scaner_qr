import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/product.dart';
import '../models/variant.dart';

class QRGeneratorScreen extends StatefulWidget {
  final Product product;
  final Variant variant;

  const QRGeneratorScreen({
    super.key,
    required this.product,
    required this.variant,
  });

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  late String _qrData;

  @override
  void initState() {
    super.initState();
    _generateQRCode();
  }

  void _generateQRCode() {
    // Generar datos del QR: producto_id|variante_id|talla|color
    _qrData = '${widget.product.id}|${widget.variant.id}|${widget.variant.talla}|${widget.variant.color}';
    
    // Asignar el código QR a la variante
    if (widget.variant.codigoQR == null) {
      widget.variant.codigoQR = _qrData;
    } else {
      _qrData = widget.variant.codigoQR!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Código QR'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Información del producto
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.nombre,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _colorFromString(widget.variant.color),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${widget.variant.talla} - ${widget.variant.color}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      if (widget.product.precio > 0)
                        Column(
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'Precio: \$${widget.product.precio.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // QR Code
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: QrImageView(
                  data: _qrData,
                  version: QrVersions.auto,
                  size: 280.0,
                ),
              ),
              const SizedBox(height: 40),

              // Información del código QR
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Código QR:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _qrData,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Cerrar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Código QR generado y guardado'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copiar Código'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
}
