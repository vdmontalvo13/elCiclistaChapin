import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../constants/colors.dart';
import '../../models/inscription_model.dart';
import '../../services/inscription_service.dart';

class ParticipantsTab extends StatefulWidget {
  final String eventId;
  final String eventName;

  const ParticipantsTab({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<ParticipantsTab> createState() => _ParticipantsTabState();
}

class _ParticipantsTabState extends State<ParticipantsTab> {
  final InscriptionService _inscriptionService = InscriptionService();
  List<InscriptionModel> _participantes = [];
  Map<String, List<InscriptionModel>> _participantesPorCategoria = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParticipantes();
  }

  @override
  void didUpdateWidget(ParticipantsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventId != widget.eventId) {
      _loadParticipantes();
    }
  }

  Future<void> _loadParticipantes() async {
    setState(() => _isLoading = true);

    List<InscriptionModel> participantes =
        await _inscriptionService.getParticipantesAprobados(widget.eventId);

    Map<String, List<InscriptionModel>> porCategoria = {};
    for (var participante in participantes) {
      if (!porCategoria.containsKey(participante.categoriaNombre)) {
        porCategoria[participante.categoriaNombre] = [];
      }
      porCategoria[participante.categoriaNombre]!.add(participante);
    }

    setState(() {
      _participantes = participantes;
      _participantesPorCategoria = porCategoria;
      _isLoading = false;
    });
  }

  void _showAsignacionModal(String categoria, List<InscriptionModel> participantes) {
    final TextEditingController inicioController = TextEditingController();
    final TextEditingController finController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Asignar Números - $categoria'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total de participantes: ${participantes.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: inicioController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Correlativo Inicio',
                border: OutlineInputBorder(),
                hintText: 'Ej: 1',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: finController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Correlativo Final',
                border: OutlineInputBorder(),
                hintText: 'Ej: 50',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Los números se asignarán en orden de inscripción',
                      style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                    ),
                  ),
                ],
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
              int? inicio = int.tryParse(inicioController.text);
              int? fin = int.tryParse(finController.text);

              if (inicio == null || fin == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ingresa números válidos'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              if (fin < inicio) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El correlativo final debe ser mayor al inicial'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              int cantidadDisponible = (fin - inicio) + 1;

              if (cantidadDisponible < participantes.length) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'No hay suficientes números. Necesitas ${participantes.length} números.',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final dialogContext = context;
              Navigator.pop(dialogContext);

              final scaffoldContext = this.context;

              showDialog(
                context: scaffoldContext,
                barrierDismissible: false,
                builder: (loadingContext) => WillPopScope(
                  onWillPop: () async => false,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );

              try {
                bool success = await _inscriptionService.asignarNumeros(
                  eventoId: widget.eventId,
                  categoria: categoria,
                  correlativoInicio: inicio,
                  correlativoFin: fin,
                );

                if (Navigator.canPop(scaffoldContext)) {
                  Navigator.pop(scaffoldContext);
                }

                if (success) {
                  if (mounted) {
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      const SnackBar(
                        content: Text('Números asignados correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadParticipantes();
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      const SnackBar(
                        content: Text('Error: No hay suficientes números disponibles'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (Navigator.canPop(scaffoldContext)) {
                  Navigator.pop(scaffoldContext);
                }

                if (mounted) {
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
            ),
            child: const Text('Asignar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _generarPDF() async {
    final pdf = pw.Document();

    for (var categoria in _participantesPorCategoria.keys) {
      final participantes = _participantesPorCategoria[categoria]!;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  widget.eventName,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Categoría: $categoria',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        _buildPdfCell('Número', isHeader: true),
                        _buildPdfCell('Nombre', isHeader: true),
                        _buildPdfCell('Apellido', isHeader: true),
                        _buildPdfCell('Categoría', isHeader: true),
                      ],
                    ),
                    ...participantes.map((p) {
                      return pw.TableRow(
                        children: [
                          _buildPdfCell(
                            p.numeroAsignado?.toString() ?? 'N/A',
                          ),
                          _buildPdfCell(p.ciclistaNombre),
                          _buildPdfCell(p.ciclistaApellido),
                          _buildPdfCell(p.categoriaNombre),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildPdfCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 12 : 10,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_participantes.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generarPDF,
              icon: const Icon(Icons.download),
              label: const Text('Descargar Listado PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _participantesPorCategoria.keys.length,
            itemBuilder: (context, index) {
              String categoria = _participantesPorCategoria.keys.elementAt(index);
              List<InscriptionModel> participantes =
                  _participantesPorCategoria[categoria]!;

              return _buildCategoriaCard(categoria, participantes);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriaCard(String categoria, List<InscriptionModel> participantes) {
    bool todosAsignados = participantes.every((p) => p.numeroAsignado != null);

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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            categoria,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            '${participantes.length} participantes',
            style: TextStyle(color: Colors.grey[600]),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (todosAsignados)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Asignado',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.expand_more),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAsignacionModal(categoria, participantes),
                      icon: const Icon(Icons.confirmation_number, size: 18),
                      label: Text(todosAsignados ? 'Reasignar Números' : 'Asignar Números'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...participantes.map((participante) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: participante.numeroAsignado != null
                                  ? AppColors.buttonPrimary
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                participante.numeroAsignado?.toString() ?? '-',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${participante.ciclistaNombre} ${participante.ciclistaApellido}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  participante.ciclistaEmail,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'No hay participantes aprobados',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aprueba inscripciones en la pestaña "Inscripciones"',
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