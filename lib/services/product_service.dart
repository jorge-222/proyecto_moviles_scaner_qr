import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';

class ProductService extends ChangeNotifier {
  static const String _key = 'products';
  late SharedPreferences _prefs;

  List<Product> _products = [];

  List<Product> get products => _products;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadProducts();
  }

  void _loadProducts() {
    final json = _prefs.getString(_key);
    if (json != null) {
      final list = jsonDecode(json) as List;
      _products = list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      _products = [];
    }
    notifyListeners();
  }

  Future<void> _saveProducts() async {
    final json = jsonEncode(_products.map((p) => p.toJson()).toList());
    await _prefs.setString(_key, json);
  }

  Future<void> addProduct(Product product) async {
    _products.add(product);
    await _saveProducts();
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      await _saveProducts();
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String productId) async {
    _products.removeWhere((p) => p.id == productId);
    await _saveProducts();
    notifyListeners();
  }

  Product? getProductById(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  Product? getProductByQRCode(String qrCode) {
    try {
      final product = _products.firstWhere(
        (p) => p.variantes.any((v) => v.codigoQR == qrCode),
      );
      return product;
    } catch (e) {
      return null;
    }
  }

  List<Product> searchProducts(String query) {
    return _products
        .where((product) =>
            product.nombre.toLowerCase().contains(query.toLowerCase()) ||
            product.talla.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
    _loadProducts();
  }
}
