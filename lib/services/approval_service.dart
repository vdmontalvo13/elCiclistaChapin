import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class ApprovalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener organizadores pendientes de aprobación
  Future<List<UserModel>> getOrganizadoresPendientes() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('rol', isEqualTo: 'organizador')
          .where('estadoAprobacion', isEqualTo: 'pendiente')
          .orderBy('fechaSolicitud', descending: false)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  // Aprobar organizador
  Future<bool> aprobarOrganizador(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'estadoAprobacion': 'aprobado',
        'fechaAprobacion': Timestamp.now(),
        'motivoRechazo': null,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Rechazar organizador
  Future<bool> rechazarOrganizador(String uid, String motivo) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'estadoAprobacion': 'rechazado',
        'motivoRechazo': motivo,
        'fechaAprobacion': Timestamp.now(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Obtener historial de aprobaciones/rechazos
  Future<List<UserModel>> getHistorialAprobaciones() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('rol', isEqualTo: 'organizador')
          .where('estadoAprobacion', whereIn: ['aprobado', 'rechazado'])
          .orderBy('fechaAprobacion', descending: true)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }
}