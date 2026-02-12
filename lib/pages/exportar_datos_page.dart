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

  Future<List<Directory>> _getCandidateBackupDirectories() async {
    final List<Directory> dirs = [];

    final appDocuments = await getApplicationDocumentsDirectory();
    dirs.add(Directory('${appDocuments.path}/backups'));

    if (Platform.isAndroid) {
      dirs.add(Directory('/storage/emulated/0/Download/TomaTensionBackups'));
      dirs.add(Directory('/storage/emulated/0/Documents/TomaTensionBackups'));
    }

    return dirs;
  }

  Future<Directory> _getPreferredBackupDirectory() async {
    final candidates = await _getCandidateBackupDirectories();

    for (final dir in candidates) {
      try {
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        return dir;
      } catch (_) {
        continue;
      }
    }

    throw Exception('No se pudo preparar ninguna carpeta de backup.');
  }

  Future<List<(File, String)>> _getAvailableBackupFiles() async {
    final files = <(File, String)>[];
    final seenPaths = <String>{};
    final candidates = await _getCandidateBackupDirectories();

    for (final dir in candidates) {
      try {
        if (!await dir.exists()) {
          continue;
        }

        final sourceLabel = dir.path;
        final dirFiles = dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.toLowerCase().endsWith('.db'))
            .toList();

        for (final file in dirFiles) {
          if (seenPaths.add(file.path)) {
            files.add((file, sourceLabel));
          }
        }
      } catch (_) {
        continue;
      }
    }

    files.sort((a, b) => b.$1.lastModifiedSync().compareTo(a.$1.lastModifiedSync()));
    return files;
  }

  Future<File?> _pickLocalBackupFile(BuildContext context) async {
    final files = await _getAvailableBackupFiles();

    if (files.isEmpty) {
      return null;
    }

    return showDialog<File>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecciona un backup'),
        content: SizedBox(
          width: 320,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index].$1;
              final source = files[index].$2;
              return ListTile(
                title: Text(file.uri.pathSegments.last),
                subtitle: Text(source),
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
      final backupsDir = await _getPreferredBackupDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final destinationPath = '${backupsDir.path}/tension_data_backup_$timestamp.db';
      final dbFile = File(sourcePath);

      if (!await dbFile.exists()) {
        _showMessage(context, 'No se encontró la base de datos para crear backup.');
        return;
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
        _showMessage(context, 'No hay backups disponibles o restauración cancelada.');
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
                  'Los backups se intentan guardar en una carpeta accesible del teléfono (Download/Documents de TomaTensionBackups). Si Android lo restringe, se usan los documentos internos de la app.',
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
                subtitle: 'Prioriza carpeta accesible del teléfono',
              ),
              const SizedBox(height: 12),
              _actionButton(
                onPressed: () => _restoreLocal(context),
                color: Colors.orange,
                icon: Icons.settings_backup_restore,
                title: 'Restaurar Backup Local',
                subtitle: 'Busca backups en carpetas internas y públicas',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
