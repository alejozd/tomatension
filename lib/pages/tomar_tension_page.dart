import 'package:flutter/material.dart';
import '../models/tension_data.dart';
import '../services/database_service.dart';

class TomarTensionPage extends StatefulWidget {
  const TomarTensionPage({super.key});

  @override
  State<TomarTensionPage> createState() => _TomarTensionPageState();
}

class _TomarTensionPageState extends State<TomarTensionPage> {
  final _sistoleController = TextEditingController();
  final _diastoleController = TextEditingController();
  final _ritmoCardiacoController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();

  Future<void> _saveData() async {
    final newTensionData = TensionData(
      sistole: int.parse(_sistoleController.text),
      diastole: int.parse(_diastoleController.text),
      ritmoCardiaco: int.parse(_ritmoCardiacoController.text),
      fechaHora: DateTime.now(),
    );

    await _databaseService.insertTensionData(newTensionData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos guardados exitosamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingresar Datos de Tensión')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _sistoleController,
              decoration: const InputDecoration(labelText: 'Sístole'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _diastoleController,
              decoration: const InputDecoration(labelText: 'Diástole'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _ritmoCardiacoController,
              decoration: const InputDecoration(labelText: 'Ritmo Cardíaco'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveData, child: const Text('Guardar')),
          ],
        ),
      ),
    );
  }
}
