import 'package:animated_button/animated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _validateForm());
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
    final int? sistole = int.tryParse(_sistoleController.text.trim());
    final int? diastole = int.tryParse(_diastoleController.text.trim());
    final int? ritmo = int.tryParse(_ritmoCardiacoController.text.trim());

    final bool isValid =
        sistole != null &&
        diastole != null &&
        ritmo != null &&
        sistole >= 60 &&
        sistole <= 260 &&
        diastole >= 40 &&
        diastole <= 180 &&
        ritmo >= 30 &&
        ritmo <= 220;

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
        if (!_isFormValid && _buttonState == ButtonState.idle) {
          _buttonState = ButtonState.fail;
        } else if (_isFormValid && _buttonState == ButtonState.fail) {
          _buttonState = ButtonState.idle;
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
    if (pickedDate == null || pickedDate == _selectedDateTime) {
      return;
    }

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

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (pickedTime == null) {
      return;
    }

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

  Future<void> _saveData() async {
    if (!_isFormValid) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Por favor, revisa los valores ingresados.')));
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

      if (!mounted) {
        return;
      }

      setState(() {
        _buttonState = ButtonState.success;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Datos guardados exitosamente')));

      _sistoleController.clear();
      _diastoleController.clear();
      _ritmoCardiacoController.clear();
      setState(() {
        _selectedDateTime = DateTime.now();
      });
      _validateForm();

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _buttonState = ButtonState.idle;
          });
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _buttonState = ButtonState.fail;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar datos: ${e.toString()}')));

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _buttonState = ButtonState.idle;
          });
        }
      });
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required String helper,
    required String text,
    required int min,
    required int max,
    required IconData icon,
  }) {
    final int? value = int.tryParse(text.trim());
    final bool hasError = text.trim().isNotEmpty && (value == null || value < min || value > max);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
      errorText: hasError ? 'Valor fuera de rango ($min-$max)' : null,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.6),
      ),
    );
  }

  Widget _buildDateTimeCard({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    required String buttonText,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedButton(
              onPressed: onPressed,
              width: double.infinity,
              height: 38,
              color: color,
              child: Text(
                buttonText,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<ButtonState, Widget> stateWidgets = {
      ButtonState.idle: const Text(
        'Guardar lectura',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      ButtonState.loading: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ),
      ButtonState.success: const Text(
        '¡Guardado!',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      ButtonState.fail: const Text(
        'Completa el formulario',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    };

    final Map<ButtonState, Color> stateColors = {
      ButtonState.idle: const Color(0xFF4F46E5),
      ButtonState.loading: Colors.blue.shade400,
      ButtonState.success: Colors.green.shade500,
      ButtonState.fail: Colors.grey.shade600,
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Ingresar Datos de Tensión'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  _buildDateTimeCard(
                    title: 'Fecha',
                    value: DateFormat('dd/MM/yyyy').format(_selectedDateTime),
                    icon: Icons.calendar_today_rounded,
                    color: const Color(0xFF0EA5E9),
                    buttonText: 'Cambiar fecha',
                    onPressed: () => _selectDate(context),
                  ),
                  const SizedBox(width: 10),
                  _buildDateTimeCard(
                    title: 'Hora',
                    value: DateFormat('HH:mm').format(_selectedDateTime),
                    icon: Icons.schedule_rounded,
                    color: const Color(0xFF22C55E),
                    buttonText: 'Cambiar hora',
                    onPressed: () => _selectTime(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Valores de la medición',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _sistoleController,
              decoration: _fieldDecoration(
                label: 'Sístole',
                hint: 'Ej: 120',
                helper: 'Rango recomendado: 60 - 260',
                text: _sistoleController.text,
                min: 60,
                max: 260,
                icon: Icons.monitor_heart,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _diastoleController,
              decoration: _fieldDecoration(
                label: 'Diástole',
                hint: 'Ej: 80',
                helper: 'Rango recomendado: 40 - 180',
                text: _diastoleController.text,
                min: 40,
                max: 180,
                icon: Icons.favorite_border,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _ritmoCardiacoController,
              decoration: _fieldDecoration(
                label: 'Ritmo Cardíaco',
                hint: 'Ej: 72',
                helper: 'Rango recomendado: 30 - 220',
                text: _ritmoCardiacoController.text,
                min: 30,
                max: 220,
                icon: Icons.favorite,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ProgressButton(
                stateWidgets: stateWidgets,
                stateColors: stateColors,
                onPressed: _isFormValid && _buttonState == ButtonState.idle ? _saveData : null,
                state: _buttonState,
                minWidth: 240,
                maxWidth: 320,
                height: 52,
                radius: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
