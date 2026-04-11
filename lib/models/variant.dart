import 'package:uuid/uuid.dart';

class Variant {
  late String id;
  late String talla;
  late String color;
  late int cantidad;
  late String? codigoQR;

  Variant({
    String? id,
    required this.talla,
    required this.color,
    this.cantidad = 0,
    this.codigoQR,
  }) {
    this.id = id ?? const Uuid().v4();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'talla': talla,
      'color': color,
      'cantidad': cantidad,
      'codigoQR': codigoQR,
    };
  }

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: json['id'] as String,
      talla: json['talla'] as String,
      color: json['color'] as String,
      cantidad: json['cantidad'] as int? ?? 0,
      codigoQR: json['codigoQR'] as String?,
    );
  }
}
