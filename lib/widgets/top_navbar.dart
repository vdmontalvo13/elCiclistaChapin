import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/user_model.dart';

/// Top navigation bar shown only on web (wide screens).
/// Replaces the BottomNavigationBar.
class TopNavbar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final UserModel? currentUser;

  const TopNavbar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final navLabel2 = currentUser?.rol == 'organizador' ? 'Mis Eventos' : 'Mis Carreras';

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(
          children: [
            // Logo + nombre (clic lleva al inicio)
            InkWell(
              onTap: () => onTap(0),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/logo.png', width: 38, height: 38),
                    const SizedBox(width: 10),
                    Text(
                      'El Ciclista Chapín',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Links de navegación
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavLink(label: 'Inicio', index: 0, selectedIndex: selectedIndex, onTap: onTap),
                _NavLink(label: 'Carreras', index: 1, selectedIndex: selectedIndex, onTap: onTap),
                _NavLink(label: navLabel2, index: 2, selectedIndex: selectedIndex, onTap: onTap),
                _NavLink(label: 'Perfil', index: 3, selectedIndex: selectedIndex, onTap: onTap),
              ],
            ),

            const Spacer(),

            // Iconos de la derecha
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: Colors.grey[700], size: 24),
              onPressed: () {},
              tooltip: 'Notificaciones',
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => onTap(3),
              borderRadius: BorderRadius.circular(18),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.buttonPrimary,
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _NavLink({
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;
    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.buttonPrimary : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: isSelected ? 24.0 : 0.0,
              decoration: BoxDecoration(
                color: AppColors.buttonPrimary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
