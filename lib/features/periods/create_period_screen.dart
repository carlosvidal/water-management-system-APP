import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_readings_app/core/providers/periods_provider.dart';
import 'package:water_readings_app/core/models/condominium.dart';
import 'package:water_readings_app/features/readings/period_readings_screen.dart';

class CreatePeriodScreen extends ConsumerStatefulWidget {
  final String condominiumId;
  final Condominium condominium;

  const CreatePeriodScreen({
    super.key,
    required this.condominiumId,
    required this.condominium,
  });

  @override
  ConsumerState<CreatePeriodScreen> createState() => _CreatePeriodScreenState();
}

class _CreatePeriodScreenState extends ConsumerState<CreatePeriodScreen> {
  DateTime _selectedReadingDate = DateTime.now();
  bool _isCreating = false;

  Future<bool> _checkIfFirstPeriod() async {
    try {
      final periodsAsync = ref.read(periodsProvider(widget.condominiumId));
      return periodsAsync.when(
        data: (periods) => periods.isEmpty,
        loading: () => false,
        error: (_, __) => false,
      );
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasOpenPeriod = ref.watch(hasOpenPeriodProvider(widget.condominiumId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Período de Lectura'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Consolidated info card
            FutureBuilder<bool>(
              future: _checkIfFirstPeriod(),
              builder: (context, snapshot) {
                final isFirstPeriod = snapshot.hasData && snapshot.data == true;
                
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Condominium header
                        Row(
                          children: [
                            Icon(Icons.apartment, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.condominium.name,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.condominium.address,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        
                        // Status and info section
                        if (hasOpenPeriod) ...[
                          Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Período Activo Detectado',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ya existe un período abierto. Se recomienda cerrar el período actual antes de crear uno nuevo.',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 12),
                        ] else if (isFirstPeriod) ...[
                          Row(
                            children: [
                              Icon(Icons.lightbulb, color: Colors.blue[700], size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Primer Período de Lectura',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Este será tu primer período. Se recomienda usar lecturas del mes anterior como referencia y marcar fechas pasadas.',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 12),
                        ],
                        
                        // Period info
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Información del Período',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Se creará en estado "ABIERTO" para registrar lecturas\n'
                          '• Abarca desde la última lectura hasta la fecha seleccionada\n'
                          '• Puedes cerrarlo manualmente al terminar las lecturas',
                          style: TextStyle(color: Colors.grey[700], height: 1.4),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Form title
            Text(
              'Nuevo Período de Lectura',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Reading date (simplified)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Fecha de Lectura',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatDate(_selectedReadingDate),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _selectReadingDate,
                        icon: const Icon(Icons.edit_calendar),
                        label: const Text('Cambiar Fecha'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Create button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createPeriod,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isCreating
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Creando Período...'),
                        ],
                      )
                    : const Text(
                        'Crear Período de Lectura',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    return '${date.day} de ${months[date.month - 1]} ${date.year}';
  }

  void _selectReadingDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1);
    final lastDate = DateTime(now.year + 1);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedReadingDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (selectedDate != null && mounted) {
      setState(() {
        _selectedReadingDate = selectedDate;
      });
    }
  }

  Future<void> _createPeriod() async {
    setState(() => _isCreating = true);

    try {
      final periodsNotifier = ref.read(periodsProvider(widget.condominiumId).notifier);
      
      // Create period and get the created period object
      final createdPeriod = await periodsNotifier.createPeriod(
        startDate: _selectedReadingDate,
      );

      if (mounted) {
        // Navigate directly to the readings screen for the new period
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PeriodReadingsScreen(
              period: createdPeriod,
              condominium: widget.condominium,
            ),
          ),
        );
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Período creado. ¡Comienza a registrar lecturas!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear período: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}