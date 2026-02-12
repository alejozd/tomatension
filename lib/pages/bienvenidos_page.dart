import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'exportar_datos_page.dart';
import 'tomar_tension_page.dart';
import 'ver_datos_page.dart';
import 'ver_grafico_page.dart';

class BienvenidosPage extends StatefulWidget {
  const BienvenidosPage({super.key});

  @override
  State<BienvenidosPage> createState() => _BienvenidosPageState();
}

class _BienvenidosPageState extends State<BienvenidosPage> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        width: 320,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
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
        title: const Text('Toma Tensión'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Container(
                width: 320,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.favorite, color: Color(0xFFEF4444), size: 34),
                    SizedBox(height: 8),
                    Text(
                      '¡Bienvenido!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Accede rápidamente a cada sección desde este panel.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _menuCard(
                icon: Icons.add_chart,
                title: 'Ingresar Datos',
                subtitle: 'Registrar una nueva medición',
                gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TomarTensionPage()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _menuCard(
                icon: Icons.fact_check,
                title: 'Ver Datos',
                subtitle: 'Consultar historial de mediciones',
                gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VerDatosPage()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _menuCard(
                icon: Icons.backup,
                title: 'Exportar / Backup',
                subtitle: 'Compartir, respaldar y restaurar datos',
                gradient: const [Color(0xFFF43F5E), Color(0xFFE11D48)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ExportarDatosPage()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _menuCard(
                icon: Icons.show_chart,
                title: 'Ver Gráfico',
                subtitle: 'Visualizar tendencias y evolución',
                gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VerGraficoPage()),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Versión: $_appVersion',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
