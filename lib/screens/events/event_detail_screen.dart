import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';
import '../../models/event_model.dart';
import 'event_inscription_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) {
          return _buildWebScaffold(context);
        }
        return _buildMobileScaffold(context);
      },
    );
  }

  // ─── MOBILE ──────────────────────────────────────────────────────────────

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildMobileAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMainInfo(),
                _buildDescription(),
                _buildCategories(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildInscriptionButton(context),
    );
  }

  Widget _buildMobileAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.buttonPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildBannerImage(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                ),
              ),
            ),
            Positioned(
              bottom: 60,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDisciplinaChip(),
                  const SizedBox(height: 12),
                  Text(
                    event.nombre,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(offset: Offset(0, 2), blurRadius: 4, color: Colors.black45)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── WEB ─────────────────────────────────────────────────────────────────

  Widget _buildWebScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildWebBanner(context),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildWebInfoCards()),
                          const SizedBox(width: 24),
                          _buildWebInscriptionCard(context),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildWebDescription(),
                      const SizedBox(height: 16),
                      _buildWebCategories(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebBanner(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 420,
          width: double.infinity,
          child: _buildBannerImage(),
        ),
        Container(
          height: 420,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 24,
          child: SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 48,
          right: 48,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDisciplinaChip(),
              const SizedBox(height: 16),
              Text(
                event.nombre,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(offset: Offset(0, 2), blurRadius: 6, color: Colors.black45)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebInfoCards() {
    return Row(
      children: [
        Expanded(
          child: _buildWebInfoCard(
            icon: Icons.calendar_today,
            label: 'FECHA',
            value: DateFormat("dd 'de' MMMM\nyyyy", 'es').format(event.fecha),
            color: AppColors.buttonPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildWebInfoCard(
            icon: Icons.location_on,
            label: 'UBICACIÓN',
            value: event.ubicacion['municipio'] ?? event.ubicacionCompleta.split(',')[0],
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildWebInfoCard(
            icon: Icons.people,
            label: 'CUPOS',
            value: event.cuposDisponibles.toString(),
            color: Colors.green[600]!,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildWebInfoCard(
            icon: Icons.attach_money,
            label: 'INSCRIPCIÓN',
            value: event.categorias.isNotEmpty
                ? 'Q${event.categorias[0]['precioInscripcion']}'
                : 'Q200',
            color: Colors.blue[600]!,
          ),
        ),
      ],
    );
  }

  Widget _buildWebInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildWebInscriptionCard(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.buttonPrimary, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inscríbete Ahora',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.buttonPrimary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EventInscriptionScreen(event: event)),
              ),
              icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
              label: const Text(
                'Inscribirse',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
                padding: const EdgeInsets.symmetric(vertical: 28),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebDescription() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Descripción',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Text(
            event.descripcion,
            style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildWebCategories() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categorías',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3.2,
            ),
            itemCount: event.categorias.length,
            itemBuilder: (context, index) {
              final categoria = event.categorias[index];
              final edadMin = categoria['edadMin'];
              final edadMax = categoria['edadMax'];
              final edadLabel = (edadMin != null && edadMax != null)
                  ? '$edadMin-$edadMax años'
                  : 'Edad Libre';
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            categoria['nombre'] ?? 'Sin nombre',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.buttonPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            edadLabel,
                            style: TextStyle(fontSize: 11, color: AppColors.buttonPrimary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      categoria['descripcion'] ?? '${categoria['distancia'] ?? 'N/A'} • ${categoria['elevacion'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── SHARED ───────────────────────────────────────────────────────────────

  Widget _buildBannerImage() {
    return event.imagenUrl.isNotEmpty
        ? Image.network(
            event.imagenUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.image, size: 80, color: Colors.grey),
            ),
          )
        : Container(
            color: Colors.grey[300],
            child: const Icon(Icons.image, size: 80, color: Colors.grey),
          );
  }

  Widget _buildDisciplinaChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getDisciplinaColor(event.disciplina),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        event.disciplina.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildMainInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.calendar_today,
                  label: 'Fecha',
                  value: DateFormat("dd 'de'\nMMMM, yyyy", 'es').format(event.fecha),
                  color: AppColors.buttonPrimary,
                ),
              ),
              Container(width: 1, height: 60, color: Colors.grey[300]),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.location_on,
                  label: 'Ubicación',
                  value: event.ubicacion['municipio'] ?? event.ubicacionCompleta.split(',')[0],
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.people,
                  label: 'Cupos',
                  value: event.cuposDisponibles.toString(),
                  color: Colors.green[600]!,
                ),
              ),
              Container(width: 1, height: 60, color: Colors.grey[300]),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.attach_money,
                  label: 'Inscripción',
                  value: event.categorias.isNotEmpty
                      ? 'Q${event.categorias[0]['precioInscripcion']}'
                      : 'Q200',
                  color: Colors.blue[600]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Descripción',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Text(
            event.descripcion,
            style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categorías',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          ...event.categorias.map((categoria) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoria['nombre'] ?? 'Sin nombre',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${categoria['distancia'] ?? 'N/A'} • ${categoria['elevacion'] ?? 'N/A'}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${categoria['edadMin']}-${categoria['edadMax']} años',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInscriptionButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EventInscriptionScreen(event: event)),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'Inscribirse Ahora',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
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
}
