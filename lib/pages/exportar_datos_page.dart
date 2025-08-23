import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';
import 'dart:io';

import 'package:sqflite/sqflite.dart';
import '../models/tension_data.dart';
import '../services/database_service.dart';
import 'package:animated_button/animated_button.dart'; // Importa el AnimatedButton

class ExportarDatosPage extends StatelessWidget {
  const ExportarDatosPage({super.key});

  Future<void> _exportDatabase(BuildContext context) async {
    try {
      final databasePath = await getDatabasesPath();
      final dbFile = File('$databasePath/tension_data.db');

      if (!await dbFile.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: La base de datos no existe.')),
          );
        }
        return;
      }

      await Share.shareXFiles([
        XFile(dbFile.path),
      ], text: 'Copia de seguridad de la base de datos de TomaTension.');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Se ha iniciado el proceso de compartir la base de datos.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar la base de datos: $e')),
        );
      }
    }
  }

  Future<void> _exportToExcel(BuildContext context) async {
    final dbService = DatabaseService();
    final List<TensionData> datos = await dbService.getTensionData();

    if (datos.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay datos para exportar.')),
        );
      }
      return;
    }

    try {
      final excel = Excel.createExcel();
      final sheet = excel.sheets[excel.getDefaultSheet() as String];

      // Añadir encabezados
      sheet?.cell(CellIndex.indexByString("A1")).value = TextCellValue("Fecha");
      sheet?.cell(CellIndex.indexByString("B1")).value = TextCellValue(
        "Sístole",
      );
      sheet?.cell(CellIndex.indexByString("C1")).value = TextCellValue(
        "Diástole",
      );
      sheet?.cell(CellIndex.indexByString("D1")).value = TextCellValue(
        "Ritmo Cardiaco",
      );

      // Añadir datos
      for (int i = 0; i < datos.length; i++) {
        final row = i + 1;
        sheet?.cell(CellIndex.indexByString("A${row + 1}")).value =
            TextCellValue(datos[i].fechaHora.toString().substring(0, 16));
        sheet?.cell(CellIndex.indexByString("B${row + 1}")).value =
            IntCellValue(datos[i].sistole);
        sheet?.cell(CellIndex.indexByString("C${row + 1}")).value =
            IntCellValue(datos[i].diastole);
        sheet?.cell(CellIndex.indexByString("D${row + 1}")).value =
            IntCellValue(datos[i].ritmoCardiaco);
      }

      // Guardar el archivo en el almacenamiento local temporal
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/Datos.xlsx');
      final excelBytes = excel.encode();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Datos de Tensión en Excel.');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Se ha iniciado el proceso de compartir el archivo Excel.',
              ),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al codificar el archivo Excel.'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar a Excel: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exportar Datos')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Envío de correo - otro medio',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30), // Más espacio para la estética
              // Botón "Archivo de base de datos"
              AnimatedButton(
                onPressed: () => _exportDatabase(context),
                width: 250, // Ancho consistente
                height: 55, // Altura consistente
                color: Colors.lightBlue, // Color diferente
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.storage,
                      color: Colors.white,
                    ), // Icono para base de datos
                    SizedBox(width: 10),
                    Text(
                      'Archivo de Base de Datos',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15), // Espacio entre botones
              // Botón "Archivo de Excel"
              AnimatedButton(
                onPressed: () => _exportToExcel(context),
                width: 250, // Ancho consistente
                height: 55, // Altura consistente
                color: Colors.teal, // Otro color diferente
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.insert_drive_file,
                      color: Colors.white,
                    ), // Icono para Excel
                    SizedBox(width: 10),
                    Text(
                      'Archivo de Excel',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
