import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/colors.dart';
import '../../models/event_model.dart';
import '../../services/profile_service.dart';
import 'my_events_tab.dart';
import 'inscriptions_tab.dart';
import 'participants_tab.dart';

class OrganizerEventsScreen extends StatefulWidget {
  const OrganizerEventsScreen({super.key});

  @override
  State<OrganizerEventsScreen> createState() => _OrganizerEventsScreenState();
}

class _OrganizerEventsScreenState extends State<OrganizerEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProfileService _profileService = ProfileService();

  List<EventModel> _eventos = [];
  String? _selectedEventId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEventos();

    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEventos() async {
    setState(() => _isLoading = true);

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      List<EventModel> eventos = await _profileService.getEventosPorOrganizador(user.uid);
      setState(() {
        _eventos = eventos;
        if (_eventos.isNotEmpty && _selectedEventId == null) {
          _selectedEventId = _eventos.first.id;
        }
      });
    }

    setState(() => _isLoading = false);
  }

  EventModel? get _selectedEvent {
    if (_selectedEventId == null) return null;
    try {
      return _eventos.firstWhere((e) => e.id == _selectedEventId);
    } catch (e) {
      return null;
    }
  }

  bool get _shouldShowEventSelector {
    return _tabController.index != 0 && _eventos.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          if (_shouldShowEventSelector) _buildEventSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                MyEventsTab(onEventChanged: _loadEventos),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _eventos.isEmpty
                        ? _buildEmptyEventsState()
                        : InscriptionsTab(
                            eventId: _selectedEventId!,
                            key: ValueKey(_selectedEventId),
                          ),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _eventos.isEmpty
                        ? _buildEmptyEventsState()
                        : ParticipantsTab(
                            eventId: _selectedEventId!,
                            eventName: _selectedEvent?.nombre ?? '',
                            key: ValueKey(_selectedEventId),
                          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.buttonPrimary, AppColors.buttonPrimary.withOpacity(0.8)],
        ),
      ),
      child: const Text(
        'Mis Eventos',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.buttonPrimary,
        labelColor: AppColors.buttonPrimary,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: 'Mis Eventos'),
          Tab(text: 'Inscripciones'),
          Tab(text: 'Participantes'),
        ],
      ),
    );
  }

  Widget _buildEventSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seleccionar Evento',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedEventId,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _eventos.map((evento) {
              return DropdownMenuItem(
                value: evento.id,
                child: Text(
                  evento.nombre,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedEventId = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyEventsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'No tienes eventos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea un evento en la pestaña "Mis Eventos"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}