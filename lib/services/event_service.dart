import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> createEvent({
    required String nombre,
    required String descripcion,
    required DateTime fecha,
    required String hora,
    required String municipio,
    required String departamento,
    required String tipoEvento,
    required String disciplina,
    required String imagenUrl,
    required String kit,
    required String organizadorId,
    required List<Map<String, dynamic>> categorias,
    required String cuentaBancaria,
    required int cuposDisponibles,
  }) async {
    try {
      await _firestore.collection('events').add({
        'nombre': nombre,
        'descripcion': descripcion,
        'fecha': Timestamp.fromDate(fecha),
        'hora': hora,
        'ubicacion': {
          'municipio': municipio,
          'departamento': departamento,
        },
        'tipoEvento': tipoEvento,
        'disciplina': disciplina,
        'imagenUrl': imagenUrl,
        'kit': kit,
        'organizadorId': organizadorId,
        'categorias': categorias,
        'cuentaBancaria': cuentaBancaria,
        'estado': 'activo',
        'cuposDisponibles': cuposDisponibles,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateEvent({
    required String eventId,
    required String nombre,
    required String descripcion,
    required DateTime fecha,
    required String hora,
    required String municipio,
    required String departamento,
    required String tipoEvento,
    required String disciplina,
    required String imagenUrl,
    required String kit,
    required List<Map<String, dynamic>> categorias,
    required String cuentaBancaria,
    required int cuposDisponibles,
  }) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'nombre': nombre,
        'descripcion': descripcion,
        'fecha': Timestamp.fromDate(fecha),
        'hora': hora,
        'ubicacion': {
          'municipio': municipio,
          'departamento': departamento,
        },
        'tipoEvento': tipoEvento,
        'disciplina': disciplina,
        'imagenUrl': imagenUrl,
        'kit': kit,
        'categorias': categorias,
        'cuentaBancaria': cuentaBancaria, 
        'cuposDisponibles': cuposDisponibles,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}