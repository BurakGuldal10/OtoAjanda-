import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../utils/error_handler.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onToggle;
  const RegisterScreen({super.key, required this.onToggle});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _galeriAdiController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _galeriAdiController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final result = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        galeriAdi: _galeriAdiController.text.trim(),
      );
      if (mounted) {
        final msg = result.needsEmailConfirmation
            ? 'Kayıt oluşturuldu! E-posta adresinize gönderilen onay linkine '
                'tıkladıktan sonra giriş yapabilirsiniz.'
            : 'Kayıt başarılı! Giriş yapabilirsiniz.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 6),
          ),
        );
        widget.onToggle();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppError.auth(e)),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isMobile => MediaQuery.sizeOf(context).width < 700;

  @override
  Widget build(BuildContext context) {
    return _isMobile ? _buildMobile() : _buildDesktop();
  }

  // ── Mobil düzen ───────────────────────────────────────────────────
  Widget _buildMobile() {
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration:
                    const BoxDecoration(gradient: AppTheme.authGradient),
                padding: const EdgeInsets.fromLTRB(28, 48, 28, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 32),
                    Text(
                      'Hesap\nOluşturun',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dakikalar içinde başlayın',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF93C5FD),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: _buildForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Masaüstü düzen ────────────────────────────────────────────────
  Widget _buildDesktop() {
    return Scaffold(
      backgroundColor: AppTheme.bgCard,
      body: Row(
        children: [
          // Sol panel — branding
          Expanded(
            flex: 42,
            child: Container(
              decoration:
                  const BoxDecoration(gradient: AppTheme.authGradient),
              padding:
                  const EdgeInsets.symmetric(horizontal: 52, vertical: 44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLogo(),
                  const Spacer(flex: 2),
                  Text(
                    'Galerinizi\ndijitale\ntaşıyın.',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ücretsiz hesap oluşturun ve araç\nyönetimine hemen başlayın.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF93C5FD),
                      fontSize: 15,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildStep('1', 'Galeri adınızı belirleyin'),
                  const SizedBox(height: 16),
                  _buildStep('2', 'E-posta ve şifrenizi girin'),
                  const SizedBox(height: 16),
                  _buildStep('3', 'Araç eklemeye hemen başlayın'),
                  const Spacer(flex: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Text(
                      'Ücretsiz  ·  Supabase bulut altyapısı',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF475569),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sağ panel — form
          Expanded(
            flex: 58,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 48, vertical: 44),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hesap Oluşturun',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bilgilerinizi girerek ücretsiz başlayın',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 36),
                      _buildForm(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Ortak form ────────────────────────────────────────────────────
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Galeri Adı'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _galeriAdiController,
            style: GoogleFonts.inter(
                fontSize: 14, color: AppTheme.textPrimary),
            decoration: _inputDecoration(
                'ABC Otomotiv', Icons.store_outlined),
            validator: (v) =>
                v == null || v.isEmpty ? 'Galeri adı gerekli' : null,
          ),
          const SizedBox(height: 18),
          _buildLabel('E-posta'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.inter(
                fontSize: 14, color: AppTheme.textPrimary),
            decoration: _inputDecoration(
                'ornek@email.com', Icons.email_outlined),
            validator: (v) {
              if (v == null || v.isEmpty) return 'E-posta gerekli';
              if (!v.contains('@')) return 'Geçerli bir e-posta girin';
              return null;
            },
          ),
          const SizedBox(height: 18),
          _buildLabel('Şifre'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: GoogleFonts.inter(
                fontSize: 14, color: AppTheme.textPrimary),
            decoration: _inputDecoration(
                    '••••••••', Icons.lock_outlined)
                .copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: AppTheme.textMuted,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Şifre gerekli';
              if (v.length < 6) return 'En az 6 karakter gerekli';
              return null;
            },
          ),
          const SizedBox(height: 28),

          // Kayıt butonu
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _isLoading ? null : _register,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Hesap Oluştur',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Giriş linki
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Hesabınız var mı? ',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppTheme.textSecondary),
              ),
              GestureDetector(
                onTap: widget.onToggle,
                child: Text(
                  'Giriş yapın',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Yardımcı widget'lar ───────────────────────────────────────────
  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: const Icon(Icons.directions_car_rounded,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          'GaleriPro',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.primaryMid.withValues(alpha: 0.25),
            shape: BoxShape.circle,
            border: Border.all(
                color: AppTheme.primaryMid.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.inter(
                color: const Color(0xFF93C5FD),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          text,
          style: GoogleFonts.inter(
              color: const Color(0xFFCBD5E1), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppTheme.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: AppTheme.textMuted),
    );
  }
}
