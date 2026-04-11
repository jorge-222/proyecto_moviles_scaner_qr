import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/variant.dart';
import '../services/product_service.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();

  late List<Variant> _variantes;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nombreController.text = widget.product!.nombre;
      _descripcionController.text = widget.product!.descripcion ?? '';
      _precioController.text = widget.product!.precio.toString();
      _variantes = List.from(widget.product!.variantes);
    } else {
      _variantes = [];
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  void _addVariante() {
    showDialog(
      context: context,
      builder: (context) => _VariantDialog(
        onSave: (talla, color) {
          setState(() {
            _variantes.add(Variant(talla: talla, color: color));
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_variantes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes agregar al menos una variante')),
        );
        return;
      }

      final product = Product(
        id: widget.product?.id,
        nombre: _nombreController.text,
        descripcion: _descripcionController.text,
        precio: double.tryParse(_precioController.text) ?? 0.0,
        variantes: _variantes,
      );

      if (mounted) {
        if (widget.product != null) {
          context.read<ProductService>().updateProduct(product);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Producto actualizado')),
          );
        } else {
          context.read<ProductService>().addProduct(product);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Producto registrado exitosamente')),
          );
        }
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null ? 'Editar Producto' : 'Registrar Producto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Producto',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.shopping_bag),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionController,
                decoration: InputDecoration(
                  labelText: 'Descripción (Opcional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precioController,
                decoration: InputDecoration(
                  labelText: 'Precio',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Variantes (Talla × Color)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addVariante,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_variantes.isEmpty)
                      const Text('Sin variantes agregadas')
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _variantes.length,
                        itemBuilder: (context, index) {
                          final variant = _variantes[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _colorFromString(variant.color),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              title: Text('${variant.talla} - ${variant.color}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _variantes.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saveProduct,
                  icon: const Icon(Icons.check),
                  label: const Text('Guardar Producto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
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

class _VariantDialog extends StatefulWidget {
  final Function(String talla, String color) onSave;

  const _VariantDialog({required this.onSave});

  @override
  State<_VariantDialog> createState() => _VariantDialogState();
}

class _VariantDialogState extends State<_VariantDialog> {
  late String _selectedTalla;
  late String _selectedColor;

  final _tallas = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  final _colores = ['Rojo', 'Azul', 'Negro', 'Blanco', 'Verde', 'Amarillo', 'Naranja', 'Púrpura', 'Rosa', 'Gris'];

  @override
  void initState() {
    super.initState();
    _selectedTalla = _tallas.first;
    _selectedColor = _colores.first;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Variante'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedTalla,
            decoration: InputDecoration(
              labelText: 'Talla',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: _tallas.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (value) {
              setState(() => _selectedTalla = value ?? _selectedTalla);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedColor,
            decoration: InputDecoration(
              labelText: 'Color',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: _colores.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (value) {
              setState(() => _selectedColor = value ?? _selectedColor);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_selectedTalla, _selectedColor);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
