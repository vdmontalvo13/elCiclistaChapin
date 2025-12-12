import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener total de participaciones del ciclista
  Future<int> getTotalParticipaciones(String userId) async {
    try {
      // Contar inscripciones aprobadas
      QuerySnapshot snapshot = await _firestore
          .collection('inscriptions')
          .where('ciclistaId', isEqualTo: userId)
          .where('estado', isEqualTo: 'aprobado')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Obtener inscripciones del mes actual
  Future<int> getInscripcionesEsteMes(String userId) async {
    try {
      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime endOfMonth = DateTime(now.year, now.month + 1, 0);

      QuerySnapshot snapshot = await _firestore
          .collection('inscriptions')
          .where('ciclistaId', isEqualTo: userId)
          .where('estado', isEqualTo: 'aprobado')
          .where(
            'fechaInscripcion',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where(
            'fechaInscripcion',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth),
          )
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Obtener mejor resultado
  Future<Map<String, dynamic>?> getMejorResultado(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('results')
          .where('ciclistaId', isEqualTo: userId)
          .orderBy('posicionGeneral', descending: false)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      Map<String, dynamic> result =
          snapshot.docs.first.data() as Map<String, dynamic>;

      // Obtener nombre del evento
      String eventoId = result['eventoId'];
      DocumentSnapshot eventoDoc = await _firestore
          .collection('events')
          .doc(eventoId)
          .get();

      if (eventoDoc.exists) {
        Map<String, dynamic> eventoData =
            eventoDoc.data() as Map<String, dynamic>;

        return {
          'eventoNombre': eventoData['nombre'],
          'posicion': result['posicionGeneral'],
          'tiempo': result['tiempoFinal'],
        };
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Obtener eventos de un organizador
  Future<List<EventModel>> getEventosPorOrganizador(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('events')
          .where('organizadorId', isEqualTo: userId)
          .get(); // Quitar el orderBy de aquí

      // Ordenar en el cliente en lugar de en Firestore
      List<EventModel> eventos = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();

      // Ordenar por fecha localmente
      eventos.sort((a, b) => a.fecha.compareTo(b.fecha));

      return eventos;
    } catch (e) {
      return [];
    }
  }

  // Actualizar perfil de usuario
  Future<bool> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        ...data,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
