import 'dart:io';

import 'package:animated_button/animated_button.dart';
import 'package:excel/excel.dart' as xls;
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

  Future<String> _getDatabaseFilePath() async {
    final databasePath = await getDatabasesPath();
    return '$databasePath/tension_data.db';
  }

  Future<Directory> _getBackupsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final backupsDir = Directory('${directory.path}/backups');
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }
    return backupsDir;
  }

  Future<File?> _pickLocalBackupFile(BuildContext context) async {
    final backupsDir = await _getBackupsDirectory();
    final files = backupsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.db'))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    if (files.isEmpty) {
      return null;
    }

    return showDialog<File>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecciona un backup local'),
        content: SizedBox(
          width: 320,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return ListTile(
                title: Text(file.uri.pathSegments.last),
                subtitle: Text(file.path),
                onTap: () => Navigator.pop(context, file),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ],
      ),
    );
  }

  Future<void> _backupLocal(BuildContext context) async {
    try {
      final sourcePath = await _getDatabaseFilePath();
      final backupsDir = await _getBackupsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final destinationPath = '${backupsDir.path}/tension_data_backup_$timestamp.db';
      final dbFile = File(sourcePath);

      if (!await dbFile.exists()) {
        _showMessage(context, 'No se encontró la base de datos para crear backup.');
        return;
      }

      final destinationFile = File(destinationPath);
      final parentDir = destinationFile.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      await dbFile.copy(destinationPath);
      _showMessage(context, 'Backup local creado en: $destinationPath');
    } catch (e) {
      _showMessage(context, 'Error al crear backup local: $e');
    }
  }

  Future<void> _restoreLocal(BuildContext context) async {
    try {
      final backupFile = await _pickLocalBackupFile(context);
      if (backupFile == null) {
        _showMessage(context, 'No hay backups locales disponibles o restauración cancelada.');
        return;
      }

      if (!await backupFile.exists()) {
        _showMessage(context, 'El archivo seleccionado no existe o no es accesible.');
        return;
      }

      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restaurar backup'),
          content: Text(
            'Se reemplazarán los datos actuales con el contenido de:\n${backupFile.path}\n\n¿Deseas continuar?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restaurar')),
          ],
        ),
      );

      if (confirmed != true) {
        return;
      }

      final dbService = DatabaseService();
      await dbService.closeDatabase();

      final destinationPath = await _getDatabaseFilePath();
      await backupFile.copy(destinationPath);

      _showMessage(context, 'Backup restaurado correctamente.');
    } catch (e) {
      _showMessage(context, 'Error al restaurar backup local: $e');
    }
  }

  Future<void> _exportDatabase(BuildContext context) async {
    try {
      final dbFile = File(await _getDatabaseFilePath());

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
      final excel = xls.Excel.createExcel();
      final String sheetName = excel.getDefaultSheet() ?? 'Sheet1';
      final sheet = excel.sheets[sheetName];

      if (sheet == null) {
        _showMessage(context, 'No se pudo crear la hoja de Excel.');
        return;
      }

      sheet.cell(xls.CellIndex.indexByString('A1')).value = xls.TextCellValue('Fecha y hora');
      sheet.cell(xls.CellIndex.indexByString('B1')).value = xls.TextCellValue('Sístole');
      sheet.cell(xls.CellIndex.indexByString('C1')).value = xls.TextCellValue('Diástole');
      sheet.cell(xls.CellIndex.indexByString('D1')).value = xls.TextCellValue('Ritmo cardíaco');

      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
      for (int i = 0; i < sortedData.length; i++) {
        final row = i + 2;
        final item = sortedData[i];
        sheet.cell(xls.CellIndex.indexByString('A$row')).value = xls.TextCellValue(dateFormat.format(item.fechaHora));
        sheet.cell(xls.CellIndex.indexByString('B$row')).value = xls.IntCellValue(item.sistole);
        sheet.cell(xls.CellIndex.indexByString('C$row')).value = xls.IntCellValue(item.diastole);
        sheet.cell(xls.CellIndex.indexByString('D$row')).value = xls.IntCellValue(item.ritmoCardiaco);
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

  Widget _actionButton({
    required VoidCallback onPressed,
    required Color color,
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return AnimatedButton(
      onPressed: onPressed,
      width: 300,
      height: 60,
      color: color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFFE2E8F0)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exportar y Respaldar Datos')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 320,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'Los backups son copias del archivo SQLite (.db) de la app y se guardan en la carpeta local de backups. Al restaurar podrás elegir uno de los backups locales detectados.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              _actionButton(
                onPressed: () => _exportDatabase(context),
                color: Colors.lightBlue,
                icon: Icons.storage,
                title: 'Compartir Base de Datos',
                subtitle: 'Envía una copia por apps compatibles',
              ),
              const SizedBox(height: 12),
              _actionButton(
                onPressed: () => _exportToExcel(context),
                color: Colors.teal,
                icon: Icons.insert_drive_file,
                title: 'Compartir Archivo Excel',
                subtitle: 'Genera un .xlsx con todas tus mediciones',
              ),
              const SizedBox(height: 12),
              _actionButton(
                onPressed: () => _backupLocal(context),
                color: Colors.deepPurple,
                icon: Icons.backup,
                title: 'Crear Backup Local',
                subtitle: 'Guarda en carpeta local backups/ con fecha',
              ),
              const SizedBox(height: 12),
              _actionButton(
                onPressed: () => _restoreLocal(context),
                color: Colors.orange,
                icon: Icons.settings_backup_restore,
                title: 'Restaurar Backup Local',
                subtitle: 'Te permitirá elegir entre backups locales',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
