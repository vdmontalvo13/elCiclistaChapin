import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/colors.dart';
import '../../services/auth_service.dart';
import '../../services/home_service.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import 'package:el_ciclista_chapin/screens/events/events_screen.dart';
import '../events/event_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../my_races/my_races_screen.dart';
import '../organizer_events/organizer_events_screen.dart';
import '../../widgets/top_navbar.dart';

const double _kWebBreakpoint = 700;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeService _homeService = HomeService();
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      UserModel? user = await _authService.getUserData(firebaseUser.uid);
      setState(() => _currentUser = user);
    }
    setState(() => _isLoading = false);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _kWebBreakpoint) {
          return _buildWebScaffold();
        }
        return _buildMobileScaffold();
      },
    );
  }

  Widget _buildMobileScaffold() {
    return Scaffold(
      body: _selectedIndex == 0 ? _buildHomeContent() : _buildPlaceholder(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildWebScaffold() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          TopNavbar(
            selectedIndex: _selectedIndex,
            onTap: _onItemTapped,
            currentUser: _currentUser,
          ),
          Expanded(
            child: _selectedIndex == 0
                ? _buildWebHomeContent()
                : _buildPlaceholder(),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildBanner(), _buildStatsCards(), _buildUpcomingEvents()],
      ),
    );
  }

  Widget _buildWebHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBanner(),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCards(),
                  _buildWebUpcomingEvents(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxWidth >= _kWebBreakpoint
            ? (constraints.maxWidth * (7 / 16)).clamp(300.0, 520.0)
            : 300.0;
        return _buildBannerContent(height);
      },
    );
  }

  Widget _buildBannerContent(double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/images/portada.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.4),
            BlendMode.darken,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'El Ciclista Chapín',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(offset: Offset(0, 2), blurRadius: 4, color: Colors.black45),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Descubre y participa en las mejores\ncarreras de ciclismo',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  shadows: [
                    Shadow(offset: Offset(0, 1), blurRadius: 3, color: Colors.black45),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => setState(() => _selectedIndex = 1),
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                label: const Text(
                  'Ver Carreras',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Expanded(
            child: StreamBuilder<int>(
              stream: _homeService.getTotalEventsStream(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 1),
                  child: _buildStatCard(
                    icon: Icons.calendar_today,
                    count: count.toString(),
                    label: 'Carreras',
                    sublabel: 'Eventos programados',
                    color: AppColors.buttonPrimary,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: StreamBuilder<int>(
              stream: _homeService.getTotalCyclistsStream(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                final displayCount = count >= 1000
                    ? '${(count / 1000).toStringAsFixed(1)}k'
                    : count.toString();
                return _buildStatCard(
                  icon: Icons.people_outline,
                  count: displayCount,
                  label: 'Ciclistas',
                  sublabel: 'En tu comunidad',
                  color: const Color(0xFFFF8C42),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String count,
    required String label,
    required String sublabel,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                count,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
              ),
              Icon(icon, size: 36, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          Text(
            sublabel,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Próximas Carreras',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _selectedIndex = 1),
                icon: const Text('Ver todas'),
                label: const Icon(Icons.arrow_forward, size: 18),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
        FutureBuilder<List<EventModel>>(
          future: _homeService.getUpcomingEvents(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyEvents();
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) => _buildEventCard(snapshot.data![index]),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildWebUpcomingEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Próximas Carreras',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _selectedIndex = 1),
                icon: const Text('Ver todas'),
                label: const Icon(Icons.arrow_forward, size: 18),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
        FutureBuilder<List<EventModel>>(
          future: _homeService.getUpcomingEvents(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyEvents();
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.05,
              ),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) => _buildEventCard(snapshot.data![index]),
            );
          },
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildEmptyEvents() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay carreras próximas',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: event.imagenUrl.isNotEmpty
                      ? Image.network(
                          event.imagenUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                        )
                      : _buildImagePlaceholder(),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getDisciplinaColor(event.disciplina),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event.disciplina,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.nombre,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: AppColors.buttonPrimary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          DateFormat("dd 'de' MMMM, yyyy", 'es').format(event.fecha),
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.ubicacionCompleta,
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (event.categorias.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.groups, size: 16, color: Colors.green[600]),
                        const SizedBox(width: 6),
                        Text(
                          '${event.categorias.length} categorías',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 180,
      color: Colors.grey[300],
      child: const Icon(Icons.image, size: 64, color: Colors.grey),
    );
  }

  Color _getDisciplinaColor(String disciplina) {
    switch (disciplina.toLowerCase()) {
      case 'mtb':    return const Color(0xFF8B4513);
      case 'ruta':   return const Color(0xFFFF8C42);
      case 'gravel': return const Color(0xFF6B8E23);
      case 'urbano': return const Color(0xFF4682B4);
      default:       return AppColors.primary;
    }
  }

  Widget _buildPlaceholder() {
    switch (_selectedIndex) {
      case 1: return const EventsScreen();
      case 2: return _currentUser?.rol == 'organizador'
          ? const OrganizerEventsScreen()
          : const MyRacesScreen();
      case 3: return const ProfileScreen();
      default: return const Center(child: Text('Sección en construcción', style: TextStyle(fontSize: 24)));
    }
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.directions_bike_outlined),
          activeIcon: Icon(Icons.directions_bike),
          label: 'Carreras',
        ),
        BottomNavigationBarItem(
          icon: Icon(_selectedIndex == 2 ? Icons.emoji_events : Icons.emoji_events_outlined),
          label: _currentUser?.rol == 'organizador' ? 'Mis Eventos' : 'Mis Carreras',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}
