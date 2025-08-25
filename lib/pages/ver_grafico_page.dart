import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/tension_data.dart';
import '../services/database_service.dart';

class VerGraficoPage extends StatefulWidget {
  const VerGraficoPage({super.key});

  @override
  State<VerGraficoPage> createState() => _VerGraficoPageState();
}

class _VerGraficoPageState extends State<VerGraficoPage> {
  final DatabaseService _dbService = DatabaseService();
  List<TensionData> _tensionData = [];
  DateTime _selectedStartDate = DateTime.now().subtract(
    const Duration(days: 30),
  );
  DateTime _selectedEndDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await _dbService.getTensionDataByDateRange(
        _selectedStartDate,
        _selectedEndDate,
      );
      setState(() {
        _tensionData = data;
      });
    } catch (e) {
      print('Error al cargar los datos para el gráfico: $e');
      // Mostrar un mensaje de error al usuario si es necesario
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedStartDate) {
      setState(() {
        _selectedStartDate = picked;
        if (_selectedStartDate.isAfter(_selectedEndDate)) {
          _selectedEndDate = _selectedStartDate;
        }
      });
      _fetchData();
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: _selectedStartDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedEndDate) {
      setState(() {
        _selectedEndDate = picked;
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gráfico de Tensión Arterial'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _selectStartDate(context),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          'Inicio: ${DateFormat('dd/MM/yyyy').format(_selectedStartDate)}',
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _selectEndDate(context),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          'Fin: ${DateFormat('dd/MM/yyyy').format(_selectedEndDate)}',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _tensionData.isEmpty
                        ? const Center(
                            child: Text(
                              'No hay datos para el rango de fechas seleccionado.',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : LineChart(mainData()),
                  ),
                ),
              ],
            ),
    );
  }

  LineChartData mainData() {
    final List<FlSpot> sistoleSpots = [];
    final List<FlSpot> diastoleSpots = [];
    final List<FlSpot> ritmoCardiacoSpots = [];

    for (int i = 0; i < _tensionData.length; i++) {
      final dataPoint = _tensionData[i];
      final double xValue = i.toDouble();

      sistoleSpots.add(FlSpot(xValue, dataPoint.sistole.toDouble()));
      diastoleSpots.add(FlSpot(xValue, dataPoint.diastole.toDouble()));
      ritmoCardiacoSpots.add(
        FlSpot(xValue, dataPoint.ritmoCardiaco.toDouble()),
      );
    }

    double minY = 0;
    double maxY = 150;

    if (_tensionData.isNotEmpty) {
      final allValues = _tensionData
          .expand((data) => [data.sistole, data.diastole, data.ritmoCardiaco])
          .toList();
      allValues.sort();
      if (allValues.isNotEmpty) {
        minY = (allValues.first.toDouble() - 10).clamp(0.0, double.infinity);
        maxY = (allValues.last.toDouble() + 10).clamp(
          minY + 20,
          double.infinity,
        );
      }
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 10,
        verticalInterval: _tensionData.length > 10
            ? (_tensionData.length / 5).ceilToDouble()
            : 1,
        getDrawingHorizontalLine: (value) {
          return const FlLine(color: Color(0xff37434d), strokeWidth: 1);
        },
        getDrawingVerticalLine: (value) {
          return const FlLine(color: Color(0xff37434d), strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value.toInt() < 0 || value.toInt() >= _tensionData.length) {
                return const Text('');
              }
              final DateTime date = _tensionData[value.toInt()].fechaHora;
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 4.0,
                  child: Text(
                    DateFormat('dd/MM').format(date),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              );
            },
            interval: _tensionData.length > 5
                ? (_tensionData.length / 5).ceilToDouble()
                : 1,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: 20,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d), width: 1),
      ),
      minX: 0,
      maxX: (_tensionData.isNotEmpty ? _tensionData.length - 1 : 0).toDouble(),
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: sistoleSpots,
          isCurved: true,
          color: Colors.blueAccent,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
        LineChartBarData(
          spots: diastoleSpots,
          isCurved: true,
          color: Colors.green,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
        LineChartBarData(
          spots: ritmoCardiacoSpots,
          isCurved: true,
          color: Colors.redAccent,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (spot) => Colors.blueGrey.withOpacity(0.8),
          tooltipBorder: BorderSide.none,
          tooltipRoundedRadius: 8.0,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              // --- CAMBIO CLAVE AQUÍ ---
              // touchedSpot ya es el FlSpot o permite acceder a sus propiedades directamente.
              if (touchedSpot.x < 0 || touchedSpot.x >= _tensionData.length) {
                return null;
              }
              final dataPoint = _tensionData[touchedSpot.x.toInt()];
              // ------------------------
              return LineTooltipItem(
                '${DateFormat('dd/MM/yy HH:mm').format(dataPoint.fechaHora)}\n'
                'Sistole: ${dataPoint.sistole}\n'
                'Diastole: ${dataPoint.diastole}\n'
                'Ritmo: ${dataPoint.ritmoCardiaco}',
                const TextStyle(color: Colors.white),
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
      ),
    );
  }
}
