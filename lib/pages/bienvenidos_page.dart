import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importa SharedPreferences

import 'tomar_tension_page.dart';
import 'ver_datos_page.dart';
import 'exportar_datos_page.dart';
import 'migration_button_screen.dart'; // Importa la pantalla de migración
import 'ver_grafico_page.dart';
import 'package:animated_button/animated_button.dart';

class BienvenidosPage extends StatefulWidget {
  const BienvenidosPage({super.key});

  @override
  State<BienvenidosPage> createState() => _BienvenidosPageState();
}

class _BienvenidosPageState extends State<BienvenidosPage> {
  String _appVersion = '';
  bool _migrationCompleted = true; // Asumimos completada hasta que se verifique

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _checkMigrationStatus();
  }

  Future<void> _loadAppVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  Future<void> _checkMigrationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool completed = prefs.getBool('migration_completed') ?? false;
    setState(() {
      _migrationCompleted = completed;
    });
    print(
      'BienvenidosPage: Estado de migración completada: $_migrationCompleted',
    );
  }

  // Función para manejar la navegación a la pantalla de migración
  Future<void> _navigateToMigrationScreen() async {
    print('BienvenidosPage: Navegando a MigrationButtonScreen...');
    // Usamos push y esperamos un resultado
    final bool? migrationResult = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MigrationButtonScreen()),
    );

    // Si regresamos con 'true', significa que la migración se completó (o ya estaba hecha)
    if (migrationResult == true) {
      print(
        'BienvenidosPage: Migración exitosa o ya completada. Actualizando estado.',
      );
      _checkMigrationStatus(); // Vuelve a verificar el estado para ocultar el botón
      // Opcional: Podrías navegar a otra página o hacer un refresh de datos si fuera necesario
    } else {
      print('BienvenidosPage: Migración no completada o cancelada.');
    }
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

            // --- NUEVO BOTÓN: Ver Gráfico ---
            AnimatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const VerGraficoPage(), // Navega a la nueva página
                  ),
                );
              },
              width: 200,
              height: 50,
              color: Colors.orange, // Color distintivo para el gráfico
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
            const SizedBox(height: 15),

            // --- NUEVO BOTÓN DE MIGRACIÓN (CONDICIONAL) ---
            if (!_migrationCompleted) // Solo se muestra si la migración no está completada
              AnimatedButton(
                onPressed: _navigateToMigrationScreen,
                width: 230,
                height: 50,
                color: Colors.purple, // Un color distintivo
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.cloud_upload, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Migrar Datos Antiguos',
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
