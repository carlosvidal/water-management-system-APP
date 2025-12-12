import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:water_readings_app/core/providers/condominium_provider.dart';
import 'package:water_readings_app/features/periods/periods_list_screen.dart';
import 'package:water_readings_app/shared/widgets/main_layout.dart';

class ReadingsOverviewScreen extends ConsumerStatefulWidget {
  const ReadingsOverviewScreen({super.key});

  @override
  ConsumerState<ReadingsOverviewScreen> createState() => _ReadingsOverviewScreenState();
}

class _ReadingsOverviewScreenState extends ConsumerState<ReadingsOverviewScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Reset navigation flag when screen is initialized
    _hasNavigated = false;
  }

  @override
  Widget build(BuildContext context) {
    final condominiumsAsync = ref.watch(condominiumProvider);

    return MainLayout(
      currentIndex: 2,
      child: RefreshIndicator(
        onRefresh: () => ref.read(condominiumProvider.notifier).refreshCondominiums(),
        child: condominiumsAsync.when(
          data: (condominiums) => _buildReadingsContent(context, condominiums),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorView(context, ref, error),
        ),
      ),
    );
  }

  Widget _buildReadingsContent(BuildContext context, List condominiums) {
    if (condominiums.isEmpty) {
      return _buildEmptyState(context);
    }

    // If user has only one condominium, navigate directly to it
    if (condominiums.length == 1) {
      final condominium = condominiums.first;
      final totalUnits = _getTotalUnits(condominium);

      // Check if condominium is ready (has units)
      if (totalUnits == 0) {
        return _buildCondominiumNotReadyState(context, condominium);
      }

      // Navigate directly to the single condominium's periods (only once)
      if (!_hasNavigated) {
        _hasNavigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToCondominiumPeriods(context, condominium);
        });

        // Show loading while navigating
        return const Center(child: CircularProgressIndicator());
      }

      // If we've already navigated, show the selection screen
      // This prevents infinite navigation loop when user presses back
      return _buildSingleCondominiumView(context, condominium);
    }

    // Show list if user has multiple condominiums
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Gestión de Lecturas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona un condominio para gestionar sus lecturas',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 24),

          // Condominiums List for Readings
          ...condominiums.map((condominium) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  condominium.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                condominium.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(condominium.address),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.domain, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${condominium.blocks?.length ?? 0} bloques',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.home, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${_getTotalUnits(condominium)} unidades',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.analytics, color: Colors.blue),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              onTap: () => _navigateToCondominiumPeriods(context, condominium),
              isThreeLine: true,
            ),
          )),

          const SizedBox(height: 24),

          // Quick Stats
          _buildQuickStats(context, condominiums),
        ],
      ),
    );
  }

  int _getTotalUnits(dynamic condominium) {
    if (condominium.blocks == null) return 0;
    int total = 0;
    for (var block in condominium.blocks) {
      total += (block.units?.length ?? 0) as int;
    }
    return total;
  }

  int _getTotalBlocks(List condominiums) {
    return condominiums.fold<int>(0, (sum, condo) => sum + (condo.blocks?.length as int? ?? 0));
  }

  Widget _buildQuickStats(BuildContext context, List condominiums) {
    final totalUnits = condominiums.fold<int>(0, (sum, condo) => sum + _getTotalUnits(condo));
    
    return Card(
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
                  'Resumen de Lecturas',
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
                    'Total Unidades',
                    totalUnits.toString(),
                    Icons.home,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Condominios',
                    condominiums.length.toString(),
                    Icons.apartment,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Bloques',
                    _getTotalBlocks(condominiums).toString(),
                    Icons.domain,
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

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _navigateToCondominiumPeriods(BuildContext context, dynamic condominium) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PeriodsListScreen(
          condominiumId: condominium.id,
          condominium: condominium,
        ),
      ),
    );
  }

  Widget _buildSingleCondominiumView(BuildContext context, dynamic condominium) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Gestión de Lecturas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tu condominio',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 24),

          // Single Condominium Card
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  condominium.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                condominium.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(condominium.address),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.domain, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${condominium.blocks?.length ?? 0} bloques',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.home, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${_getTotalUnits(condominium)} unidades',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.analytics, color: Colors.blue),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              onTap: () => _navigateToCondominiumPeriods(context, condominium),
              isThreeLine: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.analytics,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay condominios',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crea un condominio primero para gestionar lecturas',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/condominiums'),
            icon: const Icon(Icons.add),
            label: const Text('Crear Condominio'),
          ),
        ],
      ),
    );
  }

  Widget _buildCondominiumNotReadyState(BuildContext context, dynamic condominium) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber,
              size: 64,
              color: Colors.orange[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Condominio no está listo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.orange[800],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.apartment, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          condominium.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    condominium.address,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Para poder gestionar lecturas, este condominio necesita:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Crear bloques'),
                  const Text('• Agregar unidades a los bloques'),
                  const Text('• Asignar residentes a las unidades'),
                  const Text('• Configurar medidores de agua'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/condominiums'),
              icon: const Icon(Icons.settings),
              label: const Text('Configurar Condominio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
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
            'Error al cargar datos',
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
            onPressed: () => ref.read(condominiumProvider.notifier).refreshCondominiums(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}