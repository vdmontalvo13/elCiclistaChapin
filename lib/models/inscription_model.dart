import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InscriptionModel {
  final String id;
  final String eventoId;
  final String eventoNombre;
  final String ciclistaId;
  final String ciclistaNombre;
  final String ciclistaApellido;
  final String ciclistaEmail;
  final String ciclistaTelefono;
  final String categoriaNombre;
  final String numeroBoletaPago;
  final String banco;
  final DateTime fechaPago;
  final String? imagenBoleta;
  final String estado;
  final String? motivoRechazo;
  final int? numeroAsignado;
  final DateTime fechaInscripcion;
  final DateTime updatedAt;

  InscriptionModel({
    required this.id,
    required this.eventoId,
    required this.eventoNombre,
    required this.ciclistaId,
    required this.ciclistaNombre,
    required this.ciclistaApellido,
    required this.ciclistaEmail,
    required this.ciclistaTelefono,
    required this.categoriaNombre,
    required this.numeroBoletaPago,
    required this.banco,
    required this.fechaPago,
    this.imagenBoleta,
    required this.estado,
    this.motivoRechazo,
    this.numeroAsignado,
    required this.fechaInscripcion,
    required this.updatedAt,
  });

  factory InscriptionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    DateTime parseTimestamp(dynamic value, DateTime defaultValue) {
      if (value == null) return defaultValue;
      if (value is Timestamp) return value.toDate();
      return defaultValue;
    }

    return InscriptionModel(
      id: doc.id,
      eventoId: data['eventoId'] ?? '',
      eventoNombre: data['eventoNombre'] ?? '',
      ciclistaId: data['ciclistaId'] ?? '',
      ciclistaNombre: data['ciclistaNombre'] ?? '',
      ciclistaApellido: data['ciclistaApellido'] ?? '',
      ciclistaEmail: data['ciclistaEmail'] ?? '',
      ciclistaTelefono: data['ciclistaTelefono'] ?? '',
      categoriaNombre: data['categoriaNombre'] ?? '',
      numeroBoletaPago: data['numeroBoletaPago'] ?? '',
      banco: data['banco'] ?? '',
      fechaPago: parseTimestamp(data['fechaPago'], DateTime.now()),
      imagenBoleta: data['imagenBoleta'],
      estado: data['estado'] ?? 'en_progreso',
      motivoRechazo: data['motivoRechazo'],
      numeroAsignado: data['numeroAsignado'],
      fechaInscripcion: parseTimestamp(data['fechaInscripcion'], DateTime.now()),
      updatedAt: parseTimestamp(data['updatedAt'], DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
      'estado': estado,
      'motivoRechazo': motivoRechazo,
      'numeroAsignado': numeroAsignado,
      'fechaInscripcion': Timestamp.fromDate(fechaInscripcion),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Color getEstadoColor() {
    switch (estado) {
      case 'aprobado':
        return const Color(0xFF4CAF50);
      case 'rechazado':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFFFF9800);
    }
  }

  String getEstadoTexto() {
    switch (estado) {
      case 'aprobado':
        return 'Aprobada';
      case 'rechazado':
        return 'Rechazada';
      default:
        return 'En Progreso';
    }
  }
}