import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:progress_state_button/progress_button.dart'; // Importa ProgressButton y su ButtonState
import '../models/tension_data.dart';
import '../services/database_service.dart';

// Importa ButtonState de la librería
// Ya no necesitas definirlo aquí si estás usando el de progress_state_button
// enum ButtonState { idle, loading, success, fail }

class VerDatosPage extends StatefulWidget {
  const VerDatosPage({super.key});

  @override
  State<VerDatosPage> createState() => _VerDatosPageState();
}

class _VerDatosPageState extends State<VerDatosPage> {
  final DatabaseService _databaseService = DatabaseService();
  late Future<List<TensionData>> _tensionDataList;

  DateTime _startDate = DateTime.now().subtract(
    const Duration(days: 30),
  ); // Por defecto, últimos 30 días
  DateTime _endDate = DateTime.now();

  ButtonState _filterButtonState =
      ButtonState.idle; // Estado para el botón de filtro

  @override
  void initState() {
    super.initState();
    _filterData(); // Cargar datos iniciales con el rango predeterminado
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Si la fecha de inicio es posterior a la final, ajusta la final también.
        if (_startDate.isAfter(_endDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate:
          _startDate, // La fecha final no puede ser anterior a la fecha de inicio
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _filterData() async {
    if (_startDate.isAfter(_endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La fecha de inicio no puede ser posterior a la fecha fin.',
          ),
        ),
      );
      // Restablecer el estado del botón si hay un error de validación
      if (mounted) {
        setState(() {
          _filterButtonState = ButtonState.fail;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _filterButtonState = ButtonState.idle;
            });
          }
        });
      }
      return;
    }

    setState(() {
      _filterButtonState = ButtonState.loading;
    });

    try {
      _tensionDataList = _databaseService.getTensionDataByDateRange(
        _startDate,
        _endDate,
      );
      await _tensionDataList; // Esperar a que se resuelva el futuro para manejar éxito/fallo

      if (mounted) {
        setState(() {
          _filterButtonState = ButtonState.success;
        });
        // No es necesario un SnackBar aquí, la lista se actualizará
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _filterButtonState = ButtonState.fail;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al filtrar datos: ${e.toString()}')),
        );
      }
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _filterButtonState = ButtonState.idle;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ver Datos')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment
                  .start, // Alinea los textos de filtro a la izquierda
              children: [
                const Text(
                  'Filtrar por fecha',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment
                      .start, // Alinea al inicio si hay varias líneas
                  children: [
                    Expanded(
                      // Ocupa el espacio disponible para las fechas
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const SizedBox(
                                // Fija el ancho del label para alineación visual
                                width: 100,
                                child: Text(
                                  'Fecha inicio:',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _selectStartDate(context),
                                child: Text(
                                  DateFormat('dd/MM/yyyy').format(_startDate),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ), // Espacio entre fecha inicio y fin
                          Row(
                            children: [
                              const SizedBox(
                                // Fija el ancho del label para alineación visual
                                width: 100,
                                child: Text(
                                  'Fecha fin:',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _selectEndDate(context),
                                child: Text(
                                  DateFormat('dd/MM/yyyy').format(_endDate),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 15,
                    ), // Espacio entre fechas y botón OK
                    ProgressButton(
                      stateWidgets: {
                        ButtonState.idle: const Text(
                          "OK",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        ButtonState.loading: const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                        ButtonState.success: const Icon(
                          Icons.check,
                          color: Colors.white,
                        ),
                        ButtonState.fail: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      },
                      stateColors: {
                        ButtonState.idle: Colors.deepPurple,
                        ButtonState.loading: Colors.blue.shade300,
                        ButtonState.success: Colors.green.shade400,
                        ButtonState.fail: Colors.red.shade400,
                      },
                      onPressed: _filterData,
                      state: _filterButtonState,
                      minWidth: 80,
                      maxWidth: 100,
                      height:
                          50, // Altura ajustada para abarcar ambas filas de fecha
                      radius: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<TensionData>>(
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
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Fila 1: Fecha y hora (al inicio arriba)
                              Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  'Fecha y Hora: ${DateFormat('dd/MM/yyyy hh:mm a').format(data.fechaHora)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10), // Espacio entre filas
                              // Fila 2: Sístole y Diástole
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Sístole: ${data.sistole}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  Text(
                                    'Diástole: ${data.diastole}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10), // Espacio entre filas
                              // Fila 3: Ritmo Cardíaco (alineado a la izquierda)
                              Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  'Ritmo Cardíaco: ${data.ritmoCardiaco}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.purple,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
