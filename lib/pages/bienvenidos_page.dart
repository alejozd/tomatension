import 'package:animated_button/animated_button.dart';
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

  Widget _menuButton({
    required Color color,
    required IconData icon,
    required String title,
    required VoidCallback onPressed,
  }) {
    return AnimatedButton(
      onPressed: onPressed,
      width: 260,
      height: 56,
      color: color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 320,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD8E8FF)),
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
                      'Selecciona una opción para gestionar tus mediciones.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _menuButton(
                color: Colors.blueAccent,
                icon: Icons.add,
                title: 'Ingresar Datos',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TomarTensionPage()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _menuButton(
                color: Colors.green,
                icon: Icons.visibility,
                title: 'Ver Datos',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VerDatosPage()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _menuButton(
                color: Colors.redAccent,
                icon: Icons.share,
                title: 'Exportar / Backup',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ExportarDatosPage()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _menuButton(
                color: Colors.orange,
                icon: Icons.show_chart,
                title: 'Ver Gráfico',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VerGraficoPage()),
                  );
                },
              ),
              const SizedBox(height: 24),
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
