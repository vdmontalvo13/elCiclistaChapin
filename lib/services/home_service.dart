import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class HomeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener conteo total de carreras
  Future<int> getTotalEvents() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('events').get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Obtener conteo de ciclistas activos
  Future<int> getTotalCyclists() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('rol', isEqualTo: 'ciclista')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Obtener todos los eventos activos
Future<List<EventModel>> getAllActiveEvents() async {
  try { 
    QuerySnapshot snapshot = await _firestore
        .collection('events')
        .where('estado', isEqualTo: 'activo')
        .get();

    List<EventModel> events = snapshot.docs
        .map((doc) => EventModel.fromFirestore(doc))
        .toList();

    // Ordenar por fecha
    events.sort((a, b) => a.fecha.compareTo(b.fecha));

    return events;
  } catch (e) {
    return [];
  }
}

  // Obtener próximos 5 eventos
 Future<List<EventModel>> getUpcomingEvents() async {
  try {
    DateTime now = DateTime.now();
    
    // Primero obtenemos todos los eventos activos SIN orderBy
    QuerySnapshot snapshot = await _firestore
        .collection('events')
        .where('estado', isEqualTo: 'activo')
        .get();  // <-- SIN .orderBy() aquí

    // Filtramos y ordenamos EN MEMORIA (no en Firestore)
    List<EventModel> allEvents = snapshot.docs
        .map((doc) => EventModel.fromFirestore(doc))
        .where((event) => event.fecha.isAfter(now))
        .toList();

    // Ordenar por fecha EN MEMORIA
    allEvents.sort((a, b) => a.fecha.compareTo(b.fecha));

    // Retornar solo los primeros 5
    List<EventModel> upcomingEvents = allEvents.take(5).toList();

    for (var event in upcomingEvents) {
      print('   - ${event.nombre} (${event.fecha})');
    }

    return upcomingEvents;
  } catch (e) {
    return [];
  }
}

  // Stream para actualizaciones en tiempo real
  Stream<int> getTotalEventsStream() {
    return _firestore.collection('events').snapshots().map((snapshot) {
      return snapshot.docs.length;
    });
  }

  Stream<int> getTotalCyclistsStream() {
    return _firestore
        .collection('users')
        .where('rol', isEqualTo: 'ciclista')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.length;
    });
  }
}