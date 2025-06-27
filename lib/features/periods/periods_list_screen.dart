import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_readings_app/core/providers/periods_provider.dart';
import 'package:water_readings_app/core/models/condominium.dart';
import 'package:water_readings_app/features/readings/period_readings_screen.dart';
import 'package:water_readings_app/features/periods/create_period_screen.dart';

class PeriodsListScreen extends ConsumerWidget {
  final String condominiumId;
  final Condominium condominium;

  const PeriodsListScreen({
    super.key,
    required this.condominiumId,
    required this.condominium,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodsAsync = ref.watch(periodsProvider(condominiumId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Períodos de Lectura'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(periodsProvider(condominiumId).notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Condominium info
          Container(
            width: double.infinity,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.apartment, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        condominium.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  condominium.address,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          
          // Periods list
          Expanded(
            child: periodsAsync.when(
              data: (periods) => periods.isEmpty
                  ? _buildEmptyState(context)
                  : _buildPeriodsList(context, ref, periods),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorView(context, ref, error),
            ),
          ),
        ],
      ),
      floatingActionButton: periodsAsync.when(
        data: (periods) => _shouldShowCreateButton(periods) 
            ? FloatingActionButton.extended(
                onPressed: () => _navigateToCreatePeriod(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Período'),
                backgroundColor: Theme.of(context).primaryColor,
              )
            : null,
        loading: () => null,
        error: (error, stack) => null,
      ),
    );
  }

  Widget _buildPeriodsList(BuildContext context, WidgetRef ref, List<Period> periods) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: periods.length,
      itemBuilder: (context, index) {
        final period = periods[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(period.status),
              child: Icon(
                _getStatusIcon(period.status),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              'Período ${_formatDate(period.startDate)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(period.status).withValues(alpha: 0.1),
                        border: Border.all(color: _getStatusColor(period.status).withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(period.status),
                        style: TextStyle(
                          color: _getStatusColor(period.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Creado: ${_formatDateTime(period.createdAt)}'),
                if (period.endDate != null)
                  Text('Finalizado: ${_formatDate(period.endDate!)}'),
                const SizedBox(height: 4),
                Text(
                  _getPeriodActionText(period.status),
                  style: TextStyle(
                    color: _getPeriodActionColor(period.status),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getPeriodActionIcon(period.status),
                  color: _getPeriodActionColor(period.status),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
            onTap: () => _handlePeriodTap(context, ref, period),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
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
            'No hay períodos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No se han creado períodos de lectura para este condominio',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, Object error) {
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
            'Error al cargar períodos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(periodsProvider(condominiumId).notifier).refresh(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'OPEN':
        return Icons.play_arrow;
      case 'PENDING_RECEIPT':
        return Icons.receipt;
      case 'CALCULATING':
        return Icons.calculate;
      case 'CLOSED':
        return Icons.check;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'OPEN':
        return 'ABIERTO';
      case 'PENDING_RECEIPT':
        return 'ESPERANDO RECIBO';
      case 'CALCULATING':
        return 'CALCULANDO';
      case 'CLOSED':
        return 'CERRADO';
      default:
        return status;
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

  String _getPeriodActionText(String status) {
    switch (status) {
      case 'OPEN':
        return 'Toca para gestionar lecturas';
      case 'PENDING_RECEIPT':
        return 'Toca para gestionar lecturas';
      case 'CALCULATING':
        return 'Toca para gestionar lecturas';
      case 'CLOSED':
        return 'Toca para ver resultados';
      default:
        return 'Toca para ver detalles';
    }
  }

  Color _getPeriodActionColor(String status) {
    switch (status) {
      case 'OPEN':
        return Colors.blue;
      case 'PENDING_RECEIPT':
        return Colors.orange;
      case 'CALCULATING':
        return Colors.blue;
      case 'CLOSED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getPeriodActionIcon(String status) {
    switch (status) {
      case 'OPEN':
        return Icons.water_drop;
      case 'PENDING_RECEIPT':
        return Icons.water_drop;
      case 'CALCULATING':
        return Icons.water_drop;
      case 'CLOSED':
        return Icons.analytics;
      default:
        return Icons.visibility;
    }
  }

  void _handlePeriodTap(BuildContext context, WidgetRef ref, Period period) {
    if (period.status == 'CLOSED') {
      // Para períodos cerrados, ir directamente a resultados
      _navigateToResults(context, period);
    } else {
      // Para períodos abiertos, ir a gestión de lecturas
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PeriodReadingsScreen(
            period: period,
            condominium: condominium,
          ),
        ),
      );
    }
  }

  void _navigateToResults(BuildContext context, Period period) async {
    try {
      // Usar la clase _PeriodResultsScreen directamente desde period_readings_screen.dart
      // Para esto necesitamos crear una versión accesible
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PeriodResultsWrapper(
            period: period,
            condominium: condominium,
          ),
        ),
      );
    } catch (e) {
      // Si hay error accediendo a resultados, mostrar mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar resultados: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _shouldShowCreateButton(List<Period> periods) {
    // Show create button if there are no periods
    if (periods.isEmpty) return true;
    
    // Only show button if ALL periods are closed
    // Check that there are no periods with status other than 'CLOSED'
    final hasUnclosedPeriods = periods.any((period) => period.status != 'CLOSED');
    return !hasUnclosedPeriods;
  }

  void _navigateToCreatePeriod(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreatePeriodScreen(
          condominiumId: condominiumId,
          condominium: condominium,
        ),
      ),
    ).then((_) {
      // Refresh periods list after returning from create screen
      ref.read(periodsProvider(condominiumId).notifier).refresh();
    });
  }

}