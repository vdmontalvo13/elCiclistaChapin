import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';
import '../../models/inscription_model.dart';
import '../../services/inscription_service.dart';

class InscriptionsTab extends StatefulWidget {
  final String eventId;

  const InscriptionsTab({super.key, required this.eventId});

  @override
  State<InscriptionsTab> createState() => _InscriptionsTabState();
}

class _InscriptionsTabState extends State<InscriptionsTab> {
  final InscriptionService _inscriptionService = InscriptionService();
  List<InscriptionModel> _todasInscripciones = [];
  List<InscriptionModel> _inscripcionesFiltradas = [];
  bool _isLoading = true;
  String _filtroEstado = 'en_progreso';

  @override
  void initState() {
    super.initState();
    _loadInscripciones();
  }

  @override
  void didUpdateWidget(InscriptionsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventId != widget.eventId) {
      _loadInscripciones();
    }
  }

  Future<void> _loadInscripciones() async {
    setState(() => _isLoading = true);

    List<InscriptionModel> inscripciones =
        await _inscriptionService.getInscripcionesPorEvento(widget.eventId);

    setState(() {
      _todasInscripciones = inscripciones;
      _aplicarFiltro();
      _isLoading = false;
    });
  }

  void _aplicarFiltro() {
    if (_filtroEstado == 'todas') {
      _inscripcionesFiltradas = _todasInscripciones;
    } else {
      _inscripcionesFiltradas =
          _todasInscripciones.where((i) => i.estado == _filtroEstado).toList();
    }
  }

  Future<void> _aprobarInscripcion(InscriptionModel inscripcion) async {
    bool success = await _inscriptionService.aprobarInscripcion(inscripcion.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inscripción aprobada'),
          backgroundColor: Colors.green,
        ),
      );
      _loadInscripciones();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al aprobar inscripción'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rechazarInscripcion(InscriptionModel inscripcion) async {
    final TextEditingController motivoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Inscripción'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de rechazar la inscripción de ${inscripcion.ciclistaNombre}?'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo del rechazo',
                hintText: 'Explica el motivo...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (motivoController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Debes proporcionar un motivo'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              bool success = await _inscriptionService.rechazarInscripcion(
                inscripcion.id,
                motivoController.text.trim(),
              );

              if (!mounted) return;
              Navigator.pop(context);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Inscripción rechazada'),
                    backgroundColor: Colors.orange,
                  ),
                );
                _loadInscripciones();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error al rechazar inscripción'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFiltroEstado(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _inscripcionesFiltradas.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadInscripciones,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _inscripcionesFiltradas.length,
                        itemBuilder: (context, index) {
                          return _buildInscripcionCard(_inscripcionesFiltradas[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFiltroEstado() {
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
                  _buildChipFiltro('En Progreso', 'en_progreso', Colors.orange),
                  const SizedBox(width: 8),
                  _buildChipFiltro('Aprobadas', 'aprobado', Colors.green),
                  const SizedBox(width: 8),
                  _buildChipFiltro('Rechazadas', 'rechazado', Colors.red),
                  const SizedBox(width: 8),
                  _buildChipFiltro('Todas', 'todas', Colors.blue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipFiltro(String label, String valor, Color color) {
    bool isSelected = _filtroEstado == valor;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filtroEstado = valor;
          _aplicarFiltro();
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
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${inscripcion.ciclistaNombre} ${inscripcion.ciclistaApellido}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Categoría: ${inscripcion.categoriaNombre}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _buildInfoRow('No. Boleta', inscripcion.numeroBoletaPago),
          const SizedBox(height: 8),
          _buildInfoRow('Banco', inscripcion.banco),
          const SizedBox(height: 8),
          _buildInfoRow(
              'Fecha de Pago', DateFormat('dd/MM/yyyy').format(inscripcion.fechaPago)),
          const SizedBox(height: 8),
          _buildInfoRow('Email', inscripcion.ciclistaEmail),
          const SizedBox(height: 8),
          _buildInfoRow('Teléfono', inscripcion.ciclistaTelefono),
          if (inscripcion.estado == 'en_progreso') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _aprobarInscripcion(inscripcion),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aprobar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rechazarInscripcion(inscripcion),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rechazar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (inscripcion.estado == 'rechazado' && inscripcion.motivoRechazo != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Motivo de rechazo:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    inscripcion.motivoRechazo!,
                    style: TextStyle(color: Colors.red[900], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    String mensaje = 'No hay inscripciones';
    String submensaje = 'Las inscripciones aparecerán aquí';

    if (_filtroEstado == 'en_progreso') {
      mensaje = 'No hay inscripciones en progreso';
      submensaje = 'Las nuevas inscripciones aparecerán aquí';
    } else if (_filtroEstado == 'aprobado') {
      mensaje = 'No hay inscripciones aprobadas';
      submensaje = 'Aprueba inscripciones para verlas aquí';
    } else if (_filtroEstado == 'rechazado') {
      mensaje = 'No hay inscripciones rechazadas';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              submensaje,
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