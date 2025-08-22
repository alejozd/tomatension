import 'package:flutter/material.dart';
import 'tomar_tension_page.dart';
import 'ver_datos_page.dart';
import 'exportar_datos_page.dart';

class BienvenidosPage extends StatelessWidget {
  const BienvenidosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TomaTension')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              '¡Bienvenido!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navega a la página de toma de tensión
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TomarTensionPage(),
                  ),
                );
              },
              child: const Text('Ingresar Datos'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VerDatosPage()),
                );
              },
              child: const Text('Ver Datos'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExportarDatosPage(),
                  ),
                );
              },
              child: const Text('Exportar Datos'),
            ),
            // Aquí irían los otros botones para "Ver Datos" y "Exportar"
          ],
        ),
      ),
    );
  }
}
