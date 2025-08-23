import 'package:flutter/material.dart';
import 'tomar_tension_page.dart';
import 'ver_datos_page.dart';
import 'exportar_datos_page.dart';
import 'package:animated_button/animated_button.dart'; // Asegúrate de que esta importación esté presente

class BienvenidosPage extends StatelessWidget {
  const BienvenidosPage({super.key});

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

            // Botón "Ingresar Datos"
            AnimatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TomarTensionPage(),
                  ),
                );
              },
              width: 200, // Ancho consistente para todos los botones
              height: 50, // Altura para que el contenido se vea bien
              color: Colors.blueAccent, // Color de fondo diferente
              child: Padding(
                // Agregamos Padding para un offset visual desde el borde izquierdo
                padding: const EdgeInsets.only(left: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    Icon(Icons.add, color: Colors.white),
                    SizedBox(width: 10), // Espacio entre el icono y el texto
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
            ),
            const SizedBox(height: 15), // Espacio entre botones
            // Botón "Ver Datos"
            AnimatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VerDatosPage()),
                );
              },
              width: 200, // Mismo ancho
              height: 50,
              color: Colors.green, // Otro color diferente
              child: Padding(
                // Agregamos Padding para un offset visual desde el borde izquierdo
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
            const SizedBox(height: 15), // Espacio entre botones
            // Botón "Exportar Datos"
            AnimatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExportarDatosPage(),
                  ),
                );
              },
              width: 200, // Mismo ancho
              height: 50,
              color: Colors.redAccent, // Otro color más
              child: Padding(
                // Agregamos Padding para un offset visual desde el borde izquierdo
                padding: const EdgeInsets.only(left: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    Icon(Icons.share_outlined, color: Colors.white),
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
            ),
          ],
        ),
      ),
    );
  }
}
