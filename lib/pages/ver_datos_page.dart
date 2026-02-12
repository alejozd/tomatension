import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:progress_state_button/progress_button.dart';

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

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  ButtonState _filterButtonState = ButtonState.idle;

  @override
  void initState() {
    super.initState();
    _filterData();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked == null || picked == _startDate) {
      return;
    }

    setState(() {
      _startDate = picked;
      if (_startDate.isAfter(_endDate)) {
        _endDate = _startDate;
      }
    });
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );

    if (picked == null || picked == _endDate) {
      return;
    }

    setState(() {
      _endDate = picked;
    });
  }

  void _applyQuickRange(int days) {
    setState(() {
      _endDate = DateTime.now();
      _startDate = _endDate.subtract(Duration(days: days));
    });
    _filterData();
  }

  Future<void> _filterData() async {
    if (_startDate.isAfter(_endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha de inicio no puede ser posterior a la fecha fin.'),
        ),
      );

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
      _tensionDataList = _databaseService.getTensionDataByDateRange(_startDate, _endDate);
    });

    try {
      await _tensionDataList;
      if (mounted) {
        setState(() {
          _filterButtonState = ButtonState.success;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _filterButtonState = ButtonState.fail;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al filtrar datos: $e')));
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

  Widget _buildDateSelector({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDE3EC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.event, size: 16, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd/MM/yyyy').format(date),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingCard(TensionData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  DateFormat('dd/MM/yyyy · HH:mm').format(data.fechaHora),
                  style: const TextStyle(
                    color: Color(0xFF3730A3),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metricTile('Sístole', data.sistole.toString(), const Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              _metricTile('Diástole', data.diastole.toString(), const Color(0xFF22C55E)),
              const SizedBox(width: 8),
              _metricTile('Ritmo', data.ritmoCardiaco.toString(), const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Ver Datos'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildDateSelector(
                      label: 'Fecha inicio',
                      date: _startDate,
                      onTap: () => _selectStartDate(context),
                    ),
                    const SizedBox(width: 8),
                    _buildDateSelector(
                      label: 'Fecha fin',
                      date: _endDate,
                      onTap: () => _selectEndDate(context),
                    ),
                    const SizedBox(width: 8),
                    ProgressButton(
                      stateWidgets: {
                        ButtonState.idle: const Text(
                          'OK',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        ButtonState.loading: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        ButtonState.success: const Icon(Icons.check, color: Colors.white),
                        ButtonState.fail: const Icon(Icons.close, color: Colors.white),
                      },
                      stateColors: {
                        ButtonState.idle: const Color(0xFF4F46E5),
                        ButtonState.loading: Colors.blue.shade400,
                        ButtonState.success: Colors.green.shade500,
                        ButtonState.fail: Colors.red.shade400,
                      },
                      onPressed: _filterData,
                      state: _filterButtonState,
                      minWidth: 62,
                      maxWidth: 62,
                      height: 52,
                      radius: 14,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(onPressed: () => _applyQuickRange(7), child: const Text('7 días')),
                    OutlinedButton(onPressed: () => _applyQuickRange(30), child: const Text('30 días')),
                    OutlinedButton(onPressed: () => _applyQuickRange(90), child: const Text('90 días')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<TensionData>>(
              future: _tensionDataList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay datos registrados para este rango.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _filterData,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _buildReadingCard(items[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
