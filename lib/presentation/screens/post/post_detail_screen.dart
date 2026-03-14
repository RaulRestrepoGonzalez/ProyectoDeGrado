import 'package:flutter/material.dart';

import '../../../data/repositories/post_repository.dart';
import '../../widgets/post_card.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _repository = PostRepository();
  final _commentController = TextEditingController();
  
  Map<String, dynamic>? _post;
  bool _isLoading = true;
  String? _error;
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    _loadPostDetails();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPostDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final post = await _repository.getPostDetails(widget.postId);
      if (mounted) {
        setState(() {
          _post = post;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmittingComment = true);

    try {
      await _repository.comment(widget.postId, text);
      _commentController.clear();
      // Recargar detalles para mostrar el nuevo comentario
      await _loadPostDetails();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _isSubmittingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comentarios')),
      body: _buildBody(),
      bottomNavigationBar: _buildCommentInput(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text('Error: $_error', style: const TextStyle(color: Colors.white70)),
            TextButton(onPressed: _loadPostDetails, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    if (_post == null) return const Center(child: Text('Publicación no encontrada.'));

    final comentarios = _post!['comentarios'] as List<dynamic>? ?? [];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: PostCard(
              post: _post!,
              onRefresh: _loadPostDetails, // if blocked, reloads and throws 404 (ok)
            ),
          ),
        ),
        const SliverToBoxAdapter(child: Divider()),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final c = comentarios[index];
              final autor = c['autor'] ?? {};
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.white12,
                  child: Icon(Icons.person, color: Colors.white54),
                ),
                title: Text(
                  autor['nombre'] ?? 'Usuario',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(c['texto'] ?? '', style: const TextStyle(fontSize: 15)),
                isThreeLine: false,
              );
            },
            childCount: comentarios.length,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentInput() {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 8,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: const Border(top: BorderSide(color: Colors.white12)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Escribe un comentario...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white12,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _submitComment(),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: _isSubmittingComment
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send, color: Colors.blueAccent),
              onPressed: _commentController.text.trim().isEmpty || _isSubmittingComment 
                  ? null 
                  : _submitComment,
            ),
          ],
        ),
      ),
    );
  }
}
