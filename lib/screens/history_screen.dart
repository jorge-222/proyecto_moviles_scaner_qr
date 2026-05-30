import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../services/product_service.dart';
import '../models/inventory_log.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _tipoFilter = 'Todos';
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<InventoryLog> _applyFilters(List<InventoryLog> logs) {
    return logs.where((log) {
      final matchesSearch = _searchQuery.isEmpty ||
          log.productNombre.toLowerCase().contains(_searchQuery) ||
          log.nota.toLowerCase().contains(_searchQuery) ||
          log.tipo.toLowerCase().contains(_searchQuery) ||
          log.talla.toLowerCase().contains(_searchQuery) ||
          log.color.toLowerCase().contains(_searchQuery);

      final matchesTipo = _tipoFilter == 'Todos' || log.tipo == _tipoFilter;

      final matchesDesde = _fechaDesde == null ||
          !log.fechaHora.isBefore(_fechaDesde!);
      final matchesHasta = _fechaHasta == null ||
          log.fechaHora.isBefore(_fechaHasta!.add(const Duration(days: 1)));

      return matchesSearch && matchesTipo && matchesDesde && matchesHasta;
    }).toList();
  }

  Future<void> _exportCSV(List<InventoryLog> logs) async {
    if (logs.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay movimientos para exportar')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('ID,Fecha,Hora,Producto,Talla,Color,Tipo,Cantidad,Nota');
    for (final log in logs) {
      final fecha =
          '${log.fechaHora.day.toString().padLeft(2, '0')}/${log.fechaHora.month.toString().padLeft(2, '0')}/${log.fechaHora.year}';
      final hora =
          '${log.fechaHora.hour.toString().padLeft(2, '0')}:${log.fechaHora.minute.toString().padLeft(2, '0')}';
      final nombre = '"${log.productNombre.replaceAll('"', '""')}"';
      final nota = '"${log.nota.replaceAll('"', '""')}"';
      buffer.writeln(
          '${log.id},$fecha,$hora,$nombre,${log.talla},${log.color},${log.tipo},${log.cantidad},$nota');
    }

    final tempDir = await getTemporaryDirectory();
    final now = DateTime.now();
    final fileName =
        'historial_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.csv';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Historial de movimientos - StyleStock',
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _fechaDesde != null && _fechaHasta != null
          ? DateTimeRange(start: _fechaDesde!, end: _fechaHasta!)
          : null,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Theme.of(context).colorScheme.primary,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _fechaDesde = picked.start;
        _fechaHasta = picked.end;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _tipoFilter = 'Todos';
      _fechaDesde = null;
      _fechaHasta = null;
    });
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _tipoFilter != 'Todos' ||
      _fechaDesde != null;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductService>(
      builder: (context, productService, _) {
        final filteredLogs = _applyFilters(productService.logs);
        final totalEntradas = filteredLogs
            .where((l) => l.tipo == 'Entrada')
            .fold(0, (s, l) => s + l.cantidad);
        final totalSalidas = filteredLogs
            .where((l) => l.tipo == 'Salida')
            .fold(0, (s, l) => s + l.cantidad);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Historial de Movimientos'),
            centerTitle: true,
            actions: [
              if (_hasActiveFilters)
                IconButton(
                  icon: const Icon(Icons.filter_alt_off),
                  tooltip: 'Limpiar filtros',
                  onPressed: _clearFilters,
                ),
              IconButton(
                icon: const Icon(Icons.file_download_outlined),
                tooltip: 'Exportar CSV',
                onPressed: () => _exportCSV(filteredLogs),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildFiltersSection(context),
              if (filteredLogs.isNotEmpty)
                _buildSummaryBar(
                    filteredLogs.length, totalEntradas, totalSalidas),
              Expanded(
                child: filteredLogs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: filteredLogs.length,
                        itemBuilder: (_, i) => _buildLogCard(filteredLogs[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFiltersSection(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hasDate = _fechaDesde != null;

    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Buscar por producto, talla, color...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() => _searchQuery = '');
                        _searchController.clear();
                      },
                    )
                  : null,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),

          // Filtros de tipo + rango de fechas
          Row(
            children: [
              // Chips de tipo
              for (final tipo in ['Todos', 'Entrada', 'Salida'])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _tipoChip(tipo, context),
                ),

              const Spacer(),

              // Selector de rango de fechas
              GestureDetector(
                onTap: _selectDateRange,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: hasDate ? primary.withOpacity(0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasDate ? primary : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14,
                          color: hasDate ? primary : Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        hasDate
                            ? '${_fechaDesde!.day}/${_fechaDesde!.month} – ${_fechaHasta!.day}/${_fechaHasta!.month}'
                            : 'Fechas',
                        style: TextStyle(
                          fontSize: 12,
                          color: hasDate ? primary : Colors.grey[600],
                        ),
                      ),
                      if (hasDate) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(() {
                            _fechaDesde = null;
                            _fechaHasta = null;
                          }),
                          child: Icon(Icons.close, size: 14, color: primary),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tipoChip(String tipo, BuildContext context) {
    final selected = _tipoFilter == tipo;
    final color = tipo == 'Entrada'
        ? Colors.green
        : tipo == 'Salida'
            ? Colors.red
            : Theme.of(context).colorScheme.primary;

    return FilterChip(
      label: Text(tipo),
      selected: selected,
      selectedColor: color.withOpacity(0.15),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: selected ? color : Colors.grey[700],
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      onSelected: (_) => setState(() => _tipoFilter = tipo),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildSummaryBar(int total, int entradas, int salidas) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _statItem('$total', 'movimientos', Icons.swap_vert, Colors.blueGrey),
          _divider(),
          _statItem('+$entradas', 'entradas', Icons.arrow_upward, Colors.green),
          _divider(),
          _statItem('-$salidas', 'salidas', Icons.arrow_downward, Colors.red),
        ],
      ),
    );
  }

  Widget _statItem(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  style:
                      TextStyle(fontSize: 10, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
      height: 28, width: 1, color: Colors.grey.shade200,
      margin: const EdgeInsets.symmetric(horizontal: 4));

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _hasActiveFilters
                ? 'No se encontraron resultados'
                : 'No hay movimientos registrados',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          if (_hasActiveFilters)
            TextButton.icon(
              icon: const Icon(Icons.filter_alt_off, size: 16),
              label: const Text('Limpiar filtros'),
              onPressed: _clearFilters,
            ),
        ],
      ),
    );
  }

  Widget _buildLogCard(InventoryLog log) {
    final isEntrada = log.tipo == 'Entrada';
    final accent = isEntrada ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: accent, width: 4)),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: accent.withOpacity(0.1),
              radius: 20,
              child: Icon(
                isEntrada
                    ? Icons.add_circle_outline
                    : Icons.remove_circle_outline,
                color: accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          log.productNombre,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${isEntrada ? "+" : "-"}${log.cantidad}',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    _badge('Talla ${log.talla}'),
                    const SizedBox(width: 6),
                    _badge(log.color),
                  ]),
                  if (log.nota.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.notes, size: 13, color: Colors.grey[500]),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          log.nota,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic),
                        ),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.access_time, size: 13, color: Colors.grey[400]),
                    const SizedBox(width: 5),
                    Text(
                      _formatDateTime(log.fechaHora),
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      );

  String _formatDateTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
