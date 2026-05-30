import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/product.dart';
import '../models/inventory_log.dart';
import 'sync_service.dart';

class ProductService extends ChangeNotifier {
  static const String _key = 'products';
  static const String _logsKey = 'inventory_logs';
  static const String _pendingSyncKey = 'pending_sync';

  late SharedPreferences _prefs;
  final SyncService _syncService = SyncService();

  List<Product> _products = [];
  List<InventoryLog> _logs = [];

  // Pending actions for offline support
  // 'upsert_productId' or 'delete_productId'
  List<String> _pendingSyncActions = [];

  bool _isSyncing = false;
  bool _wasOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  List<Product> get products => _products;
  List<InventoryLog> get logs => _logs;
  bool get isSyncing => _isSyncing;
  bool get hasPendingSync => _pendingSyncActions.isNotEmpty;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadLocalProducts();
    _loadLocalLogs();
    _loadPendingSyncActions();
    _syncFromCloud();
    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline && _wasOffline && _pendingSyncActions.isNotEmpty) {
        _syncFromCloud();
      }
      _wasOffline = !isOnline;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // PERSISTENCIA LOCAL
  // ──────────────────────────────────────────────

  void _loadPendingSyncActions() {
    _pendingSyncActions = _prefs.getStringList(_pendingSyncKey) ?? [];
  }

  Future<void> _savePendingSyncActions() async {
    await _prefs.setStringList(_pendingSyncKey, _pendingSyncActions);
    notifyListeners();
  }

  Future<void> _addPendingAction(String action) async {
    if (!_pendingSyncActions.contains(action)) {
      _pendingSyncActions.add(action);
      await _savePendingSyncActions();
    }
  }

  Future<void> _removePendingAction(String action) async {
    if (_pendingSyncActions.remove(action)) {
      await _savePendingSyncActions();
    }
  }

  void _loadLocalProducts() {
    final json = _prefs.getString(_key);
    if (json != null) {
      final list = jsonDecode(json) as List;
      _products = list
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
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
      _logs = list
          .map((e) => InventoryLog.fromJson(e as Map<String, dynamic>))
          .toList();
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
    if (_isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    // 1. Process pending changes (Local -> Cloud)
    List<String> remainingActions = List.from(_pendingSyncActions);
    bool anyActionFailed = false;

    for (final action in _pendingSyncActions) {
      if (action.startsWith('upsert_')) {
        final productId = action.substring('upsert_'.length);
        final product = getProductById(productId);
        if (product != null) {
          final success = await _syncService.pushProduct(product);
          if (success) {
            remainingActions.remove(action);
          } else {
            anyActionFailed = true;
          }
        } else {
          // Product no longer exists locally, remove from pending
          remainingActions.remove(action);
        }
      } else if (action.startsWith('delete_')) {
        final productId = action.substring('delete_'.length);
        final success = await _syncService.deleteProductFromCloud(productId);
        if (success) {
          remainingActions.remove(action);
        } else {
          anyActionFailed = true;
        }
      }
    }

    _pendingSyncActions = remainingActions;
    await _savePendingSyncActions();

    // 2. Fetch latest data (Cloud -> Local) only if we pushed our pending data
    if (!anyActionFailed) {
      final cloudProducts = await _syncService.pullFromCloud();

      if (cloudProducts != null) {
        _products = cloudProducts;
        await _saveLocalProducts();
      }
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
    _addPendingAction('upsert_${product.id}');
    _syncNowInBackground();
  }

  Future<void> updateProduct(Product product) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      await _saveLocalProducts();
      notifyListeners();
      // Push a la nube en segundo plano
      _addPendingAction('upsert_${product.id}');
      _syncNowInBackground();
    }
  }

  Future<void> deleteProduct(String productId) async {
    _products.removeWhere((p) => p.id == productId);
    await _saveLocalProducts();

    // Si estaba pendiente de upsert, lo removemos
    _removePendingAction('upsert_$productId');
    _addPendingAction('delete_$productId');

    notifyListeners();
    // Eliminar en la nube en segundo plano
    _syncNowInBackground();
  }

  void _syncNowInBackground() {
    if (!_isSyncing) {
      _syncFromCloud();
    }
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
        .where(
          (product) =>
              product.nombre.toLowerCase().contains(query.toLowerCase()) ||
              (product.categoria != null &&
                  product.categoria!.toLowerCase().contains(
                    query.toLowerCase(),
                  )),
        )
        .toList();
  }

  List<Product> getFilteredProducts({
    String query = '',
    String? talla,
    String? color,
  }) {
    return _products.where((product) {
      final matchQuery =
          query.isEmpty ||
          product.nombre.toLowerCase().contains(query.toLowerCase()) ||
          (product.categoria != null &&
              product.categoria!.toLowerCase().contains(query.toLowerCase()));

      final matchTalla =
          talla == null ||
          talla.isEmpty ||
          product.variantes.any((v) => v.talla == talla);

      final matchColor =
          color == null ||
          color.isEmpty ||
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
