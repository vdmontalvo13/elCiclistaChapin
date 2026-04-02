import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/colors.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  String _selectedRol = 'ciclista';
  String? _selectedCiclismoPreferido;
  String? _selectedGenero;
  DateTime? _fechaNacimiento;

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.buttonPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fechaNacimiento = picked;
      });
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRol == 'ciclista' && _selectedCiclismoPreferido == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona tu ciclismo preferido'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_selectedRol == 'ciclista' && _selectedGenero == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona tu género'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_selectedRol == 'ciclista' && _fechaNacimiento == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona tu fecha de nacimiento'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        UserCredential userCredential =
            await _authService.registerWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        Map<String, dynamic> userData = {
          'nombre': _nombreController.text.trim(),
          'apellido': _apellidoController.text.trim(),
          'email': _emailController.text.trim(),
          'telefono': _telefonoController.text.trim(),
          'rol': _selectedRol,
        };

        if (_selectedRol == 'ciclista') {
          userData.addAll({
            'ciclismoPreferido': _selectedCiclismoPreferido,
            'genero': _selectedGenero,
            'fechaNacimiento': _fechaNacimiento != null
                ? Timestamp.fromDate(_fechaNacimiento!)
                : null,
            'descripcion': _descripcionController.text.trim(),
          });
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userData);

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.buttonPrimary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    IconData? icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: AppColors.buttonPrimary, width: 1.5),
      ),
      prefixIcon: icon != null
          ? Icon(icon, color: Colors.grey[400], size: 20)
          : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF4F6F8),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF031F41),
              Color(0xFF006670),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWeb = constraints.maxWidth > 600;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: isWeb ? 48.0 : 24.0,
                ),
                child: Column(
                  children: [
                    // Card con formulario
                    Center(
                      child: SizedBox(
                        width: isWeb ? 420.0 : double.infinity,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Logo + título (dentro del card)
                                Center(
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        'assets/images/logo.png',
                                        width: isWeb ? 100.0 : 80.0,
                                        height: isWeb ? 100.0 : 80.0,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Únete a la ruta',
                                        style: TextStyle(
                                          fontSize: isWeb ? 26.0 : 22.0,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.darkBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'La comunidad de ciclismo que une a toda Guatemala. '
                                        'Disfruta de las mejores carreras de ciclismo de Guatemala, '
                                        'entérate, inscríbete y descubre nuevas rutas.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),

                                // TOGGLE ROL
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4F6F8),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Row(
                                    children: [
                                      _rolTab('Ciclista', 'ciclista'),
                                      _rolTab('Organizador', 'organizador'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // CAMPOS COMUNES
                                _fieldLabel('NOMBRE'),
                                TextFormField(
                                  controller: _nombreController,
                                  decoration: _fieldDecoration(
                                      hint: 'Ej. Juan', icon: Icons.person_outline),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingresa tu nombre';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                _fieldLabel('APELLIDO'),
                                TextFormField(
                                  controller: _apellidoController,
                                  decoration: _fieldDecoration(
                                      hint: 'Ej. Pérez',
                                      icon: Icons.person_outline),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingresa tu apellido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                _fieldLabel('CORREO ELECTRÓNICO'),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _fieldDecoration(
                                      hint: 'tu@email.com',
                                      icon: Icons.email_outlined),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingresa tu correo';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Por favor ingresa un correo válido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                _fieldLabel('TELÉFONO'),
                                TextFormField(
                                  controller: _telefonoController,
                                  keyboardType: TextInputType.phone,
                                  decoration: _fieldDecoration(
                                      hint: '+502 0000-0000',
                                      icon: Icons.phone_outlined),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingresa tu teléfono';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                // CAMPOS ESPECÍFICOS PARA CICLISTAS
                                if (_selectedRol == 'ciclista') ...[
                                  _fieldLabel('GÉNERO'),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedGenero,
                                    decoration: _fieldDecoration(
                                        hint: 'Seleccionar'),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'Masculino',
                                          child: Text('Masculino')),
                                      DropdownMenuItem(
                                          value: 'Femenino',
                                          child: Text('Femenino')),
                                    ],
                                    onChanged: (value) {
                                      setState(() => _selectedGenero = value);
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  _fieldLabel('FECHA DE NACIMIENTO'),
                                  InkWell(
                                    onTap: _selectDate,
                                    child: InputDecorator(
                                      decoration: _fieldDecoration(
                                        hint: 'dd/mm/aaaa',
                                        icon: Icons.calendar_today_outlined,
                                      ),
                                      child: Text(
                                        _fechaNacimiento != null
                                            ? '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}'
                                            : 'dd/mm/aaaa',
                                        style: TextStyle(
                                          color: _fechaNacimiento != null
                                              ? Colors.black87
                                              : Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  _fieldLabel('CICLISMO PREFERIDO'),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedCiclismoPreferido,
                                    decoration: _fieldDecoration(
                                        hint: 'Seleccionar',
                                        icon: Icons.directions_bike_outlined),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'MTB', child: Text('MTB')),
                                      DropdownMenuItem(
                                          value: 'Ruta', child: Text('Ruta')),
                                      DropdownMenuItem(
                                          value: 'Gravel',
                                          child: Text('Gravel')),
                                      DropdownMenuItem(
                                          value: 'Urbano',
                                          child: Text('Urbano')),
                                    ],
                                    onChanged: (value) {
                                      setState(() =>
                                          _selectedCiclismoPreferido = value);
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  _fieldLabel('DESCRIPCIÓN (OPCIONAL)'),
                                  TextFormField(
                                    controller: _descripcionController,
                                    maxLines: 3,
                                    decoration: _fieldDecoration(
                                        hint: 'Cuéntanos un poco sobre ti...'),
                                  ),
                                  const SizedBox(height: 14),
                                ],

                                // CONTRASEÑA
                                _fieldLabel('CONTRASEÑA'),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: _fieldDecoration(
                                    hint: '••••••••',
                                    icon: Icons.lock_outline,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: Colors.grey[400],
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() =>
                                            _obscurePassword = !_obscurePassword);
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingresa tu contraseña';
                                    }
                                    if (value.length < 6) {
                                      return 'La contraseña debe tener al menos 6 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),

                                // BOTÓN REGISTRARSE
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.buttonPrimary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(25),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Registrarse',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(Icons.arrow_forward,
                                                  color: Colors.white,
                                                  size: 18),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // LINK A LOGIN
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '¿Ya tienes una cuenta? ',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Text(
                                        'Inicia Sesión',
                                        style: TextStyle(
                                          color: AppColors.buttonPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // FOOTER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            color: Colors.white70, size: 22),
                        const SizedBox(width: 24),
                        Icon(Icons.camera_alt_outlined,
                            color: Colors.white70, size: 22),
                        const SizedBox(width: 24),
                        Icon(Icons.emoji_events_outlined,
                            color: Colors.white70, size: 22),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _footerLink('PRIVACIDAD'),
                        const SizedBox(width: 20),
                        _footerLink('TÉRMINOS'),
                        const SizedBox(width: 20),
                        _footerLink('SOPORTE'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '© 2024 EL CICLISTA CHAPÍN. TODOS LOS DERECHOS RESERVADOS.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _rolTab(String label, String value) {
    final isSelected = _selectedRol == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedRol = value;
          _selectedCiclismoPreferido = null;
          _selectedGenero = null;
          _fechaNacimiento = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.buttonPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footerLink(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}
