import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inscription_model.dart';

class InscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Verificar si el ciclista ya está inscrito en el evento
  Future<InscriptionModel?> getInscripcionExistente(String ciclistaId, String eventoId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('inscriptions')
          .where('ciclistaId', isEqualTo: ciclistaId)
          .where('eventoId', isEqualTo: eventoId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return InscriptionModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      return null;
    }
  }

  // Nueva inscripción
  Future<bool> createInscription({
    required String eventoId,
    required String eventoNombre,
    required String ciclistaId,
    required String ciclistaNombre,
    required String ciclistaApellido,
    required String ciclistaEmail,
    required String ciclistaTelefono,
    required String categoriaNombre,
    required String numeroBoletaPago,
    required String banco,
    required DateTime fechaPago,
    String? imagenBoleta,
  }) async {
    try {
      await _firestore.collection('inscriptions').add({
        'eventoId': eventoId,
        'eventoNombre': eventoNombre,
        'ciclistaId': ciclistaId,
        'ciclistaNombre': ciclistaNombre,
        'ciclistaApellido': ciclistaApellido,
        'ciclistaEmail': ciclistaEmail,
        'ciclistaTelefono': ciclistaTelefono,
        'categoriaNombre': categoriaNombre,
        'numeroBoletaPago': numeroBoletaPago,
        'banco': banco,
        'fechaPago': Timestamp.fromDate(fechaPago),
        'imagenBoleta': imagenBoleta,
        'estado': 'en_progreso',
        'motivoRechazo': null,
        'numeroAsignado': null,
        'fechaInscripcion': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Obtener inscripciones del ciclista
  Future<List<InscriptionModel>> getInscripcionesCiclista(String ciclistaId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('inscriptions')
          .where('ciclistaId', isEqualTo: ciclistaId)
          .orderBy('fechaInscripcion', descending: true)
          .get();

      return snapshot.docs.map((doc) => InscriptionModel.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  // Obtener inscripciones por evento (para organizadores)
  Future<List<InscriptionModel>> getInscripcionesPorEvento(String eventoId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('inscriptions')
          .where('eventoId', isEqualTo: eventoId)
          .orderBy('fechaInscripcion', descending: false)
          .get();

      return snapshot.docs.map((doc) => InscriptionModel.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  // Obtener participantes aprobados por evento
Future<List<InscriptionModel>> getParticipantesAprobados(String eventoId) async {
  try {
    QuerySnapshot snapshot = await _firestore
        .collection('inscriptions')
        .where('eventoId', isEqualTo: eventoId)
        .where('estado', isEqualTo: 'aprobado')
        .get();

    List<InscriptionModel> participantes = 
        snapshot.docs.map((doc) => InscriptionModel.fromFirestore(doc)).toList();
    
    // Ordenar localmente por categoría y luego por fecha
    participantes.sort((a, b) {
      int categoriaCompare = a.categoriaNombre.compareTo(b.categoriaNombre);
      if (categoriaCompare != 0) return categoriaCompare;
      return a.fechaInscripcion.compareTo(b.fechaInscripcion);
    });

    return participantes;
  } catch (e) {
    print('Error al obtener participantes: $e'); // Para debug
    return [];
  }
}

  // Aprobar inscripción
  Future<bool> aprobarInscripcion(String inscripcionId) async {
    try {
      await _firestore.collection('inscriptions').doc(inscripcionId).update({
        'estado': 'aprobado',
        'motivoRechazo': null,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Rechazar inscripción
  Future<bool> rechazarInscripcion(String inscripcionId, String motivo) async {
    try {
      await _firestore.collection('inscriptions').doc(inscripcionId).update({
        'estado': 'rechazado',
        'motivoRechazo': motivo,
        'numeroAsignado': null,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

 // Asignar números a participantes de una categoría
Future<bool> asignarNumeros({
  required String eventoId,
  required String categoria,
  required int correlativoInicio,
  required int correlativoFin,
}) async {
  try {
    // Obtener inscripciones aprobadas de la categoría (SIN orderBy para evitar índice)
    QuerySnapshot snapshot = await _firestore
        .collection('inscriptions')
        .where('eventoId', isEqualTo: eventoId)
        .where('categoriaNombre', isEqualTo: categoria)
        .where('estado', isEqualTo: 'aprobado')
        .get();

    List<DocumentSnapshot> inscripciones = snapshot.docs;
    
    // Ordenar localmente por fecha de inscripción
    inscripciones.sort((a, b) {
      Timestamp aTime = a['fechaInscripcion'] as Timestamp;
      Timestamp bTime = b['fechaInscripcion'] as Timestamp;
      return aTime.compareTo(bTime);
    });
    
    int cantidadDisponible = (correlativoFin - correlativoInicio) + 1;

    if (inscripciones.length > cantidadDisponible) {
      return false; // No hay suficientes números
    }

    // Asignar números en batch
    WriteBatch batch = _firestore.batch();
    int numeroActual = correlativoInicio;

    for (var doc in inscripciones) {
      batch.update(doc.reference, {
        'numeroAsignado': numeroActual,
        'updatedAt': Timestamp.now(),
      });
      numeroActual++;
    }

    await batch.commit();
    return true;
  } catch (e) {
    print('Error al asignar números: $e'); // Para debug
    return false;
  }
}

  // Obtener categorías con cantidad de participantes aprobados
  Future<Map<String, int>> getCategoriasCantidades(String eventoId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('inscriptions')
          .where('eventoId', isEqualTo: eventoId)
          .where('estado', isEqualTo: 'aprobado')
          .get();

      Map<String, int> categorias = {};
      for (var doc in snapshot.docs) {
        String categoria = doc['categoriaNombre'] ?? '';
        categorias[categoria] = (categorias[categoria] ?? 0) + 1;
      }

      return categorias;
    } catch (e) {
      return {};
    }
  }
}