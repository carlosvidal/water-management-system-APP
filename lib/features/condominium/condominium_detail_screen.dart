import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:water_readings_app/core/providers/condominium_detail_provider.dart';
import 'package:water_readings_app/core/models/condominium.dart' as models;
import 'package:water_readings_app/features/condominium/unit_detail_screen.dart';

class CondominiumDetailScreen extends ConsumerWidget {
  final String condominiumId;

  const CondominiumDetailScreen({
    super.key,
    required this.condominiumId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final condominiumAsync = ref.watch(condominiumDetailProvider(condominiumId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Condominio'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _navigateBack(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(condominiumDetailProvider(condominiumId).notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(condominiumDetailProvider(condominiumId).notifier).refresh(),
        child: condominiumAsync.when(
          data: (condominium) => condominium != null 
              ? _buildCondominiumDetail(context, ref, condominium)
              : _buildEmptyState(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorView(context, ref, error),
        ),
      ),
      floatingActionButton: condominiumAsync.whenOrNull(
        data: (condominium) {
          if (condominium == null) return null;
          
          // Check if capacity limit is reached
          if (condominium.totalUnitsPlanned != null && condominium.blocks != null) {
            final totalCapacity = condominium.blocks!.fold<int>(
              0, 
              (sum, block) => sum + (block.maxUnits ?? 0),
            );
            if (totalCapacity >= condominium.totalUnitsPlanned!) {
              return null; // Hide FAB if capacity is reached
            }
          }
          
          return FloatingActionButton(
            onPressed: () => _showCreateBlockDialog(context, ref),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildCondominiumDetail(BuildContext context, WidgetRef ref, models.Condominium condominium) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del condominio
          Card(
            child: Padding(
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
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.location_on, 'Dirección', condominium.address),
                  if (condominium.city != null)
                    _buildInfoRow(Icons.location_city, 'Ciudad', condominium.city!),
                  if (condominium.readingDay != null)
                    _buildInfoRow(Icons.calendar_today, 'Día de lectura', 'Día ${condominium.readingDay} de cada mes'),
                  _buildSummaryInfo(condominium),
                  _buildStatusBadge(condominium),
                  _buildInfoRow(Icons.check_circle, 'Estado', condominium.isActive ? 'Activo' : 'Inactivo'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Bloques y Unidades
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bloques y Unidades',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Only show add block button if capacity allows
              _shouldShowAddButton(condominium) 
                ? TextButton.icon(
                    onPressed: () => _showCreateBlockDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Bloque'),
                  )
                : const SizedBox.shrink(),
            ],
          ),
          
          const SizedBox(height: 12),
          
          if (condominium.blocks == null || condominium.blocks!.isEmpty)
            _buildEmptyBlocksState(context, ref)
          else
            ..._buildBlocksList(context, ref, condominium.blocks!),
        ],
      ),
    );
  }

  bool _shouldShowAddButton(models.Condominium condominium) {
    if (condominium.totalUnitsPlanned == null || condominium.blocks == null) {
      return true; // Show if no limit is set
    }
    
    final totalCapacity = condominium.blocks!.fold<int>(
      0, 
      (sum, block) => sum + (block.maxUnits ?? 0),
    );
    
    return totalCapacity < condominium.totalUnitsPlanned!;
  }

  bool _shouldShowAddUnitButton(models.Block block) {
    if (block.maxUnits == null) {
      return true; // Show if no limit is set for the block
    }
    
    final currentUnits = block.units?.length ?? 0;
    return currentUnits < block.maxUnits!;
  }

  String _buildBlockSubtitle(models.Block block) {
    final currentUnits = block.units?.length ?? 0;
    if (block.maxUnits == null) {
      return '$currentUnits unidades';
    }
    
    if (currentUnits >= block.maxUnits!) {
      return '$currentUnits de ${block.maxUnits} unidades (Completo)';
    } else {
      return '$currentUnits de ${block.maxUnits} unidades';
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryInfo(models.Condominium condominium) {
    final totalBlocks = condominium.blocks?.length ?? 0;
    final totalUnits = condominium.blocks?.fold<int>(
      0, 
      (sum, block) => sum + (block.units?.length ?? 0),
    ) ?? 0;

    return _buildInfoRow(
      Icons.dashboard, 
      'Resumen', 
      'Bloques: $totalBlocks, Unidades: $totalUnits'
    );
  }

  Widget _buildStatusBadge(models.Condominium condominium) {
    final totalUnits = condominium.blocks?.fold<int>(
      0, 
      (sum, block) => sum + (block.units?.length ?? 0),
    ) ?? 0;
    
    final plannedUnits = condominium.totalUnitsPlanned ?? 0;
    
    String statusText;
    Color statusColor;
    
    if (totalUnits == 0) {
      statusText = 'Nuevo';
      statusColor = Colors.red;
    } else if (plannedUnits > 0 && totalUnits >= plannedUnits) {
      statusText = 'Listo';
      statusColor = Colors.green;
    } else {
      statusText = 'En Progreso';
      statusColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.flag, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          const Text(
            'Estado del proyecto: ',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBlocksState(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.domain,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'No hay bloques',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Agrega el primer bloque para comenzar a gestionar las unidades',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showCreateBlockDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Crear Bloque'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBlocksList(BuildContext context, WidgetRef ref, List<models.Block> blocks) {
    // Sort blocks alphabetically
    final sortedBlocks = List<models.Block>.from(blocks)
      ..sort((a, b) => a.name.compareTo(b.name));
    
    // Auto-expand if there's only one block
    final shouldAutoExpand = blocks.length == 1;
      
    return sortedBlocks.map<Widget>((models.Block block) => Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: shouldAutoExpand,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            block.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          block.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _buildBlockSubtitle(block),
        ),
        trailing: _shouldShowAddUnitButton(block) 
          ? IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCreateUnitDialog(context, ref, block),
            )
          : null,
        children: [
          if (block.units == null || block.units!.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No hay unidades en este bloque',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...(block.units!..sort((a, b) => a.name.compareTo(b.name))).map((unit) => ListTile(
              leading: const Icon(Icons.home),
              title: Text(unit.name),
              subtitle: _buildUnitSubtitle(unit),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    (unit.isActive ?? true) ? Icons.check_circle : Icons.cancel,
                    color: (unit.isActive ?? true) ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              onTap: () => _navigateToUnitDetail(context, ref, unit),
            )),
        ],
      ),
    )).toList();
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.apartment,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Condominio no encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
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
            'Error al cargar condominio',
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
            onPressed: () => ref.read(condominiumDetailProvider(condominiumId).notifier).refresh(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  void _showCreateBlockDialog(BuildContext context, WidgetRef ref) {
    final condominium = ref.read(condominiumDetailDataProvider(condominiumId));
    final nameController = TextEditingController();
    final maxUnitsController = TextEditingController();

    // Calculate current capacity and remaining
    int currentCapacity = 0;
    int? totalPlanned = condominium?.totalUnitsPlanned;
    
    if (condominium?.blocks != null) {
      currentCapacity = condominium!.blocks!.fold<int>(
        0, 
        (sum, block) => sum + (block.maxUnits ?? 0),
      );
    }
    
    final remaining = totalPlanned != null ? totalPlanned - currentCapacity : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Bloque'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del bloque',
                border: OutlineInputBorder(),
                hintText: 'Ej: Bloque A, Torre 1',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: maxUnitsController,
              decoration: InputDecoration(
                labelText: 'Número de unidades en este bloque',
                border: const OutlineInputBorder(),
                hintText: remaining != null ? 'Máximo: $remaining' : 'Ej: 8',
              ),
              keyboardType: TextInputType.number,
            ),
            if (totalPlanned != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Capacidad del condominio',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Total planificado: $totalPlanned unidades'),
                    Text('Asignado actualmente: $currentCapacity unidades'),
                    if (remaining != null && remaining > 0)
                      Text(
                        'Disponible: $remaining unidades',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else if (remaining != null && remaining <= 0)
                      const Text(
                        'Capacidad completa',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El nombre del bloque es requerido')),
                );
                return;
              }

              final maxUnits = int.tryParse(maxUnitsController.text) ?? 0;

              if (maxUnits <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El número de unidades debe ser mayor a 0')),
                );
                return;
              }

              // Validate against remaining capacity if totalPlanned is set
              if (remaining != null && maxUnits > remaining) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Este bloque excedería la capacidad disponible ($remaining unidades restantes)')),
                );
                return;
              }

              try {
                await ref.read(condominiumDetailProvider(condominiumId).notifier)
                    .createBlock(nameController.text.trim(), maxUnits);

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bloque creado exitosamente')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al crear bloque: $e')),
                  );
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showCreateUnitDialog(BuildContext context, WidgetRef ref, models.Block block) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nueva Unidad en ${block.name}'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre de la unidad',
            border: OutlineInputBorder(),
            hintText: 'Ej: 101, Apto A, Depto 1',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El nombre de la unidad es requerido')),
                );
                return;
              }

              try {
                await ref.read(condominiumDetailProvider(condominiumId).notifier)
                    .createUnit(block.id, nameController.text.trim());

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unidad creada exitosamente')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al crear unidad: $e')),
                  );
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitSubtitle(models.Unit unit) {
    // Only check for the main resident (one per unit)
    if (unit.residentId != null && unit.resident != null) {
      return Text('Residente: ${unit.resident!.name}');
    } else {
      return const Text('Sin residente asignado');
    }
  }

  void _navigateToUnitDetail(BuildContext context, WidgetRef ref, models.Unit unit) {
    final condominium = ref.read(condominiumDetailDataProvider(condominiumId));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UnitDetailScreen(
          unit: unit,
          condominiumId: condominiumId,
          condominium: condominium,
        ),
      ),
    );
  }

  void _navigateBack(BuildContext context) {
    // Try to pop first, if it can't pop (no previous route), navigate to dashboard
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // Using GoRouter to navigate to dashboard
      context.go('/dashboard');
    }
  }
}