import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TensionData {
  int? id; // El ID puede ser nulo antes de insertarse en la base de datos
  int sistole;
  int diastole;
  int ritmoCardiaco;
  DateTime fechaHora;

  TensionData({
    this.id,
    required this.sistole,
    required this.diastole,
    required this.ritmoCardiaco,
    required this.fechaHora,
  });

  // Convierte un objeto TensionData en un Mapa. Útil para insertar en la BD.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sistole': sistole,
      'diastole': diastole,
      'ritmoCardiaco': ritmoCardiaco,
      'fechaHora': fechaHora
          .toIso8601String(), // Guarda la fecha como String ISO 8601
    };
  }

  // Crea un objeto TensionData desde un Mapa (leído de la base de datos).
  factory TensionData.fromMap(Map<String, dynamic> map) {
    print('--- Intentando crear TensionData desde map: $map ---');

    // ID - Intentar con 'id' (minúsculas) o 'Id' (mayúsculas)
    final dynamic rawId = map['id'] ?? map['Id'];
    print('Raw Id: $rawId (Tipo: ${rawId.runtimeType})');

    // Sistole - Intentar con 'sistole' o 'Sistole'
    int parsedSistole = 0;
    final dynamic rawSistole = map['sistole'] ?? map['Sistole'];
    print('Raw Sistole: $rawSistole (Tipo: ${rawSistole.runtimeType})');
    if (rawSistole is int) {
      parsedSistole = rawSistole;
    } else if (rawSistole != null) {
      try {
        parsedSistole = int.parse(rawSistole.toString());
      } catch (e) {
        print(
          'ERROR: No se pudo parsear sistole de "$rawSistole" a int. Usando 0. Error: $e',
        );
      }
    }

    // Diastole - Intentar con 'diastole' o 'Diastole'
    int parsedDiastole = 0;
    final dynamic rawDiastole = map['diastole'] ?? map['Diastole'];
    print('Raw Diastole: $rawDiastole (Tipo: ${rawDiastole.runtimeType})');
    if (rawDiastole is int) {
      parsedDiastole = rawDiastole;
    } else if (rawDiastole != null) {
      try {
        parsedDiastole = int.parse(rawDiastole.toString());
      } catch (e) {
        print(
          'ERROR: No se pudo parsear diastole de "$rawDiastole" a int. Usando 0. Error: $e',
        );
      }
    }

    // RitmoCardiaco - Intentar con 'ritmoCardiaco' o 'RitmoCardiaco'
    int parsedRitmoCardiaco = 0;
    final dynamic rawRitmoCardiaco =
        map['ritmoCardiaco'] ?? map['RitmoCardiaco'];
    print(
      'Raw RitmoCardiaco: $rawRitmoCardiaco (Tipo: ${rawRitmoCardiaco.runtimeType})',
    );
    if (rawRitmoCardiaco is int) {
      parsedRitmoCardiaco = rawRitmoCardiaco;
    } else if (rawRitmoCardiaco != null) {
      try {
        parsedRitmoCardiaco = int.parse(rawRitmoCardiaco.toString());
      } catch (e) {
        print(
          'ERROR: No se pudo parsear ritmoCardiaco de "$rawRitmoCardiaco" a int. Usando 0. Error: $e',
        );
      }
    }

    // FechaHora - Priorizar String (ISO 8601) de Flutter DB, luego int (NET Ticks) de Xamarin
    DateTime parsedFechaHora;
    final dynamic rawFechaHora =
        map['fechaHora'] ?? map['FechaHora']; // Check both cases
    print('Raw FechaHora: $rawFechaHora (Tipo: ${rawFechaHora.runtimeType})');
    if (rawFechaHora is String) {
      // Prioritize String (ISO 8601) from Flutter DB
      try {
        parsedFechaHora = DateTime.parse(rawFechaHora);
        print('FechaHora convertida de String ISO: $parsedFechaHora');
      } catch (e) {
        print(
          'ERROR: No se pudo parsear fechaHora (String) de "$rawFechaHora" a DateTime. Usando fecha actual. Error: $e',
        );
        parsedFechaHora = DateTime.now();
      }
    } else if (rawFechaHora is int) {
      // Handle NET Ticks from Xamarin DB
      final int netTicks = rawFechaHora;
      const int netTicksEpochDifference = 621355968000000000;
      final int dartMicroseconds = (netTicks - netTicksEpochDifference) ~/ 10;
      parsedFechaHora = DateTime.fromMicrosecondsSinceEpoch(dartMicroseconds);
      print('FechaHora convertida de NET Ticks: $parsedFechaHora');
    } else {
      print(
        'ERROR: Formato de fechaHora inesperado para "$rawFechaHora". Usando fecha actual.',
      );
      parsedFechaHora = DateTime.now();
    }

    print(
      'Datos finalizados para TensionData: Id=${rawId}, Sistole=$parsedSistole, Diastole=$parsedDiastole, RitmoCardiaco=$parsedRitmoCardiaco, FechaHora=$parsedFechaHora',
    );
    print('--- Fin creación TensionData ---');

    return TensionData(
      id: rawId as int?,
      sistole: parsedSistole,
      diastole: parsedDiastole,
      ritmoCardiaco: parsedRitmoCardiaco,
      fechaHora: parsedFechaHora,
    );
  }
}
