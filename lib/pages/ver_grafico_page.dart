import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
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
  DateTime _selectedStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _selectedEndDate = DateTime.now();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _dbService.getTensionDataByDateRange(
        _selectedStartDate,
        _selectedEndDate,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _tensionData = data;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'No se pudieron cargar los datos. Intenta nuevamente.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos del gráfico: $e')),
      );
    } finally {
      if (!mounted) {
        return;
      }
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

    if (picked == null || picked == _selectedStartDate) {
      return;
    }

    setState(() {
      _selectedStartDate = picked;
      if (_selectedStartDate.isAfter(_selectedEndDate)) {
        _selectedEndDate = _selectedStartDate;
      }
    });

    _fetchData();
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: _selectedStartDate,
      lastDate: DateTime.now(),
    );

    if (picked == null || picked == _selectedEndDate) {
      return;
    }

    setState(() {
      _selectedEndDate = picked;
    });

    _fetchData();
  }

  void _applyQuickRange(int days) {
    setState(() {
      _selectedEndDate = DateTime.now();
      _selectedStartDate = _selectedEndDate.subtract(Duration(days: days));
    });
    _fetchData();
  }

  double _calculateChartWidth() {
    final double baseWidth = MediaQuery.of(context).size.width - 26;
    const double minPointWidth = 44;
    return (_tensionData.length * minPointWidth).clamp(baseWidth, double.infinity);
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildMetricCard(String label, int? value, Color color) {
    return Expanded(
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              const SizedBox(height: 4),
              Text(
                value?.toString() ?? '-',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int? _averageBy(int Function(TensionData item) selector) {
    if (_tensionData.isEmpty) {
      return null;
    }
    final total = _tensionData.fold<int>(0, (sum, item) => sum + selector(item));
    return (total / _tensionData.length).round();
  }

  LineChartData _buildChartData() {
    final List<FlSpot> sistoleSpots = [];
    final List<FlSpot> diastoleSpots = [];
    final List<FlSpot> ritmoCardiacoSpots = [];

    for (int i = 0; i < _tensionData.length; i++) {
      final item = _tensionData[i];
      final x = i.toDouble();
      sistoleSpots.add(FlSpot(x, item.sistole.toDouble()));
      diastoleSpots.add(FlSpot(x, item.diastole.toDouble()));
      ritmoCardiacoSpots.add(FlSpot(x, item.ritmoCardiaco.toDouble()));
    }

    double minY = 40;
    double maxY = 180;

    if (_tensionData.isNotEmpty) {
      final allValues = _tensionData
          .expand((item) => [item.sistole, item.diastole, item.ritmoCardiaco])
          .toList()
        ..sort();

      minY = (allValues.first - 10).clamp(0, 260).toDouble();
      maxY = (allValues.last + 10).clamp(minY + 20, 260).toDouble();
    }

    final int horizontalLabelStep = _tensionData.length > 7 ? (_tensionData.length / 6).ceil() : 1;

    return LineChartData(
      minX: 0,
      maxX: (_tensionData.length > 1 ? _tensionData.length - 1 : 0).toDouble(),
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        horizontalInterval: 10,
        verticalInterval: horizontalLabelStep.toDouble(),
        getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 1),
        getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 1),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: 20,
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            interval: horizontalLabelStep.toDouble(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= _tensionData.length) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  DateFormat('dd/MM').format(_tensionData[index].fechaHora),
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        _lineData(sistoleSpots, Colors.blueAccent),
        _lineData(diastoleSpots, Colors.green),
        _lineData(ritmoCardiacoSpots, Colors.redAccent),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => Colors.blueGrey.shade700,
          getTooltipItems: (spots) {
            return spots.map((spot) {
              final index = spot.x.toInt();
              if (index < 0 || index >= _tensionData.length) {
                return null;
              }
              final item = _tensionData[index];
              return LineTooltipItem(
                '${DateFormat('dd/MM/yy HH:mm').format(item.fechaHora)}\n'
                'Sístole: ${item.sistole}\n'
                'Diástole: ${item.diastole}\n'
                'Ritmo: ${item.ritmoCardiaco}',
                const TextStyle(color: Colors.white),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  LineChartBarData _lineData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int? averageSistole = _averageBy((item) => item.sistole);
    final int? averageDiastole = _averageBy((item) => item.diastole);
    final int? averageRitmo = _averageBy((item) => item.ritmoCardiaco);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gráfico de Tensión Arterial'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _selectStartDate(context),
                    icon: const Icon(Icons.event, size: 18),
                    label: Text('Inicio: ${DateFormat('dd/MM/yyyy').format(_selectedStartDate)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _selectEndDate(context),
                    icon: const Icon(Icons.event_available, size: 18),
                    label: Text('Fin: ${DateFormat('dd/MM/yyyy').format(_selectedEndDate)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(onPressed: () => _applyQuickRange(7), child: const Text('7 días')),
                OutlinedButton(onPressed: () => _applyQuickRange(30), child: const Text('30 días')),
                OutlinedButton(onPressed: () => _applyQuickRange(90), child: const Text('90 días')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.blueAccent, 'Sístole'),
                const SizedBox(width: 10),
                _buildLegendItem(Colors.green, 'Diástole'),
                const SizedBox(width: 10),
                _buildLegendItem(Colors.redAccent, 'Ritmo'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildMetricCard('Prom. Sístole', averageSistole, Colors.blueAccent),
                _buildMetricCard('Prom. Diástole', averageDiastole, Colors.green),
                _buildMetricCard('Prom. Ritmo', averageRitmo, Colors.redAccent),
              ],
            ),
            const SizedBox(height: 14),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(child: Text(_errorMessage!, textAlign: TextAlign.center)),
              )
            else if (_tensionData.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: Text(
                    'No hay datos para el rango seleccionado.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: _calculateChartWidth(),
                  height: 320,
                  child: LineChart(_buildChartData()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
