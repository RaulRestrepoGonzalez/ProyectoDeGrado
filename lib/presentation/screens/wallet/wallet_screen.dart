import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/wallet_repository.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _repository = WalletRepository();

  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _error;
  int _tokens = 0;
  int _publicacionesLibres = 0;
  String? _selectedPlan;

  static const _plans = [
    {
      'id': 'basico',
      'nombre': 'Plan Básico',
      'tokens': 5,
      'precio': 1.00,
      'descripcion': '5 tokens mensuales',
      'icon': Icons.bolt,
      'color': AppColors.accent,
    },
    {
      'id': 'pro',
      'nombre': 'Plan Pro',
      'tokens': 15,
      'precio': 3.00,
      'descripcion': '15 tokens mensuales',
      'icon': Icons.workspace_premium,
      'color': Color(0xFFFBBF24), // amber
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    try {
      final data = await _repository.getWallet();
      if (mounted) {
        setState(() {
          _tokens = (data['tokens'] as num?)?.toInt() ?? 0;
          _publicacionesLibres = (data['publicacionesLibresRestantes'] as num?)?.toInt() ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _confirmPurchase() async {
    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecciona un plan antes de continuar.'),
          backgroundColor: AppColors.surface,
        ),
      );
      return;
    }
    setState(() => _isPurchasing = true);
    try {
      final result = await _repository.purchasePlan(_selectedPlan!);
      final newData = result['data'] as Map<String, dynamic>?;
      if (mounted) {
        setState(() {
          _tokens = (newData?['tokens'] as num?)?.toInt() ?? _tokens;
          _publicacionesLibres = (newData?['publicacionesLibresRestantes'] as num?)?.toInt() ?? _publicacionesLibres;
          _selectedPlan = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '¡Compra exitosa!'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade800),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.accent)));
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Cartera')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Balance Banner ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentDark, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Balance de Tokens', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.toll_rounded, color: Colors.white, size: 36),
                      const SizedBox(width: 10),
                      Text('$_tokens', style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      const Text('tokens', style: TextStyle(color: Colors.white70, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _publicacionesLibres > 0
                          ? '📬 Te quedan $_publicacionesLibres publicaciones gratuitas'
                          : '⚡ Usando tokens para publicar',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            const Text('Elige tu Plan', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Los tokens se añaden inmediatamente a tu cartera.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),

            // ── Plan Cards ────────────────────────────────────────────────────
            ..._plans.map((plan) {
              final isSelected = _selectedPlan == plan['id'];
              final color = plan['color'] as Color;
              return GestureDetector(
                onTap: () => setState(() => _selectedPlan = plan['id'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.15) : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? color : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(plan['icon'] as IconData, color: color, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(plan['nombre'] as String, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 2),
                            Text(plan['descripcion'] as String, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('\$${(plan['precio'] as double).toStringAsFixed(0)} USD', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
                          const Text('/mes', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.check_circle_rounded, color: color),
                      ],
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 10),

            // ── Nota legal ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.textSecondary, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Los pagos son responsabilidad exclusiva del titular de la cuenta. Esta plataforma actúa únicamente como intermediaria.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _isPurchasing ? null : _confirmPurchase,
              icon: _isPurchasing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.payment_rounded),
              label: Text(_isPurchasing ? 'Procesando...' : 'Confirmar Pago'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('Simulación de pago – sin cobro real por ahora.', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}
