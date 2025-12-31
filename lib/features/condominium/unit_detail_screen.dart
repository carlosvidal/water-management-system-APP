import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_readings_app/core/models/condominium.dart';
import 'package:water_readings_app/core/services/api_service.dart';
import 'package:water_readings_app/features/condominium/unit_residents_screen.dart';
import 'package:water_readings_app/features/readings/period_readings_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class UnitDetailScreen extends ConsumerStatefulWidget {
  final Unit unit;
  final String condominiumId;
  final Condominium? condominium;

  const UnitDetailScreen({
    super.key,
    required this.unit,
    required this.condominiumId,
    this.condominium,
  });

  @override
  ConsumerState<UnitDetailScreen> createState() => _UnitDetailScreenState();
}

class _UnitDetailScreenState extends ConsumerState<UnitDetailScreen> {
  List<dynamic> periods = [];
  List<Map<String, dynamic>> unitHistory = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadUnitReadingsHistory();
  }

  String _getBlockName() {
    // First try to get it from the current unit
    if (widget.unit.block?.name != null) {
      return widget.unit.block!.name;
    }

    // If not available, try to find it in the condominium data passed as parameter
    if (widget.condominium?.blocks != null) {
      for (final block in widget.condominium!.blocks!) {
        if (block.id == widget.unit.blockId) {
          return block.name;
        }
      }
    }

    // If we still don't have the block name, show the blockId as fallback
    return widget.unit.blockId?.isNotEmpty == true ? widget.unit.blockId! : 'N/A';
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
        title: Text('${_getBlockName()} - ${widget.unit.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Ver residentes',
            onPressed: () => _navigateToResidents(),
          ),
        ],
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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildEnhancedSummaryCard(),
          const SizedBox(height: 16),
          _buildConsumptionChart(),
          const SizedBox(height: 16),
          Text(
            'Historial de Períodos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...unitHistory.map((historyItem) => _buildPeriodCard(historyItem)),
        ],
      ),
    );
  }

  Widget _buildEnhancedSummaryCard() {
    if (unitHistory.isEmpty) return const SizedBox.shrink();

    // Get last 12 readings (or less if not available)
    final last12 = unitHistory.take(12).toList();

    // Calculate totals from last 12
    double totalConsumption = 0;
    double totalAmount = 0;

    for (final item in last12) {
      final calc = item['calculation'];
      totalConsumption += (calc['consumption'] as num).toDouble();
      totalAmount += (calc['totalAmount'] as num).toDouble();
    }

    final avgConsumption = totalConsumption / last12.length;
    final avgAmount = totalAmount / last12.length;

    // Get latest reading
    final latestCalc = unitHistory.first['calculation'];
    final latestConsumption = (latestCalc['consumption'] as num).toDouble();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen de ${widget.unit.name}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Últimas ${last12.length} lecturas',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Main metric - Average consumption
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.water_drop,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Lectura Promedio',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${avgConsumption.toStringAsFixed(2)} m³',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'S/ ${avgAmount.toStringAsFixed(2)} promedio',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Additional metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Última Lectura',
                    '${latestConsumption.toStringAsFixed(1)} m³',
                    Icons.schedule,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Total Registros',
                    '${unitHistory.length}',
                    Icons.history,
                    Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Consumo Total',
                    '${totalConsumption.toStringAsFixed(1)} m³',
                    Icons.water,
                    Colors.cyan,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Monto Total',
                    'S/ ${totalAmount.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConsumptionChart() {
    if (unitHistory.isEmpty) return const SizedBox.shrink();

    // Get last 12 readings (reversed to show oldest to newest)
    final last12 = unitHistory.take(12).toList().reversed.toList();

    // Find max consumption for scaling
    double maxConsumption = 0;
    for (final item in last12) {
      final consumption = (item['calculation']['consumption'] as num).toDouble();
      if (consumption > maxConsumption) maxConsumption = consumption;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Consumo - Últimas ${last12.length} Lecturas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxConsumption * 1.2, // Add 20% padding
                  minY: 0,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.black87,
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final item = last12[group.x.toInt()];
                        final period = item['period'];
                        final startDate = DateTime.parse(period['startDate']);
                        final consumption = (item['calculation']['consumption'] as num).toDouble();

                        return BarTooltipItem(
                          '${_getMonthName(startDate.month)} ${startDate.year}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: '${consumption.toStringAsFixed(2)} m³',
                              style: const TextStyle(
                                color: Colors.yellow,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= last12.length) return const Text('');
                          final item = last12[value.toInt()];
                          final period = item['period'];
                          final startDate = DateTime.parse(period['startDate']);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _getMonthAbbr(startDate.month),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          );
                        },
                        reservedSize: 35,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxConsumption / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300]!,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.grey[300]!),
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  barGroups: List.generate(
                    last12.length,
                    (index) {
                      final consumption = (last12[index]['calculation']['consumption'] as num).toDouble();
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: consumption,
                            color: Theme.of(context).primaryColor,
                            width: 16,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withValues(alpha: 0.7),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Toca las barras para ver más detalles',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }

  String _getMonthAbbr(int month) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return months[month - 1];
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
      child: InkWell(
        onTap: () => _navigateToPeriodDetail(period),
        borderRadius: BorderRadius.circular(12),
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
    return '${_getMonthName(startDate.month)} ${startDate.year}';
  }

  void _navigateToPeriodDetail(Map<String, dynamic> periodData) {
    // Convert period map to Period object from condominium.dart model
    final period = Period(
      id: periodData['id'] as String,
      condominiumId: widget.condominiumId,
      startDate: DateTime.parse(periodData['startDate'] as String),
      endDate: periodData['endDate'] != null
          ? DateTime.parse(periodData['endDate'] as String)
          : null,
      status: periodData['status'] as String,
      totalVolume: periodData['totalVolume'] != null
          ? (periodData['totalVolume'] as num).toDouble()
          : null,
      totalAmount: periodData['totalAmount'] != null
          ? (periodData['totalAmount'] as num).toDouble()
          : null,
      receiptPhoto1: periodData['receiptPhoto1'] as String?,
      receiptPhoto2: periodData['receiptPhoto2'] as String?,
      createdAt: DateTime.parse(periodData['createdAt'] as String),
      updatedAt: DateTime.parse(periodData['updatedAt'] as String),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PeriodResultsWrapper(
          period: period,
          condominium: widget.condominium ?? Condominium(
            id: widget.condominiumId,
            name: '',
            address: '',
            city: '',
            country: '',
            readingDay: 1,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      ),
    );
  }

  void _navigateToResidents() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UnitResidentsScreen(
          unit: widget.unit,
          condominiumId: widget.condominiumId,
          condominium: widget.condominium,
        ),
      ),
    );
  }
}
