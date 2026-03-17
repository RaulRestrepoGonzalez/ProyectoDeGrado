import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/search_repository.dart';
import '../../widgets/post_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchRepo = SearchRepository();
  final _searchController = TextEditingController();
  Timer? _debounce;
  
  bool _isLoading = false;
  String _error = '';

  List<dynamic> _publicaciones = [];
  List<dynamic> _perfiles = [];
  List<dynamic> _convocatorias = [];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _publicaciones = [];
          _perfiles = [];
          _convocatorias = [];
          _error = '';
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final results = await _searchRepo.searchAll(query);
      if (mounted) {
        setState(() {
          _publicaciones = results['publicaciones'] ?? [];
          _perfiles = results['perfiles'] ?? [];
          _convocatorias = results['convocatorias'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al realizar la búsqueda. ${e.toString().replaceAll('Exception: ', '')}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 80, // Más espacio para la barra de búsqueda
          title: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar músicos, bandas o posts...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                ),
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
          bottom: const TabBar(
            indicatorColor: AppColors.accent,
            indicatorWeight: 3,
            labelColor: AppColors.accent,
            unselectedLabelColor: Colors.white54,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: 'Publicaciones'),
              Tab(text: 'Perfiles'),
              Tab(text: 'Convocatorias'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? Center(child: Text(_error, style: const TextStyle(color: Colors.redAccent)))
                : TabBarView(
                    children: [
                      _buildPostsList(_publicaciones),
                      _buildProfilesList(_perfiles),
                      _buildPostsList(_convocatorias), // Mismo widget que publicaciones
                    ],
                  ),
      ),
    );
  }

  Widget _buildPostsList(List<dynamic> posts) {
    if (posts.isEmpty) {
      return const Center(child: Text('No hay resultados.', style: TextStyle(color: Colors.white54)));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final post = posts[index];
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7, // Altura moderada para lista normal no pantalla completa
          child: PostCard(
            post: post,
            onRefresh: () {}, // No refresh on search
          ),
        );
      },
    );
  }

  Widget _buildProfilesList(List<dynamic> profiles) {
    if (profiles.isEmpty) {
      return const Center(child: Text('No hay resultados.', style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        final id = profile['_id'];
        final nombre = profile['nombre'] ?? 'Usuario Desconocido';
        final rol = profile['rol'] ?? 'Sin rol';
        final picture = profile['fotoPerfil'];

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: picture != null ? NetworkImage(picture) : null,
            child: picture == null ? const Icon(Icons.person) : null,
          ),
          title: Text(nombre, style: const TextStyle(color: Colors.white)),
          subtitle: Text(rol, style: const TextStyle(color: Colors.white54)),
          onTap: () {
            if (id != null) context.push('/profile/$id');
          },
        );
      },
    );
  }
}
