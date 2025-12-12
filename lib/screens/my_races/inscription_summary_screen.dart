import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';
import '../../models/inscription_model.dart';
import '../../models/event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InscriptionSummaryScreen extends StatefulWidget {
  final InscriptionModel inscription;

  const InscriptionSummaryScreen({super.key, required this.inscription});

  @override
  State<InscriptionSummaryScreen> createState() => _InscriptionSummaryScreenState();
}

class _InscriptionSummaryScreenState extends State<InscriptionSummaryScreen> {
  EventModel? _event;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEventDetails();
  }

  Future<void> _loadEventDetails() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.inscription.eventoId)
          .get();

      if (doc.exists) {
        setState(() {
          _event = EventModel.fromFirestore(doc);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? _getCategoriaDetails() {
    if (_event == null) return null;

    for (var categoria in _event!.categorias) {
      if (categoria['nombre'] == widget.inscription.categoriaNombre) {
        return categoria;
      }
    }
    return null;
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copiado al portapapeles'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: Colors.white,
          title: const Text('Detalle de Inscripción'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: Colors.white,
          title: const Text('Detalle de Inscripción'),
        ),
        body: const Center(child: Text('Error al cargar evento')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.buttonPrimary,
        foregroundColor: Colors.white,
        title: const Text('Detalle de Inscripción'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildInscriptionDetails(),
      ),
    );
  }

  Widget _buildInscriptionDetails() {
    Map<String, dynamic>? categoria = _getCategoriaDetails();

    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Detalle de Inscripción',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Categoría
          if (categoria != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.buttonPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.buttonPrimary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        categoria['nombre'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.buttonPrimary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Q${categoria['precioInscripcion']}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${categoria['edadMin']}-${categoria['edadMax']} años • ${categoria['genero']}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        categoria['distancia'] ?? '',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.terrain, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        categoria['elevacion'] ?? '',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Datos de pago
          const Text(
            'Datos de Pago',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          _buildPaymentDetail(
            'Número de Boleta',
            widget.inscription.numeroBoletaPago,
            canCopy: true,
          ),
          const SizedBox(height: 8),
          _buildPaymentDetail('Banco', widget.inscription.banco),
          const SizedBox(height: 8),
          _buildPaymentDetail(
            'Fecha de Pago',
            DateFormat('dd/MM/yyyy').format(widget.inscription.fechaPago),
          ),

          // Motivo de rechazo si aplica
          if (widget.inscription.estado == 'rechazado' &&
              widget.inscription.motivoRechazo != null) ...[
            const SizedBox(height: 16),
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
                      Icon(Icons.info_outline, size: 18, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Motivo de Rechazo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.inscription.motivoRechazo!,
                    style: TextStyle(color: Colors.red[900], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentDetail(String label, String value, {bool canCopy = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            if (canCopy) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _copyToClipboard(value),
                child: Icon(
                  Icons.copy,
                  size: 16,
                  color: AppColors.buttonPrimary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}