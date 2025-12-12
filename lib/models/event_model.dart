import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String nombre;
  final String descripcion;
  final DateTime fecha;
  final String hora;
  final Map<String, dynamic> ubicacion; // Cambiado a Map
  final String tipoEvento;
  final String disciplina;
  final String imagenUrl;
  final String kit;
  final String organizadorId;
  final List<Map<String, dynamic>> categorias;
  final String cuentaBancaria;
  final String estado;
  final int cuposDisponibles;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.fecha,
    required this.hora,
    required this.ubicacion,
    required this.tipoEvento,
    required this.disciplina,
    required this.imagenUrl,
    required this.kit,
    required this.organizadorId,
    required this.categorias,
    required this.cuentaBancaria,
    required this.estado,
    required this.cuposDisponibles,
    required this.createdAt,
    required this.updatedAt,
  });

  // Getter para obtener ubicación completa como string
  String get ubicacionCompleta {
    if (ubicacion.containsKey('municipio') && ubicacion.containsKey('departamento')) {
      return '${ubicacion['municipio']}, ${ubicacion['departamento']}';
    }
    return ubicacion.toString();
  }

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Manejar ubicación como Map o String (retrocompatibilidad)
    Map<String, dynamic> ubicacionMap;
    if (data['ubicacion'] is Map) {
      ubicacionMap = Map<String, dynamic>.from(data['ubicacion']);
    } else {
      // Si es string, convertir a formato antiguo
      String ubicacionStr = data['ubicacion'] ?? '';
      List<String> parts = ubicacionStr.split(',');
      ubicacionMap = {
        'municipio': parts.isNotEmpty ? parts[0].trim() : '',
        'departamento': parts.length > 1 ? parts[1].trim() : '',
      };
    }
    
    return EventModel(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      fecha: (data['fecha'] as Timestamp).toDate(),
      hora: data['hora'] ?? '',
      ubicacion: ubicacionMap,
      tipoEvento: data['tipoEvento'] ?? '',
      disciplina: data['disciplina'] ?? '',
      imagenUrl: data['imagenUrl'] ?? '',
      kit: data['kit'] ?? '',
      organizadorId: data['organizadorId'] ?? '',
      categorias: List<Map<String, dynamic>>.from(data['categorias'] ?? []),
      cuentaBancaria: data['cuentaBancaria'] ?? '', 
      estado: data['estado'] ?? 'activo',
      cuposDisponibles: data['cuposDisponibles'] ?? 250, 
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'fecha': Timestamp.fromDate(fecha),
      'hora': hora,
      'ubicacion': ubicacion,
      'tipoEvento': tipoEvento,
      'disciplina': disciplina,
      'imagenUrl': imagenUrl,
      'kit': kit,
      'organizadorId': organizadorId,
      'categorias': categorias,
      'cuentaBancaria': cuentaBancaria,
      'estado': estado,
      'cuposDisponibles': cuposDisponibles,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}