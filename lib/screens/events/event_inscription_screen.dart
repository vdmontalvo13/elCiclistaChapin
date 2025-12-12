import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../models/inscription_model.dart';
import '../../services/auth_service.dart';
import '../../services/inscription_service.dart';

class EventInscriptionScreen extends StatefulWidget {
  final EventModel event;

  const EventInscriptionScreen({super.key, required this.event});

  @override
  State<EventInscriptionScreen> createState() => _EventInscriptionScreenState();
}

class _EventInscriptionScreenState extends State<EventInscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final InscriptionService _inscriptionService = InscriptionService();

  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isSubmitting = false;

  String? _selectedCategoria;
  final TextEditingController _numeroBoletaController = TextEditingController();
  final TextEditingController _bancoController = TextEditingController();
  DateTime? _fechaPago;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _numeroBoletaController.dispose();
    _bancoController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      UserModel? user = await _authService.getUserData(firebaseUser.uid);
      if (user != null) {
        setState(() => _currentUser = user);

        // Verificar si ya está inscrito
        InscriptionModel? inscripcionExistente = await _inscriptionService
            .getInscripcionExistente(user.uid, widget.event.id);

        if (inscripcionExistente != null && mounted) {
          // Ya está inscrito
          _showAlreadyInscribedDialog(inscripcionExistente);
        }
      }
    }

    setState(() => _isLoading = false);
  }

  void _showAlreadyInscribedDialog(InscriptionModel inscripcion) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Ya estás inscrito'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ya tienes una inscripción en este evento.'),
            const SizedBox(height: 8),
            Text(
              'Estado: ${inscripcion.getEstadoTexto()}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: inscripcion.getEstadoColor(),
              ),
            ),
            if (inscripcion.estado == 'rechazado' && inscripcion.motivoRechazo != null) ...[
              const SizedBox(height: 8),
              const Text('Motivo de rechazo:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(inscripcion.motivoRechazo!),
              const SizedBox(height: 8),
              const Text(
                'Puedes intentar inscribirte nuevamente.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          if (inscripcion.estado == 'rechazado')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Permitir re-inscripción
              },
              child: const Text('Volver a intentar'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFechaPago() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.buttonPrimary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _fechaPago = picked);
    }
  }

  void _showConfirmationDialog() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoria == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una categoría'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_fechaPago == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona la fecha de pago'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Inscripción'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConfirmItem('Evento', widget.event.nombre),
              _buildConfirmItem('Categoría', _selectedCategoria!),
              const Divider(),
              _buildConfirmItem('Nombre', '${_currentUser!.nombre} ${_currentUser!.apellido}'),
              _buildConfirmItem('Email', _currentUser!.email),
              _buildConfirmItem('Teléfono', _currentUser!.telefono),
              const Divider(),
              _buildConfirmItem('No. Boleta', _numeroBoletaController.text),
              _buildConfirmItem('Banco', _bancoController.text),
              _buildConfirmItem('Fecha Pago', DateFormat('dd/MM/yyyy').format(_fechaPago!)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Editar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitInscription();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
            ),
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitInscription() async {
    setState(() => _isSubmitting = true);

    bool success = await _inscriptionService.createInscription(
      eventoId: widget.event.id,
      eventoNombre: widget.event.nombre,
      ciclistaId: _currentUser!.uid,
      ciclistaNombre: _currentUser!.nombre,
      ciclistaApellido: _currentUser!.apellido,
      ciclistaEmail: _currentUser!.email,
      ciclistaTelefono: _currentUser!.telefono,
      categoriaNombre: _selectedCategoria!,
      numeroBoletaPago: _numeroBoletaController.text,
      banco: _bancoController.text,
      fechaPago: _fechaPago!,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('¡Inscripción Exitosa!'),
          content: const Text(
            'Tu inscripción ha sido enviada y está en proceso de revisión. '
            'Recibirás una notificación cuando sea aprobada.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
              ),
              child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al crear inscripción'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Inscripción'),
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Inscripción'),
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Error al cargar datos del usuario')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Inscripción'),
        backgroundColor: AppColors.buttonPrimary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Información del Evento'),
              const SizedBox(height: 12),
              _buildEventCard(),
              const SizedBox(height: 24),

              _buildSectionTitle('Tus Datos'),
              const SizedBox(height: 12),
              _buildUserDataCard(),
              const SizedBox(height: 24),

              _buildSectionTitle('Categoría'),
              const SizedBox(height: 12),
              _buildCategoriaSelector(),
              const SizedBox(height: 24),

              if (widget.event.cuentaBancaria.isNotEmpty) ...[
                _buildSectionTitle('Información de Pago'),
                const SizedBox(height: 12),
                _buildCuentaBancariaCard(),
                const SizedBox(height: 24),
              ],

              _buildSectionTitle('Datos de Pago'),
              const SizedBox(height: 12),
              _buildPaymentForm(),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _showConfirmationDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Inscribirse',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildEventCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.event.nombre,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                DateFormat('dd \'de\' MMMM, yyyy', 'es').format(widget.event.fecha),
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                widget.event.ubicacionCompleta,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserDataCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDataRow('Nombre', '${_currentUser!.nombre} ${_currentUser!.apellido}'),
          const SizedBox(height: 8),
          _buildDataRow('Email', _currentUser!.email),
          const SizedBox(height: 8),
          _buildDataRow('Teléfono', _currentUser!.telefono),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildCategoriaSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecciona tu categoría:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ...widget.event.categorias.map((cat) {
            String nombre = cat['nombre'] ?? '';
            return RadioListTile<String>(
              title: Text(nombre),
              subtitle: Text(
                '${cat['edadMin']}-${cat['edadMax']} años • ${cat['distancia']} • Q${cat['precioInscripcion']}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              value: nombre,
              groupValue: _selectedCategoria,
              activeColor: AppColors.buttonPrimary,
              onChanged: (value) {
                setState(() => _selectedCategoria = value);
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCuentaBancariaCard() {
    return Container(
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
            children: [
              Icon(Icons.account_balance, color: AppColors.buttonPrimary),
              const SizedBox(width: 8),
              const Text(
                'Cuenta para depósito',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.event.cuentaBancaria,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _numeroBoletaController,
            decoration: const InputDecoration(
              labelText: 'Número de Boleta',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bancoController,
            decoration: const InputDecoration(
              labelText: 'Banco',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _selectFechaPago,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: AppColors.buttonPrimary),
                  const SizedBox(width: 12),
                  Text(
                    _fechaPago == null
                        ? 'Fecha de Pago'
                        : DateFormat('dd/MM/yyyy').format(_fechaPago!),
                    style: TextStyle(
                      fontSize: 16,
                      color: _fechaPago == null ? Colors.grey[600] : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
            ),
            child: Row(
              children: [
                Icon(Icons.image, size: 40, color: Colors.grey[400]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Imagen de boleta (opcional)\nFuncionalidad próximamente',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}