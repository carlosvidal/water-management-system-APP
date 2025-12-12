import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_readings_app/core/models/condominium.dart';
import 'package:water_readings_app/core/providers/residents_provider.dart';
import 'package:water_readings_app/core/providers/condominium_detail_provider.dart';
import 'package:water_readings_app/core/services/api_service.dart';
import 'package:water_readings_app/features/readings/unit_readings_history_screen.dart';

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
  late Unit _currentUnit;

  @override
  void initState() {
    super.initState();
    _currentUnit = widget.unit;
  }

  String _getBlockName() {
    // First try to get it from the current unit
    if (_currentUnit.block?.name != null) {
      return _currentUnit.block!.name;
    }
    
    // If not available, try to find it in the condominium data passed as parameter
    if (widget.condominium?.blocks != null) {
      for (final block in widget.condominium!.blocks!) {
        if (block.id == _currentUnit.blockId) {
          return block.name;
        }
      }
    }
    
    // As a last resort, try to get it from the provider
    final condominium = ref.watch(condominiumDetailDataProvider(widget.condominiumId));
    if (condominium?.blocks != null) {
      for (final block in condominium!.blocks!) {
        if (block.id == _currentUnit.blockId) {
          return block.name;
        }
      }
    }
    
    // If we still don't have the block name, show the blockId as fallback
    return _currentUnit.blockId?.isNotEmpty == true ? _currentUnit.blockId! : 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Unidad ${_currentUnit.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.water_drop),
            tooltip: 'Ver historial de lecturas',
            onPressed: () => _navigateToReadings(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUnitInfo(),
            const SizedBox(height: 24),
            _buildResidentsSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddResidentDialog(),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildUnitInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.home, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Unidad ${_currentUnit.name}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.domain, 'Bloque', _getBlockName()),
            _buildInfoRow(
              Icons.check_circle,
              'Estado',
              (_currentUnit.isActive ?? true) ? 'Activa' : 'Inactiva',
            ),
          ],
        ),
      ),
    );
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

  Widget _buildResidentsSection() {
    // For multiple residents, we'll fetch the unit residents directly
    return FutureBuilder<List<dynamic>>(
      future: ref.read(apiServiceProvider).getUnitResidents(widget.condominiumId, _currentUnit.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final residents = snapshot.data ?? [];
        final maxResidents = 2; // Support up to 2 residents per unit
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Residentes (${residents.length}/$maxResidents)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (residents.length < maxResidents)
                  TextButton.icon(
                    onPressed: () => _showAddResidentDialog(),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Agregar'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (residents.isEmpty)
              _buildEmptyResidentsState()
            else
              ..._buildResidentsList(residents),
          ],
        );
      },
    );
  }

  Widget _buildEmptyResidentsState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.person_outline,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'No hay residentes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Esta unidad no tiene residentes asignados',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showAddResidentDialog(),
                icon: const Icon(Icons.person_add),
                label: const Text('Agregar Residente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildResidentsList(List<dynamic> residents) {
    return residents.map<Widget>((residentData) {
      final isPrimary = residentData['isPrimary'] == true;
      final residentInfo = residentData as Map<String, dynamic>;
      
      return Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isPrimary 
                ? Theme.of(context).primaryColor 
                : Colors.grey[600],
            child: Text(
              (residentInfo['name'] as String).substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  residentInfo['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Principal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (residentInfo['email'] != null && (residentInfo['email'] as String).isNotEmpty)
                Text(residentInfo['email'] as String),
              if (residentInfo['phone'] != null && (residentInfo['phone'] as String).isNotEmpty)
                Text('Tel: ${residentInfo['phone']}'),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showEditResidentDialog(residentInfo);
              } else if (value == 'remove') {
                _showRemoveResidentDialog(residentInfo);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Editar Info'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.person_remove, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Quitar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          isThreeLine: true,
        ),
      );
    }).toList();
  }

  void _showAddResidentDialog() {
    _showResidentDialog();
  }

  void _showEditResidentDialog(Map<String, dynamic> residentData) {
    _showResidentDialog(residentData: residentData, isEdit: true);
  }
  
  
  void _showRemoveResidentDialog(Map<String, dynamic> residentData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitar Residente'),
        content: Text('¿Estás seguro de que quieres quitar a ${residentData['name']} de esta unidad?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _removeResident(context, residentData['id'] as String),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
  }

  void _showResidentDialog({Map<String, dynamic>? residentData, bool isEdit = false}) {
    final nameController = TextEditingController(text: residentData?['name'] ?? '');
    final emailController = TextEditingController(text: residentData?['email'] ?? '');
    final phoneController = TextEditingController(text: residentData?['phone'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(residentData == null ? 'Agregar Residente' : (isEdit ? 'Editar Información' : 'Cambiar Residente')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo *',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Juan Pérez',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  hintText: 'ejemplo@correo.com (opcional)',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  border: const OutlineInputBorder(),
                  hintText: _getPhoneHint(),
                ),
                keyboardType: TextInputType.phone,
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
            onPressed: () => _saveResident(
              context,
              nameController.text,
              emailController.text,
              phoneController.text,
              residentData,
            ),
            child: Text(residentData == null ? 'Agregar' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  void _saveResident(
    BuildContext context,
    String name,
    String email,
    String phone,
    Map<String, dynamic>? existingResident,
  ) async {
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es requerido')),
      );
      return;
    }

    // Validar formato de email si se proporciona
    if (email.trim().isNotEmpty && !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un email válido')),
      );
      return;
    }

    final processedPhone = _processPhoneNumber(phone.trim());
    
    try {
      final residentsNotifier = ref.read(residentsProvider(widget.condominiumId).notifier);
      
      if (existingResident != null) {
        // Actualizar residente existente
        await residentsNotifier.updateResident(
          residentId: existingResident['id'] as String,
          name: name.trim(),
          email: email.trim().isNotEmpty ? email.trim() : null,
          phone: processedPhone,
        );
      } else {
        // Crear nuevo residente
        final newResident = await residentsNotifier.createResident(
          name: name.trim(),
          email: email.trim().isNotEmpty ? email.trim() : null,
          phone: processedPhone,
        );
        
        // Agregar el residente a la unidad usando el nuevo endpoint
        await ref.read(apiServiceProvider).addResidentToUnit(
          widget.condominiumId, 
          _currentUnit.id, 
          newResident.id,
          isPrimary: false, // First resident will be automatically set as primary
        );
      }
      
      // Actualizar ambos providers para asegurar sincronización
      await Future.wait([
        ref.read(condominiumDetailProvider(widget.condominiumId).notifier).refresh(),
        ref.read(residentsProvider(widget.condominiumId).notifier).refreshResidents(),
      ]);

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existingResident == null 
              ? 'Residente agregado exitosamente' 
              : 'Residente actualizado exitosamente'),
          ),
        );
        
        // Refresh the screen to show updated residents
        setState(() {});
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }




  void _removeResident(BuildContext context, String residentId) async {
    try {
      // Use the new multiple residents endpoint
      await ref.read(apiServiceProvider).removeResidentFromUnit(
        widget.condominiumId, 
        _currentUnit.id,
        residentId,
      );
      
      // Actualizar condominio
      await ref.read(condominiumDetailProvider(widget.condominiumId).notifier).refresh();
      
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Residente quitado exitosamente')),
        );
        
        // Refresh the screen to show updated residents
        setState(() {});
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al quitar residente: $e')),
        );
      }
    }
  }

  void _navigateToReadings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UnitReadingsHistoryScreen(
          unit: _currentUnit,
          condominiumId: widget.condominiumId,
          blockName: _getBlockName(),
        ),
      ),
    );
  }

  String _getPhoneHint() {
    final countryCode = _getCountryCode();
    return countryCode.isNotEmpty ? '$countryCode 1234567890' : 'Ej: 1234567890';
  }

  String _getCountryCode() {
    final country = widget.condominium?.country?.toLowerCase() ?? '';
    
    // Map common countries to their phone codes
    final countryCodes = {
      'colombia': '+57',
      'mexico': '+52',
      'argentina': '+54',
      'chile': '+56',
      'peru': '+51',
      'ecuador': '+593',
      'venezuela': '+58',
      'bolivia': '+591',
      'paraguay': '+595',
      'uruguay': '+598',
      'españa': '+34',
      'spain': '+34',
      'estados unidos': '+1',
      'united states': '+1',
      'usa': '+1',
    };
    
    // Try to get country code from condominium country
    return countryCodes[country] ?? '+57'; // Default to Colombia
  }

  String? _processPhoneNumber(String phone) {
    if (phone.isEmpty) return null;
    
    final countryCode = _getCountryCode();
    
    // If phone already has country code, return as is
    if (phone.startsWith('+')) {
      return phone;
    }
    
    // If phone starts with country code without +, add +
    if (phone.startsWith(countryCode.substring(1))) {
      return '+$phone';
    }
    
    // If phone doesn't have country code, add it
    return '$countryCode$phone';
  }
}