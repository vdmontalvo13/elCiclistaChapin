import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';
import '../../models/categoria_model.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';

class EditEventScreen extends StatefulWidget {
  final EventModel event;

  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final EventService _eventService = EventService();

  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _municipioController;
  late TextEditingController _horaController;
  late TextEditingController _kitController;
  late TextEditingController _imagenUrlController;
  late TextEditingController _cuposController;
  late DateTime _selectedDate;
  late String _selectedDepartamento;
  late String _selectedTipoEvento;
  late String _selectedDisciplina;
  late TextEditingController _cuentaBancariaController;

  List<CategoriaModel> _categorias = [];
  bool _isSaving = false;

  final List<String> _departamentos = [
    'Guatemala',
    'Alta Verapaz',
    'Baja Verapaz',
    'Chimaltenango',
    'Chiquimula',
    'El Progreso',
    'Escuintla',
    'Huehuetenango',
    'Izabal',
    'Jalapa',
    'Jutiapa',
    'Petén',
    'Quetzaltenango',
    'Quiché',
    'Retalhuleu',
    'Sacatepéquez',
    'San Marcos',
    'Santa Rosa',
    'Sololá',
    'Suchitepéquez',
    'Totonicapán',
    'Zacapa',
  ];

  final List<String> _tiposEvento = [
    'Carrera',
    'Travesía',
    'Colazo',
    'Travesía y Carrera',
    'Benéfico',
  ];

  final List<String> _disciplinas = ['MTB', 'Ruta', 'Gravel', 'Urbano'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadEventData();
  }

  void _initializeControllers() {
    _nombreController = TextEditingController();
    _descripcionController = TextEditingController();
    _municipioController = TextEditingController();
    _horaController = TextEditingController();
    _kitController = TextEditingController();
    _imagenUrlController = TextEditingController();
    _cuposController = TextEditingController();
    _cuentaBancariaController = TextEditingController();
  }

  void _loadEventData() {
    _nombreController.text = widget.event.nombre;
    _descripcionController.text = widget.event.descripcion;
    _municipioController.text = widget.event.ubicacion['municipio'] ?? '';
    _horaController.text = widget.event.hora;
    _kitController.text = widget.event.kit;
    _imagenUrlController.text = widget.event.imagenUrl;
    _cuposController.text = widget.event.cuposDisponibles.toString();
    _cuentaBancariaController.text = widget.event.cuentaBancaria;
    _selectedDate = widget.event.fecha;
    _selectedDepartamento =
        widget.event.ubicacion['departamento'] ?? 'Guatemala';
    _selectedTipoEvento = widget.event.tipoEvento;
    _selectedDisciplina = widget.event.disciplina;

    _categorias = widget.event.categorias
        .map((cat) => CategoriaModel.fromMap(cat))
        .toList();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _municipioController.dispose();
    _horaController.dispose();
    _kitController.dispose();
    _imagenUrlController.dispose();
    _cuposController.dispose();
    _cuentaBancariaController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay initialTime = TimeOfDay.now();
    try {
      final timeParts = _horaController.text.split(':');
      if (timeParts.length == 2) {
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1].split(' ')[0]);
        if (_horaController.text.contains('PM') && hour != 12) {
          hour += 12;
        }
        initialTime = TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      // Si falla el parsing, usar hora actual
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
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
      final String formattedTime = picked.format(context);
      setState(() => _horaController.text = formattedTime);
    }
  }

  void _addCategoria() {
    CategoriaModel nuevaCategoria = CategoriaModel(
      nombre: 'Nueva Categoría',
      edadMin: 18,
      edadMax: 35,
      genero: 'masculino',
      distancia: '50km',
      elevacion: '600m',
      precioInscripcion: 150,
    );

    setState(() {
      _categorias.add(nuevaCategoria);
    });

    int newIndex = _categorias.length - 1;
    _showCategoriaDialog(_categorias[newIndex], newIndex);
  }

  void _editCategoria(int index) {
    _showCategoriaDialog(_categorias[index], index);
  }

  void _deleteCategoria(int index) {
    if (_categorias.length > 1) {
      setState(() => _categorias.removeAt(index));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe haber al menos una categoría'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showCategoriaDialog(CategoriaModel categoria, int index) {
    final TextEditingController nombreCtrl = TextEditingController(
      text: categoria.nombre,
    );
    final TextEditingController edadMinCtrl = TextEditingController(
      text: categoria.edadMin.toString(),
    );
    final TextEditingController edadMaxCtrl = TextEditingController(
      text: categoria.edadMax.toString(),
    );
    final TextEditingController distanciaCtrl = TextEditingController(
      text: categoria.distancia,
    );
    final TextEditingController elevacionCtrl = TextEditingController(
      text: categoria.elevacion,
    );
    final TextEditingController precioCtrl = TextEditingController(
      text: categoria.precioInscripcion.toString(),
    );
    String selectedGenero = categoria.genero;

    bool isNewCategory = categoria.nombre == 'Nueva Categoría';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isNewCategory ? 'Nueva Categoría' : 'Editar Categoría'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: edadMinCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Edad Min',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: edadMaxCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Edad Max',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedGenero,
                  decoration: const InputDecoration(labelText: 'Género'),
                  items: const [
                    DropdownMenuItem(
                      value: 'masculino',
                      child: Text('Masculino'),
                    ),
                    DropdownMenuItem(
                      value: 'femenino',
                      child: Text('Femenino'),
                    ),
                    DropdownMenuItem(value: 'mixto', child: Text('Mixto')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedGenero = value!);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: distanciaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Distancia (ej: 50km)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: elevacionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Elevación (ej: 800m)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: precioCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Precio (Q)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (isNewCategory) {
                  setState(() {
                    _categorias.removeAt(index);
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nombreCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El nombre de la categoría es requerido'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                setState(() {
                  _categorias[index] = CategoriaModel(
                    nombre: nombreCtrl.text,
                    edadMin: int.tryParse(edadMinCtrl.text) ?? 18,
                    edadMax: int.tryParse(edadMaxCtrl.text) ?? 35,
                    genero: selectedGenero,
                    distancia: distanciaCtrl.text,
                    elevacion: elevacionCtrl.text,
                    precioInscripcion: int.tryParse(precioCtrl.text) ?? 150,
                  );
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
              ),
              child: const Text(
                'Guardar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    List<Map<String, dynamic>> categoriasMap = _categorias
        .map((c) => c.toMap())
        .toList();

    bool success = await _eventService.updateEvent(
      eventId: widget.event.id,
      nombre: _nombreController.text,
      descripcion: _descripcionController.text,
      fecha: _selectedDate,
      hora: _horaController.text,
      municipio: _municipioController.text,
      departamento: _selectedDepartamento,
      tipoEvento: _selectedTipoEvento,
      disciplina: _selectedDisciplina,
      imagenUrl: _imagenUrlController.text.trim().isEmpty
          ? 'https://images.unsplash.com/photo-1541625602330-2277a4c46182?w=800'
          : _imagenUrlController.text.trim(),
      kit: _kitController.text,
      categorias: categoriasMap,
      cuentaBancaria: _cuentaBancariaController.text,
      cuposDisponibles: int.tryParse(_cuposController.text) ?? 250,
    );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(
        context,
        true,
      ); // Retornar true para indicar que se actualizó
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar evento'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Editar Evento'),
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
              _buildSectionTitle('Información General'),
              const SizedBox(height: 16),
              _buildTextField(
                'Nombre del Evento',
                _nombreController,
                required: true,
              ),
              const SizedBox(height: 16),
              _buildDateField(),
              const SizedBox(height: 16),
              _buildTimeField(),
              const SizedBox(height: 24),

              _buildSectionTitle('Ubicación'),
              const SizedBox(height: 16),
              _buildDropdown(
                'Departamento',
                _selectedDepartamento,
                _departamentos,
                (value) => setState(() => _selectedDepartamento = value!),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Municipio',
                _municipioController,
                required: true,
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Detalles del Evento'),
              const SizedBox(height: 16),
              _buildDropdown(
                'Tipo de Evento',
                _selectedTipoEvento,
                _tiposEvento,
                (value) => setState(() => _selectedTipoEvento = value!),
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                'Disciplina',
                _selectedDisciplina,
                _disciplinas,
                (value) => setState(() => _selectedDisciplina = value!),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Descripción',
                _descripcionController,
                maxLines: 4,
                required: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Kit incluido',
                _kitController,
                maxLines: 2,
                hint: 'Playera, medalla, hidratación...',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Cupos Disponibles',
                _cuposController,
                required: true,
                hint: 'Número máximo de participantes',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Información de Cuenta Bancaria',
                _cuentaBancariaController,
                maxLines: 3,
                hint: 'Ej: Banrural - Cuenta Ahorro Q - 1234567890',
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Imagen del Evento'),
              const SizedBox(height: 16),
              _buildImageSection(),
              const SizedBox(height: 24),

              _buildCategoriasSection(),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Guardar Cambios',
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool required = false,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: controller == _cuposController
          ? TextInputType.number
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: required
          ? (value) => value!.isEmpty ? 'Campo requerido' : null
          : null,
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.buttonPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('dd/MM/yyyy').format(_selectedDate),
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField() {
    return GestureDetector(
      onTap: _selectTime,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: AppColors.buttonPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _horaController.text,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _imagenUrlController,
          decoration: InputDecoration(
            labelText: 'URL de la imagen',
            hintText: 'https://ejemplo.com/imagen.jpg',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.link),
            helperText: 'Deja vacío para usar imagen por defecto',
            helperMaxLines: 2,
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              Uri? uri = Uri.tryParse(value);
              if (uri == null || !uri.hasScheme) {
                return 'Ingresa una URL válida';
              }
            }
            return null;
          },
          onChanged: (value) {
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _imagenUrlController.text.trim().isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Vista previa de la imagen',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : Image.network(
                    _imagenUrlController.text.trim(),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Error al cargar imagen',
                              style: TextStyle(
                                color: Colors.red[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Categorías'),
            TextButton.icon(
              onPressed: _addCategoria,
              icon: const Icon(Icons.add_circle),
              label: const Text('Agregar'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.buttonPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._categorias.asMap().entries.map((entry) {
          int index = entry.key;
          CategoriaModel cat = entry.value;
          return _buildCategoriaCard(cat, index);
        }).toList(),
      ],
    );
  }

  Widget _buildCategoriaCard(CategoriaModel categoria, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                categoria.nombre,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _editCategoria(index),
                    color: AppColors.buttonPrimary,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => _deleteCategoria(index),
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${categoria.edadMin}-${categoria.edadMax} años',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Precio:',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      'Q${categoria.precioInscripcion}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distancia:',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      categoria.distancia,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Elevación:',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      categoria.elevacion,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
