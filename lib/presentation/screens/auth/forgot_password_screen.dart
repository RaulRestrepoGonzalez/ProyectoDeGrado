import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/repositories/auth_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _repository = AuthRepository();
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _codeRequested = false;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _identifierValidator(String? value) {
    final identifier = value?.trim() ?? '';
    final isEmail = identifier.contains('@');
    final isPhone = RegExp(r'^\+?[0-9]{7,15}$').hasMatch(identifier);
    if (!isEmail && !isPhone) {
      return 'Ingresa tu correo o WhatsApp con código de país';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (!_codeRequested) {
        final whatsappUrl = await _repository.requestPasswordRecovery(
          identifier: _identifierController.text.trim(),
        );
        final opened = await launchUrl(
          Uri.parse(whatsappUrl),
          mode: LaunchMode.externalApplication,
        );
        if (!opened) {
          throw Exception('No se pudo abrir WhatsApp en este dispositivo.');
        }
        setState(() => _codeRequested = true);
        _message('Copia el código desde WhatsApp y pégalo aquí.');
      } else {
        await _repository.resetPassword(
          identifier: _identifierController.text.trim(),
          codigo: _codeController.text.trim(),
          newPassword: _passwordController.text,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña actualizada. Ya puedes iniciar sesión.'),
          ),
        );
        context.go('/auth');
      }
    } catch (error) {
      _message(error.toString().replaceAll('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red.shade800 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_reset, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      _codeRequested
                          ? 'Verifica tu identidad'
                          : 'Abre WhatsApp para obtener tu código',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _codeRequested
                          ? 'Escribe el código de seis dígitos y crea una contraseña nueva.'
                          : 'Se abrirá una conversación con tu propio número. Copia el código y regresa a la aplicación.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _identifierController,
                      enabled: !_codeRequested,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Correo o WhatsApp de tu cuenta',
                        hintText: 'correo@ejemplo.com o +573001234567',
                        prefixIcon: Icon(Icons.person_search),
                      ),
                      validator: _identifierValidator,
                    ),
                    if (_codeRequested) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'Código de 6 dígitos',
                        ),
                        validator: (value) =>
                            value != null && RegExp(r'^\d{6}$').hasMatch(value)
                            ? null
                            : 'Ingresa el código de seis dígitos',
                      ),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Nueva contraseña',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            value != null &&
                                value.length >= 8 &&
                                value.contains(RegExp(r'[A-Z]')) &&
                                value.contains(RegExp(r'[a-z]')) &&
                                value.contains(RegExp(r'[0-9]')) &&
                                value.contains(RegExp(r'[^A-Za-z0-9]'))
                            ? null
                            : 'Usa 8 caracteres, mayúscula, minúscula, número y símbolo',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Repite la contraseña',
                        ),
                        validator: (value) => value == _passwordController.text
                            ? null
                            : 'Las contraseñas no coinciden',
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _codeRequested
                                    ? 'Cambiar contraseña'
                                    : 'Enviar código',
                              ),
                      ),
                    ),
                    TextButton(
                      onPressed: _loading ? null : () => context.go('/auth'),
                      child: const Text('Volver al inicio de sesión'),
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
