import 'package:uuid/uuid.dart';
import 'variant.dart';

class Product {
  late String id;
  late String nombre;
  late String? descripcion;
  late double precio;
  late List<Variant> variantes; // Talla × Color
  late DateTime fechaCreacion;

  Product({
    String? id,
    required this.nombre,
    this.descripcion,
    this.precio = 0.0,
    List<Variant>? variantes,
  }) {
    this.id = id ?? const Uuid().v4();
    this.variantes = variantes ?? [];
    this.fechaCreacion = DateTime.now();
  }

  // Getters para compatibilidad con pantalla anterior
  String get talla => variantes.isNotEmpty ? variantes.first.talla : '';
  
  int get cantidad => variantes.fold(0, (sum, v) => sum + v.cantidad);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'variantes': variantes.map((v) => v.toJson()).toList(),
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final variantesJson = json['variantes'] as List?;
    final variantes = variantesJson != null
        ? variantesJson.map((v) => Variant.fromJson(v as Map<String, dynamic>)).toList()
        : <Variant>[];

    return Product(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
      variantes: variantes,
    )..fechaCreacion = json['fechaCreacion'] != null
        ? DateTime.parse(json['fechaCreacion'] as String)
        : DateTime.now();
  }
}
