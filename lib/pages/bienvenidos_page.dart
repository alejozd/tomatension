import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'tomar_tension_page.dart';
import 'ver_datos_page.dart';
import 'exportar_datos_page.dart';
import 'ver_grafico_page.dart';
import 'package:animated_button/animated_button.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toma Tensión')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              '¡Bienvenido!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            AnimatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TomarTensionPage(),
                  ),
                );
              },
              width: 200,
              height: 50,
              color: Colors.blueAccent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Ingresar Datos',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            AnimatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VerDatosPage()),
                );
              },
              width: 200,
              height: 50,
              color: Colors.green,
              child: Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    Icon(Icons.visibility, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Ver Datos',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            AnimatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExportarDatosPage(),
                  ),
                );
              },
              width: 200,
              height: 50,
              color: Colors.redAccent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.share, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Exportar Datos',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            AnimatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VerGraficoPage(),
                  ),
                );
              },
              width: 200,
              height: 50,
              color: Colors.orange,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.show_chart, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Ver Gráfico',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Mostrar la versión de la aplicación
            Text(
              'Versión: $_appVersion',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
