import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/post_repository.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _repository = PostRepository();
  final _contentController = TextEditingController();
  final _vacantesController = TextEditingController();
  final _precioController = TextEditingController();

  bool _isLoading = false;
  String _tipoPost = 'GENERAL';
  final List<File> _evidencias = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _contentController.dispose();
    _vacantesController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_evidencias.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 5 evidencias permitidas.')),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _evidencias.add(File(image.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _evidencias.removeAt(index);
    });
  }

  void _showTokensAlert() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.toll_rounded, color: AppColors.accent),
            SizedBox(width: 10),
            Text(
              'Tokens agotados',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: const Text(
          'Has superado las 3 publicaciones gratuitas.\n\nRecarga tokens en tu Cartera para seguir publicando.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('/wallet');
            },
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: const Text('Ir a la Cartera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      int? vacantes = int.tryParse(_vacantesController.text.trim());
      double? precio = double.tryParse(_precioController.text.trim());
      final paths = _evidencias.map((f) => f.path).toList();

      await _repository.createPost(
        contenido: content,
        tipoPost: _tipoPost,
        vacantes: vacantes,
        precio: precio,
        evidencias: paths,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Publicación creada con éxito!')),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.toLowerCase().contains('token') ||
          errorMsg.contains('needsTokens') ||
          errorMsg.contains('402') ||
          errorMsg.contains('gratuitas')) {
        _showTokensAlert();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.accentDark,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showVacantesPrecio =
        _tipoPost == 'BUSCANDO_PERSONAL' || _tipoPost == 'BUSCANDO_OPORTUNIDAD';
    final showEvidencias = _tipoPost == 'BUSCANDO_OPORTUNIDAD' || _tipoPost == 'GENERAL';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Publicación'),
        actions: [
          TextButton(
            onPressed: _isLoading || _contentController.text.trim().isEmpty
                ? null
                : _submitPost,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  )
                : const Text(
                    'Publicar',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Tipo de Publicación
              DropdownButtonFormField<String>(
                initialValue: _tipoPost,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Publicación',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'GENERAL',
                    child: Text('Publicación General'),
                  ),
                  DropdownMenuItem(
                    value: 'BUSCANDO_PERSONAL',
                    child: Text('Buscando Personal (Ofrezco empleo)'),
                  ),
                  DropdownMenuItem(
                    value: 'BUSCANDO_OPORTUNIDAD',
                    child: Text('Buscando Oportunidad (Busco empleo)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _tipoPost = val;
                      if (![
                        'BUSCANDO_PERSONAL',
                        'BUSCANDO_OPORTUNIDAD',
                      ].contains(_tipoPost)) {
                        _vacantesController.clear();
                        _precioController.clear();
                      }
                      if (_tipoPost != 'BUSCANDO_OPORTUNIDAD' && _tipoPost != 'GENERAL') {
                        _evidencias.clear();
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // 2. Contenido
              Container(
                constraints: const BoxConstraints(minHeight: 120),
                child: TextField(
                  controller: _contentController,
                  autofocus: true,
                  maxLines: 5,
                  maxLength: 1000,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText:
                        '¿Qué estás buscando o quieres compartir? (Músicos, instrumentos, bandas...)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),

              // 3. Vacantes y Precio
              if (showVacantesPrecio) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _vacantesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Nº Vacantes',
                          prefixIcon: Icon(
                            Icons.people,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _precioController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Precio \$',
                          prefixIcon: Icon(
                            Icons.monetization_on,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // 4. Evidencias
              if (showEvidencias) ...[
                const SizedBox(height: 24),
                const Text(
                  'Evidencias (Fotos o Videos):',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...List.generate(_evidencias.length, (index) {
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              image: DecorationImage(
                                image: FileImage(_evidencias[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    if (_evidencias.length < 5)
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(14),
                            color: AppColors.surface,
                          ),
                          child: const Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
