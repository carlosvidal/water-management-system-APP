import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:water_readings_app/core/providers/auth_provider.dart';
import 'package:water_readings_app/core/services/api_service.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  final int currentIndex;
  final Widget? floatingActionButton;
  final String? title;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    this.floatingActionButton,
    this.title,
  });

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  void _onDestinationSelected(int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/condominiums');
        break;
      case 2:
        context.go('/readings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'AquaFlow'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(context, ref, user),
      body: widget.child,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: widget.currentIndex >= 0
          ? NavigationBar(
              selectedIndex: widget.currentIndex,
              onDestinationSelected: _onDestinationSelected,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.apartment),
                  selectedIcon: Icon(Icons.apartment),
                  label: 'Condominios',
                ),
                NavigationDestination(
                  icon: Icon(Icons.analytics),
                  selectedIcon: Icon(Icons.analytics),
                  label: 'Lecturas',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref, dynamic user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.name ?? 'Usuario'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(
                  fontSize: 24,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              context.go('/dashboard');
            },
          ),
          ListTile(
            leading: const Icon(Icons.apartment),
            title: const Text('Condominios'),
            onTap: () {
              Navigator.pop(context);
              context.go('/condominiums');
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Lecturas'),
            onTap: () {
              Navigator.pop(context);
              context.go('/readings');
            },
          ),
          const Divider(),
          if (ref.read(authProvider.notifier).isSuperAdmin || ref.read(authProvider.notifier).isAdmin) ...[
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Configuración - Próximamente')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Usuarios'),
              onTap: () {
                Navigator.pop(context);
                _showCondominiumSelectorForUsers(context, ref);
              },
            ),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Ayuda'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to help
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ayuda - Próximamente')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Acerca de'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context, ref);
            },
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'AquaFlow',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.water_drop, size: 48, color: Colors.blue),
      children: [
        const Text('Sistema de gestión de lecturas de agua para condominios.'),
        const SizedBox(height: 16),
        const Text('Desarrollado con Flutter y tecnologías modernas.'),
      ],
    );
  }

  void _showCondominiumSelectorForUsers(BuildContext context, WidgetRef ref) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final condominiums = await apiService.getCondominiums();

      if (!context.mounted) return;

      if (condominiums.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay condominios disponibles'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // If only one condominium, navigate directly
      if (condominiums.length == 1) {
        context.go('/condominium/${condominiums[0]['id']}/users');
        return;
      }

      // Show dialog to select condominium
      final selectedCondominium = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Seleccionar Condominio'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: condominiums.length,
              itemBuilder: (context, index) {
                final condo = condominiums[index];
                return ListTile(
                  leading: const Icon(Icons.apartment),
                  title: Text(condo['name'] ?? 'Sin nombre'),
                  subtitle: Text(condo['address'] ?? ''),
                  onTap: () => Navigator.pop(context, condo),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      );

      if (selectedCondominium != null && context.mounted) {
        context.go('/condominium/${selectedCondominium['id']}/users');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar condominios: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}