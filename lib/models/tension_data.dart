class TensionData {
  int? id;
  final int sistole;
  final int diastole;
  final int ritmoCardiaco;
  final DateTime fechaHora;

  TensionData({
    this.id,
    required this.sistole,
    required this.diastole,
    required this.ritmoCardiaco,
    required this.fechaHora,
  });

  // Convertir un objeto TensionData en un mapa (Map)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sistole': sistole,
      'diastole': diastole,
      'ritmoCardiaco': ritmoCardiaco,
      'fechaHora': fechaHora
          .toIso8601String(), // Guardar como String para SQLite
    };
  }

  // Crear un objeto TensionData a partir de un mapa (Map)
  factory TensionData.fromMap(Map<String, dynamic> map) {
    return TensionData(
      id: map['id'],
      sistole: map['sistole'],
      diastole: map['diastole'],
      ritmoCardiaco: map['ritmoCardiaco'],
      fechaHora: DateTime.parse(
        map['fechaHora'],
      ), // Convertir de String a DateTime
    );
  }
}
