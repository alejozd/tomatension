import 'package:flutter/material.dart';
import 'dart:async';
import 'bienvenidos_page.dart';

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
    await Future.delayed(const Duration(seconds: 3), () {});

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BienvenidosPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // <--- Fondo blanco para tu logo
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tu imagen de ZambranoSoft
            Image.asset(
              'assets/images/logoSplash.JPG', // Asegúrate de que esta ruta sea correcta
              width: 200, // Ajusta el tamaño según tu imagen
              height: 200,
            ),
            const SizedBox(height: 20),
            const Text(
              'TomaTension', // Puedes cambiar esto a 'ZambranoSoft' si quieres
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors
                    .deepPurple, // Color oscuro para que se vea en fondo blanco
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.deepPurple,
              ), // Color del indicador de carga
            ),
          ],
        ),
      ),
    );
  }
}
