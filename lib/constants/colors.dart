import 'package:flutter/material.dart';

class AppColors {
  // Colores del logo
  static const Color primary = Color(0xFF2D8B6E); // Verde del logo
  static const Color secondary = Color(0xFF8FBF3B); // Verde claro del logo
  static const Color accent = Color(0xFFFF6B6B); // Naranja del ciclista
  static const Color darkBlue = Color(0xFF1E3A5F); // Azul oscuro del logo

   // Color principal para botones
  static const Color buttonPrimary = Color.fromARGB(255, 9, 125, 141); // Tu color especificado
  
  // Colores adicionales
  static const Color lightCyan = Color.fromARGB(255, 155, 229, 238); // Celeste para splash y botones
  static const Color background = Color(0xFFF5F5F5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2C3E50);
  static const Color textLight = Color(0xFF7F8C8D);
  
  // Colores de estado
  static const Color approved = Color(0xFF4CAF50);
  static const Color pending = Color(0xFFFF9800);
  static const Color rejected = Color(0xFFF44336);

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4DD0E1), Color(0xFF2D8B6E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}