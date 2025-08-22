import 'package:flutter/material.dart';
import '../models/tension_data.dart';
import '../services/database_service.dart';

class VerDatosPage extends StatefulWidget {
  const VerDatosPage({super.key});

  @override
  State<VerDatosPage> createState() => _VerDatosPageState();
}

class _VerDatosPageState extends State<VerDatosPage> {
  final DatabaseService _databaseService = DatabaseService();
  late Future<List<TensionData>> _tensionDataList;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _tensionDataList = _databaseService.getTensionData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ver Datos'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      body: FutureBuilder<List<TensionData>>(
        future: _tensionDataList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay datos registrados.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final data = snapshot.data![index];
                return ListTile(
                  title: Text(
                    'Sístole: ${data.sistole}, Diástole: ${data.diastole}',
                  ),
                  subtitle: Text(
                    'Ritmo Cardíaco: ${data.ritmoCardiaco} | Fecha: ${data.fechaHora.toString().substring(0, 16)}',
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
