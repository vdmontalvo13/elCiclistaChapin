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
  bool _categoriasVisible = true;

  String? _selectedCategoria;
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _numeroBoletaController = TextEditingController();
  final TextEditingController _bancoEmisorController = TextEditingController();
  DateTime? _fechaPago;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _numeroBoletaController.dispose();
    _bancoEmisorController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      final user = await _authService.getUserData(firebaseUser.uid);
      if (user != null) {
        setState(() {
          _currentUser = user;
          _nombreController.text = '${user.nombre} ${user.apellido}';
          _emailController.text = user.email;
          _telefonoController.text = user.telefono;
        });
        final inscripcionExistente = await _inscriptionService
            .getInscripcionExistente(user.uid, widget.event.id);
        if (inscripcionExistente != null && mounted) {
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
            const Text('Ya tienes una inscripción en este evento.'),
            const SizedBox(height: 8),
            Text(
              'Estado: ${inscripcion.getEstadoTexto()}',
              style: TextStyle(fontWeight: FontWeight.bold, color: inscripcion.getEstadoColor()),
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
              onPressed: () => Navigator.pop(context),
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
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.buttonPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fechaPago = picked);
  }

  void _showConfirmationDialog() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoria == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_fechaPago == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha de pago'), backgroundColor: Colors.orange),
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
              _buildConfirmItem('Nombre', _nombreController.text),
              _buildConfirmItem('Email', _emailController.text),
              _buildConfirmItem('Teléfono', _telefonoController.text),
              const Divider(),
              _buildConfirmItem('No. Boleta', _numeroBoletaController.text),
              _buildConfirmItem('Banco', _bancoEmisorController.text),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonPrimary),
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
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _submitInscription() async {
    setState(() => _isSubmitting = true);
    final success = await _inscriptionService.createInscription(
      eventoId: widget.event.id,
      eventoNombre: widget.event.nombre,
      ciclistaId: _currentUser!.uid,
      ciclistaNombre: _currentUser!.nombre,
      ciclistaApellido: _currentUser!.apellido,
      ciclistaEmail: _emailController.text,
      ciclistaTelefono: _telefonoController.text,
      categoriaNombre: _selectedCategoria!,
      numeroBoletaPago: _numeroBoletaController.text,
      banco: _bancoEmisorController.text,
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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonPrimary),
              child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al crear inscripción'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0),
        body: const Center(child: Text('Error al cargar datos del usuario')),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) return _buildWebScaffold();
        return _buildMobileScaffold();
      },
    );
  }

  Widget _buildMobileScaffold() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEventCard(),
              const SizedBox(height: 20),
              _buildPersonalDataSection(),
              const SizedBox(height: 20),
              _buildCategorySection(),
              const SizedBox(height: 20),
              if (widget.event.cuentaBancaria.isNotEmpty) ...[
                _buildDepositSection(),
                const SizedBox(height: 20),
              ],
              _buildComprobanteSection(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 16),
              Text(
                'Al inscribirse acepta los términos de participación y reglamentos de la competencia.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebScaffold() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWebPageHeader(),
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              _buildWebEventCard(),
                              const SizedBox(height: 20),
                              _buildWebPersonalDataSection(),
                              const SizedBox(height: 20),
                              _buildWebCategoryGrid(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        SizedBox(
                          width: 360,
                          child: Column(
                            children: [
                              if (widget.event.cuentaBancaria.isNotEmpty) ...[
                                _buildDepositSection(),
                                const SizedBox(height: 20),
                              ],
                              _buildComprobanteSection(),
                              const SizedBox(height: 20),
                              _buildSubmitButton(),
                              const SizedBox(height: 12),
                              Text(
                                'Al hacer clic en inscribirse, aceptas nuestros términos y condiciones de participación y liberación de responsabilidad.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Registro de Inscripción',
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          'Completa tus datos para participar en el evento más esperado del año.',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildWebEventCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: widget.event.imagenUrl.isNotEmpty
                ? Image.network(
                    widget.event.imagenUrl,
                    width: 160,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 160,
                      height: 120,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 40, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 160,
                    height: 120,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 40, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.nombre,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 15, color: AppColors.buttonPrimary),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat("dd 'de' MMMM, yyyy", 'es').format(widget.event.fecha),
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 15, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.event.ubicacionCompleta,
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildWebPersonalDataSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: AppColors.buttonPrimary, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Datos Personales',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('Nombre Completo'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nombreController,
                      decoration: _inputDecoration('Ej. Juan Pérez'),
                      validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('Correo Electrónico'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration('juan@ejemplo.com').copyWith(
                        filled: true,
                        fillColor: Colors.grey[100],
                        suffixIcon: Icon(Icons.lock_outline, size: 16, color: Colors.grey[400]),
                      ),
                      readOnly: true,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputLabel('Teléfono de Contacto'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _telefonoController,
                  decoration: _inputDecoration('+502 0000 0000'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebCategoryGrid() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_bike_outlined, color: AppColors.buttonPrimary, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Selecciona tu Categoría',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.0,
            ),
            itemCount: widget.event.categorias.length,
            itemBuilder: (context, index) {
              final cat = widget.event.categorias[index];
              final nombre = cat['nombre'] ?? '';
              final edadMin = cat['edadMin'] ?? '';
              final edadMax = cat['edadMax'] ?? '';
              final precio = cat['precioInscripcion'] ?? '';
              final distancia = cat['distancia'] ?? '';
              final isSelected = _selectedCategoria == nombre;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategoria = nombre),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.buttonPrimary : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.buttonPrimary : Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$edadMin-$edadMax años',
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            'Q$precio',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.buttonPrimary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'Distancia: $distancia',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white70 : Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                isSelected ? Icons.check_circle : Icons.arrow_forward,
                                size: 14,
                                color: isSelected ? Colors.white : AppColors.buttonPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isSelected ? 'Seleccionado' : 'Seleccionar',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : AppColors.buttonPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _showConfirmationDialog,
        icon: _isSubmitting
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.directions_bike, color: Colors.white),
        label: const Text(
          'Inscribirse',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildEventCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: widget.event.imagenUrl.isNotEmpty
                ? Image.network(
                    widget.event.imagenUrl,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 90,
                      height: 90,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 90,
                    height: 90,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.nombre,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 13, color: AppColors.buttonPrimary),
                      const SizedBox(width: 5),
                      Text(
                        DateFormat("dd 'de' MMMM, yyyy", 'es').format(widget.event.fecha),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 13, color: AppColors.accent),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          widget.event.ubicacionCompleta,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDataSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: AppColors.buttonPrimary, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Datos Personales',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInputLabel('NOMBRE COMPLETO'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nombreController,
            decoration: _inputDecoration('Ej. Juan Pérez'),
            validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 16),
          _buildInputLabel('CORREO ELECTRÓNICO'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            decoration: _inputDecoration('juan@ejemplo.com').copyWith(
              filled: true,
              fillColor: Colors.grey[100],
              suffixIcon: Icon(Icons.lock_outline, size: 16, color: Colors.grey[400]),
            ),
            readOnly: true,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          _buildInputLabel('TELÉFONO'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _telefonoController,
            decoration: _inputDecoration('+502 0000 0000'),
            keyboardType: TextInputType.phone,
            validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () => setState(() => _categoriasVisible = !_categoriasVisible),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.groups_outlined, color: AppColors.buttonPrimary, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Selecciona tu Categoría',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  if (_selectedCategoria != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.buttonPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _selectedCategoria!,
                        style: TextStyle(fontSize: 12, color: AppColors.buttonPrimary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _categoriasVisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey[500],
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _categoriasVisible
                ? Column(
                    children: [
                      Divider(height: 1, color: Colors.grey[200]),
                      ...widget.event.categorias.map((cat) {
                        final nombre = cat['nombre'] ?? '';
                        final edadMin = cat['edadMin'] ?? '';
                        final edadMax = cat['edadMax'] ?? '';
                        final precio = cat['precioInscripcion'] ?? '';
                        final isSelected = _selectedCategoria == nombre;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedCategoria = nombre;
                            _categoriasVisible = false;
                          }),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.buttonPrimary : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.buttonPrimary : Colors.grey[200]!,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$edadMin-$edadMax años',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isSelected ? Colors.white70 : Colors.grey[500],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        nombre,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Q$precio',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : AppColors.buttonPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle, color: Colors.white, size: 24),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDepositSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.buttonPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Datos de Depósito',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.event.cuentaBancaria,
            style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildComprobanteSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: AppColors.buttonPrimary, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Comprobante',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('NO. BOLETA'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _numeroBoletaController,
                      decoration: _inputDecoration(''),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('BANCO EMISOR'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _bancoEmisorController,
                      decoration: _inputDecoration(''),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputLabel('FECHA DE PAGO'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _selectFechaPago,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 10),
                  Text(
                    _fechaPago == null
                        ? 'mm/dd/aaaa'
                        : DateFormat('dd/MM/yyyy').format(_fechaPago!),
                    style: TextStyle(
                      fontSize: 14,
                      color: _fechaPago == null ? Colors.grey[400] : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(Icons.cloud_upload_outlined, size: 36, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'Cargar recibo o captura',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'JPG, PNG o PDF hasta 5MB',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 0.5),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.buttonPrimary, width: 1.5),
      ),
    );
  }
}
