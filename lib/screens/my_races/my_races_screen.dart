import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';
import '../../models/inscription_model.dart';
import '../../services/inscription_service.dart';
import '../events/event_inscription_screen.dart';
import 'inscription_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/event_model.dart';
import 'inscription_summary_screen.dart';

class MyRacesScreen extends StatefulWidget {
  const MyRacesScreen({super.key});

  @override
  State<MyRacesScreen> createState() => _MyRacesScreenState();
}

class _MyRacesScreenState extends State<MyRacesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InscriptionService _inscriptionService = InscriptionService();
  List<InscriptionModel> _inscripciones = [];
  bool _isLoading = true;
  String _filtroInscripciones = 'activas'; // 'activas', 'rechazadas', 'todas'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInscripciones();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInscripciones() async {
    setState(() => _isLoading = true);

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      List<InscriptionModel> inscripciones = await _inscriptionService
          .getInscripcionesCiclista(user.uid);

      setState(() {
        _inscripciones = inscripciones;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  List<InscriptionModel> get _inscripcionesFiltradas {
    if (_filtroInscripciones == 'activas') {
      return _inscripciones
          .where((i) => i.estado == 'en_progreso' || i.estado == 'aprobado')
          .toList();
    } else if (_filtroInscripciones == 'rechazadas') {
      return _inscripciones.where((i) => i.estado == 'rechazado').toList();
    } else {
      return _inscripciones;
    }
  }

  List<InscriptionModel> get _proximasCarreras =>
      _inscripciones.where((i) => i.estado == 'aprobado').toList();

  int get _countResultados => 0; // Para futuro

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMisInscripcionesTab(),
                      _buildProximasTab(),
                      _buildResultadosTab(),
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
          colors: [
            AppColors.buttonPrimary,
            AppColors.buttonPrimary.withOpacity(0.8),
          ],
        ),
      ),
      child: const Text(
        'Mis Carreras',
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
        tabs: [
          Tab(text: 'Mis Inscripciones (${_inscripciones.length})'),
          Tab(text: 'Próximas (${_proximasCarreras.length})'),
          Tab(text: 'Resultados ($_countResultados)'),
        ],
      ),
    );
  }

  // TAB 1: MIS INSCRIPCIONES
  Widget _buildMisInscripcionesTab() {
    return Column(
      children: [
        _buildFiltroInscripciones(),
        Expanded(
          child: _inscripcionesFiltradas.isEmpty
              ? _buildEmptyState(
                  icon: Icons.assignment_outlined,
                  title: _getEmptyTitle(),
                  subtitle: _getEmptySubtitle(),
                )
              : RefreshIndicator(
                  onRefresh: _loadInscripciones,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _inscripcionesFiltradas.length,
                    itemBuilder: (context, index) {
                      return _buildInscripcionCard(
                        _inscripcionesFiltradas[index],
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  String _getEmptyTitle() {
    if (_filtroInscripciones == 'activas') {
      return 'No tienes inscripciones activas';
    } else if (_filtroInscripciones == 'rechazadas') {
      return 'No tienes inscripciones rechazadas';
    }
    return 'No tienes inscripciones';
  }

  String _getEmptySubtitle() {
    if (_filtroInscripciones == 'activas') {
      return 'Ve a la sección de Carreras para inscribirte';
    } else if (_filtroInscripciones == 'rechazadas') {
      return 'Aquí aparecerán las inscripciones rechazadas';
    }
    return 'Ve a la sección de Carreras para inscribirte';
  }

  Widget _buildFiltroInscripciones() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            'Filtrar:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChipFiltro('Activas', 'activas', Colors.blue),
                  const SizedBox(width: 8),
                  _buildChipFiltro('Rechazadas', 'rechazadas', Colors.red),
                  const SizedBox(width: 8),
                  _buildChipFiltro('Todas', 'todas', Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipFiltro(String label, String valor, Color color) {
    bool isSelected = _filtroInscripciones == valor;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filtroInscripciones = valor;
        });
      },
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(color: isSelected ? color : Colors.grey[300]!),
    );
  }

  Widget _buildInscripcionCard(InscriptionModel inscripcion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Header con estado
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: inscripcion.getEstadoColor().withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    inscripcion.eventoNombre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: inscripcion.getEstadoColor(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    inscripcion.getEstadoTexto(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.category, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Categoría: ${inscripcion.categoriaNombre}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Inscripción: ${DateFormat('dd/MM/yyyy').format(inscripcion.fechaInscripcion)}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ],
                ),

                // Motivo de rechazo
                if (inscripcion.estado == 'rechazado' &&
                    inscripcion.motivoRechazo != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.red[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Motivo de rechazo:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          inscripcion.motivoRechazo!,
                          style: TextStyle(
                            color: Colors.red[900],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Botones de acción
                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InscriptionSummaryScreen(
                                inscription: inscripcion,
                              ), 
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.buttonPrimary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Ver Detalles',
                          style: TextStyle(color: AppColors.buttonPrimary),
                        ),
                      ),
                    ),
                    if (inscripcion.estado == 'rechazado') ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            DocumentSnapshot eventDoc = await FirebaseFirestore
                                .instance
                                .collection('events')
                                .doc(inscripcion.eventoId)
                                .get();

                            if (eventDoc.exists && mounted) {
                              EventModel event = EventModel.fromFirestore(
                                eventDoc,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EventInscriptionScreen(event: event),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Reintentar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: PRÓXIMAS
  Widget _buildProximasTab() {
    if (_proximasCarreras.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_available,
        title: 'No tienes carreras próximas',
        subtitle: 'Las carreras con inscripción aprobada aparecerán aquí',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInscripciones,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _proximasCarreras.length,
        itemBuilder: (context, index) {
          return _buildProximaCarreraCard(_proximasCarreras[index]);
        },
      ),
    );
  }

  Widget _buildProximaCarreraCard(InscriptionModel inscripcion) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('events')
          .doc(inscripcion.eventoId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        EventModel event = EventModel.fromFirestore(snapshot.data!);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
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
              // Imagen del evento
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      event.imagenUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Inscrito',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InscriptionDetailScreen(
                                inscription: inscripcion,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Ver Detalles',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // TAB 3: RESULTADOS (DUMMY)
  Widget _buildResultadosTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.buttonPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events,
                size: 80,
                color: AppColors.buttonPrimary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Resultados Próximamente',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aquí podrás ver tus resultados, posiciones y tiempos de todas las carreras en las que has participado.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildFeatureItem(Icons.timer, 'Tiempos oficiales'),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    Icons.emoji_events,
                    'Posiciones por categoría',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    Icons.show_chart,
                    'Estadísticas personales',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(Icons.share, 'Compartir logros'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.buttonPrimary),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
