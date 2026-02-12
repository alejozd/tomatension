import 'dart:io';

import 'package:animated_button/animated_button.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
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

  Future<String> _getDefaultBackupPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final backupsDir = Directory('${directory.path}/backups');
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return '${backupsDir.path}/tension_data_backup_$timestamp.db';
  }

  Future<bool> _isValidBackupFile(String path) async {
    Database? db;
    try {
      db = await openReadOnlyDatabase(path);
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='TensionData'",
      );
      return result.isNotEmpty;
    } catch (_) {
      return false;
    } finally {
      if (db != null && db.isOpen) {
        await db.close();
      }
    }
  }

  Future<void> _backupLocal(BuildContext context) async {
    try {
      final sourcePath = await _getDatabaseFilePath();
      final dbFile = File(sourcePath);

      if (!await dbFile.exists()) {
        _showMessage(context, 'No se encontró la base de datos para crear backup.');
        return;
      }

      final defaultPath = await _getDefaultBackupPath();
      String? destinationPath;

      try {
        destinationPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Guardar backup de base de datos',
          fileName: defaultPath.split('/').last,
          type: FileType.custom,
          allowedExtensions: ['db', 'sqlite'],
        );
      } catch (_) {
        destinationPath = null;
      }

      final finalPath = destinationPath ?? defaultPath;
      await dbFile.copy(finalPath);

      final usedDefault = destinationPath == null;
      _showMessage(
        context,
        usedDefault
            ? 'Backup creado en ruta predeterminada: $finalPath'
            : 'Backup creado en: $finalPath',
      );
    } catch (e) {
      _showMessage(context, 'Error al crear backup local: $e');
    }
  }

  Future<void> _restoreLocal(BuildContext context) async {
    try {
      FilePickerResult? picked;
      try {
        picked = await FilePicker.platform.pickFiles(
          dialogTitle: 'Selecciona el archivo de backup',
          type: FileType.custom,
          allowedExtensions: ['db', 'sqlite'],
        );
      } catch (_) {
        picked = null;
      }

      if (picked == null || picked.files.single.path == null) {
        _showMessage(
          context,
          'No se seleccionó archivo. Si tu plataforma no permite selector, usa la ruta predeterminada en Documentos/backups.',
        );
        return;
      }

      final backupPath = picked.files.single.path!;
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        _showMessage(context, 'El archivo seleccionado no existe.');
        return;
      }

      final valid = await _isValidBackupFile(backupPath);
      if (!valid) {
        _showMessage(
          context,
          'Archivo inválido. Debe ser una base SQLite con tabla TensionData.',
        );
        return;
      }

      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restaurar backup'),
          content: Text(
            'Se reemplazarán los datos actuales con el contenido de:\n$backupPath\n\n¿Deseas continuar?',
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

  Widget _actionButton({
    required VoidCallback onPressed,
    required Color color,
    required IconData icon,
    required String title,
  }) {
    return AnimatedButton(
      onPressed: onPressed,
      width: 280,
      height: 52,
      color: color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
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
      appBar: AppBar(title: const Text('Exportar y Respaldar Datos')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Exporta, crea respaldo local o restaura tu información',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Formato de restore: archivo SQLite (.db/.sqlite) con tabla TensionData.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _actionButton(
                onPressed: () => _exportDatabase(context),
                color: Colors.lightBlue,
                icon: Icons.storage,
                title: 'Compartir Base de Datos',
              ),
              const SizedBox(height: 12),
              _actionButton(
                onPressed: () => _exportToExcel(context),
                color: Colors.teal,
                icon: Icons.insert_drive_file,
                title: 'Compartir Archivo Excel',
              ),
              const SizedBox(height: 12),
              _actionButton(
                onPressed: () => _backupLocal(context),
                color: Colors.deepPurple,
                icon: Icons.backup,
                title: 'Crear Backup Local',
              ),
              const SizedBox(height: 12),
              _actionButton(
                onPressed: () => _restoreLocal(context),
                color: Colors.orange,
                icon: Icons.settings_backup_restore,
                title: 'Restaurar Backup Local',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
