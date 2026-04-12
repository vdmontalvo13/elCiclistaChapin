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
  Set<String> _selectedDisciplinas = <String>{};
  String? _selectedDepartamento;

  List<EventModel> _allEvents = [];
  List<EventModel> _filteredEvents = [];
  List<String> _availableDepartamentos = ['Todos'];
  bool _isLoading = true;
  bool _filtersVisible = false;

  int get _activeFilterCount {
    int count = 0;
    if (_startDate != null) count++;
    if (_endDate != null) count++;
    if (_selectedTipoEvento != null && _selectedTipoEvento != 'Todos') count++;
    if (_selectedDisciplinas.isNotEmpty) count += _selectedDisciplinas.length;
    if (_selectedDepartamento != null && _selectedDepartamento != 'Todos') count++;
    return count;
  }

  final List<String> _tiposEvento = ['Todos', 'Travesía', 'Colazo', 'Carrera', 'Travesía y Carrera', 'Benéfico'];
  final List<String> _disciplinas = ['MTB', 'Ruta', 'Gravel', 'Urbano'];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await _homeService.getAllActiveEvents();
      final departamentosSet = <String>{'Todos'};
      for (final event in events) {
        final departamento = event.ubicacion['departamento'] as String?;
        if (departamento != null && departamento.isNotEmpty) {
          departamentosSet.add(departamento);
        }
      }
      final departamentosList = departamentosSet.toList()..remove('Todos')..sort();
      departamentosList.insert(0, 'Todos');
      setState(() {
        _allEvents = events;
        _filteredEvents = events;
        _availableDepartamentos = departamentosList;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredEvents = _allEvents.where((event) {
        if (_startDate != null && event.fecha.isBefore(_startDate!)) { return false; }
        if (_endDate != null && event.fecha.isAfter(_endDate!)) { return false; }
        if (_selectedTipoEvento != null &&
            _selectedTipoEvento != 'Todos' &&
            event.tipoEvento != _selectedTipoEvento) { return false; }
        if (_selectedDisciplinas.isNotEmpty &&
            !_selectedDisciplinas.contains(event.disciplina)) { return false; }
        if (_selectedDepartamento != null && _selectedDepartamento != 'Todos') {
          final eventDepartamento = event.ubicacion['departamento'] ?? '';
          if (eventDepartamento != _selectedDepartamento) return false;
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
      _selectedDisciplinas = <String>{};
      _selectedDepartamento = null;
      _filteredEvents = _allEvents;
    });
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.buttonPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      if (_endDate != null && picked.isAfter(_endDate!)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('La fecha de inicio debe ser menor a la fecha fin'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ));
        return;
      }
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final minDate = _startDate ?? DateTime.now();
    var initialDate = _endDate ?? minDate.add(const Duration(days: 1));
    if (initialDate.isBefore(minDate)) {
      initialDate = minDate.add(const Duration(days: 1));
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.buttonPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      if (_startDate != null && picked.isBefore(_startDate!)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('La fecha fin debe ser mayor a la fecha de inicio'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ));
        return;
      }
      setState(() => _endDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _filtersVisible ? _buildFilters() : const SizedBox.shrink(),
            ),
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

  Widget _buildWebScaffold() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWebPageHeader(),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWebFilterSidebar(),
                      const SizedBox(width: 24),
                      Expanded(child: _buildWebEventGrid()),
                    ],
                  ),
                ],
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
          'Calendario de Carreras',
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          'Encuentra tu próximo reto en los paisajes más impresionantes de Guatemala.\nDesde volcanes hasta selvas tropicales.',
          style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
        ),
      ],
    );
  }

  Widget _buildWebFilterSidebar() {
    return SizedBox(
      width: 240,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: AppColors.buttonPrimary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Filtros',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSidebarLabel('Rango de Fechas'),
            const SizedBox(height: 8),
            _buildSidebarDatePicker(label: 'Fecha inicio', date: _startDate, onTap: _selectStartDate),
            const SizedBox(height: 8),
            _buildSidebarDatePicker(label: 'Fecha fin', date: _endDate, onTap: _selectEndDate),
            const SizedBox(height: 16),
            _buildSidebarLabel('Disciplina'),
            const SizedBox(height: 4),
            ..._disciplinas.map((d) => CheckboxListTile(
              value: _selectedDisciplinas.contains(d),
              onChanged: (checked) => setState(() {
                if (checked == true) {
                  _selectedDisciplinas.add(d);
                } else {
                  _selectedDisciplinas.remove(d);
                }
              }),
              title: Text(d, style: const TextStyle(fontSize: 14)),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.buttonPrimary,
            )),
            const SizedBox(height: 16),
            _buildSidebarLabel('Tipo de evento'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: ValueKey('tipo_$_selectedTipoEvento'),
              initialValue: _selectedTipoEvento,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              hint: const Text('Todos'),
              items: _tiposEvento.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (value) => setState(() => _selectedTipoEvento = value),
            ),
            const SizedBox(height: 16),
            _buildSidebarLabel('Departamento'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: ValueKey('departamento_$_selectedDepartamento'),
              initialValue: _selectedDepartamento,
              isExpanded: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_on, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              hint: const Text('Todos'),
              items: _availableDepartamentos.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (value) => setState(() => _selectedDepartamento = value),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _applyFilters,
                icon: const Icon(Icons.search, size: 18, color: Colors.white),
                label: const Text('Buscar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _activeFilterCount > 0 ? _clearFilters : null,
                icon: const Icon(Icons.clear_all, size: 18),
                label: Text(_activeFilterCount > 0 ? 'Limpiar filtros ($_activeFilterCount)' : 'Limpiar filtros'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.buttonPrimary,
                  side: BorderSide(
                    color: _activeFilterCount > 0 ? AppColors.buttonPrimary : Colors.grey[300]!,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
    );
  }

  Widget _buildSidebarDatePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              date == null ? label : DateFormat('dd/MM/yyyy').format(date),
              style: TextStyle(fontSize: 13, color: date == null ? Colors.grey[500] : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebEventGrid() {
    if (_isLoading) {
      return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
    }
    if (_filteredEvents.isEmpty) return _buildEmptyState();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.05,
      ),
      itemCount: _filteredEvents.length,
      itemBuilder: (context, index) => _buildEventCard(_filteredEvents[index]),
    );
  }

  Widget _buildHeader() {
    final activeCount = _activeFilterCount;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.buttonPrimary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          GestureDetector(
            onTap: () => setState(() => _filtersVisible = !_filtersVisible),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _filtersVisible ? Colors.white : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _filtersVisible ? Icons.filter_list_off : Icons.filter_list,
                    size: 18,
                    color: _filtersVisible ? AppColors.buttonPrimary : Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Filtros',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _filtersVisible ? AppColors.buttonPrimary : Colors.white,
                    ),
                  ),
                  if (activeCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _filtersVisible ? AppColors.buttonPrimary : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$activeCount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _filtersVisible ? Colors.white : AppColors.buttonPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                            _startDate == null ? 'Fecha inicio' : DateFormat('dd/MM/yyyy').format(_startDate!),
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
                            _endDate == null ? 'Fecha fin' : DateFormat('dd/MM/yyyy').format(_endDate!),
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
          DropdownButtonFormField<String>(
            value: _selectedTipoEvento,
            decoration: InputDecoration(
              hintText: 'Tipo de evento',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            items: _tiposEvento.map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo))).toList(),
            onChanged: (value) => setState(() => _selectedTipoEvento = value),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Disciplina',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _disciplinas.map((d) {
              final selected = _selectedDisciplinas.contains(d);
              return FilterChip(
                label: Text(d),
                selected: selected,
                onSelected: (checked) => setState(() {
                  if (checked) {
                    _selectedDisciplinas.add(d);
                  } else {
                    _selectedDisciplinas.remove(d);
                  }
                }),
                selectedColor: AppColors.buttonPrimary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.buttonPrimary,
                side: BorderSide(color: selected ? AppColors.buttonPrimary : Colors.grey[300]!),
                labelStyle: TextStyle(
                  color: selected ? AppColors.buttonPrimary : Colors.black87,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedDepartamento,
            decoration: InputDecoration(
              hintText: 'Departamento',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            items: _availableDepartamentos.map((depto) => DropdownMenuItem(value: depto, child: Text(depto))).toList(),
            onChanged: (value) => setState(() => _selectedDepartamento = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _activeFilterCount > 0
                      ? () {
                          _clearFilters();
                          setState(() => _filtersVisible = false);
                        }
                      : null,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: Text(_activeFilterCount > 0 ? 'Borrar ($_activeFilterCount)' : 'Borrar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.buttonPrimary,
                    side: BorderSide(
                      color: _activeFilterCount > 0 ? AppColors.buttonPrimary : Colors.grey[300]!,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _applyFilters();
                    setState(() => _filtersVisible = false);
                  },
                  icon: const Icon(Icons.search, size: 18, color: Colors.white),
                  label: const Text('Buscar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
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
        itemBuilder: (context, index) => _buildEventCard(_filteredEvents[index]),
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
                          errorBuilder: (_, __, ___) => Container(
                            height: 180,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 64, color: Colors.grey),
                          ),
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
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: AppColors.buttonPrimary),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat("dd 'de' MMMM, yyyy", 'es').format(event.fecha),
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
      case 'mtb':    return const Color(0xFF8B4513);
      case 'ruta':   return const Color(0xFFFF8C42);
      case 'gravel': return const Color(0xFF6B8E23);
      case 'urbano': return const Color(0xFF4682B4);
      default:       return AppColors.primary;
    }
  }
}
