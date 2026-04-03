import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/user_model.dart';

/// Left navigation sidebar shown only on wide web screens (>= 1100px).
/// Provides the same navigation as TopNavbar but in a vertical panel.
class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final UserModel? currentUser;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final navLabel2 = currentUser?.rol == 'organizador' ? 'Mis Eventos' : 'Mis Carreras';

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _SidebarItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Inicio',
            index: 0,
            selectedIndex: selectedIndex,
            onTap: onTap,
          ),
          _SidebarItem(
            icon: Icons.directions_bike_outlined,
            activeIcon: Icons.directions_bike,
            label: 'Carreras',
            index: 1,
            selectedIndex: selectedIndex,
            onTap: onTap,
          ),
          _SidebarItem(
            icon: Icons.emoji_events_outlined,
            activeIcon: Icons.emoji_events,
            label: navLabel2,
            index: 2,
            selectedIndex: selectedIndex,
            onTap: onTap,
          ),
          _SidebarItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Perfil',
            index: 3,
            selectedIndex: selectedIndex,
            onTap: onTap,
          ),

          const Spacer(),

          // Info del usuario en la parte inferior
          if (currentUser != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.buttonPrimary,
                    child: const Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentUser!.nombreCompleto,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentUser!.rol == 'organizador' ? 'Organizador' : 'Ciclista',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _SidebarItem({
    required this.icon,
    required this.activeIcon,
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.buttonPrimary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.buttonPrimary : Colors.grey[600],
              size: 21,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.buttonPrimary : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
