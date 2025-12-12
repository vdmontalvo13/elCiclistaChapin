import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';
import '../../services/home_service.dart';
import '../../models/event_model.dart';
import 'event_detail_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final HomeService _homeService = HomeService();
  
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedTipoEvento;
  String? _selectedDisciplina;
  String? _selectedDepartamento;
  
  List<EventModel> _allEvents = [];
  List<EventModel> _filteredEvents = [];
  List<String> _availableDepartamentos = ['Todos']; // Lista dinámica
  bool _isLoading = true;

  final List<String> _tiposEvento = ['Todos', 'Travesía', 'Colazo', 
                                      'Carrera', 'Travesía y Carrera','Benéfico', ];
  final List<String> _disciplinas = ['Todas', 'MTB', 'Ruta', 'Gravel', 'Urbano'];
  
  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    
    try {
      List<EventModel> events = await _homeService.getAllActiveEvents();
      
      // Extraer departamentos únicos de los eventos
      Set<String> departamentosSet = {'Todos'};
      for (var event in events) {
        String? departamento = event.ubicacion['departamento'];
        if (departamento != null && departamento.isNotEmpty) {
          departamentosSet.add(departamento);
        }
      }
      
      // Ordenar alfabéticamente (excepto "Todos" que va primero)
      List<String> departamentosList = departamentosSet.toList();
      departamentosList.remove('Todos');
      departamentosList.sort();
      departamentosList.insert(0, 'Todos');
      
      setState(() {
        _allEvents = events;
        _filteredEvents = events;
        _availableDepartamentos = departamentosList;
        _isLoading = false;
      });
      
      print('📍 Departamentos disponibles: $_availableDepartamentos');
    } catch (e) {
      print('❌ Error cargando eventos: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredEvents = _allEvents.where((event) {
        // Filtro por rango de fechas
        if (_startDate != null && event.fecha.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && event.fecha.isAfter(_endDate!)) {
          return false;
        }
        
        // Filtro por tipo de evento
        if (_selectedTipoEvento != null && 
            _selectedTipoEvento != 'Todos' && 
            event.tipoEvento != _selectedTipoEvento) {
          return false;
        }
        
        // Filtro por disciplina
        if (_selectedDisciplina != null && 
            _selectedDisciplina != 'Todas' && 
            event.disciplina != _selectedDisciplina) {
          return false;
        }
        
        // Filtro por departamento
        if (_selectedDepartamento != null && 
            _selectedDepartamento != 'Todos') {
          String eventDepartamento = event.ubicacion['departamento'] ?? '';
          if (eventDepartamento != _selectedDepartamento) {
            return false;
          }
        }
        
        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedTipoEvento = null;
      _selectedDisciplina = null;
      _selectedDepartamento = null;
      _filteredEvents = _allEvents;
    });
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
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
      // Validar que la fecha fin sea mayor a la fecha inicio
      if (_endDate != null && picked.isAfter(_endDate!)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La fecha de inicio debe ser menor a la fecha fin'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      
      setState(() => _startDate = picked);
      _applyFilters();
    }
  }

  Future<void> _selectEndDate() async {
    // Si no hay fecha de inicio, usar la fecha actual como mínimo
    DateTime minDate = _startDate ?? DateTime.now();
    
    // Si hay fecha de inicio, la fecha inicial del picker debe ser un día después
    DateTime initialDate = _endDate ?? minDate.add(const Duration(days: 1));
    
    // Asegurar que la fecha inicial no sea menor que la fecha mínima
    if (initialDate.isBefore(minDate)) {
      initialDate = minDate.add(const Duration(days: 1));
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: DateTime(2030),
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
      // Validar que la fecha fin sea mayor a la fecha inicio
      if (_startDate != null && picked.isBefore(_startDate!)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La fecha fin debe ser mayor a la fecha de inicio'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      
      setState(() => _endDate = picked);
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredEvents.isEmpty
                      ? _buildEmptyState()
                      : _buildEventsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.buttonPrimary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Carreras',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (_startDate != null || _endDate != null || _selectedTipoEvento != null || 
              _selectedDisciplina != null || _selectedDepartamento != null)
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear, color: Colors.white, size: 18),
              label: const Text(
                'Limpiar',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, color: AppColors.buttonPrimary),
              const SizedBox(width: 8),
              const Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Fechas
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _selectStartDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _startDate == null
                                ? 'Fecha inicio'
                                : DateFormat('dd/MM/yyyy').format(_startDate!),
                            style: TextStyle(
                              color: _startDate == null ? Colors.grey[600] : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: _selectEndDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _endDate == null
                                ? 'Fecha fin'
                                : DateFormat('dd/MM/yyyy').format(_endDate!),
                            style: TextStyle(
                              color: _endDate == null ? Colors.grey[600] : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Tipo de evento
          DropdownButtonFormField<String>(
            value: _selectedTipoEvento,
            decoration: InputDecoration(
              hintText: 'Tipo de evento',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            items: _tiposEvento.map((tipo) {
              return DropdownMenuItem(value: tipo, child: Text(tipo));
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedTipoEvento = value);
              _applyFilters();
            },
          ),
          const SizedBox(height: 8),
          
          // Disciplina
          DropdownButtonFormField<String>(
            value: _selectedDisciplina,
            decoration: InputDecoration(
              hintText: 'Disciplina',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            items: _disciplinas.map((disciplina) {
              return DropdownMenuItem(value: disciplina, child: Text(disciplina));
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedDisciplina = value);
              _applyFilters();
            },
          ),
          const SizedBox(height: 8),
          
          // Departamento - LISTA DINÁMICA
          DropdownButtonFormField<String>(
            value: _selectedDepartamento,
            decoration: InputDecoration(
              hintText: 'Departamento',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            items: _availableDepartamentos.map((depto) {
              return DropdownMenuItem(value: depto, child: Text(depto));
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedDepartamento = value);
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return RefreshIndicator(
      onRefresh: _loadEvents,
      color: AppColors.buttonPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredEvents.length,
        itemBuilder: (context, index) {
          return _buildEventCard(_filteredEvents[index]);
        },
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
      },
      child: Container(
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
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 180,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, size: 64, color: Colors.grey),
                            );
                          },
                        )
                      : Container(
                          height: 180,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 64, color: Colors.grey),
                        ),
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
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: AppColors.buttonPrimary),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd \'de\' MMMM, yyyy', 'es').format(event.fecha),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 18, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.ubicacionCompleta,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Icon(Icons.groups, size: 18, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      Text(
                        '${event.categorias.length} categorías',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      if (event.categorias.isNotEmpty && event.categorias[0]['distancia'] != null) ...[
                        Icon(Icons.speed, size: 18, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Text(
                          event.categorias[0]['distancia'],
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
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
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No se encontraron carreras',
              style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta ajustar los filtros',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDisciplinaColor(String disciplina) {
    switch (disciplina.toLowerCase()) {
      case 'mtb':
        return const Color(0xFF8B4513);
      case 'ruta':
        return const Color(0xFFFF8C42);
      case 'gravel':
        return const Color(0xFF6B8E23);
      case 'urbano':
        return const Color(0xFF4682B4);
      default:
        return AppColors.primary;
    }
  }
}