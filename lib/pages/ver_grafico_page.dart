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

  static const Color _sistoleColor = Color(0xFF3B82F6);
  static const Color _diastoleColor = Color(0xFF22C55E);
  static const Color _ritmoColor = Color(0xFFEF4444);

  List<TensionData> _tensionData = [];
  DateTime _selectedStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _selectedEndDate = DateTime.now();

  bool _isLoading = false;
  String? _errorMessage;
  int _selectedQuickRange = 30;

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
      _selectedQuickRange = 0;
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
      _selectedQuickRange = 0;
    });

    _fetchData();
  }

  void _applyQuickRange(int days) {
    setState(() {
      _selectedQuickRange = days;
      _selectedEndDate = DateTime.now();
      _selectedStartDate = _selectedEndDate.subtract(Duration(days: days));
    });

    _fetchData();
  }

  double _calculateChartWidth() {
    final double baseWidth = MediaQuery.of(context).size.width - 44;
    const double minPointWidth = 38;
    return (_tensionData.length * minPointWidth).clamp(baseWidth, double.infinity);
  }

  int? _averageBy(int Function(TensionData item) selector) {
    if (_tensionData.isEmpty) {
      return null;
    }

    final total = _tensionData.fold<int>(0, (sum, item) => sum + selector(item));
    return (total / _tensionData.length).round();
  }

  Widget _buildDateCard({
    required String title,
    required DateTime date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x331F2937),
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(icon, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(date),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
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

  Widget _buildRangeSelector() {
    return Wrap(
      spacing: 8,
      children: [
        _rangeChip(7),
        _rangeChip(30),
        _rangeChip(90),
      ],
    );
  }

  Widget _rangeChip(int days) {
    final selected = _selectedQuickRange == days;
    return ChoiceChip(
      label: Text('$days días'),
      selected: selected,
      onSelected: (_) => _applyQuickRange(days),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFE0E7FF),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF312E81) : const Color(0xFF475569),
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: selected ? const Color(0xFF6366F1) : const Color(0xFFD1D5DB),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      showCheckmark: false,
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF334155),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required int? value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value?.toString() ?? '-',
              style: TextStyle(
                fontSize: 26,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _lineData(
    List<FlSpot> spots,
    Color color,
    bool withArea,
  ) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.28,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: withArea,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.22),
            color.withOpacity(0.01),
          ],
        ),
      ),
    );
  }

  LineChartData _buildChartData() {
    final List<FlSpot> sistoleSpots = [];
    final List<FlSpot> diastoleSpots = [];
    final List<FlSpot> ritmoSpots = [];

    for (int i = 0; i < _tensionData.length; i++) {
      final item = _tensionData[i];
      final x = i.toDouble();
      sistoleSpots.add(FlSpot(x, item.sistole.toDouble()));
      diastoleSpots.add(FlSpot(x, item.diastole.toDouble()));
      ritmoSpots.add(FlSpot(x, item.ritmoCardiaco.toDouble()));
    }

    double minY = 40;
    double maxY = 180;

    if (_tensionData.isNotEmpty) {
      final allValues = _tensionData
          .expand((item) => [item.sistole, item.diastole, item.ritmoCardiaco])
          .toList()
        ..sort();

      minY = (allValues.first - 8).clamp(0, 260).toDouble();
      maxY = (allValues.last + 10).clamp(minY + 20, 260).toDouble();
    }

    final int horizontalLabelStep = _tensionData.length > 6 ? (_tensionData.length / 6).ceil() : 1;

    return LineChartData(
      minX: 0,
      maxX: (_tensionData.length > 1 ? _tensionData.length - 1 : 0).toDouble(),
      minY: minY,
      maxY: maxY,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        horizontalInterval: 10,
        verticalInterval: horizontalLabelStep.toDouble(),
        getDrawingHorizontalLine: (_) => FlLine(
          color: const Color(0xFFE2E8F0),
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (_) => FlLine(
          color: const Color(0xFFF1F5F9),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            interval: 20,
            getTitlesWidget: (value, _) => Text(
              value.toInt().toString(),
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
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
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          tooltipPadding: const EdgeInsets.all(10),
          tooltipBorderRadius: BorderRadius.circular(10),
          getTooltipColor: (_) => const Color(0xFF0F172A).withOpacity(0.92),
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
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        _lineData(sistoleSpots, _sistoleColor, true),
        _lineData(diastoleSpots, _diastoleColor, false),
        _lineData(ritmoSpots, _ritmoColor, false),
      ],
    );
  }

  Widget _buildChartContainer() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 70),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 70),
        child: Center(
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF475569), fontSize: 15),
          ),
        ),
      );
    }

    if (_tensionData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 70),
        child: Center(
          child: Text(
            'No hay datos para el rango seleccionado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _calculateChartWidth(),
        height: 340,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 700),
          tween: Tween(begin: 0, end: 1),
          builder: (_, value, __) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 16 * (1 - value)),
                child: LineChart(_buildChartData()),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int? averageSistole = _averageBy((item) => item.sistole);
    final int? averageDiastole = _averageBy((item) => item.diastole);
    final int? averageRitmo = _averageBy((item) => item.ritmoCardiaco);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Gráfico de Tensión Arterial'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          children: [
            Row(
              children: [
                _buildDateCard(
                  title: 'Inicio',
                  date: _selectedStartDate,
                  icon: Icons.calendar_today_rounded,
                  onTap: () => _selectStartDate(context),
                ),
                const SizedBox(width: 10),
                _buildDateCard(
                  title: 'Fin',
                  date: _selectedEndDate,
                  icon: Icons.event_available_rounded,
                  onTap: () => _selectEndDate(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRangeSelector(),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                _buildLegendItem(_sistoleColor, 'Sístole'),
                _buildLegendItem(_diastoleColor, 'Diástole'),
                _buildLegendItem(_ritmoColor, 'Ritmo'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMetricCard(
                  label: 'Prom. Sístole',
                  value: averageSistole,
                  color: _sistoleColor,
                ),
                _buildMetricCard(
                  label: 'Prom. Diástole',
                  value: averageDiastole,
                  color: _diastoleColor,
                ),
                _buildMetricCard(
                  label: 'Prom. Ritmo',
                  value: averageRitmo,
                  color: _ritmoColor,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x120F172A),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: _buildChartContainer(),
            ),
          ],
        ),
      ),
    );
  }
}
