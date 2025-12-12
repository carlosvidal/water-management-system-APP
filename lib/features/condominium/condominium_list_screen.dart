import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:water_readings_app/core/providers/condominium_provider.dart';
import 'package:water_readings_app/core/models/condominium.dart';
import 'package:water_readings_app/shared/widgets/main_layout.dart';

class CondominiumListScreen extends ConsumerWidget {
  const CondominiumListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final condominiumsAsync = ref.watch(condominiumProvider);

    return MainLayout(
      currentIndex: 1,
      title: 'Condominios',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateCondominiumDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      child: RefreshIndicator(
        onRefresh: () => ref.read(condominiumProvider.notifier).refreshCondominiums(),
        child: condominiumsAsync.when(
          data: (condominiums) => _buildCondominiumsList(context, condominiums),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorView(context, ref, error),
        ),
      ),
    );
  }

  Widget _buildCondominiumsList(BuildContext context, List<Condominium> condominiums) {
    if (condominiums.isEmpty) {
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
              'No hay condominios',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Agrega tu primer condominio presionando el botón +',
              style: TextStyle(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: condominiums.length,
      itemBuilder: (context, index) {
        final condominium = condominiums[index];
        return Card(
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
                if (condominium.city != null)
                  Text(
                    condominium.city!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
            onTap: () => context.go('/condominium/${condominium.id}'),
            isThreeLine: condominium.city != null,
          ),
        );
      },
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
            'Error al cargar condominios',
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

  void _showCreateCondominiumDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final blocksController = TextEditingController(text: '1');
    final totalUnitsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Condominio'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del condominio',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'Ciudad (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: blocksController,
                decoration: const InputDecoration(
                  labelText: 'Número de bloques',
                  border: OutlineInputBorder(),
                  hintText: '1 para un solo edificio',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: totalUnitsController,
                decoration: const InputDecoration(
                  labelText: 'Total de unidades',
                  border: OutlineInputBorder(),
                  hintText: 'Número total de departamentos/casas',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              const Text(
                'Si solo hay 1 bloque, se creará automáticamente y podrás agregar las unidades directamente.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty || 
                  addressController.text.trim().isEmpty ||
                  totalUnitsController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nombre, dirección y total de unidades son requeridos')),
                );
                return;
              }

              final numberOfBlocks = int.tryParse(blocksController.text) ?? 1;
              final totalUnits = int.tryParse(totalUnitsController.text) ?? 0;

              if (totalUnits <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El número de unidades debe ser mayor a 0')),
                );
                return;
              }

              if (numberOfBlocks <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El número de bloques debe ser mayor a 0')),
                );
                return;
              }

              try {
                await ref.read(condominiumProvider.notifier).createCondominiumWithStructure({
                  'name': nameController.text.trim(),
                  'address': addressController.text.trim(),
                  'city': cityController.text.trim().isEmpty ? null : cityController.text.trim(),
                  'country': 'Perú',
                  'numberOfBlocks': numberOfBlocks,
                  'totalUnits': totalUnits,
                });

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(numberOfBlocks == 1 
                          ? 'Condominio creado con 1 bloque automático. Ahora puedes agregar $totalUnits unidades.'
                          : 'Condominio creado. Ahora puedes configurar $numberOfBlocks bloques con $totalUnits unidades en total.'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al crear condominio: $e')),
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
}