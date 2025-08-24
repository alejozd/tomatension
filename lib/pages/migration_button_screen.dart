import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';

import '../services/database_service.dart';
// No necesitamos importar SplashPage aquí, ya que regresaremos a ella con pop

class MigrationButtonScreen extends StatefulWidget {
  const MigrationButtonScreen({super.key});

  @override
  State<MigrationButtonScreen> createState() => _MigrationButtonScreenState();
}

class _MigrationButtonScreenState extends State<MigrationButtonScreen> {
  String _migrationStatus = "Presiona 'Migrar Datos' para iniciar.";
  bool _isMigrating = false;

  Future<void> _performMigration() async {
    if (_isMigrating) return;

    setState(() {
      _isMigrating = true;
      _migrationStatus = "Iniciando migración...";
    });

    try {
      print('Iniciando verificación de migración desde el botón...');

      var status = await Permission.storage.request();
      if (!status.isGranted) {
        setState(() {
          _migrationStatus =
              'ERROR: Permiso de almacenamiento denegado. No se puede acceder al archivo. Por favor, concede el permiso.';
          _isMigrating = false;
        });
        print('ERROR: Permiso de almacenamiento denegado.');
        return; // No popear, dejar que el usuario vea el error
      }
      print('Permiso de almacenamiento concedido.');

      final Directory? appExternalFilesDir =
          await getExternalStorageDirectory();
      if (appExternalFilesDir == null) {
        setState(() {
          _migrationStatus =
              'ERROR: No se pudo acceder al directorio de archivos externos de la aplicación.';
          _isMigrating = false;
        });
        print(
          'ERROR: No se pudo acceder al directorio de archivos externos de la aplicación.',
        );
        return; // No popear, dejar que el usuario vea el error
      }

      final String xamarinDbPathInAppExternalFiles = p.join(
        appExternalFilesDir.path,
        'xamarin_database.db',
      );
      final File xamarinDbFileInAppExternalFiles = File(
        xamarinDbPathInAppExternalFiles,
      );

      print(
        'Buscando archivo de Xamarin en: ${xamarinDbFileInAppExternalFiles.path}',
      );

      if (await xamarinDbFileInAppExternalFiles.exists()) {
        print('Archivo xamarin_database.db ENCONTRADO.');

        final databasesPath = await getDatabasesPath();
        final flutterDbPath = p.join(databasesPath, 'tension_data.db');
        final flutterDbFile = File(flutterDbPath);

        bool flutterDbHasData = false;
        if (await flutterDbFile.exists()) {
          final length = await flutterDbFile.length();
          flutterDbHasData = length > 0;
          print('La BD de Flutter existe y tiene un tamaño de: $length bytes.');
        }

        if (!flutterDbHasData) {
          setState(() {
            _migrationStatus = 'Copiando datos...';
          });
          print(
            'La base de datos de Flutter no existe o está vacía. Iniciando migración...',
          );

          final dbService = DatabaseService();
          await dbService.migrateDataFromExternalDb(
            xamarinDbFileInAppExternalFiles.path,
          );

          setState(() {
            _migrationStatus = '¡Migración completada con éxito!';
          });
          print('Base de datos migrada exitosamente.');

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(
            'migration_completed',
            true,
          ); // Marcar como completada

          await xamarinDbFileInAppExternalFiles.delete();
          print('Archivo de Xamarin eliminado de la ubicación temporal.');

          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.of(
              context,
            ).pop(true); // <--- Pop con 'true' si la migración fue exitosa
          }
        } else {
          setState(() {
            _migrationStatus =
                'La base de datos de Flutter ya contiene datos. No se realiza la migración.';
          });
          print(
            'La base de datos de Flutter ya existe y contiene datos. No se realiza la migración.',
          );
          await xamarinDbFileInAppExternalFiles.delete();
          print('Archivo de Xamarin eliminado (ya existía la BD de Flutter).');

          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.of(
              context,
            ).pop(true); // <--- Pop con 'true' si ya estaba migrada
          }
        }
      } else {
        setState(() {
          _migrationStatus =
              'ERROR: Archivo xamarin_database.db NO ENCONTRADO en la ubicación esperada.';
          _isMigrating = false;
        });
        print('Archivo xamarin_database.db NO ENCONTRADO.');
        print(
          '¡IMPORTANTE!: Necesitas empujar la base de datos de Xamarin a esta ubicación específica.',
        );
        print(
          'Usa el comando: adb push "C:\\Users\\Alejo\\Desktop\\xamarin_database.db" "${appExternalFilesDir.path}/xamarin_database.db"',
        );
        // No popear aquí, dejar el error visible para el usuario para que sepa qué hacer
      }
    } catch (e) {
      setState(() {
        _migrationStatus = 'ERROR CRÍTICO durante la migración: $e';
        _isMigrating = false;
      });
      print('ERROR CRÍTICO durante la migración: $e');
      // No popear, dejar el error visible
    } finally {
      if (mounted && _isMigrating) {
        // Solo si no hemos poppeado ya
        setState(() {
          _isMigrating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Migración de Datos')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _migrationStatus,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: _migrationStatus.startsWith('ERROR')
                      ? Colors.red
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isMigrating ? null : _performMigration,
                icon: _isMigrating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.upload_file),
                label: Text(_isMigrating ? 'Migrando...' : 'Migrar Datos'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  textStyle: const TextStyle(fontSize: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Añadir un botón de "Cancelar" o "Volver" si la migración no es obligatoria
              if (!_isMigrating &&
                  !_migrationStatus.startsWith('¡Migración completada!'))
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop(false); // Pop con 'false' si el usuario cancela
                  },
                  child: const Text('Volver al Menú Principal'),
                ),
              const SizedBox(height: 20),
              if (!_isMigrating && _migrationStatus.contains("NO ENCONTRADO"))
                FutureBuilder<String>(
                  future: _getExpectedMigrationPath(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error obteniendo ruta: ${snapshot.error}');
                    } else {
                      return Text(
                        "Ruta esperada para el archivo xamarin_database.db: ${snapshot.data}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _getExpectedMigrationPath() async {
    final Directory? appExternalFilesDir = await getExternalStorageDirectory();
    if (appExternalFilesDir == null) {
      return "No se pudo determinar la ruta de almacenamiento externo.";
    }
    return p.join(appExternalFilesDir.path, 'xamarin_database.db');
  }
}
