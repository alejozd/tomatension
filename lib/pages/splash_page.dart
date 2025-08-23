import 'package:flutter/material.dart';
import 'dart:async'; // Necesario para Future.delayed
import 'bienvenidos_page.dart'; // Importa la página a la que navegarás

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    // Retraso de 3 segundos para mostrar el splash screen
    await Future.delayed(const Duration(seconds: 3), () {});

    if (mounted) {
      // Asegura que el widget sigue montado antes de navegar
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BienvenidosPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple, // Color de fondo del splash
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Aquí puedes agregar un logo o imagen.
            // Por ahora, pondremos un icono grande y un texto.
            const Icon(
              Icons
                  .monitor_heart, // Icono de corazón, puedes usar tu latido-del-corazon.png
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'TomaTension',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white,
              ), // Color del indicador de carga
            ),
          ],
        ),
      ),
    );
  }
}
