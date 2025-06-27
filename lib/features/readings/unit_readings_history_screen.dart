import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_readings_app/core/models/condominium.dart';
import 'package:water_readings_app/core/services/api_service.dart';

class UnitReadingsHistoryScreen extends ConsumerStatefulWidget {
  final Unit unit;
  final String condominiumId;
  final String blockName;

  const UnitReadingsHistoryScreen({
    super.key,
    required this.unit,
    required this.condominiumId,
    required this.blockName,
  });

  @override
  ConsumerState<UnitReadingsHistoryScreen> createState() => _UnitReadingsHistoryScreenState();
}

class _UnitReadingsHistoryScreenState extends ConsumerState<UnitReadingsHistoryScreen> {
  List<dynamic> periods = [];
  List<Map<String, dynamic>> unitHistory = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadUnitReadingsHistory();
  }

  Future<void> _loadUnitReadingsHistory() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      
      // Get all periods for the condominium
      final allPeriods = await apiService.getCondominiumPeriods(widget.condominiumId);
      
      // Filter only closed periods
      final closedPeriods = allPeriods.where((period) => period['status'] == 'CLOSED').toList();
      
      // Sort periods by creation date (newest first)
      closedPeriods.sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
      
      final List<Map<String, dynamic>> history = [];
      
      // For each closed period, try to get the unit's reading data
      for (final period in closedPeriods) {
        try {
          final storedData = await apiService.getStoredCalculations(period['id']);
          if (storedData['unitCalculations'] != null) {
            final unitCalculations = storedData['unitCalculations'] as List;
            
            // Find this unit's calculation
            final unitCalc = unitCalculations.firstWhere(
              (calc) => calc['unitId'] == widget.unit.id,
              orElse: () => null,
            );
            
            if (unitCalc != null) {
              history.add({
                'period': period,
                'calculation': unitCalc,
                'periodCalculation': storedData['periodCalculation'],
              });
            }
          }
        } catch (e) {
          // Period doesn't have stored calculations, skip it
          continue;
        }
      }

      if (mounted) {
        setState(() {
          periods = closedPeriods;
          unitHistory = history;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lecturas de ${widget.blockName} - ${widget.unit.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return _buildErrorView();
    }

    if (unitHistory.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadUnitReadingsHistory,
      child: Column(
        children: [
          _buildSummaryCard(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: unitHistory.length,
              itemBuilder: (context, index) {
                final historyItem = unitHistory[index];
                return _buildPeriodCard(historyItem);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (unitHistory.isEmpty) return const SizedBox.shrink();
    
    // Calculate totals
    double totalConsumption = 0;
    double totalAmount = 0;
    
    for (final item in unitHistory) {
      final calc = item['calculation'];
      totalConsumption += (calc['consumption'] as num).toDouble();
      totalAmount += (calc['totalAmount'] as num).toDouble();
    }
    
    final avgConsumption = totalConsumption / unitHistory.length;
    final avgAmount = totalAmount / unitHistory.length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Resumen de ${widget.unit.name}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Períodos',
                    unitHistory.length.toString(),
                    Icons.calendar_month,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Consumo Total',
                    '${totalConsumption.toStringAsFixed(1)} m³',
                    Icons.water_drop,
                    Colors.cyan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Promedio Consumo',
                    '${avgConsumption.toStringAsFixed(1)} m³',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Promedio Monto',
                    'S/ ${avgAmount.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodCard(Map<String, dynamic> historyItem) {
    final period = historyItem['period'];
    final calculation = historyItem['calculation'];
    final periodCalculation = historyItem['periodCalculation'];
    
    final consumption = (calculation['consumption'] as num).toDouble();
    final previousReading = (calculation['previousReading'] as num).toDouble();
    final currentReading = (calculation['currentReading'] as num).toDouble();
    final individualAmount = (calculation['individualAmount'] as num).toDouble();
    final commonAreasAmount = (calculation['commonAreasAmount'] as num).toDouble();
    final totalAmount = (calculation['totalAmount'] as num).toDouble();
    final residentName = calculation['residentName'] as String?;
    
    final startDate = DateTime.parse(period['startDate']);
    final endDate = DateTime.parse(period['endDate']);
    final costPerM3 = (periodCalculation['costPerCubicMeter'] as num).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatPeriodTitle(startDate, endDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'CERRADO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            
            if (residentName != null && residentName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                residentName,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Reading metrics
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetric('Lectura Anterior', '${previousReading.toStringAsFixed(3)} m³', Icons.history),
                      _buildMetric('Lectura Actual', '${currentReading.toStringAsFixed(3)} m³', Icons.water_drop),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetric('Consumo', '${consumption.toStringAsFixed(3)} m³', Icons.trending_up, color: Colors.blue),
                      _buildMetric('Costo por m³', 'S/ ${costPerM3.toStringAsFixed(4)}', Icons.attach_money, color: Colors.purple),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Amount breakdown
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetric('Consumo Individual', 'S/ ${individualAmount.toStringAsFixed(2)}', Icons.person, color: Colors.blue),
                      _buildMetric('Áreas Comunes', 'S/ ${commonAreasAmount.toStringAsFixed(2)}', Icons.domain, color: Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMetric('TOTAL', 'S/ ${totalAmount.toStringAsFixed(2)}', Icons.account_balance_wallet, color: Colors.green, isTotal: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, {Color? color, bool isTotal = false}) {
    final effectiveColor = color ?? Colors.grey[600]!;
    
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: effectiveColor, size: isTotal ? 24 : 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
              color: Colors.grey[600],
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: effectiveColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin historial de lecturas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta unidad no tiene períodos cerrados con lecturas registradas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUnitReadingsHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar lecturas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUnitReadingsHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPeriodTitle(DateTime startDate, DateTime endDate) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    
    return '${months[startDate.month - 1]} ${startDate.year}';
  }
}