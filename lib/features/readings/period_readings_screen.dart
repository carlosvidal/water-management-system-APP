import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_readings_app/core/models/condominium.dart';
import 'package:water_readings_app/core/services/api_service.dart';
import 'package:water_readings_app/core/providers/periods_provider.dart';
import 'package:water_readings_app/core/providers/billing_calculation_provider.dart';

class PeriodReadingsScreen extends ConsumerStatefulWidget {
  final Period period;
  final Condominium condominium;

  const PeriodReadingsScreen({
    super.key,
    required this.period,
    required this.condominium,
  });

  @override
  ConsumerState<PeriodReadingsScreen> createState() => _PeriodReadingsScreenState();
}

class _PeriodReadingsScreenState extends ConsumerState<PeriodReadingsScreen> {
  List<dynamic> units = [];
  List<dynamic> readings = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      
      // Load units and readings in parallel
      final results = await Future.wait([
        apiService.getCondominiumUnits(widget.condominium.id),
        apiService.getPeriodReadings(widget.period.id),
      ]);

      if (mounted) {
        setState(() {
          units = results[0];
          readings = results[1];
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
        title: const Text('Lecturas del Período'),
        actions: [
          // Temporary reset button for PENDING_RECEIPT periods
          if (widget.period.status == 'PENDING_RECEIPT')
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: _resetPeriodStatus,
              tooltip: 'Resetear a ABIERTO',
            ),
          // Validate all readings button
          if (widget.period.status != 'CLOSED')
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: _validateAllReadings,
              tooltip: 'Validar todas las lecturas',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Period info header
          Container(
            width: double.infinity,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.condominium.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Período: ${_formatDate(widget.period.startDate)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withValues(alpha: 0.1),
                        border: Border.all(color: _getStatusColor().withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_getCompletedReadings()}/${units.length} lecturas',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Units list
          Expanded(
            child: _buildContent(),
          ),
          
          // Action button (show if period is OPEN or PENDING_RECEIPT and has readings)
          if ((widget.period.status == 'OPEN' || widget.period.status == 'PENDING_RECEIPT') && _canFinalizePeriod())
            FutureBuilder<bool>(
              future: _checkForPreviousPeriods(),
              builder: (context, snapshot) {
                final hasPerviousPeriods = snapshot.data ?? false;
                
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.3),
                        offset: const Offset(0, -2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: hasPerviousPeriods 
                        ? ElevatedButton.icon(
                            onPressed: _calculateConsumption,
                            icon: const Icon(Icons.calculate),
                            label: const Text('Calcular Consumo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _closePeriodDirectly,
                            icon: const Icon(Icons.lock),
                            label: const Text('Cerrar Período Base'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return _buildErrorView();
    }

    if (units.isEmpty) {
      return _buildEmptyState();
    }

    return _buildUnitsList();
  }

  Widget _buildUnitsList() {
    // Separate units into those with and without readings
    final unitsWithoutReadings = <dynamic>[];
    final unitsWithReadings = <dynamic>[];
    
    for (final unit in units) {
      final hasReading = _getReadingForUnit(unit) != null;
      if (hasReading) {
        unitsWithReadings.add(unit);
      } else {
        unitsWithoutReadings.add(unit);
      }
    }
    
    // Sort both groups alphabetically by block and unit name
    void sortUnits(List<dynamic> unitList) {
      unitList.sort((a, b) {
        final blockComparison = (a['block']?['name'] ?? '').compareTo(b['block']?['name'] ?? '');
        if (blockComparison != 0) return blockComparison;
        return a['name'].compareTo(b['name']);
      });
    }
    
    sortUnits(unitsWithoutReadings);
    sortUnits(unitsWithReadings);
    
    // Build the complete list with section headers
    final List<Widget> listItems = [];
    
    // Add pending readings section
    if (unitsWithoutReadings.isNotEmpty) {
      listItems.add(_buildSectionHeader(
        'Lecturas Pendientes (${unitsWithoutReadings.length})',
        Icons.schedule,
        Colors.orange,
      ));
      
      for (final unit in unitsWithoutReadings) {
        listItems.add(_buildUnitCard(unit));
      }
    }
    
    // Add completed readings section
    if (unitsWithReadings.isNotEmpty) {
      if (unitsWithoutReadings.isNotEmpty) {
        listItems.add(const SizedBox(height: 8)); // Spacing between sections
      }
      
      listItems.add(_buildSectionHeader(
        'Lecturas Completadas (${unitsWithReadings.length})',
        Icons.check_circle,
        Colors.green,
      ));
      
      for (final unit in unitsWithReadings) {
        listItems.add(_buildUnitCard(unit));
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: listItems,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(color: color.withValues(alpha: 0.3), thickness: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitCard(dynamic unit) {
    final unitReading = _getReadingForUnit(unit);
    final hasReading = unitReading != null;
    final meter = _getWaterMeter(unit);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: hasReading ? Colors.green : Colors.grey,
          child: Icon(
            hasReading ? Icons.check : Icons.water_drop,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          '${unit['block']?['name'] ?? 'N/A'} - ${unit['name']}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (unit['residents'] != null && unit['residents'].isNotEmpty)
              Text('Residente: ${unit['residents'][0]['name']}')
            else if (unit['resident'] != null)
              Text('Residente: ${unit['resident']['name']}')
            else
              const Text('Sin residente asignado'),
            
            const SizedBox(height: 4),
            
            if (hasReading) ...[
              Text(
                'Lectura: ${unitReading['value']} m³',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Registrada: ${_formatDateTime(DateTime.parse(unitReading['createdAt']))}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (widget.period.status != 'CLOSED')
                Text(
                  'Toca para editar',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ] else ...[
              Text(
                widget.period.status == 'CLOSED' 
                    ? 'Sin lectura registrada'
                    : 'Toca para registrar lectura',
                style: TextStyle(
                  color: widget.period.status == 'CLOSED' ? Colors.grey : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (meter != null)
                Text(
                  'Medidor: ${meter['serialNumber'] ?? meter['id']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ],
        ),
        trailing: widget.period.status == 'CLOSED'
            ? (hasReading 
                ? const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  )
                : const Icon(
                    Icons.block,
                    color: Colors.grey,
                    size: 20,
                  ))
            : const Icon(
                Icons.edit_outlined, 
                color: Colors.blue,
                size: 20,
              ),
        onTap: () => _showReadingDialog(unit, unitReading),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay unidades',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Este condominio no tiene unidades configuradas',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar datos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error!,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  void _showReadingDialog(dynamic unit, dynamic existingReading) {
    // Check if period is closed
    if (widget.period.status == 'CLOSED') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pueden editar lecturas de un período cerrado'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final meter = _getWaterMeter(unit);
    if (meter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta unidad no tiene medidor de agua configurado')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _ReadingDialog(
        unit: unit,
        meter: meter,
        period: widget.period,
        existingReading: existingReading,
        onReadingSaved: _loadData,
      ),
    );
  }

  dynamic _getReadingForUnit(dynamic unit) {
    final meter = _getWaterMeter(unit);
    if (meter == null) return null;
    
    try {
      return readings.firstWhere((reading) => reading['meterId'] == meter['id']);
    } catch (e) {
      return null;
    }
  }

  dynamic _getWaterMeter(dynamic unit) {
    final meters = unit['meters'] as List?;
    if (meters == null || meters.isEmpty) return null;
    
    try {
      return meters.firstWhere((meter) => meter['type'] == 'WATER');
    } catch (e) {
      return meters.first; // Fallback to first meter
    }
  }

  int _getCompletedReadings() {
    return units.where((unit) => _getReadingForUnit(unit) != null).length;
  }

  Color _getStatusColor() {
    switch (widget.period.status) {
      case 'OPEN':
        return Colors.green;
      case 'PENDING_RECEIPT':
        return Colors.orange;
      case 'CALCULATING':
        return Colors.blue;
      case 'CLOSED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (widget.period.status) {
      case 'OPEN':
        return 'ABIERTO';
      case 'PENDING_RECEIPT':
        return 'ESPERANDO RECIBO';
      case 'CALCULATING':
        return 'CALCULANDO';
      case 'CLOSED':
        return 'CERRADO';
      default:
        return widget.period.status;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  bool _canFinalizePeriod() {
    if (units.isEmpty) return false;
    
    // Count units with water meters
    final unitsWithMeters = units.where((unit) {
      final meters = unit['meters'] as List?;
      return meters != null && meters.any((meter) => meter['type'] == 'WATER');
    }).length;

    // Check if all units have readings
    final completedReadings = _getCompletedReadings();
    return completedReadings >= unitsWithMeters;
  }

  Future<void> _calculateConsumption() async {
    // Navigate directly to calculation since we already know there are previous periods
    _navigateToCalculation();
  }

  Future<void> _closePeriodDirectly() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Cerrar Período Base'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Este período se cerrará como "período base" para futuras comparaciones.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16),
            Text('Al cerrar este período:'),
            SizedBox(height: 8),
            Text('• Se guardará como referencia para cálculos futuros'),
            Text('• Los siguientes períodos podrán calcular consumos'),
            Text('• No se calculará distribución de costos'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Store context references before async operations
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final dialogContext = context;
              
              try {
                // Close dialog first
                navigator.pop();
                
                // Show loading indicator
                showDialog(
                  context: dialogContext,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Cerrando período...'),
                      ],
                    ),
                  ),
                );
                
                // Close period
                await ref.read(periodsProvider(widget.condominium.id).notifier).closePeriod(widget.period.id);
                
                if (mounted) {
                  // Close loading dialog
                  navigator.pop();
                  
                  // Navigate back to periods list
                  navigator.pop();
                  
                  // Show success message
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Período base cerrado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  // Close loading dialog if it exists
                  navigator.pop();
                  
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error al cerrar período: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Cerrar Período Base'),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkForPreviousPeriods() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final periods = await apiService.getCondominiumPeriods(widget.condominium.id);
      
      // Filter out the current period and check if there are any closed periods
      final otherPeriods = periods.where((p) => p['id'] != widget.period.id).toList();
      final closedPeriods = otherPeriods.where((p) => p['status'] == 'CLOSED').toList();
      
      return closedPeriods.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _resetPeriodStatus() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      
      // Store context references before async operation
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      
      await apiService.resetPeriodStatus(widget.period.id);
      
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Estado del período resetado a ABIERTO'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the screen to show updated status
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al resetear período: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _validateAllReadings() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      
      // Store context reference before async operation
      final messenger = ScaffoldMessenger.of(context);
      
      final result = await apiService.validateAllReadings(widget.period.id);
      
      if (mounted) {
        final count = result['count'] ?? 0;
        messenger.showSnackBar(
          SnackBar(
            content: Text('$count lecturas validadas exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the screen to show updated status
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al validar lecturas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void _navigateToCalculation() {
    // Navigate to calculation screen with billing form
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PeriodCalculationScreen(
          period: widget.period,
          condominium: widget.condominium,
        ),
      ),
    );
  }
}

class _ReadingDialog extends ConsumerStatefulWidget {
  final dynamic unit;
  final dynamic meter;
  final Period period;
  final dynamic existingReading;
  final VoidCallback onReadingSaved;

  const _ReadingDialog({
    required this.unit,
    required this.meter,
    required this.period,
    this.existingReading,
    required this.onReadingSaved,
  });

  @override
  ConsumerState<_ReadingDialog> createState() => _ReadingDialogState();
}

class _ReadingDialogState extends ConsumerState<_ReadingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  final _valueFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingReading != null) {
      _valueController.text = widget.existingReading['value'].toString();
      _notesController.text = widget.existingReading['notes'] ?? '';
    }
    
    // Request focus on the reading field after the dialog is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _valueFocusNode.requestFocus();
      
      // If editing existing reading, select all text for easy replacement
      if (widget.existingReading != null && _valueController.text.isNotEmpty) {
        _valueController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _valueController.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    _valueFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingReading != null;
    
    return AlertDialog(
      title: Text(isEdit ? 'Editar Lectura' : 'Nueva Lectura'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unit info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.unit['block']?['name'] ?? 'N/A'} - ${widget.unit['name']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (widget.unit['residents'] != null && widget.unit['residents'].isNotEmpty)
                      Text('Residente: ${widget.unit['residents'][0]['name']}')
                    else if (widget.unit['resident'] != null)
                      Text('Residente: ${widget.unit['resident']['name']}')
                    else
                      const Text('Sin residente asignado'),
                    Text('Medidor: ${widget.meter['serialNumber'] ?? widget.meter['id']}'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Reading value
              TextFormField(
                controller: _valueController,
                focusNode: _valueFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Lectura (m³) *',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: 1234.5',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (!_isLoading) {
                    _saveReading();
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La lectura es requerida';
                  }
                  final number = double.tryParse(value);
                  if (number == null) {
                    return 'Ingresa un número válido';
                  }
                  if (number < 0) {
                    return 'La lectura no puede ser negativa';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'Observaciones sobre la lectura',
                ),
                maxLines: 3,
              ),
              
              if (isEdit) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Lectura registrada',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Fecha: ${_formatDateTime(DateTime.parse(widget.existingReading['createdAt']))}'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveReading,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Actualizar' : 'Guardar'),
        ),
      ],
    );
  }

  Future<void> _saveReading() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final value = double.parse(_valueController.text);
      
      if (widget.existingReading != null) {
        // Update existing reading with new value
        final updateData = <String, dynamic>{
          'value': value,
          'isValidated': true,
          'isAnomalous': false,
        };
        
        // Only add notes if not empty
        if (_notesController.text.trim().isNotEmpty) {
          updateData['notes'] = _notesController.text.trim();
        }
        
        await apiService.updateReading(
          widget.period.id,
          widget.existingReading['id'],
          updateData,
        );
      } else {
        // Create new reading (auto-validated)
        final readingData = <String, dynamic>{
          'meterId': widget.meter['id'],
          'value': value,
          'isValidated': true, // Auto-validate all readings
          'isAnomalous': false, // Default to non-anomalous
        };
        
        // Only add notes if not empty
        if (_notesController.text.trim().isNotEmpty) {
          readingData['notes'] = _notesController.text.trim();
        }
        
        await apiService.createReading(widget.period.id, readingData);
      }

      if (mounted) {
        final navigator = Navigator.of(context);
        final messenger = ScaffoldMessenger.of(context);
        
        navigator.pop();
        widget.onReadingSaved();
        messenger.showSnackBar(
          SnackBar(
            content: Text(widget.existingReading != null 
                ? 'Lectura actualizada exitosamente' 
                : 'Lectura guardada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar lectura: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _PeriodCalculationScreen extends ConsumerStatefulWidget {
  final Period period;
  final Condominium condominium;

  const _PeriodCalculationScreen({
    required this.period,
    required this.condominium,
  });

  @override
  ConsumerState<_PeriodCalculationScreen> createState() => _PeriodCalculationScreenState();
}

class _PeriodCalculationScreenState extends ConsumerState<_PeriodCalculationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _totalVolumeController = TextEditingController();
  final _totalAmountController = TextEditingController();
  List<dynamic> units = [];
  List<dynamic> readings = [];
  List<dynamic> _previousReadings = [];
  List<Map<String, dynamic>> consumptionData = [];
  double totalConsumption = 0.0;
  double totalAmount = 0.0;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadSavedBillingData();
    _loadDataAndCalculate();
  }

  void _loadSavedBillingData() {
    final billingNotifier = ref.read(billingCalculationProvider.notifier);
    final savedData = billingNotifier.getBillingDataForPeriod(widget.period.id);
    
    if (savedData != null) {
      if (savedData.totalVolume != null) {
        _totalVolumeController.text = savedData.totalVolume!;
      }
      if (savedData.totalAmount != null) {
        _totalAmountController.text = savedData.totalAmount!;
      }
    }

    // Add listeners to save data when text changes
    _totalVolumeController.addListener(_saveBillingData);
    _totalAmountController.addListener(_saveBillingData);
  }

  void _saveBillingData() {
    final billingNotifier = ref.read(billingCalculationProvider.notifier);
    billingNotifier.updateBillingData(
      widget.period.id,
      _totalVolumeController.text.isNotEmpty ? _totalVolumeController.text : null,
      _totalAmountController.text.isNotEmpty ? _totalAmountController.text : null,
    );
  }

  Future<void> _loadDataAndCalculate() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      
      // Load units, readings, and previous period readings
      final results = await Future.wait([
        apiService.getCondominiumUnits(widget.condominium.id),
        apiService.getPeriodReadings(widget.period.id),
        apiService.getPreviousPeriodReadings(widget.condominium.id, widget.period.id),
      ]);

      units = results[0];
      readings = results[1];
      _previousReadings = results[2];

      // Calculate consumption after loading data
      _calculateConsumption();

    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  void _calculateConsumption() {
    setState(() => isLoading = true);

    try {
      final List<Map<String, dynamic>> calculations = [];
      double totalConsume = 0.0;
      double totalCost = 0.0;

      for (final unit in units) {
        try {
          final reading = _getReadingForUnit(unit);
          if (reading == null) continue;

          final unitCalculation = _calculateUnitConsumption(unit, reading);
          calculations.add(unitCalculation);
          
          final consumption = unitCalculation['consumption'] as double? ?? 0.0;
          final amount = unitCalculation['amount'] as double? ?? 0.0;
          
          totalConsume += consumption;
          totalCost += amount;
        } catch (e) {
          // Error processing unit, continue with next unit
          // Continue with next unit instead of crashing
          continue;
        }
      }

      if (mounted) {
        setState(() {
          consumptionData = calculations;
          totalConsumption = totalConsume;
          totalAmount = totalCost;
          isLoading = false;
        });
      }
    } catch (e) {
      // Error calculating consumption
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al calcular consumo: $e')),
        );
      }
    }
  }

  Map<String, dynamic> _calculateUnitConsumption(dynamic unit, dynamic reading) {
    try {
      // Safe parsing of values
      final currentReading = ((reading['value'] as num?) ?? 0).toDouble();
      
      // Get actual previous reading from previous period (if available)
      double previousReading = 0.0;
      
      // Find the meter for this unit
      final meter = _getWaterMeter(unit);
      if (meter != null) {
        // Look for previous reading for this meter
        try {
          final previousReadingData = _previousReadings.firstWhere(
            (prevReading) => prevReading['meterId'] == meter['id'],
          );
          previousReading = ((previousReadingData['value'] as num?) ?? 0).toDouble();
        } catch (e) {
          // No previous reading found for this meter, keep as 0.0
          previousReading = 0.0;
        }
      }
      
      final consumption = currentReading - previousReading;
      
      // Get rate from plan or use default
      final planRate = widget.condominium.plan?.pricePerUnitPEN ?? 2.5;
      final amount = consumption * planRate;
      
      return {
        'unit': unit,
        'reading': reading,
        'currentReading': currentReading,
        'previousReading': previousReading,
        'consumption': consumption,
        'rate': planRate,
        'amount': amount,
        'residentName': _getResidentName(unit),
      };
    } catch (e) {
      // Error calculating unit consumption, using safe defaults
      // Return safe defaults
      return {
        'unit': unit,
        'reading': reading,
        'currentReading': 0.0,
        'previousReading': 0.0,
        'consumption': 0.0,
        'rate': 2.5,
        'amount': 0.0,
        'residentName': _getResidentName(unit),
      };
    }
  }

  dynamic _getReadingForUnit(dynamic unit) {
    try {
      final meter = _getWaterMeter(unit);
      if (meter == null) return null;
      
      return readings.firstWhere((reading) => reading['meterId'] == meter['id']);
    } catch (e) {
      return null;
    }
  }

  dynamic _getWaterMeter(dynamic unit) {
    try {
      final meters = unit['meters'] as List?;
      if (meters == null || meters.isEmpty) return null;
      
      return meters.firstWhere((meter) => meter['type'] == 'WATER');
    } catch (e) {
      // If no WATER meter found, try to return first meter
      final meters = unit['meters'] as List?;
      return (meters != null && meters.isNotEmpty) ? meters.first : null;
    }
  }

  String _getResidentName(dynamic unit) {
    try {
      if (unit['residents'] != null && (unit['residents'] as List).isNotEmpty) {
        return unit['residents'][0]['name'] ?? 'Sin nombre';
      } else if (unit['resident'] != null) {
        return unit['resident']['name'] ?? 'Sin nombre';
      }
      return 'Sin residente';
    } catch (e) {
      return 'Sin residente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cálculo de Consumo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBackNavigation,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.condominium.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Período: ${_formatDate(widget.period.startDate)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Billing information form
              Text(
                'Información de Facturación',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa los datos de la factura de la compañía de agua para este período',
                style: TextStyle(color: Colors.grey[600]),
              ),
              
              const SizedBox(height: 16),
              
              // Total volume field
              TextFormField(
                controller: _totalVolumeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Volumen Total Facturado (m³) *',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: 1250.5',
                  prefixIcon: Icon(Icons.water_drop),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El volumen total es requerido';
                  }
                  final number = double.tryParse(value);
                  if (number == null || number <= 0) {
                    return 'Ingresa un volumen válido mayor a 0';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Total amount field
              TextFormField(
                controller: _totalAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto Total Facturado (S/) *',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: 1500.00',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El monto total es requerido';
                  }
                  final number = double.tryParse(value);
                  if (number == null || number <= 0) {
                    return 'Ingresa un monto válido mayor a 0';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Info box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Cómo funciona el cálculo:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('• Se calcula el consumo individual: Lectura actual - Lectura anterior'),
                    const Text('• Se distribuye el costo proporcionalmente al consumo'),
                    const Text('• Cada unidad paga según su consumo real'),
                    const Text('• Los datos ingresados deben coincidir con el recibo de agua'),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Calculate button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _calculateAndNavigate,
                  icon: const Icon(Icons.calculate),
                  label: const Text('Calcular Distribución'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _totalVolumeController.removeListener(_saveBillingData);
    _totalAmountController.removeListener(_saveBillingData);
    _totalVolumeController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }

  void _calculateAndNavigate() {
    if (!_formKey.currentState!.validate()) return;
    
    final totalVolume = double.parse(_totalVolumeController.text);
    final totalAmount = double.parse(_totalAmountController.text);
    
    // Navigate to results screen with billing data
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PeriodResultsScreen(
          period: widget.period,
          condominium: widget.condominium,
          totalVolumeFromBill: totalVolume,
          totalAmountFromBill: totalAmount,
        ),
      ),
    );
  }

  void _handleBackNavigation() {
    Navigator.of(context).pop();
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// Results screen to show calculated consumption and allow period closure
class _PeriodResultsScreen extends ConsumerStatefulWidget {
  final Period period;
  final Condominium condominium;
  final double totalVolumeFromBill;
  final double totalAmountFromBill;

  const _PeriodResultsScreen({
    required this.period,
    required this.condominium,
    required this.totalVolumeFromBill,
    required this.totalAmountFromBill,
  });

  @override
  ConsumerState<_PeriodResultsScreen> createState() => _PeriodResultsScreenState();
}

class _PeriodResultsScreenState extends ConsumerState<_PeriodResultsScreen> {
  List<dynamic> units = [];
  List<dynamic> readings = [];
  List<dynamic> _previousReadings = [];
  List<Map<String, dynamic>> consumptionData = [];
  double totalConsumption = 0.0;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadDataAndCalculate();
  }

  Future<void> _loadDataAndCalculate() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      
      // Check if period is closed and has stored calculations
      if (widget.period.status == 'CLOSED') {
        try {
          final storedData = await apiService.getStoredCalculations(widget.period.id);
          if (storedData['periodCalculation'] != null && storedData['unitCalculations'] != null) {
            _loadStoredCalculations(storedData);
            return;
          }
        } catch (e) {
          // If no stored calculations found, fall back to real-time calculation
          // No stored calculations found, falling back to real-time calculation
        }
      }
      
      // Load units, readings, and previous period readings for real-time calculation
      final results = await Future.wait([
        apiService.getCondominiumUnits(widget.condominium.id),
        apiService.getPeriodReadings(widget.period.id),
        apiService.getPreviousPeriodReadings(widget.condominium.id, widget.period.id),
      ]);

      units = results[0];
      readings = results[1];
      _previousReadings = results[2];

      // Calculate consumption after loading data
      _calculateConsumption();

    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  void _loadStoredCalculations(Map<String, dynamic> storedData) {
    setState(() => isLoading = true);

    try {
      final unitCalcs = storedData['unitCalculations'] as List;

      // Build consumption data from stored calculations
      final List<Map<String, dynamic>> calculations = [];
      double totalConsume = 0.0;

      for (final unitCalc in unitCalcs) {
        final calculationData = {
          'unit': {
            'id': unitCalc['unitId'],
            'name': unitCalc['unitName'] ?? 'N/A',
            'block': {'name': unitCalc['blockName'] ?? 'N/A'},
          },
          'reading': {'value': unitCalc['currentReading']},
          'currentReading': (unitCalc['currentReading'] as num).toDouble(),
          'previousReading': (unitCalc['previousReading'] as num).toDouble(),
          'consumption': (unitCalc['consumption'] as num).toDouble(),
          'individualAmount': (unitCalc['individualAmount'] as num).toDouble(),
          'commonAreasAmount': (unitCalc['commonAreasAmount'] as num).toDouble(),
          'amount': (unitCalc['totalAmount'] as num).toDouble(),
          'residentName': unitCalc['residentName'] ?? 'Sin residente',
          // Add the saved names directly to the data for easy access
          'unitName': unitCalc['unitName'],
          'blockName': unitCalc['blockName'],
        };
        
        calculations.add(calculationData);
        totalConsume += calculationData['consumption'] as double;
      }

      if (mounted) {
        setState(() {
          consumptionData = calculations;
          totalConsumption = totalConsume;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar cálculos guardados: $e')),
        );
      }
    }
  }

  void _calculateConsumption() {
    setState(() => isLoading = true);

    try {
      final List<Map<String, dynamic>> calculations = [];
      double totalConsume = 0.0;

      for (final unit in units) {
        try {
          final reading = _getReadingForUnit(unit);
          if (reading == null) continue;

          final unitCalculation = _calculateUnitConsumption(unit, reading);
          calculations.add(unitCalculation);
          
          final consumption = unitCalculation['consumption'] as double? ?? 0.0;
          totalConsume += consumption;
        } catch (e) {
          // Continue with next unit instead of crashing
          continue;
        }
      }

      // Calculate amounts using cost per cubic meter
      final costPerM3 = widget.totalVolumeFromBill > 0 ? widget.totalAmountFromBill / widget.totalVolumeFromBill : 0.0;
      final commonAreasConsumption = widget.totalVolumeFromBill - totalConsume;
      final commonAreasPerUnit = calculations.isNotEmpty ? (commonAreasConsumption * costPerM3) / calculations.length : 0.0;
      
      for (final calculation in calculations) {
        final consumption = calculation['consumption'] as double;
        final individualAmount = consumption * costPerM3;
        calculation['individualAmount'] = individualAmount;
        calculation['commonAreasAmount'] = commonAreasPerUnit;
        calculation['amount'] = individualAmount + commonAreasPerUnit; // Total amount per unit
      }

      if (mounted) {
        setState(() {
          consumptionData = calculations;
          totalConsumption = totalConsume;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al calcular consumo: $e')),
        );
      }
    }
  }

  Map<String, dynamic> _calculateUnitConsumption(dynamic unit, dynamic reading) {
    try {
      final currentReading = ((reading['value'] as num?) ?? 0).toDouble();
      
      // Get actual previous reading from previous period
      double previousReading = 0.0;
      
      // Find the meter for this unit
      final meter = _getWaterMeter(unit);
      if (meter != null) {
        // Look for previous reading for this meter
        try {
          final previousReadingData = _previousReadings.firstWhere(
            (prevReading) => prevReading['meterId'] == meter['id'],
          );
          previousReading = ((previousReadingData['value'] as num?) ?? 0).toDouble();
        } catch (e) {
          // No previous reading found for this meter, keep as 0.0
          previousReading = 0.0;
        }
      }
      
      final consumption = currentReading - previousReading;
      
      return {
        'unit': unit,
        'reading': reading,
        'currentReading': currentReading,
        'previousReading': previousReading,
        'consumption': consumption,
        'residentName': _getResidentName(unit),
        'amount': 0.0, // Will be calculated later based on proportion
      };
    } catch (e) {
      // Return safe defaults
      return {
        'unit': unit,
        'reading': reading,
        'currentReading': 0.0,
        'previousReading': 0.0,
        'consumption': 0.0,
        'residentName': _getResidentName(unit),
        'amount': 0.0,
      };
    }
  }

  dynamic _getReadingForUnit(dynamic unit) {
    try {
      final meter = _getWaterMeter(unit);
      if (meter == null) return null;
      
      return readings.firstWhere((reading) => reading['meterId'] == meter['id']);
    } catch (e) {
      return null;
    }
  }

  dynamic _getWaterMeter(dynamic unit) {
    try {
      final meters = unit['meters'] as List?;
      if (meters == null || meters.isEmpty) return null;
      
      return meters.firstWhere((meter) => meter['type'] == 'WATER');
    } catch (e) {
      final meters = unit['meters'] as List?;
      return (meters != null && meters.isNotEmpty) ? meters.first : null;
    }
  }

  String _getResidentName(dynamic unit) {
    try {
      if (unit['residents'] != null && (unit['residents'] as List).isNotEmpty) {
        return unit['residents'][0]['name'] ?? 'Sin nombre';
      } else if (unit['resident'] != null) {
        return unit['resident']['name'] ?? 'Sin nombre';
      }
      return 'Sin residente';
    } catch (e) {
      return 'Sin residente';
    }
  }

  double _calculateCommonAreasConsumption() {
    // Consumo de áreas comunes = Volumen Facturado - Consumo Medido
    return widget.totalVolumeFromBill - totalConsumption;
  }


  double _calculateTotalIndividualAmount() {
    // Suma de todos los montos individuales
    return consumptionData.fold(0.0, (sum, data) => sum + (data['individualAmount'] as double? ?? 0.0));
  }

  double _calculateCommonAreasAmount() {
    // Suma de todos los montos de áreas comunes
    return consumptionData.fold(0.0, (sum, data) => sum + (data['commonAreasAmount'] as double? ?? 0.0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados - Distribución'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBackNavigation,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _buildErrorView()
              : Column(
                  children: [
                    // Header with totals
                    Container(
                      width: double.infinity,
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.condominium.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('Período: ${_formatDate(widget.period.startDate)}'),
                          const SizedBox(height: 12),
                          // Consolidated ScoreCards showing both volume and amount
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.receipt, color: Colors.orange[700], size: 16),
                                          const SizedBox(width: 4),
                                          const Expanded(
                                            child: Text(
                                              'Volumen\nFacturado',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, height: 1.1),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${widget.totalVolumeFromBill.toStringAsFixed(3)} m³',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'S/ ${widget.totalAmountFromBill.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.orange[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.water_drop, color: Colors.blue[700], size: 16),
                                          const SizedBox(width: 4),
                                          const Expanded(
                                            child: Text(
                                              'Consumo\nIndividual',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, height: 1.1),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${totalConsumption.toStringAsFixed(3)} m³',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'S/ ${_calculateTotalIndividualAmount().toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.domain, color: Colors.purple[700], size: 16),
                                          const SizedBox(width: 4),
                                          const Expanded(
                                            child: Text(
                                              'Áreas\nComunes',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, height: 1.1),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${_calculateCommonAreasConsumption().toStringAsFixed(3)} m³',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.purple,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'S/ ${_calculateCommonAreasAmount().toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.purple[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Consumption list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: consumptionData.length,
                        itemBuilder: (context, index) {
                          final data = consumptionData[index];
                          return _buildConsumptionCard(data);
                        },
                      ),
                    ),

                    // Close period button (only show if period is not already closed)
                    if (widget.period.status != 'CLOSED')
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.3),
                              offset: const Offset(0, -2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _confirmClosePeriod,
                                icon: const Icon(Icons.lock),
                                label: const Text('Cerrar Período Definitivamente'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }

  String _getBlockName(Map<String, dynamic> data, dynamic unit) {
    // Try to get from saved calculation data first (for closed periods)
    if (data.containsKey('blockName') && data['blockName'] != null) {
      return data['blockName'] as String;
    }
    // Fallback to unit structure (for real-time data)
    return unit?['block']?['name'] ?? 'N/A';
  }

  String _getUnitName(Map<String, dynamic> data, dynamic unit) {
    // Try to get from saved calculation data first (for closed periods)
    if (data.containsKey('unitName') && data['unitName'] != null) {
      return data['unitName'] as String;
    }
    // Fallback to unit structure (for real-time data)
    return unit?['name'] ?? 'N/A';
  }

  Widget _buildConsumptionCard(Map<String, dynamic> data) {
    final unit = data['unit'];
    final consumption = data['consumption'] as double;
    final amount = data['amount'] as double;
    final individualAmount = data['individualAmount'] as double? ?? 0.0;
    final commonAreasAmount = data['commonAreasAmount'] as double? ?? 0.0;
    final currentReading = data['currentReading'] as double;
    final previousReading = data['previousReading'] as double;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getBlockName(data, unit)} - ${_getUnitName(data, unit)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              data['residentName'] as String,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            // Consumption metrics row
            Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    child: _buildInfoColumn(
                      'Lectura Anterior',
                      '${previousReading.toStringAsFixed(3)} m³',
                      Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'Lectura Actual',
                    '${currentReading.toStringAsFixed(3)} m³',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'Consumo',
                    '${consumption.toStringAsFixed(3)} m³',
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Amount breakdown row
            Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    child: _buildInfoColumn(
                      'Consumo Individual',
                      'S/ ${individualAmount.toStringAsFixed(2)}',
                      Colors.teal,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'Áreas Comunes',
                    'S/ ${commonAreasAmount.toStringAsFixed(2)}',
                    Colors.indigo,
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'Total a Pagar',
                    'S/ ${amount.toStringAsFixed(2)}',
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

  Widget _buildInfoColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _handleBackNavigation() {
    // If period is already closed, just navigate back without confirmation
    if (widget.period.status == 'CLOSED') {
      Navigator.of(context).pop();
      return;
    }
    
    // If period is not closed, show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir sin cerrar?'),
        content: const Text('Si sales ahora, el período no se cerrará y los cálculos no se guardarán.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final navigator = Navigator.of(context);
              navigator.pop(); // Close dialog
              navigator.pop(); // Go back to readings
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Salir sin Cerrar'),
          ),
        ],
      ),
    );
  }

  void _confirmClosePeriod() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Cierre'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de cerrar el período con estos cálculos?'),
            SizedBox(height: 12),
            Text(
              'Esta acción es irreversible.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _closePeriod,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar Período'),
          ),
        ],
      ),
    );
  }

  Future<void> _closePeriod() async {
    // Store context before async operations
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      // First update period with billing data
      await ref.read(periodsProvider(widget.condominium.id).notifier).updatePeriod(
        widget.period.id,
        {
          'totalVolume': widget.totalVolumeFromBill,
          'totalAmount': widget.totalAmountFromBill,
        },
      );
      
      // Calculate and prepare data for storage
      final costPerM3 = widget.totalVolumeFromBill > 0 ? widget.totalAmountFromBill / widget.totalVolumeFromBill : 0.0;
      final commonAreasConsumption = widget.totalVolumeFromBill - totalConsumption;

      // Prepare period-level calculation data
      final periodCalculation = {
        'costPerCubicMeter': costPerM3,
        'totalIndividualConsumption': totalConsumption,
        'totalCommonAreasConsumption': commonAreasConsumption,
        'totalIndividualAmount': _calculateTotalIndividualAmount(),
        'totalCommonAreasAmount': _calculateCommonAreasAmount(),
      };

      // Prepare unit-level calculations data
      final unitCalculations = consumptionData.map((data) {
        final unit = data['unit'];
        final meter = _getWaterMeter(unit);
        
        return {
          'unitId': unit['id'],
          'meterId': meter?['id'],
          'unitName': unit['name'],
          'blockName': unit['block']?['name'],
          'previousReading': data['previousReading'],
          'currentReading': data['currentReading'],
          'consumption': data['consumption'],
          'individualAmount': data['individualAmount'] ?? 0.0,
          'commonAreasAmount': data['commonAreasAmount'] ?? 0.0,
          'totalAmount': data['amount'] ?? 0.0,
          'residentName': data['residentName'],
        };
      }).toList();

      // Save calculations to database
      final apiService = ref.read(apiServiceProvider);
      await apiService.saveCalculations(widget.period.id, {
        'periodCalculation': periodCalculation,
        'unitCalculations': unitCalculations,
      });
      
      // Then close period using the periods provider
      await ref.read(periodsProvider(widget.condominium.id).notifier).closePeriod(widget.period.id);
      
      if (mounted) {
        // Navigate back through all screens
        navigator.pop(); // Close confirmation dialog
        navigator.pop(); // Back to calculation screen
        navigator.pop(); // Back to readings screen  
        navigator.pop(); // Back to periods list
        
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Período cerrado exitosamente con cálculos guardados'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        navigator.pop(); // Close confirmation dialog
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error al cerrar período: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar datos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error!,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDataAndCalculate,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// Wrapper class to make _PeriodResultsScreen accessible from other files
class PeriodResultsWrapper extends ConsumerWidget {
  final Period period;
  final Condominium condominium;

  const PeriodResultsWrapper({
    super.key,
    required this.period,
    required this.condominium,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For closed periods, we need to get the billing data from the period
    // If period has billing data, use it; otherwise show error
    if (period.totalVolume != null && period.totalAmount != null) {
      return _PeriodResultsScreen(
        period: period,
        condominium: condominium,
        totalVolumeFromBill: period.totalVolume!,
        totalAmountFromBill: period.totalAmount!,
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Resultados - Distribución'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.orange,
                ),
                SizedBox(height: 16),
                Text(
                  'Sin datos de facturación',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Este período no tiene datos de facturación guardados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}