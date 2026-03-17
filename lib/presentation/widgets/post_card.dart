import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/post_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import 'audio_wave_painter.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback onRefresh;

  const PostCard({
    super.key,
    required this.post,
    required this.onRefresh,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final _repository = PostRepository();
  late bool _hasLiked;
  late int _likesCount;
  bool _isLoadingLike = false;

  @override
  void initState() {
    super.initState();
    _hasLiked = widget.post['hasLiked'] ?? false;
    _likesCount = widget.post['likesCount'] ?? 0;
  }

  Future<void> _toggleLike() async {
    if (_isLoadingLike) return;
    setState(() => _isLoadingLike = true);

    try {
      final res = await _repository.toggleLike(widget.post['_id']);
      if (mounted) {
        setState(() {
          _hasLiked = res['hasLiked'];
          _likesCount = res['likesCount'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLike = false);
    }
  }

  Future<void> _handleMenuAction(String value) async {
    final postId = widget.post['_id'];

    try {
      if (value == 'favorite') {
        await _repository.toggleFavorite(postId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Favoritos actualizado.')),
        );
      } else if (value == 'block') {
        await _repository.blockPost(postId);
        widget.onRefresh(); // Refresh feed to hide it
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publicación bloqueada y oculta del feed.')),
        );
      } else if (value == 'report') {
        await _repository.reportPost(postId, 'OFENSIVO', 'Reportado vía app.');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publicación denunciada.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final autor = widget.post['autor'] ?? {};
    final String authorName = autor['nombre'] ?? 'Usuario Desconocido';
    final String authorRole = autor['rol'] ?? 'usuario';

    final String tipoPost = widget.post['tipoPost'] ?? 'GENERAL';
    final int? vacantes = widget.post['vacantes'];
    final num? precio = widget.post['precio'];
    final List<dynamic> evidencias = widget.post['evidencias'] ?? [];
    final String tipoEvidencia = widget.post['tipoEvidencia'] ?? 'IMAGEN';
    final int? duracionAudio = widget.post['duracionAudio'];

    final createdAt = DateTime.tryParse(widget.post['createdAt'] ?? '');
    final String timeStr = createdAt != null 
        ? '${createdAt.day}/${createdAt.month}/${createdAt.year}' 
        : 'Reciente';

    final telefono = autor['telefono']?.toString() ?? '';

    // URL helper for WhatsApp
    Future<void> launchWhatsApp() async {
      if (telefono.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('El autor no tiene un número registrado.')),
        );
        return;
      }
      
      // Clean phone number (remove spaces, plus, etc.)
      final cleanPhone = telefono.replaceAll(RegExp(r'\D'), '');
      
      // Check if it's a valid number. We prepend the country code if not present, assuming 57 (Colombia) as default. 
      // Modify as needed for the target audience.
      final fullPhone = cleanPhone.startsWith('57') ? cleanPhone : '57$cleanPhone';
      
      final url = Uri.parse("https://wa.me/$fullPhone");
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
        );
      }
    }

    final hasImage = evidencias.isNotEmpty && tipoEvidencia != 'AUDIO';

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7, // Altura fija para feed estilo TikTok/Shorts
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Media (Image, Video, or Audio placeholder)
          if (hasImage)
            Image.network(
              evidencias.first,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade900),
            )
          else if (tipoEvidencia == 'AUDIO')
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade900, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                children: [
                  // Ondas de audio animadas
                  Positioned.fill(
                    child: CustomPaint(
                      painter: AudioWavePainter(),
                    ),
                  ),
                  // Icono de audio
                  const Center(
                    child: Icon(Icons.audiotrack, size: 60, color: Colors.white70),
                  ),
                  // Duración del audio
                  if (duracionAudio != null)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${duracionAudio}s',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade900, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(
                child: Icon(Icons.music_note, size: 80, color: Colors.white12),
              ),
            ),

          // 2. Dark Overlay at the bottom for readability
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3. User Info & Content (Left Side, Bottom)
          Positioned(
            bottom: 20,
            left: 16,
            right: 80, // Space for right actions
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        final autorId = autor['_id'];
                        if (autorId != null) context.push('/profile/$autorId');
                      },
                      child: const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person, color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authorName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [const Shadow(color: Colors.black, blurRadius: 4)],
                            ),
                          ),
                          Text(
                            '$authorRole • $timeStr',
                            style: const TextStyle(color: Colors.white70, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Etiqueta de Tipo de Post
                if (tipoPost != 'GENERAL')
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: tipoPost == 'BUSCANDO_PERSONAL' ? Colors.blue.withOpacity(0.8) : Colors.amber.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tipoPost == 'BUSCANDO_PERSONAL' ? 'Buscando Personal' : 'Busca Oportunidad',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),

                Text(
                  widget.post['contenido'] ?? '',
                  style: const TextStyle(color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Vacantes y Precio
                if (vacantes != null || precio != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        if (vacantes != null) ...[
                          const Icon(Icons.people, size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text('Vacantes: $vacantes', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          const SizedBox(width: 12),
                        ],
                        if (precio != null) ...[
                          const Icon(Icons.monetization_on, size: 14, color: Colors.greenAccent),
                          const SizedBox(width: 4),
                          Text('\$$precio', style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // 4. Actions (Right Side)
          Positioned(
            bottom: 20,
            right: 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Favorite/Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 30),
                  onSelected: _handleMenuAction,
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'favorite',
                      child: Text('Favoritos'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'block',
                      child: Text('Bloquear'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'report',
                      child: Text('Reportar', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Like Button
                InkWell(
                  onTap: _toggleLike,
                  child: Column(
                    children: [
                      Icon(
                        _hasLiked ? Icons.favorite : Icons.favorite_border,
                        size: 35,
                        color: _hasLiked ? Colors.redAccent : Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text('$_likesCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Contact / WhatsApp Button
                InkWell(
                  onTap: launchWhatsApp,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.message, size: 24, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      const Text('Contactar', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
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
