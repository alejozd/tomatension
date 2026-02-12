import 'dart:io';

import 'package:animated_button/animated_button.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../models/tension_data.dart';
import '../services/database_service.dart';

class ExportarDatosPage extends StatelessWidget {
  const ExportarDatosPage({super.key});

  void _showMessage(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _exportDatabase(BuildContext context) async {
    try {
      final databasePath = await getDatabasesPath();
      final dbFile = File('$databasePath/tension_data.db');

      if (!await dbFile.exists()) {
        _showMessage(context, 'No se encontró la base de datos para exportar.');
        return;
      }

      await Share.shareXFiles(
        [XFile(dbFile.path)],
        text: 'Copia de seguridad de la base de datos de TomaTension.',
      );

      _showMessage(context, 'Se inició el proceso para compartir la base de datos.');
    } catch (e) {
      _showMessage(context, 'Error al exportar la base de datos: $e');
    }
  }

  Future<void> _exportToExcel(BuildContext context) async {
    try {
      final dbService = DatabaseService();
      final List<TensionData> datos = await dbService.getTensionData();

      if (datos.isEmpty) {
        _showMessage(context, 'No hay datos para exportar.');
        return;
      }

      final sortedData = [...datos]..sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
      final excel = Excel.createExcel();
      final String sheetName = excel.getDefaultSheet() ?? 'Sheet1';
      final sheet = excel.sheets[sheetName];

      if (sheet == null) {
        _showMessage(context, 'No se pudo crear la hoja de Excel.');
        return;
      }

      sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Fecha y hora');
      sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Sístole');
      sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Diástole');
      sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('Ritmo cardíaco');

      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
      for (int i = 0; i < sortedData.length; i++) {
        final row = i + 2;
        final item = sortedData[i];
        sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(dateFormat.format(item.fechaHora));
        sheet.cell(CellIndex.indexByString('B$row')).value = IntCellValue(item.sistole);
        sheet.cell(CellIndex.indexByString('C$row')).value = IntCellValue(item.diastole);
        sheet.cell(CellIndex.indexByString('D$row')).value = IntCellValue(item.ritmoCardiaco);
      }

      final excelBytes = excel.encode();
      if (excelBytes == null) {
        _showMessage(context, 'No se pudo generar el archivo Excel.');
        return;
      }

      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/Datos_Tension_$timestamp.xlsx');
      await file.writeAsBytes(excelBytes, flush: true);

      await Share.shareXFiles([XFile(file.path)], text: 'Datos de Tensión en Excel.');
      _showMessage(context, 'Se inició el proceso para compartir el archivo Excel.');
    } catch (e) {
      _showMessage(context, 'Error al exportar a Excel: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exportar Datos')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Comparte tus datos por el medio que prefieras',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              AnimatedButton(
                onPressed: () => _exportDatabase(context),
                width: 250,
                height: 55,
                color: Colors.lightBlue,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.storage, color: Colors.white),
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
              const SizedBox(height: 15),
              AnimatedButton(
                onPressed: () => _exportToExcel(context),
                width: 250,
                height: 55,
                color: Colors.teal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.insert_drive_file, color: Colors.white),
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
