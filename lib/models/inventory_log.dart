import 'package:uuid/uuid.dart';

class InventoryLog {
  late String id;
  late DateTime fechaHora;
  late String productId;
  late String productNombre;
  late String talla;
  late String color;
  late String tipo; // 'Entrada' o 'Salida'
  late int cantidad;
  late String nota;

  InventoryLog({
    String? id,
    DateTime? fechaHora,
    required this.productId,
    required this.productNombre,
    required this.talla,
    required this.color,
    required this.tipo,
    required this.cantidad,
    required this.nota,
  }) {
    this.id = id ?? const Uuid().v4();
    this.fechaHora = fechaHora ?? DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fechaHora': fechaHora.toIso8601String(),
      'productId': productId,
      'productNombre': productNombre,
      'talla': talla,
      'color': color,
      'tipo': tipo,
      'cantidad': cantidad,
      'nota': nota,
    };
  }

  factory InventoryLog.fromJson(Map<String, dynamic> json) {
    return InventoryLog(
      id: json['id'] as String,
      fechaHora: DateTime.parse(json['fechaHora'] as String),
      productId: json['productId'] as String,
      productNombre: json['productNombre'] as String,
      talla: json['talla'] as String,
      color: json['color'] as String,
      tipo: json['tipo'] as String,
      cantidad: json['cantidad'] as int,
      nota: json['nota'] as String,
    );
  }
}
