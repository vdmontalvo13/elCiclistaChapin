import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final String rol;
  final String? ciclismoPreferido;
  final String? genero;
  final DateTime? fechaNacimiento;
  final String? descripcion;
  final String? fotoPerfil;

  UserModel({
    required this.uid,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    required this.rol,
    this.ciclismoPreferido,
    this.genero,
    this.fechaNacimiento,
    this.descripcion,
    this.fotoPerfil,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    DateTime? parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return UserModel(
      uid: doc.id,
      nombre: data['nombre'] ?? '',
      apellido: data['apellido'] ?? '',
      email: data['email'] ?? '',
      telefono: data['telefono'] ?? '',
      rol: data['rol'] ?? 'ciclista',
      ciclismoPreferido: data['ciclismoPreferido'],
      genero: data['genero'],
      fechaNacimiento: parseTimestamp(data['fechaNacimiento']),
      descripcion: data['descripcion'],
      fotoPerfil: data['fotoPerfil'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'rol': rol,
      'ciclismoPreferido': ciclismoPreferido,
      'genero': genero,
      'fechaNacimiento': fechaNacimiento != null ? Timestamp.fromDate(fechaNacimiento!) : null,
      'descripcion': descripcion,
      'fotoPerfil': fotoPerfil,
    };
  }

  String get nombreCompleto => '$nombre $apellido';
}