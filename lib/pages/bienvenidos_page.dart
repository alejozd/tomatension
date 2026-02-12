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

  Widget _menuTile({
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: const [
            BoxShadow(color: Color(0x220F172A), blurRadius: 10, offset: Offset(0, 5)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Bienvenido!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Elige una opción para registrar, consultar, analizar o respaldar tus datos.',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.08,
                children: [
                  _menuTile(
                    icon: Icons.add,
                    title: 'Ingresar',
                    subtitle: 'Registrar medición',
                    gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TomarTensionPage()),
                      );
                    },
                  ),
                  _menuTile(
                    icon: Icons.list_alt,
                    title: 'Ver datos',
                    subtitle: 'Historial filtrable',
                    gradient: const [Color(0xFF16A34A), Color(0xFF15803D)],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const VerDatosPage()),
                      );
                    },
                  ),
                  _menuTile(
                    icon: Icons.show_chart,
                    title: 'Gráfico',
                    subtitle: 'Tendencias y promedios',
                    gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const VerGraficoPage()),
                      );
                    },
                  ),
                  _menuTile(
                    icon: Icons.backup,
                    title: 'Backup',
                    subtitle: 'Exportar y restaurar',
                    gradient: const [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ExportarDatosPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
            Center(
              child: Text(
                'Versión: $_appVersion',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
