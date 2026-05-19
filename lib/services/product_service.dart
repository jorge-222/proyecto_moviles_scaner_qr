import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/inventory_log.dart';
import 'sync_service.dart';

class ProductService extends ChangeNotifier {
  static const String _key = 'products';
  static const String _logsKey = 'inventory_logs';
  late SharedPreferences _prefs;
  final SyncService _syncService = SyncService();

  List<Product> _products = [];
  List<InventoryLog> _logs = [];
  bool _isSyncing = false;

  List<Product> get products => _products;
  List<InventoryLog> get logs => _logs;
  bool get isSyncing => _isSyncing;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadLocalProducts();
    _loadLocalLogs();
    // Sincronizar desde la nube en segundo plano
    _syncFromCloud();
  }

  // ──────────────────────────────────────────────
  // PERSISTENCIA LOCAL
  // ──────────────────────────────────────────────

  void _loadLocalProducts() {
    final json = _prefs.getString(_key);
    if (json != null) {
      final list = jsonDecode(json) as List;
      _products =
          list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      _products = [];
    }
    notifyListeners();
  }

  Future<void> _saveLocalProducts() async {
    final json = jsonEncode(_products.map((p) => p.toJson()).toList());
    await _prefs.setString(_key, json);
  }

  void _loadLocalLogs() {
    final jsonStr = _prefs.getString(_logsKey);
    if (jsonStr != null) {
      final list = jsonDecode(jsonStr) as List;
      _logs = list.map((e) => InventoryLog.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      _logs = [];
    }
    _logs.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
    notifyListeners();
  }

  Future<void> _saveLocalLogs() async {
    final jsonStr = jsonEncode(_logs.map((l) => l.toJson()).toList());
    await _prefs.setString(_logsKey, jsonStr);
  }

  Future<void> addLog(InventoryLog log) async {
    _logs.insert(0, log);
    await _saveLocalLogs();
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // SINCRONIZACIÓN CON LA NUBE
  // ──────────────────────────────────────────────

  Future<void> _syncFromCloud() async {
    _isSyncing = true;
    notifyListeners();

    final cloudProducts = await _syncService.pullFromCloud();

    if (cloudProducts != null) {
      _products = cloudProducts;
      await _saveLocalProducts();
      notifyListeners();
    }

    _isSyncing = false;
    notifyListeners();
  }

  /// Fuerza una sincronización manual desde la nube.
  Future<void> syncNow() => _syncFromCloud();

  // ──────────────────────────────────────────────
  // CRUD
  // ──────────────────────────────────────────────

  Future<void> addProduct(Product product) async {
    _products.add(product);
    await _saveLocalProducts();
    notifyListeners();
    // Push a la nube en segundo plano
    _syncService.pushProduct(product);
  }

  Future<void> updateProduct(Product product) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      await _saveLocalProducts();
      notifyListeners();
      // Push a la nube en segundo plano
      _syncService.pushProduct(product);
    }
  }

  Future<void> deleteProduct(String productId) async {
    _products.removeWhere((p) => p.id == productId);
    await _saveLocalProducts();
    notifyListeners();
    // Eliminar en la nube en segundo plano
    _syncService.deleteProductFromCloud(productId);
  }

  // ──────────────────────────────────────────────
  // BÚSQUEDAS
  // ──────────────────────────────────────────────

  Product? getProductById(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  Product? getProductByQRCode(String qrCode) {
    try {
      return _products.firstWhere(
        (p) => p.variantes.any((v) => v.codigoQR == qrCode),
      );
    } catch (e) {
      return null;
    }
  }

  List<Product> searchProducts(String query) {
    return _products
        .where((product) =>
            product.nombre.toLowerCase().contains(query.toLowerCase()) ||
            (product.categoria != null && product.categoria!.toLowerCase().contains(query.toLowerCase())))
        .toList();
  }

  List<Product> getFilteredProducts({String query = '', String? talla, String? color}) {
    return _products.where((product) {
      final matchQuery = query.isEmpty ||
          product.nombre.toLowerCase().contains(query.toLowerCase()) ||
          (product.categoria != null && product.categoria!.toLowerCase().contains(query.toLowerCase()));

      final matchTalla = talla == null || talla.isEmpty ||
          product.variantes.any((v) => v.talla == talla);

      final matchColor = color == null || color.isEmpty ||
          product.variantes.any((v) => v.color == color);

      return matchQuery && matchTalla && matchColor;
    }).toList();
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
    await _prefs.remove(_logsKey);
    _loadLocalProducts();
    _loadLocalLogs();
  }
}
