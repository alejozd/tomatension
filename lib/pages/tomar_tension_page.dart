import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:animated_button/animated_button.dart';
import 'package:progress_state_button/progress_button.dart';
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

  DateTime _selectedDateTime = DateTime.now();
  ButtonState _buttonState = ButtonState.idle;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _sistoleController.addListener(_validateForm);
    _diastoleController.addListener(_validateForm);
    _ritmoCardiacoController.addListener(_validateForm);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateForm();
    });
  }

  @override
  void dispose() {
    _sistoleController.removeListener(_validateForm);
    _diastoleController.removeListener(_validateForm);
    _ritmoCardiacoController.removeListener(_validateForm);
    _sistoleController.dispose();
    _diastoleController.dispose();
    _ritmoCardiacoController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final sistoleText = _sistoleController.text.trim();
    final diastoleText = _diastoleController.text.trim();
    final ritmoCardiacoText = _ritmoCardiacoController.text.trim();

    final isValid =
        sistoleText.isNotEmpty &&
        diastoleText.isNotEmpty &&
        ritmoCardiacoText.isNotEmpty;

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
        // Si el formulario deja de ser válido mientras el botón está en idle,
        // nos aseguramos de que el estado visual refleje "deshabilitado".
        if (!_isFormValid && _buttonState == ButtonState.idle) {
          _buttonState =
              ButtonState.fail; // Usamos fail para el look deshabilitado
        } else if (_isFormValid && _buttonState == ButtonState.fail) {
          _buttonState = ButtonState.idle; // Volvemos a idle si es válido
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDateTime) {
      setState(() {
        _selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  Future<void> _saveData() async {
    if (!_isFormValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, ingresa todos los datos.')),
        );
      }
      return;
    }

    setState(() {
      _buttonState = ButtonState.loading;
    });

    try {
      final newTensionData = TensionData(
        sistole: int.parse(_sistoleController.text.trim()),
        diastole: int.parse(_diastoleController.text.trim()),
        ritmoCardiaco: int.parse(_ritmoCardiacoController.text.trim()),
        fechaHora: _selectedDateTime,
      );

      await _databaseService.insertTensionData(newTensionData);

      if (mounted) {
        setState(() {
          _buttonState = ButtonState.success;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos guardados exitosamente')),
        );
        _sistoleController.clear();
        _diastoleController.clear();
        _ritmoCardiacoController.clear();
        setState(() {
          _selectedDateTime = DateTime.now();
          _validateForm(); // Re-validar el formulario después de limpiar los campos
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _buttonState = ButtonState.idle;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _buttonState = ButtonState.fail; // Para indicar fallo de operación
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar datos: ${e.toString()}')),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _buttonState =
                  ButtonState.idle; // Volver a idle después del error
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definimos los widgets para cada estado, incluyendo un estado para "Faltan Datos"
    final Map<ButtonState, Widget> stateWidgets = {
      ButtonState.idle: const Text(
        "Guardar",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      ButtonState.loading: const Text(
        "Cargando",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      ButtonState.success: const Text(
        "¡Guardado!",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      ButtonState.fail: const Text(
        // Este es el estado que usaremos para "deshabilitado" visualmente
        "Faltan Datos",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
    };

    // Definimos los colores para cada estado
    final Map<ButtonState, Color> stateColors = {
      ButtonState.idle: Colors.deepPurple,
      ButtonState.loading: Colors.blue.shade300,
      ButtonState.success: Colors.green.shade400,
      ButtonState.fail:
          Colors.grey.shade600, // Color gris para el estado deshabilitado/fallo
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Ingresar Datos de Tensión')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Seleccionar Fecha',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDateTime),
                  style: const TextStyle(fontSize: 16),
                ),
                AnimatedButton(
                  onPressed: () => _selectDate(context),
                  width: 120,
                  height: 40,
                  color: const Color.fromARGB(255, 87, 173, 216),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.calendar_today, color: Colors.white, size: 18),
                      SizedBox(width: 5),
                      Text(
                        'Fecha',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'Seleccionar Hora',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('hh:mm a').format(_selectedDateTime),
                  style: const TextStyle(fontSize: 16),
                ),
                AnimatedButton(
                  onPressed: () => _selectTime(context),
                  width: 120,
                  height: 40,
                  color: const Color.fromARGB(255, 66, 190, 104),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.access_time, color: Colors.white, size: 18),
                      SizedBox(width: 5),
                      Text(
                        'Hora',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            TextField(
              controller: _sistoleController,
              decoration: const InputDecoration(labelText: 'Sístole'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _diastoleController,
              decoration: const InputDecoration(labelText: 'Diástole'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _ritmoCardiacoController,
              decoration: const InputDecoration(labelText: 'Ritmo Cardíaco'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 30),

            Center(
              child: ProgressButton(
                stateWidgets: stateWidgets, // Usamos el mapa definido aquí
                stateColors: stateColors, // Usamos el mapa definido aquí
                // onPressed es null si el formulario no es válido, deshabilitando el botón
                onPressed: _isFormValid && _buttonState == ButtonState.idle
                    ? _saveData
                    : null,
                state:
                    _buttonState, // El estado del botón se controla directamente
                padding: const EdgeInsets.all(8.0),
                minWidth: 150,
                maxWidth: 200,
                height: 50,
                radius: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
