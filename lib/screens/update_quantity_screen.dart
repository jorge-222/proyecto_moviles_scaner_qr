import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/variant.dart';
import '../models/inventory_log.dart';
import '../services/product_service.dart';

class UpdateQuantityScreen extends StatefulWidget {
  final Product product;
  final Variant variant;

  const UpdateQuantityScreen({
    super.key,
    required this.product,
    required this.variant,
  });

  @override
  State<UpdateQuantityScreen> createState() => _UpdateQuantityScreenState();
}

class _UpdateQuantityScreenState extends State<UpdateQuantityScreen> {
  final _amountController = TextEditingController(text: '1');
  String _selectedNote = 'Venta';
  final List<String> _notes = ['Venta', 'Daño', 'Devolución', 'Otro'];
  final _customNoteController = TextEditingController();
  bool _isExit = true; // True for Salida, False for Entrada

  @override
  void dispose() {
    _amountController.dispose();
    _customNoteController.dispose();
    super.dispose();
  }

  void _processStockTransaction() {
    final int? amount = int.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa una cantidad válida mayor a 0.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final productService = context.read<ProductService>();
    final currentQty = widget.variant.cantidad;
    int newQty;
    String transactionType;
    String logNote;

    if (_isExit) {
      // Salida de Stock (SCRUM-9)
      if (currentQty < amount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock insuficiente. Stock actual: $currentQty.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      newQty = currentQty - amount;
      transactionType = 'Salida';
      logNote = _selectedNote == 'Otro' && _customNoteController.text.isNotEmpty
          ? _customNoteController.text.trim()
          : _selectedNote;
    } else {
      // Entrada de Stock (SCRUM-8)
      newQty = currentQty + amount;
      transactionType = 'Entrada';
      logNote = 'Entrada de mercancía';
    }

    // Actualizar cantidad en la variante y guardar producto
    widget.variant.cantidad = newQty;
    productService.updateProduct(widget.product);

    // Crear y registrar el log de inventario
    final log = InventoryLog(
      productId: widget.product.id,
      productNombre: widget.product.nombre,
      talla: widget.variant.talla,
      color: widget.variant.color,
      tipo: transactionType,
      cantidad: amount,
      nota: logNote,
    );
    productService.addLog(log);
    FirebaseAnalytics.instance.logEvent(
      name: 'inventario_actualizado',
      parameters: {
        'tipo': transactionType,
        'cantidad': amount,
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Inventario actualizado: $transactionType de $amount ud(s).'),
        backgroundColor: _isExit ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    // Volver a la pantalla principal de inventario
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Movimiento'),
        centerTitle: true,
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      if (widget.product.categoria != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Categoría: ${widget.product.categoria}',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _colorFromString(widget.variant.color),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Talla: ${widget.variant.talla}  |  Color: ${widget.variant.color}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Stock Actual:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.variant.cantidad > 3
                                  ? Colors.green.withOpacity(0.1)
                                  : (widget.variant.cantidad > 0 ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${widget.variant.cantidad} unidades',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: widget.variant.cantidad > 3
                                    ? Colors.green[800]
                                    : (widget.variant.cantidad > 0 ? Colors.orange[850] : Colors.red[800]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Selector de tipo de transacción: Entrada / Salida
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isExit = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isExit ? Colors.green : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'ENTRADA',
                            style: TextStyle(
                              color: !_isExit ? Colors.white : Colors.grey[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isExit = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isExit ? Colors.red : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'SALIDA',
                            style: TextStyle(
                              color: _isExit ? Colors.white : Colors.grey[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Formulario de cantidad y notas
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isExit ? Colors.red.shade200 : Colors.green.shade200,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isExit ? 'Registrar Salida de Stock' : 'Registrar Entrada de Stock',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isExit ? Colors.red[850] : Colors.green[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad de unidades',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pin),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    if (_isExit) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedNote,
                        decoration: const InputDecoration(
                          labelText: 'Motivo / Nota de Salida',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.assignment_turned_in),
                        ),
                        items: _notes
                            .map((note) => DropdownMenuItem(value: note, child: Text(note)))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedNote = value ?? _selectedNote;
                          });
                        },
                      ),
                      if (_selectedNote == 'Otro') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _customNoteController,
                          decoration: const InputDecoration(
                            labelText: 'Especificar motivo...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _processStockTransaction,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isExit ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
