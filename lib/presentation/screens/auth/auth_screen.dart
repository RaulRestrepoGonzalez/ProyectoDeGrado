import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth_service.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _repository = AuthRepository();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  String _selectedRole = 'artista';
  bool _acceptedTerms = false;

  final List<String> _rolesList = ['compañia', 'independiente', 'artista'];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Términos y Condiciones Legales'),
          content: const SingleChildScrollView(
            child: Text(
              'Al crear este perfil, usted acepta explícitamente las siguientes condiciones:\n\n'
              '1. Todos los pagos, cobros o transacciones económicas realizadas dentro de la plataforma son de ÚNICA Y EXCLUSIVA RESPONSABILIDAD de su perfil o entidad.\n\n'
              '2. La divulgación de información personal suya o de otros usuarios sin el debido consentimiento incurrirá en MEDIDAS LEGALES según los artículos de ley vigentes correspondientes al país donde se instala la aplicación, así como los estatutos de ley internacional aplicables.\n\n'
              '3. El usuario libera de toda culpa, cargo y desvincula de CUALQUIER ACCIÓN LEGAL a los intermediarios y dueños de esta aplicación por el mal uso de las herramientas o daños derivados del intercambio de servicios entre particulares.\n\n'
              'Su registro en esta app equivale a una firma de conformidad con los términos expuestos.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isLogin && !_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Debe aceptar los términos y condiciones para registrarse.',
          ),
          backgroundColor: Colors.red.shade800,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final emailValue = _emailController.text.trim().toLowerCase();

      if (_isLogin) {
        final tokens = await _repository.login(
          email: emailValue,
          password: _passwordController.text.trim(),
        );

        await AuthService.instance.saveTokens(
          tokens['token']!,
          tokens['refreshToken']!,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('¡Ingreso exitoso!')));

        context.go('/home');
      } else {
        await _repository.register(
          email: emailValue,
          password: _passwordController.text.trim(),
          nombre: _nameController.text.trim(),
          rol: _selectedRole,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro exitoso, ya puedes iniciar sesión.'),
          ),
        );
        setState(() {
          _isLogin = true;
          _passwordController.clear();
        });
      }
    } catch (error) {
      if (mounted) {
        final errorMsg = error.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red.shade800,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Iniciar sesión' : 'Registrarse')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isLogin) ...[
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Perfil',
                        ),
                        items: _rolesList.map((String role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(
                              role[0].toUpperCase() + role.substring(1),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedRole = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo o Razón Social',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 2) {
                            return 'Ingresa un nombre válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                      ),
                      validator: (value) {
                        if (value == null || !value.contains('@')) {
                          return 'Ingresa un correo válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Mínimo 6 caracteres';
                        }
                        return null;
                      },
                    ),

                    if (!_isLogin) ...[
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CheckboxListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          title: const Text(
                            'He leído y acepto expresamente los ',
                          ),
                          subtitle: GestureDetector(
                            onTap: _showTermsDialog,
                            child: const Text(
                              'Términos y Condiciones Legales',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          value: _acceptedTerms,
                          onChanged: (val) {
                            setState(() {
                              _acceptedTerms = val ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_isLogin ? 'Ingresar' : 'Crear cuenta'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading ? null : _toggleMode,
                      child: Text(
                        _isLogin
                            ? '¿Aún no tienes cuenta? Regístrate'
                            : '¿Ya tienes cuenta? Inicia sesión',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
