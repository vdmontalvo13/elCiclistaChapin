class CategoriaModel {
  String nombre;
  int edadMin;
  int edadMax;
  String genero;
  String distancia;
  String elevacion;
  int precioInscripcion;

  CategoriaModel({
    required this.nombre,
    required this.edadMin,
    required this.edadMax,
    required this.genero,
    required this.distancia,
    required this.elevacion,
    required this.precioInscripcion,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'edadMin': edadMin,
      'edadMax': edadMax,
      'genero': genero,
      'distancia': distancia,
      'elevacion': elevacion,
      'precioInscripcion': precioInscripcion,
    };
  }

  factory CategoriaModel.fromMap(Map<String, dynamic> map) {
    return CategoriaModel(
      nombre: map['nombre'] ?? '',
      edadMin: map['edadMin'] ?? 0,
      edadMax: map['edadMax'] ?? 0,
      genero: map['genero'] ?? 'masculino',
      distancia: map['distancia'] ?? '',
      elevacion: map['elevacion'] ?? '',
      precioInscripcion: map['precioInscripcion'] ?? 0,
    );
  }

  CategoriaModel copyWith({
    String? nombre,
    int? edadMin,
    int? edadMax,
    String? genero,
    String? distancia,
    String? elevacion,
    int? precioInscripcion,
  }) {
    return CategoriaModel(
      nombre: nombre ?? this.nombre,
      edadMin: edadMin ?? this.edadMin,
      edadMax: edadMax ?? this.edadMax,
      genero: genero ?? this.genero,
      distancia: distancia ?? this.distancia,
      elevacion: elevacion ?? this.elevacion,
      precioInscripcion: precioInscripcion ?? this.precioInscripcion,
    );
  }
}