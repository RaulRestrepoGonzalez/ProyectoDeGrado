import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/repositories/user_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _repository = UserRepository();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  String _selectedRole = 'artista';
  final List<String> _rolesList = ['compañia', 'independiente', 'artista'];

  File? _selectedImage;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _loadMyData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadMyData() async {
    try {
      final userInfo = await AuthService.instance.getUserInfo();
      if (userInfo != null) {
        final userId = userInfo['_id'] ?? userInfo['userId'];
        if (userId != null) {
          final mappedUser = await _repository.getUserProfile(userId);
          final userObj = mappedUser['usuario'] ?? {};

          setState(() {
            _nameController.text = userObj['nombre'] as String? ?? '';
            _phoneController.text = userObj['telefono'] as String? ?? '';
            final role = userObj['rol'] as String?;
            if (role != null && _rolesList.contains(role.toLowerCase())) {
              _selectedRole = role.toLowerCase();
            } else {
              _selectedRole = 'artista'; // Fallback for legacy users
            }
            _currentImageUrl = userObj['fotoPerfil'] as String?;
          });
        }
      }
    } catch (e) {
      _error = 'Error cargando datos: ${e.toString()}';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    final newName = _nameController.text.trim();
    if (newName.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El nombre es demasiado corto',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedUser = await _repository.updateUserProfile(
        nombre: newName,
        rol: _selectedRole,
        telefono: _phoneController.text.trim(),
        imagePath: _selectedImage?.path,
      );

      // Actualizamos la caché local del JWT o la de AuthService para no arrastrar avatar viejo
      final tokens = await AuthService.instance.getStoredTokens();
      if (tokens != null) {
        await AuthService.instance.saveTokens(
          tokens['token']!,
          tokens['refreshToken']!,
        ); // Esto refresca user info interno
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Perfil actualizado correctamente',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Retornamos al perfil. Pop() para forzar refresh si lo llamamos con await.
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al guardar: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveChanges,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blueAccent,
                    ),
                  )
                : const Text(
                    'Guardar',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white12,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!) as ImageProvider
                              : (_currentImageUrl != null
                                    ? NetworkImage(_currentImageUrl!)
                                    : null),
                          child:
                              (_selectedImage == null &&
                                  _currentImageUrl == null)
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white54,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Toca para cambiar la foto',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),

                  const SizedBox(height: 40),

                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre o Razón Social',
                      prefixIcon: Icon(Icons.badge, color: Colors.white70),
                    ),
                  ),

                  const SizedBox(height: 24),

                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono de Contacto (Opcional)',
                      prefixIcon: Icon(Icons.phone, color: Colors.white70),
                    ),
                  ),

                  const SizedBox(height: 24),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Perfil',
                      prefixIcon: Icon(Icons.work, color: Colors.white70),
                    ),
                    items: _rolesList.map((String role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(role[0].toUpperCase() + role.substring(1)),
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
                ],
              ),
            ),
    );
  }
}
