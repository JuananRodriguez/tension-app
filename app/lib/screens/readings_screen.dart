import 'package:flutter/material.dart';
import '../models/reading.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ReadingsScreen extends StatefulWidget {
  const ReadingsScreen({super.key});

  @override
  State<ReadingsScreen> createState() => _ReadingsScreenState();
}

class _ReadingsScreenState extends State<ReadingsScreen> {
  List<Reading> _readings = [];
  bool _loading = true;
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _pulseController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  Future<void> _loadReadings() async {
    try {
      final readings = await ApiService.getMyReadings();
      setState(() {
        _readings = readings;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _createReading() async {
    final systolic = int.tryParse(_systolicController.text);
    final diastolic = int.tryParse(_diastolicController.text);

    if (systolic == null || diastolic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sistólica y diastólica son obligatorias')),
      );
      return;
    }

    try {
      await ApiService.createReading(Reading(
        userId: 0,
        systolic: systolic,
        diastolic: diastolic,
        pulse: int.tryParse(_pulseController.text),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      ));

      _systolicController.clear();
      _diastolicController.clear();
      _pulseController.clear();
      _notesController.clear();
      Navigator.pop(context);
      _loadReadings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showAddReadingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Lectura'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _systolicController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sistólica *'),
              ),
              TextField(
                controller: _diastolicController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Diastólica *'),
              ),
              TextField(
                controller: _pulseController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Pulso'),
              ),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notas'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: _createReading,
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReading(Reading reading) async {
    if (reading.id == null) return;
    try {
      await ApiService.deleteReading(reading.id!);
      _loadReadings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lectura eliminada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  void _confirmDeleteReading(Reading reading) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar lectura'),
        content: const Text('¿Eliminar esta lectura?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteReading(reading);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getPressureColor(int systolic, int diastolic) {
    if (systolic < 120 && diastolic < 80) return Colors.green;
    if (systolic < 130 && diastolic < 80) return Colors.yellow.shade700;
    if (systolic < 140 || diastolic < 90) return Colors.orange;
    return Colors.red;
  }

  String _getPressureCategory(int systolic, int diastolic) {
    if (systolic < 120 && diastolic < 80) return 'Normal';
    if (systolic < 130 && diastolic < 80) return 'Elevada';
    if (systolic < 140 || diastolic < 90) return 'Hipertensión Etapa 1';
    return 'Hipertensión Etapa 2';
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Lecturas${user != null ? ' - ${user.name}' : ''}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _readings.isEmpty
              ? const Center(child: Text('No hay lecturas'))
              : ListView.builder(
                  itemCount: _readings.length,
                  itemBuilder: (context, index) {
                    final r = _readings[index];
                    final color = _getPressureColor(r.systolic, r.diastolic);
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color,
                          child: Text(
                            '${r.systolic}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        title: Text('${r.systolic}/${r.diastolic} mmHg'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_getPressureCategory(r.systolic, r.diastolic)),
                            if (r.pulse != null) Text('Pulso: ${r.pulse} bpm'),
                            if (r.notes != null) Text('Notas: ${r.notes}'),
                            Text('${r.createdAt}'),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteReading(r),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReadingDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
