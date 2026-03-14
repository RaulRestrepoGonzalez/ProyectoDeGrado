import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/repositories/user_repository.dart';
import '../../widgets/post_card.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; 

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final _repository = UserRepository();
  late TabController _tabController;
  
  bool _isLoading = true;
  String? _error;
  
  Map<String, dynamic>? _myUserInfo; 
  Map<String, dynamic>? _remoteProfileData; 

  bool _isFollowing = false;
  int _seguidoresCount = 0;
  bool _isTogglingFollow = false;

  bool get _isMyProfile => widget.userId == null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isMyProfile) {
        _myUserInfo = await AuthService.instance.getUserInfo();
        final myId = _myUserInfo?['_id'] ?? _myUserInfo?['userId'];
        if (myId != null) {
          final data = await _repository.getUserProfile(myId);
          _remoteProfileData = data;
        }
      } else {
        final data = await _repository.getUserProfile(widget.userId!);
        _remoteProfileData = data;
        
        final userObj = data['usuario'] ?? {};
        _isFollowing = userObj['isFollowing'] ?? false;
        _seguidoresCount = userObj['seguidoresCount'] ?? 0;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_isTogglingFollow || widget.userId == null) return;

    setState(() => _isTogglingFollow = true);
    try {
      final res = await _repository.toggleFollow(widget.userId!);
      if (mounted) {
        setState(() {
          _isFollowing = res['isFollowing'] ?? false;
          _seguidoresCount = res['seguidoresCount'] ?? _seguidoresCount;
        });
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
         );
      }
    } finally {
      if (mounted) setState(() => _isTogglingFollow = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error', style: const TextStyle(color: Colors.redAccent)),
              TextButton(onPressed: _loadProfileData, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    final userObj = _remoteProfileData?['usuario'] ?? _myUserInfo ?? {};
    final publicacionesRecientes = _remoteProfileData?['publicacionesRecientes'] as List? ?? [];
    final publicacionesGustadas = _remoteProfileData?['publicacionesGustadas'] as List? ?? [];
    final siguiendo = _remoteProfileData?['siguiendo'] as List? ?? [];

    final String name = userObj['nombre'] ?? 'Usuario';
    final String email = userObj['email'] ?? '@usuario';
    final String role = userObj['rol'] ?? 'N/A';
    
    final int sigosCounts = userObj['siguiendoCount'] ?? siguiendo.length;
    final int followersCount = _isMyProfile ? (userObj['seguidoresCount'] ?? 0) : _seguidoresCount;
    
    // Suma de likes como métrica de TikTok
    int totalLikes = 0;
    for (var post in publicacionesRecientes) {
      totalLikes += (post['likesCount'] as int? ?? 0);
    }

    return Scaffold(
      appBar: _isMyProfile ? null : AppBar(title: Text(name)),
      body: NestedScrollView(
        headerSliverBuilder: (context, bool innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                   const SizedBox(height: 24),
                   CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white12,
                      backgroundImage: userObj['fotoPerfil'] != null 
                          ? NetworkImage(userObj['fotoPerfil'])
                          : null,
                      child: userObj['fotoPerfil'] == null 
                          ? const Icon(Icons.person, size: 50, color: Colors.white70)
                          : null,
                   ),
                   const SizedBox(height: 12),
                   Text('@${email.split('@')[0]}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   Text(role.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                   
                   if (userObj['telefono'] != null && userObj['telefono'].toString().trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                            const Icon(Icons.phone, size: 16, color: Color(0xFF4ADE80)),
                            const SizedBox(width: 6),
                            Text(userObj['telefono'], style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                         ],
                      )
                   ],

                   const SizedBox(height: 20),
                   // Contadores estilo TikTok
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                        _buildStatColumn('Siguiendo', sigosCounts),
                        _buildDivider(),
                        _buildStatColumn('Seguidores', followersCount),
                        _buildDivider(),
                        _buildStatColumn('Me gusta', totalLikes),
                     ],
                   ),
                   
                   const SizedBox(height: 20),
                   // Botones de acción
                   if (_isMyProfile) ...[
                     Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         ElevatedButton(
                           onPressed: () async {
                              final updated = await context.push('/edit-profile');
                              if (updated == true) {
                                 _loadProfileData(); // Auto Refresh!
                              }
                           }, 
                           style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.white12,
                             foregroundColor: AppColors.textPrimary,
                             padding: const EdgeInsets.symmetric(horizontal: 32)
                           ),
                           child: const Text('Editar perfil')
                         ),
                         const SizedBox(width: 8),
                         IconButton(
                           onPressed: () async {
                              await AuthService.instance.logout();
                              if (context.mounted) context.go('/auth');
                           }, 
                           icon: const Icon(Icons.logout, color: Colors.redAccent),
                           style: IconButton.styleFrom(backgroundColor: Colors.white12),
                         )
                       ]
                     ),
                     // Botón de cartera para compañia e independiente
                     if (role == 'compañia' || role == 'independiente') ...[
                       const SizedBox(height: 10),
                       TextButton.icon(
                         onPressed: () => context.push('/wallet'),
                         icon: const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.accent),
                         label: const Text('Mi Cartera', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                       ),
                     ],
                   ] else
                     ElevatedButton(
                       onPressed: _isTogglingFollow ? null : _toggleFollow,
                       style: ElevatedButton.styleFrom(
                         backgroundColor: _isFollowing ? Colors.white12 : Colors.blueAccent,
                         foregroundColor: Colors.white,
                         padding: const EdgeInsets.symmetric(horizontal: 40)
                       ),
                       child: _isTogglingFollow 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_isFollowing ? 'Siguiendo' : 'Seguir', style: const TextStyle(fontWeight: FontWeight.bold)),
                     ),

                   const SizedBox(height: 16),
                ]
              )
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on)),
                    Tab(icon: Icon(Icons.favorite_border)),
                    Tab(icon: Icon(Icons.people_outline)),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Posts
            _buildPostList(publicacionesRecientes),
            // Tab 2: Likes
            _buildPostList(publicacionesGustadas),
            // Tab 3: Siguiendo
            _buildFollowingList(siguiendo),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(value.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.white24,
    );
  }

  Widget _buildPostList(List<dynamic> posts) {
    if (posts.isEmpty) {
      return const Center(child: Text('Aún no hay publicaciones.', style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: PostCard(
            post: posts[index],
            onRefresh: _loadProfileData,
          ),
        );
      },
    );
  }

  Widget _buildFollowingList(List<dynamic> following) {
     if(following.isEmpty) {
        return const Center(child: Text('No sigue a nadie.', style: TextStyle(color: Colors.white54)));
     }
     return ListView.builder(
        itemCount: following.length,
        itemBuilder: (context, index) {
           final user = following[index];
           return ListTile(
              leading: const CircleAvatar(
                 backgroundColor: Colors.white12,
                 child: Icon(Icons.person, color: Colors.white70)
              ),
              title: Text(user['nombre'] ?? 'Usuario'),
              subtitle: Text(user['rol'] ?? 'usuario'),
              onTap: () {
                 final uId = user['_id'];
                 if (uId != null) {
                    context.push('/profile/$uId');
                 }
              },
           );
        }
     );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
