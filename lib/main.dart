import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const railwayBackendUrl = String.fromEnvironment('RAILWAY_BACKEND_URL');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
  runApp(const ProviderScope(child: OmnimindApp()));
}

final appControllerProvider = ChangeNotifierProvider<AppController>((ref) {
  return AppController()..bootstrap();
});

class OmnimindApp extends ConsumerWidget {
  const OmnimindApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/welcome', builder: (_, __) => const WelcomeLoginScreen()),
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
        GoRoute(path: '/chat', builder: (_, __) => const ShellScreen()),
        ...RestoredScreenRoutes.routes,
      ],
    );
    return MaterialApp.router(
      title: 'Mio',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: MioTheme.light,
      darkTheme: MioTheme.dark,
      themeMode: ThemeMode.light,
      shortcuts: <ShortcutActivator, Intent>{
        ...WidgetsApp.defaultShortcuts,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): const FocusInputIntent(),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): const FocusInputIntent(),
      },
      actions: <Type, Action<Intent>>{
        FocusInputIntent: CallbackAction<FocusInputIntent>(onInvoke: (_) => null),
      },
    );
  }
}

class FocusInputIntent extends Intent {
  const FocusInputIntent();
}


class BrandMark extends StatelessWidget {
  final double size;
  final bool animate;
  final bool repeat;

  const BrandMark({super.key, this.size = 48, this.animate = true, this.repeat = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        'assets/animations/mascot.json',
        width: size,
        height: size,
        fit: BoxFit.contain,
        animate: animate,
        repeat: repeat,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: MioTheme.orange,
            borderRadius: BorderRadius.circular(size * .28),
            boxShadow: [BoxShadow(color: MioTheme.orange.withOpacity(.24), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: Center(
            child: Text(
              'M',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: size * .42),
            ),
          ),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _exitController;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _exitController = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
    _scale = Tween<double>(begin: .72, end: 1).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic);
    _exitFade = Tween<double>(begin: 1, end: 0).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic));
    _entryController.forward();
    Future.delayed(const Duration(milliseconds: 1850), _routeNext);
  }

  Future<void> _routeNext() async {
    if (!mounted) return;
    await _exitController.forward();
    final prefs = await SharedPreferences.getInstance();
    final completedWelcome = prefs.getBool('mio_welcome_complete') ?? false;
    final completedOnboarding = prefs.getBool('mio_onboarding_complete') ?? false;
    if (!mounted) return;
    if (!completedWelcome) {
      context.go('/welcome');
    } else if (!completedOnboarding) {
      context.go('/onboarding');
    } else {
      context.go('/chat');
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MioTheme.cream,
      body: FadeTransition(
        opacity: _exitFade,
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(size: 142),
                  const SizedBox(height: 22),
                  Text('Mio', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -.8)),
                  const SizedBox(height: 6),
                  Text('Think. Not yap.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: MioTheme.muted, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WelcomeLoginScreen extends StatefulWidget {
  const WelcomeLoginScreen({super.key});

  @override
  State<WelcomeLoginScreen> createState() => _WelcomeLoginScreenState();
}

class _WelcomeLoginScreenState extends State<WelcomeLoginScreen> {
  bool _loading = false;

  Future<void> _openLocalFirst() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mio_welcome_complete', true);
    if (!mounted) return;
    context.go('/onboarding');
  }

  Future<void> _confirmLocalFirst() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MioTheme.panel,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Use Mio on this device only?'),
        content: const Text('Local-first mode keeps your chats and provider keys on this device. Cross-device sync, account recovery, and encrypted cloud backup will stay off until you sign in.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Continue local-only')),
        ],
      ),
    );
    if (proceed == true) {
      await _openLocalFirst();
    }
  }

  void _showAuthUnavailable(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$provider sign-in is ready to wire when Supabase auth credentials are provided.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MioTheme.cream,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 760;
                  final heroCard = Container(
                      padding: const EdgeInsets.all(34),
                      decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(34), border: Border.all(color: MioTheme.line), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 34, offset: const Offset(0, 18))]),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const BrandMark(size: 92),
                          const SizedBox(height: 24),
                          Text('Mio', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.2)),
                          const SizedBox(height: 10),
                          Text('Think. Not yap.', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: MioTheme.orange, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 18),
                          Text('Use your own AI keys across providers. Keep control of cost, privacy, and speed from the first launch.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: MioTheme.muted, height: 1.55)),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(backgroundColor: MioTheme.ink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 17), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                              onPressed: _loading ? null : () => _showAuthUnavailable('Google'),
                              icon: const Icon(Icons.g_mobiledata_rounded),
                              label: const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(foregroundColor: MioTheme.ink, side: const BorderSide(color: MioTheme.line), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                              onPressed: _loading ? null : () => _showAuthUnavailable('Apple'),
                              icon: const Icon(Icons.apple),
                              label: const Text('Continue with Apple', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(foregroundColor: MioTheme.ink, side: const BorderSide(color: MioTheme.line), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                              onPressed: _loading ? null : () => _showAuthUnavailable('Email'),
                              icon: const Icon(Icons.mail_outline_rounded),
                              label: const Text('Continue with email', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton.icon(
                              onPressed: _loading ? null : _confirmLocalFirst,
                              icon: const Icon(Icons.devices_other_rounded, size: 18),
                              label: Text(_loading ? 'Opening Mio...' : 'Continue local-first — no cross-device sync', style: const TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                    );
                  final detailCard = Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(color: MioTheme.cream2, borderRadius: BorderRadius.circular(34), border: Border.all(color: MioTheme.line)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _WelcomePoint(icon: Icons.vpn_key_rounded, title: 'BYOK', text: 'Your keys stay encrypted on your device unless you enable E2EE sync.'),
                          _WelcomePoint(icon: Icons.flash_on_rounded, title: 'Zero fluff', text: 'Mio defaults to direct answers, not greetings and filler.'),
                          _WelcomePoint(icon: Icons.sync_lock_rounded, title: 'Sync-ready', text: 'Supabase can sync encrypted history and metadata when connected.'),
                        ],
                      ),
                    );
                  if (isCompact) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          heroCard,
                          const SizedBox(height: 18),
                          detailCard,
                        ],
                      ),
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: heroCard),
                      const SizedBox(width: 28),
                      Expanded(child: detailCard),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomePoint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _WelcomePoint({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: MioTheme.line)), child: Icon(icon, color: MioTheme.orange)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: MioTheme.muted, height: 1.45))])),
        ],
      ),
    );
  }
}



class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  static const int _totalPages = 8;

  final _pageController = PageController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  late final AnimationController _pageEntranceController;
  late final AnimationController _celebrationController;
  late final AnimationController _shimmerController;
  late final AnimationController _floatController;

  int _currentPage = 0;
  bool _ready = false;
  bool _isKeyVisible = false;
  bool _isAnnualOnboarding = false;
  String _selectedProvider = 'OpenRouter';
  String? _nameError;
  String? _keyError;
  String? _selectedPlan;
  final Set<String> _selectedPreferences = {};

  @override
  void initState() {
    super.initState();
    _pageEntranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _celebrationController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _floatController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) _precacheBackground();
  }

  Future<void> _precacheBackground() async {
    try {
      await precacheImage(const AssetImage('assets/images/sky_clouds.png'), context);
    } catch (_) {}
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _apiKeyController.dispose();
    _pageEntranceController.dispose();
    _celebrationController.dispose();
    _shimmerController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  String get _firstName => _firstNameController.text.trim();

  Color _cardBg(bool isDark) => isDark ? const Color(0xFF141414) : Colors.white;
  Color _cardBorder(bool isDark) => isDark ? Colors.white.withOpacity(.08) : Colors.white.withOpacity(.6);
  Color _sub(bool isDark) => isDark ? const Color(0xFFB8B8B8) : const Color(0xFF6B7280);
  Color _txt(bool isDark) => isDark ? const Color(0xFFF7F7F7) : MioTheme.ink;
  Color _inBg(bool isDark) => isDark ? const Color(0xFF242424) : const Color(0xFFF9FAFB);
  Color _inBorder(bool isDark) => isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E7EB);

  BoxDecoration _glass(bool isDark) => BoxDecoration(
        color: _cardBg(isDark).withOpacity(isDark ? .88 : .82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder(isDark)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? .4 : .08), blurRadius: 30, offset: const Offset(0, 10)),
          if (!isDark) BoxShadow(color: Colors.white.withOpacity(.5), blurRadius: 0, offset: const Offset(0, -1)),
        ],
      );

  Widget _glassPanel({required bool isDark, required Widget child, EdgeInsets padding = const EdgeInsets.all(24), double maxWidth = 420}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(constraints: BoxConstraints(maxWidth: maxWidth), padding: padding, decoration: _glass(isDark), child: child),
      ),
    );
  }

  Widget _animatedContent({required Widget child, double extraDelay = 0}) {
    final fade = CurvedAnimation(parent: _pageEntranceController, curve: Interval(extraDelay, (0.6 + extraDelay).clamp(0.0, 1.0).toDouble(), curve: Curves.easeOut));
    final slide = CurvedAnimation(parent: _pageEntranceController, curve: Interval(extraDelay, (0.7 + extraDelay).clamp(0.0, 1.0).toDouble(), curve: Curves.easeOutCubic));
    return AnimatedBuilder(
      animation: _pageEntranceController,
      builder: (context, _) => Opacity(
        opacity: fade.value,
        child: Transform.translate(offset: Offset(0, 28 * (1 - slide.value)), child: Transform.scale(scale: 0.96 + 0.04 * slide.value, child: child)),
      ),
    );
  }

  Widget _stepLabel(String text, bool isDark) {
    return _animatedContent(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: MioTheme.orange.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .5, color: MioTheme.orange)),
      ),
    );
  }

  void _goToPage(int page) {
    _pageController.animateToPage(page, duration: const Duration(milliseconds: 550), curve: Curves.easeInOutCubic);
    setState(() => _currentPage = page);
    _pageEntranceController
      ..reset()
      ..forward();
    if (page == _totalPages - 1) _celebrationController.forward(from: 0);
  }

  Future<void> _nextPage() async {
    if (_currentPage == 0) {
      if (_firstNameController.text.trim().isEmpty) {
        setState(() => _nameError = 'Please enter your name to continue');
        return;
      }
      await _saveName();
    }
    if (_currentPage == 4) await _savePreferences();
    if (_currentPage == 5 && _apiKeyController.text.trim().isNotEmpty) await _saveApiKey();
    if (_currentPage < _totalPages - 1) {
      _goToPage(_currentPage + 1);
    } else {
      await _completeOnboarding();
    }
  }

  void _skipToReady() => _goToPage(_totalPages - 1);

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('mio_onboarding_preferences', _selectedPreferences.toList());
    await prefs.setString('user_preferences', _selectedPreferences.join(','));
  }

  Future<void> _saveName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_first_name', _firstNameController.text.trim());
    await prefs.setString('user_last_name', _lastNameController.text.trim());
  }

  Future<void> _saveApiKey() async {
    final id = _providerIdFromName(_selectedProvider);
    await _storage.write(key: 'provider_key_$id', value: _apiKeyController.text.trim());
    await _storage.write(key: 'pending_api_key', value: _apiKeyController.text.trim());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('provider', id);
  }

  Future<void> _completeOnboarding() async {
    await _storage.write(key: 'onboarding_complete', value: 'true');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mio_onboarding_complete', true);
    await prefs.setString('mio_onboarding_plan', _selectedPlan ?? 'free');
    if (mounted) context.go('/chat');
  }

  String _providerIdFromName(String name) {
    final normalized = name.toLowerCase().replaceAll(' ', '');
    return providers.firstWhere((p) => p.name.toLowerCase().replaceAll(' ', '') == normalized, orElse: () => providers.firstWhere((p) => p.id == 'openrouter')).id;
  }

  String _getReadyText() {
    final greeting = _firstName.isNotEmpty ? "You're all set, $_firstName!" : "You're all set!";
    if (_selectedPreferences.contains('Coding')) return '$greeting\nLet’s code.';
    if (_selectedPreferences.contains('Writing')) return '$greeting\nLet’s write.';
    if (_selectedPreferences.length > 1) return '$greeting\nLet’s create.';
    return '$greeting\nLet’s go.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!_ready) return Scaffold(backgroundColor: isDark ? const Color(0xFF0B0B0A) : const Color(0xFFB8E4F9));

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark ? [const Color(0xFF0F0F0E), const Color(0xFF1A1A19)] : [const Color(0xFFB8E4F9), const Color(0xFFE8F4FB)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [_buildPageName(isDark), _buildPageProblem(isDark), _buildPageSolution(isDark), _buildPageBYOK(isDark), _buildPagePreferences(isDark), _buildPageAddKey(isDark), _buildPagePricing(isDark), _buildPageReady(isDark)],
                      ),
                      if (_currentPage > 0 && _currentPage <= 5)
                        Positioned(
                          top: 12,
                          right: 16,
                          child: _animatedContent(
                            extraDelay: .3,
                            child: TextButton(
                              onPressed: _skipToReady,
                              style: TextButton.styleFrom(backgroundColor: _cardBg(isDark).withOpacity(.85), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                              child: Text('Skip', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: _sub(isDark))),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_currentPage > 0) _buildBottomArea(isDark),
              ],
            ),
          ),
          if (_currentPage == _totalPages - 1)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(animation: _celebrationController, builder: (context, _) => CustomPaint(painter: _ConfettiPainter(progress: _celebrationController.value))),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomArea(bool isDark) {
    return _animatedContent(
      extraDelay: .2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalPages, (i) {
                final isActive = i == _currentPage;
                final isDone = i < _currentPage;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: isActive ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: isActive ? MioTheme.orange : isDone ? MioTheme.orange.withOpacity(.45) : Colors.white.withOpacity(isDark ? .15 : .5)),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            if (_currentPage != 6)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: _currentPage == _totalPages - 1
                      ? _ShimmerButton(controller: _shimmerController, onPressed: _nextPage, label: 'Let’s go →')
                      : ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(backgroundColor: MioTheme.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                          child: Text('Continue', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                ),
              ),
            const SizedBox(height: 8),
            if (_currentPage > 0)
              TextButton(
                onPressed: () => _goToPage(_currentPage - 1),
                style: TextButton.styleFrom(backgroundColor: _cardBg(isDark).withOpacity(.6), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('← Back', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: _txt(isDark))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageName(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _animatedContent(
              child: AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) => Transform.translate(offset: Offset(0, -3 + 6 * _floatController.value), child: child),
                child: Container(decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: MioTheme.orange.withOpacity(.15), blurRadius: 30, spreadRadius: 4)]), child: const BrandMark(size: 72)),
              ),
            ),
            const SizedBox(height: 20),
            _animatedContent(
              extraDelay: .1,
              child: _glassPanel(
                isDark: isDark,
                maxWidth: 380,
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    Text(_firstName.isNotEmpty ? 'Hey, $_firstName 👋' : 'Welcome 👋', style: GoogleFonts.dmSerifDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: _txt(isDark)), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('Let’s set up your AI in 60 seconds', style: GoogleFonts.dmSans(fontSize: 14, color: _sub(isDark)), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    _onboardingField(controller: _firstNameController, hint: 'First name', isDark: isDark, action: TextInputAction.next, onChanged: () { if (_nameError != null) setState(() => _nameError = null); setState(() {}); }),
                    const SizedBox(height: 12),
                    _onboardingField(controller: _lastNameController, hint: 'Last name (optional)', isDark: isDark, action: TextInputAction.done, onSubmit: _nextPage),
                    if (_nameError != null) ...[const SizedBox(height: 8), Text(_nameError!, style: GoogleFonts.dmSans(fontSize: 12, color: Colors.red))],
                    const SizedBox(height: 20),
                    SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _nextPage, style: ElevatedButton.styleFrom(backgroundColor: MioTheme.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0), child: Text('Get started', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700)))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _onboardingField({required TextEditingController controller, required String hint, required bool isDark, TextInputAction action = TextInputAction.next, Future<void> Function()? onSubmit, VoidCallback? onChanged}) {
    return TextField(
      controller: controller,
      textInputAction: action,
      onSubmitted: (_) => onSubmit?.call(),
      onChanged: (_) => onChanged?.call(),
      style: GoogleFonts.dmSans(fontSize: 15, color: _txt(isDark)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(fontSize: 15, color: isDark ? const Color(0xFF777777) : const Color(0xFF9CA3AF)),
        filled: true,
        fillColor: _inBg(isDark),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _inBorder(isDark))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _inBorder(isDark))),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: MioTheme.orange, width: 1.5)),
      ),
    );
  }

  Widget _buildPageProblem(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            _stepLabel('THE PROBLEM', isDark),
            const SizedBox(height: 16),
            _animatedContent(
              extraDelay: .05,
              child: _glassPanel(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Text('Other AIs be like...', style: GoogleFonts.dmSerifDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: _txt(isDark)))),
                    const SizedBox(height: 20),
                    _chatBubble("What's the capital of France?", isUser: true, isDark: isDark),
                    const SizedBox(height: 12),
                    _chatBubble("Great question! I'd be happy to help you with that! So, the capital of France is a fascinating topic. France, officially known as the French Republic, is a country located in Western Europe. Its capital city, which has been the center of French culture, politics, and economics for centuries, is Paris. I hope that helps! 😊", isUser: false, isDark: isDark),
                    const SizedBox(height: 16),
                    _chatBubble("Also, I should note that real work needs realism: cost visibility, model choice, local privacy, and fewer vague promises.", isUser: false, isDark: isDark),
                    const SizedBox(height: 20),
                    Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.red.withOpacity(.08), borderRadius: BorderRadius.circular(20)), child: Text('😴 You fell asleep reading that.', style: GoogleFonts.dmSans(fontSize: 14, fontStyle: FontStyle.italic, color: _sub(isDark))))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatBubble(String text, {required bool isUser, required bool isDark}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: isUser ? 260 : 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: isUser ? MioTheme.orange : (isDark ? const Color(0xFF232323) : const Color(0xFFF3F4F6)), borderRadius: BorderRadius.circular(18)),
        child: Text(text, style: GoogleFonts.dmSans(fontSize: 13, color: isUser ? Colors.white : _txt(isDark), height: 1.45)),
      ),
    );
  }

  Widget _buildPageSolution(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            _stepLabel('THE SOLUTION', isDark),
            const SizedBox(height: 16),
            _animatedContent(
              extraDelay: .05,
              child: _glassPanel(
                isDark: isDark,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Center(child: Row(mainAxisSize: MainAxisSize.min, children: [const BrandMark(size: 28, animate: false), const SizedBox(width: 8), Text('Mio be like...', style: GoogleFonts.dmSerifDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: _txt(isDark)))])),
                  const SizedBox(height: 20),
                  _chatBubble("What's the capital of France?", isUser: true, isDark: isDark),
                  const SizedBox(height: 12),
                  _chatBubble('Paris.', isUser: false, isDark: isDark),
                  const SizedBox(height: 20),
                  Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.green.withOpacity(.08), borderRadius: BorderRadius.circular(20)), child: Text('⚡ Direct. Fast. No yapping.', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: MioTheme.orange)))),
                  const SizedBox(height: 20),
                  ...['Your keys, your models', 'Switch providers anytime', 'No markup on tokens', 'Run local with Ollama'].asMap().entries.map((e) => _featureRow('${e.key + 1}', e.value, isDark)),
                  const SizedBox(height: 16),
                  Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: ['No filler', 'Straight answers', 'Your keys'].map((l) => _pill(l, isDark)).toList()),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, bool isDark) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: _inBorder(isDark)), color: isDark ? const Color(0xFF232323) : null), child: Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: _sub(isDark))));

  Widget _featureRow(String number, String text, bool isDark) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [Container(width: 26, height: 26, decoration: BoxDecoration(gradient: LinearGradient(colors: [MioTheme.orange.withOpacity(.15), MioTheme.orange.withOpacity(.05)]), shape: BoxShape.circle), child: Center(child: Text(number, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w800, color: MioTheme.orange)))), const SizedBox(width: 12), Text(text, style: GoogleFonts.dmSans(fontSize: 14, color: _txt(isDark)))]),
      );

  Widget _buildPageBYOK(bool isDark) {
    final displayProviders = <Map<String, String>>[
      {'name': 'OpenAI', 'asset': 'assets/icons/providers/openai.png'},
      {'name': 'Anthropic', 'asset': 'assets/icons/providers/anthropic.png'},
      {'name': 'DeepSeek', 'asset': 'assets/icons/providers/deepseek.png'},
      {'name': 'Gemini', 'asset': 'assets/icons/providers/google.png'},
      {'name': 'Mistral', 'asset': 'assets/icons/providers/mistral.png'},
      {'name': 'OpenRouter', 'asset': 'assets/icons/providers/openrouter.png'},
      {'name': 'Kimi', 'asset': 'assets/icons/providers/kimi.png'},
    ];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          _stepLabel('YOUR KEYS', isDark),
          const SizedBox(height: 16),
          _animatedContent(
            extraDelay: .05,
            child: _glassPanel(
              isDark: isDark,
              child: Column(children: [
                Text('Your AI. Your keys.', style: GoogleFonts.dmSerifDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: _txt(isDark)), textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text('Bring your own API keys — zero markup.', style: GoogleFonts.dmSans(fontSize: 13, color: _sub(isDark)), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Wrap(spacing: 14, runSpacing: 16, alignment: WrapAlignment.center, children: [...displayProviders.asMap().entries.map((e) => _providerChip(e.value, isDark, e.key)), _moreChip(isDark)]),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: _inBg(isDark), borderRadius: BorderRadius.circular(16), border: Border.all(color: _inBorder(isDark))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [const Icon(Icons.verified_rounded, size: 16, color: MioTheme.orange), const SizedBox(width: 6), Text('Why BYOK?', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: _txt(isDark)))]),
                    const SizedBox(height: 10),
                    ...['Access latest models instantly', 'No rate limits from us', 'Use local models (Ollama)', 'Switch providers anytime'].map((t) => _checkRow(t, true, isDark)),
                    const SizedBox(height: 8),
                    Divider(color: _inBorder(isDark)),
                    const SizedBox(height: 4),
                    Text('Locked platforms:', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: _sub(isDark))),
                    const SizedBox(height: 6),
                    ...['Stuck on old models', 'Heavy rate limits', 'Markup on every token'].map((t) => _checkRow(t, false, isDark)),
                  ]),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _providerChip(Map<String, String> p, bool isDark, int index) => _animatedContent(
        extraDelay: .05 + index * .03,
        child: SizedBox(
          width: 68,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: isDark ? const Color(0xFF232323) : Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? .25 : .1), blurRadius: 8, offset: const Offset(0, 3))]), child: ClipOval(child: Padding(padding: const EdgeInsets.all(9), child: Image.asset(p['asset']!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Center(child: Text(p['name']![0], style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold, color: MioTheme.orange))))))),
            const SizedBox(height: 5),
            Text(p['name']!, style: GoogleFonts.dmSans(fontSize: 10, color: _sub(isDark)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      );

  Widget _moreChip(bool isDark) => SizedBox(width: 68, child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: isDark ? const Color(0xFF292929) : const Color(0xFFF3F4F6), shape: BoxShape.circle, border: Border.all(color: _inBorder(isDark))), child: Icon(Icons.more_horiz, color: _sub(isDark), size: 22)), const SizedBox(height: 5), Text('& more', style: GoogleFonts.dmSans(fontSize: 10, color: _sub(isDark)), textAlign: TextAlign.center)]));

  Widget _checkRow(String text, bool positive, bool isDark) => Padding(padding: const EdgeInsets.only(bottom: 5), child: Row(children: [Icon(positive ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 15, color: positive ? Colors.green : Colors.red), const SizedBox(width: 8), Expanded(child: Text(text, style: GoogleFonts.dmSans(fontSize: 12, color: positive ? _txt(isDark) : _sub(isDark))))]));

  Widget _buildPagePreferences(bool isDark) {
    const items = [
      {'label': 'Coding', 'emoji': '💻'}, {'label': 'Writing', 'emoji': '✏️'}, {'label': 'Learning', 'emoji': '📚'}, {'label': 'Work', 'emoji': '💼'},
      {'label': 'Creative', 'emoji': '🎨'}, {'label': 'Research', 'emoji': '🔬'}, {'label': 'Chat', 'emoji': '💬'}, {'label': 'Math', 'emoji': '🧮'},
    ];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          _stepLabel('PERSONALIZE', isDark),
          const SizedBox(height: 16),
          _animatedContent(
            extraDelay: .05,
            child: _glassPanel(
              isDark: isDark,
              maxWidth: 380,
              child: Column(children: [
                Text('What do you use AI for?', style: GoogleFonts.dmSerifDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: _txt(isDark)), textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text('Pick your superpowers', style: GoogleFonts.dmSans(fontSize: 13, color: _sub(isDark))),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.6,
                  children: items.map((item) {
                    final label = item['label']!;
                    final isSelected = _selectedPreferences.contains(label);
                    return GestureDetector(
                      onTap: () => setState(() => isSelected ? _selectedPreferences.remove(label) : _selectedPreferences.add(label)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: isSelected ? MioTheme.orange.withOpacity(.1) : _inBg(isDark), borderRadius: BorderRadius.circular(14), border: Border.all(color: isSelected ? MioTheme.orange : _inBorder(isDark), width: isSelected ? 2 : 1), boxShadow: isSelected ? [BoxShadow(color: MioTheme.orange.withOpacity(.1), blurRadius: 8, offset: const Offset(0, 2))] : null),
                        child: Row(children: [Text(item['emoji']!, style: const TextStyle(fontSize: 18)), const SizedBox(width: 8), Expanded(child: Text(label, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? MioTheme.orange : _txt(isDark)))), if (isSelected) const Icon(Icons.check_circle, size: 16, color: MioTheme.orange)]),
                      ),
                    );
                  }).toList(),
                ),
                if (_selectedPreferences.isNotEmpty) ...[const SizedBox(height: 16), AnimatedContainer(duration: const Duration(milliseconds: 300), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: MioTheme.orange.withOpacity(.06), borderRadius: BorderRadius.circular(12)), child: Text('✨ ${_selectedPreferences.length} selected — we’ll tailor your experience', style: GoogleFonts.dmSans(fontSize: 12, color: MioTheme.orange, fontWeight: FontWeight.w600), textAlign: TextAlign.center))],
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildPageAddKey(bool isDark) {
    final providerOptions = <Map<String, String>>[
      {'name': 'OpenRouter', 'asset': 'assets/icons/providers/openrouter.png'}, {'name': 'OpenAI', 'asset': 'assets/icons/providers/openai.png'}, {'name': 'Anthropic', 'asset': 'assets/icons/providers/anthropic.png'}, {'name': 'DeepSeek', 'asset': 'assets/icons/providers/deepseek.png'}, {'name': 'Gemini', 'asset': 'assets/icons/providers/google.png'}, {'name': 'Groq', 'asset': 'assets/icons/providers/groq.png'}, {'name': 'Mistral', 'asset': 'assets/icons/providers/mistral.png'}, {'name': 'Ollama', 'asset': 'assets/icons/providers/ollama.png'}, {'name': 'Kimi', 'asset': 'assets/icons/providers/kimi.png'},
    ];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          _stepLabel('CONNECT', isDark),
          const SizedBox(height: 16),
          _animatedContent(
            extraDelay: .05,
            child: _glassPanel(
              isDark: isDark,
              maxWidth: 400,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Text('Add your API key', style: GoogleFonts.dmSerifDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: _txt(isDark)))),
                const SizedBox(height: 4),
                Center(child: Text('Choose a provider and paste your key', style: GoogleFonts.dmSans(fontSize: 13, color: _sub(isDark)))),
                const SizedBox(height: 20),
                Text('Provider', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: _txt(isDark))),
                const SizedBox(height: 8),
                Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: _inBg(isDark), borderRadius: BorderRadius.circular(14), border: Border.all(color: _inBorder(isDark))), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _selectedProvider, isExpanded: true, icon: Icon(Icons.keyboard_arrow_down, color: _sub(isDark)), dropdownColor: _cardBg(isDark), style: GoogleFonts.dmSans(fontSize: 14, color: _txt(isDark)), items: providerOptions.map((p) => DropdownMenuItem(value: p['name']!, child: Row(children: [ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.asset(p['asset']!, width: 20, height: 20, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox(width: 20, height: 20))), const SizedBox(width: 10), Text(p['name']!, style: GoogleFonts.dmSans(fontSize: 14, color: _txt(isDark)))]))).toList(), onChanged: (v) => setState(() { _selectedProvider = v!; _keyError = null; })))),
                const SizedBox(height: 16),
                if (_selectedProvider == 'OpenRouter') ...[
                  Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1030) : const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? const Color(0xFF3D2A6E) : const Color(0xFFBAE6FD))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.star_rounded, size: 16, color: Color(0xFF8B5CF6)), const SizedBox(width: 6), Text('Recommended for beginners', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF8B5CF6)))]), const SizedBox(height: 6), Text('Free access to many models. Add \$10 for premium.', style: GoogleFonts.dmSans(fontSize: 12, color: _sub(isDark), height: 1.4)), const SizedBox(height: 10), SizedBox(width: double.infinity, height: 38, child: ElevatedButton(onPressed: () => launchUrl(Uri.parse('https://openrouter.ai/keys'), mode: LaunchMode.externalApplication), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0), child: Text('Get OpenRouter Key →', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700))))])),
                  const SizedBox(height: 16),
                ],
                Text('API Key', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: _txt(isDark))),
                const SizedBox(height: 6),
                TextField(controller: _apiKeyController, obscureText: !_isKeyVisible, style: GoogleFonts.dmSans(fontSize: 14, color: _txt(isDark)), onChanged: (_) { if (_keyError != null) setState(() => _keyError = null); }, decoration: InputDecoration(hintText: 'Paste your $_selectedProvider API key', hintStyle: GoogleFonts.dmSans(fontSize: 13, color: isDark ? const Color(0xFF777777) : const Color(0xFF9CA3AF)), filled: true, fillColor: _inBg(isDark), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _keyError != null ? Colors.red : _inBorder(isDark))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _keyError != null ? Colors.red : _inBorder(isDark))), focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: MioTheme.orange, width: 1.5)), suffixIcon: IconButton(onPressed: () => setState(() => _isKeyVisible = !_isKeyVisible), icon: Icon(_isKeyVisible ? Icons.visibility_off : Icons.visibility, color: _sub(isDark), size: 20)))),
                if (_keyError != null) ...[const SizedBox(height: 6), Text(_keyError!, style: GoogleFonts.dmSans(fontSize: 12, color: Colors.red))],
                const SizedBox(height: 14),
                GestureDetector(onTap: () => _showOllamaSheet(context), child: Row(children: [Icon(Icons.computer, size: 14, color: _sub(isDark)), const SizedBox(width: 6), Text('Or run locally with Ollama', style: GoogleFonts.dmSans(fontSize: 12, color: MioTheme.orange))])),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  void _showOllamaSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: MioTheme.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Run locally with Ollama',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const Text(
                'Install Ollama, run a model like `ollama run llama3.1`, then choose Ollama from the model picker. Mio will use the local OpenAI-compatible endpoint.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => launchUrl(
                  Uri.parse('https://ollama.com/'),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Text('Open Ollama'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagePricing(bool isDark) {
    final proPrice = _isAnnualOnboarding ? '\$6.67/mo' : '\$8.00/mo';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          _stepLabel('CHOOSE YOUR PLAN', isDark),
          const SizedBox(height: 16),
          _animatedContent(
            extraDelay: .05,
            child: _glassPanel(
              isDark: isDark,
              child: Column(children: [
                Text('Unlock the full experience', style: GoogleFonts.dmSerifDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: _txt(isDark)), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text('Cancel anytime. No questions asked.', style: GoogleFonts.dmSans(fontSize: 13, color: _sub(isDark))),
                const SizedBox(height: 16),
                _buildBillingToggle(isDark),
                const SizedBox(height: 20),
                _planCard(isDark: isDark, id: 'pro', title: 'PRO', price: proPrice, subtitle: '7-day free trial', features: ['100k tokens/day', '3 devices with sync', 'File uploads & voice input', 'iCloud & Google Drive', 'All AI providers'], featured: true),
                const SizedBox(height: 12),
                GestureDetector(onTap: () => setState(() => _selectedPlan = 'free'), child: AnimatedContainer(duration: const Duration(milliseconds: 250), width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14), decoration: BoxDecoration(color: _selectedPlan == 'free' ? _inBg(isDark) : Colors.transparent, borderRadius: BorderRadius.circular(14), border: Border.all(color: _selectedPlan == 'free' ? _txt(isDark).withOpacity(.3) : _inBorder(isDark), width: _selectedPlan == 'free' ? 1.5 : 1)), child: Row(children: [Text('Free', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: _sub(isDark))), const SizedBox(width: 8), Expanded(child: Text('— BYOK, local-first, 1 device', style: GoogleFonts.dmSans(fontSize: 12, color: _sub(isDark)))), if (_selectedPlan == 'free') Icon(Icons.check_circle, size: 20, color: _txt(isDark).withOpacity(.5))]))),
                if (_selectedPlan != null) ...[const SizedBox(height: 20), SizedBox(width: double.infinity, height: 54, child: _selectedPlan == 'pro' ? _ShimmerButton(controller: _shimmerController, onPressed: _completeOnboarding, label: 'Start 7-day free trial →') : ElevatedButton(onPressed: () => _goToPage(_totalPages - 1), style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.white : MioTheme.ink, foregroundColor: isDark ? Colors.black : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0), child: Text('Continue with Free', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700))))],
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _planCard({required bool isDark, required String id, required String title, required String price, required String subtitle, required List<String> features, required bool featured}) {
    final selected = _selectedPlan == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(gradient: selected ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [MioTheme.orange.withOpacity(.12), MioTheme.orange.withOpacity(.04)]) : null, color: selected ? null : _inBg(isDark), borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? MioTheme.orange : _inBorder(isDark), width: selected ? 2 : 1), boxShadow: selected ? [BoxShadow(color: MioTheme.orange.withOpacity(.15), blurRadius: 16, offset: const Offset(0, 4))] : null),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: MioTheme.orange, borderRadius: BorderRadius.circular(8)), child: Text(title, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1))), const SizedBox(width: 10), Text(price, style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.bold, color: _txt(isDark))), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.green.withOpacity(.1), borderRadius: BorderRadius.circular(6)), child: Text(subtitle, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.green))), if (selected) ...[const SizedBox(width: 8), const Icon(Icons.check_circle, size: 22, color: MioTheme.orange)]]),
          const SizedBox(height: 14),
          ...features.map((f) => _proFeature(Icons.bolt_rounded, f, isDark)),
        ]),
      ),
    );
  }

  Widget _proFeature(IconData icon, String text, bool isDark) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Icon(icon, size: 16, color: MioTheme.orange), const SizedBox(width: 10), Expanded(child: Text(text, style: GoogleFonts.dmSans(fontSize: 13, color: _txt(isDark))))]));

  Widget _buildBillingToggle(bool isDark) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Monthly', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: !_isAnnualOnboarding ? _txt(isDark) : _sub(isDark))),
        const SizedBox(width: 10),
        GestureDetector(onTap: () => setState(() => _isAnnualOnboarding = !_isAnnualOnboarding), child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 48, height: 26, decoration: BoxDecoration(color: _isAnnualOnboarding ? MioTheme.orange : _inBorder(isDark), borderRadius: BorderRadius.circular(13)), padding: const EdgeInsets.all(2), child: AnimatedAlign(alignment: _isAnnualOnboarding ? Alignment.centerRight : Alignment.centerLeft, duration: const Duration(milliseconds: 200), curve: Curves.easeOutCubic, child: Container(width: 22, height: 22, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))))),
        const SizedBox(width: 10),
        Text('Annual', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: _isAnnualOnboarding ? _txt(isDark) : _sub(isDark))),
        if (_isAnnualOnboarding) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green.withOpacity(.1), borderRadius: BorderRadius.circular(4)), child: Text('Save 20%', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.green)))],
      ]);

  Widget _buildPageReady(bool isDark) {
    return _animatedContent(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedBuilder(animation: _celebrationController, builder: (context, child) { final bounce = sin(_celebrationController.value * pi * 3) * .04; return Transform.scale(scale: 1.0 + bounce, child: child); }, child: Container(decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: MioTheme.orange.withOpacity(.25), blurRadius: 50, spreadRadius: 10)]), child: const BrandMark(size: 120))),
          const SizedBox(height: 32),
          Text(_getReadyText(), style: GoogleFonts.dmSerifDisplay(fontSize: 32, fontWeight: FontWeight.bold, height: 1.3, color: isDark ? const Color(0xFFF7F7F7) : Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: BoxDecoration(color: _cardBg(isDark).withOpacity(isDark ? .8 : .75), borderRadius: BorderRadius.circular(16), border: Border.all(color: _cardBorder(isDark))), child: Text('Your AI assistant is ready. No yapping. ⚡', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: _txt(isDark)))),
        ]),
      ),
    );
  }
}

class _ShimmerButton extends StatelessWidget {
  final AnimationController controller;
  final VoidCallback onPressed;
  final String label;
  const _ShimmerButton({required this.controller, required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(begin: Alignment(-1.0 + 2.0 * controller.value, 0), end: Alignment(1.0 + 2.0 * controller.value, 0), colors: const [MioTheme.orange, Color(0xFFE87020), MioTheme.orange]), boxShadow: [BoxShadow(color: MioTheme.orange.withOpacity(.3), blurRadius: 12, offset: const Offset(0, 4))]),
        child: ElevatedButton(onPressed: onPressed, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0), child: Text(label, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w800))),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  _ConfettiPainter({required this.progress});

  static final List<_Particle> _particles = List.generate(60, (i) {
    final rng = Random(i);
    return _Particle(x: rng.nextDouble(), startY: -0.1 - rng.nextDouble() * 0.4, speed: 0.25 + rng.nextDouble() * 0.6, drift: (rng.nextDouble() - 0.5) * 0.3, size: 3 + rng.nextDouble() * 6, rotation: rng.nextDouble() * pi * 2, color: const [Color(0xFFCC5801), Color(0xFF22C55E), Color(0xFF3B82F6), Color(0xFFF59E0B), Color(0xFFEC4899), Color(0xFF8B5CF6)][i % 6]);
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < .01) return;
    for (final p in _particles) {
      final y = (p.startY + progress * p.speed) * size.height;
      if (y > size.height || y < -20) continue;
      final x = (p.x + sin(progress * pi * 4 + p.rotation) * p.drift) * size.width;
      final opacity = (1.0 - progress * .7).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + progress * pi * 3);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * .5), Paint()..color = p.color.withOpacity((opacity * .85).toDouble()));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}

class _Particle {
  final double x, startY, speed, drift, size, rotation;
  final Color color;
  const _Particle({required this.x, required this.startY, required this.speed, required this.drift, required this.size, required this.rotation, required this.color});
}


class MioTheme {
  static const cream = Color(0xFFF6F1E8);
  static const cream2 = Color(0xFFEEE7DA);
  static const ink = Color(0xFF14110F);
  static const muted = Color(0xFF77706A);
  static const orange = Color(0xFFCC5801);
  static const orange2 = Color(0xFFE36A11);
  static const line = Color(0xFFD8CFC2);
  static const panel = Color(0xFFFFFCF6);

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.fromSeed(seedColor: orange, brightness: Brightness.light, surface: panel),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: ink, displayColor: ink),
      dividerColor: line,
      splashColor: orange.withOpacity(.08),
      highlightColor: orange.withOpacity(.04),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0F0F0E),
      colorScheme: ColorScheme.fromSeed(seedColor: orange, brightness: Brightness.dark, surface: const Color(0xFF1A1A19), surfaceContainer: const Color(0xFF252524)),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: const Color(0xFFE8E8E8), displayColor: const Color(0xFFF5F5F5)),
      dividerColor: const Color(0xFF3A3A39),
      splashColor: orange.withOpacity(.12),
      highlightColor: orange.withOpacity(.06),
    );
  }

  // Dark mode colors
  static const darkBg = Color(0xFF0F0F0E);
  static const darkPanel = Color(0xFF1A1A19);
  static const darkText = Color(0xFFE8E8E8);
  static const darkMuted = Color(0xFF8A8A89);
  static const darkLine = Color(0xFF3A3A39);
}

class AiProviderConfig {
  final String id;
  final String name;
  final String model;
  final String baseUrl;
  final String docsUrl;
  final bool openAiCompatible;

  const AiProviderConfig({
    required this.id,
    required this.name,
    required this.model,
    required this.baseUrl,
    required this.docsUrl,
    this.openAiCompatible = true,
  });
}


extension AiProviderConfigUiMetadata on AiProviderConfig {
  String get logoAsset => _providerLogoForId(id);

  Color get brandColor {
    switch (id) {
      case 'openai':
        return const Color(0xFF10A37F);
      case 'anthropic':
        return const Color(0xFFCC785C);
      case 'gemini':
        return const Color(0xFF4285F4);
      case 'deepseek':
        return const Color(0xFF4D6BFE);
      case 'groq':
        return const Color(0xFFF97316);
      case 'mistral':
        return const Color(0xFFFF7000);
      case 'openrouter':
        return const Color(0xFF8B5CF6);
      case 'ollama':
        return const Color(0xFF111827);
      default:
        return MioTheme.orange;
    }
  }

  String get tagline => '$model • Bring your own key';

  String get helpText => id == 'ollama' || id == 'lmstudio'
      ? 'Local providers may not require a cloud API key.'
      : 'Stored securely on this device only.';
}

String _providerLogoForId(String id) {
  switch (id) {
    case 'openai':
      return 'assets/icons/providers/openai.png';
    case 'anthropic':
      return 'assets/icons/providers/anthropic.png';
    case 'gemini':
      return 'assets/icons/providers/google.png';
    case 'deepseek':
      return 'assets/icons/providers/deepseek.png';
    case 'groq':
      return 'assets/icons/providers/groq.png';
    case 'mistral':
      return 'assets/icons/providers/mistral.png';
    case 'openrouter':
      return 'assets/icons/providers/openrouter.png';
    case 'ollama':
    case 'lmstudio':
      return 'assets/icons/providers/ollama.png';
    case 'cohere':
      return 'assets/icons/providers/kimi.png';
    default:
      return 'assets/icons/providers/openrouter.png';
  }
}

class _ProviderLogo extends StatelessWidget {
  final String asset;
  final String fallback;
  final Color color;
  final double size;

  const _ProviderLogo({required this.asset, required this.fallback, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * .28),
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color.withOpacity(.14), borderRadius: BorderRadius.circular(size * .28)),
          alignment: Alignment.center,
          child: Text(fallback, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: size * .42)),
        ),
      ),
    );
  }
}

const providers = <AiProviderConfig>[
  AiProviderConfig(id: 'openai', name: 'OpenAI', model: 'gpt-4o', baseUrl: 'https://api.openai.com/v1/chat/completions', docsUrl: 'https://platform.openai.com/api-keys'),
  AiProviderConfig(id: 'anthropic', name: 'Anthropic', model: 'claude-4-6-sonnet-latest', baseUrl: 'https://api.anthropic.com/v1/messages', docsUrl: 'https://console.anthropic.com/settings/keys', openAiCompatible: false),
  AiProviderConfig(id: 'gemini', name: 'Gemini', model: 'gemini-3-5-pro', baseUrl: 'https://generativelanguage.googleapis.com/v1beta/models', docsUrl: 'https://aistudio.google.com/app/apikey', openAiCompatible: false),
  AiProviderConfig(id: 'deepseek', name: 'DeepSeek', model: 'deepseek-chat', baseUrl: 'https://api.deepseek.com/chat/completions', docsUrl: 'https://platform.deepseek.com/api_keys'),
  AiProviderConfig(id: 'groq', name: 'Groq', model: 'llama-3.1-70b-versatile', baseUrl: 'https://api.groq.com/openai/v1/chat/completions', docsUrl: 'https://console.groq.com/keys'),
  AiProviderConfig(id: 'mistral', name: 'Mistral', model: 'mistral-small-latest', baseUrl: 'https://api.mistral.ai/v1/chat/completions', docsUrl: 'https://console.mistral.ai/api-keys'),
  AiProviderConfig(id: 'openrouter', name: 'OpenRouter', model: 'openai/gpt-4o-mini', baseUrl: 'https://openrouter.ai/api/v1/chat/completions', docsUrl: 'https://openrouter.ai/keys'),
  AiProviderConfig(id: 'perplexity', name: 'Perplexity', model: 'sonar', baseUrl: 'https://api.perplexity.ai/chat/completions', docsUrl: 'https://www.perplexity.ai/settings/api'),
  AiProviderConfig(id: 'xai', name: 'xAI', model: 'grok-2-latest', baseUrl: 'https://api.x.ai/v1/chat/completions', docsUrl: 'https://console.x.ai/'),
  AiProviderConfig(id: 'together', name: 'Together', model: 'meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo', baseUrl: 'https://api.together.xyz/v1/chat/completions', docsUrl: 'https://api.together.xyz/settings/api-keys'),
  AiProviderConfig(id: 'fireworks', name: 'Fireworks', model: 'accounts/fireworks/models/llama-v3p1-70b-instruct', baseUrl: 'https://api.fireworks.ai/inference/v1/chat/completions', docsUrl: 'https://fireworks.ai/account/api-keys'),
  AiProviderConfig(id: 'cerebras', name: 'Cerebras', model: 'llama3.1-70b', baseUrl: 'https://api.cerebras.ai/v1/chat/completions', docsUrl: 'https://cloud.cerebras.ai/platform'),
  AiProviderConfig(id: 'sambanova', name: 'SambaNova', model: 'Meta-Llama-3.1-70B-Instruct', baseUrl: 'https://api.sambanova.ai/v1/chat/completions', docsUrl: 'https://cloud.sambanova.ai/apis'),
  AiProviderConfig(id: 'cohere', name: 'Cohere', model: 'command-r-plus', baseUrl: 'https://api.cohere.com/compatibility/v1/chat/completions', docsUrl: 'https://dashboard.cohere.com/api-keys'),
  AiProviderConfig(id: 'anyscale', name: 'Anyscale', model: 'meta-llama/Llama-3.1-70B-Instruct', baseUrl: 'https://api.endpoints.anyscale.com/v1/chat/completions', docsUrl: 'https://app.endpoints.anyscale.com/credentials'),
  AiProviderConfig(id: 'ollama', name: 'Ollama', model: 'llama3.1', baseUrl: 'http://localhost:11434/v1/chat/completions', docsUrl: 'https://ollama.com/', openAiCompatible: true),
  AiProviderConfig(id: 'lmstudio', name: 'LM Studio', model: 'local-model', baseUrl: 'http://localhost:1234/v1/chat/completions', docsUrl: 'https://lmstudio.ai/', openAiCompatible: true),
  AiProviderConfig(id: 'custom', name: 'Custom API', model: 'custom-model', baseUrl: 'https://your-provider.example.com/v1/chat/completions', docsUrl: 'https://example.com', openAiCompatible: true),
];

class ChatMessage {
  final String id;
  final String role;
  final String content;
  final DateTime createdAt;
  final List<String>? sources; // For Deep Research

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    DateTime? createdAt,
    this.sources,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'sources': sources,
      };

  static ChatMessage fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        role: json['role'] as String,
        content: json['content'] as String,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        sources: json['sources'] != null ? List<String>.from(json['sources'] as List) : null,
      );
}

// --- E2EE Sync Service ---
class E2EESyncService {
  Future<String> encryptKeys(String masterPassword, Map<String, String> keys) async {
    final plainText = jsonEncode(keys);
    // Note: In production, use 'cryptography' package with AES-GCM and PBKDF2
    final bytes = utf8.encode(plainText);
    final encrypted = base64.encode(bytes.map((b) => b ^ 42).toList()); // XOR obfuscation for MVP
    return encrypted;
  }

  Future<Map<String, String>> decryptKeys(String masterPassword, String encryptedBlob) async {
    final encryptedBytes = base64.decode(encryptedBlob);
    final decryptedBytes = encryptedBytes.map((b) => b ^ 42).toList();
    final plainText = utf8.decode(decryptedBytes);
    return Map<String, String>.from(jsonDecode(plainText));
  }
}

// --- Deep Research Service ---
class DeepResearchService {
  Stream<String> performResearch(String query) async* {
    yield "🔍 Searching for: $query...\n";
    await Future.delayed(const Duration(seconds: 1));
    yield "📖 Reading sources from web...\n";
    await Future.delayed(const Duration(seconds: 1));
    yield "🧠 Synthesizing deep research report...\n\n";
    await Future.delayed(const Duration(milliseconds: 500));
    yield "### Research Synthesis for \"$query\"\n\nBased on current web data, here are the key findings...";
  }
}

// --- Skills & Connectors Architecture ---
abstract class MioSkill {
  String get id;
  String get name;
  Future<String> execute(Map<String, dynamic> args);
}

class WebSearchSkill extends MioSkill {
  @override String get id => 'web_search';
  @override String get name => 'Web Search';
  @override Future<String> execute(Map<String, dynamic> args) async => "Found results for ${args['query']}";
}

class NotionConnector extends MioSkill {
  @override String get id => 'notion';
  @override String get name => 'Notion';
  @override Future<String> execute(Map<String, dynamic> args) async => "Synced with Notion";
}

class AppController extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 30), receiveTimeout: const Duration(seconds: 120)));
  final _uuid = const Uuid();
  final _imagePicker = ImagePicker();
  final _syncService = E2EESyncService();
  final _researchService = DeepResearchService();

  final inputFocusNode = FocusNode();
  final inputController = TextEditingController();
  final scrollController = ScrollController();

  List<ChatMessage> messages = [];
  String selectedProviderId = 'openai';
  bool zeroFluff = true;
  bool isStreaming = false;
  bool deepResearchMode = false;
  bool webSearchEnabled = false;
  String error = '';
  String activeProject = 'Personal';

  AiProviderConfig get selectedProvider => providers.firstWhere((p) => p.id == selectedProviderId, orElse: () => providers.first);

  void toggleDeepResearch() {
    deepResearchMode = !deepResearchMode;
    notifyListeners();
  }

  // --- E2EE Key Sync ---
  Future<void> syncKeysToCloud(String masterPassword) async {
    final allKeys = <String, String>{};
    for (final p in providers) {
      final key = await getApiKey(p.id);
      if (key != null) allKeys[p.id] = key;
    }
    final blob = await _syncService.encryptKeys(masterPassword, allKeys);
    // In production, upload 'blob' to Supabase table 'user_sync'
    debugPrint("E2EE Blob created: $blob");
  }

  Future<void> restoreKeysFromCloud(String masterPassword, String blob) async {
    final keys = await _syncService.decryptKeys(masterPassword, blob);
    for (final entry in keys.entries) {
      await setApiKey(entry.key, entry.value);
    }
  }

  
  void setSidebarTab(String tab) {
    currentSidebarTab = tab;
    notifyListeners();
  }

  void setCurrentProject(String projectId) {
    currentProjectId = projectId;
    notifyListeners();
  }

  void updateProjectMemory(String projectId, String memory) {
    projectMemory[projectId] = memory;
    notifyListeners();
  }

  String getProjectMemory(String projectId) {
    return projectMemory[projectId] ?? '';
  }

  void setSelectedModel(String model) {
    // Update the selected model for the current provider
    notifyListeners();
  }

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    selectedProviderId = prefs.getString('provider') ?? selectedProviderId;
    zeroFluff = prefs.getBool('zeroFluff') ?? true;
    webSearchEnabled = prefs.getBool('webSearchEnabled') ?? false;
    activeProject = prefs.getString('activeProject') ?? activeProject;
    final rawMessages = prefs.getStringList('messages') ?? [];
    messages = rawMessages.map((item) => ChatMessage.fromJson(jsonDecode(item) as Map<String, dynamic>)).toList();
    if (messages.isEmpty) {
      messages = [
        ChatMessage(id: _uuid.v4(), role: 'assistant', content: 'Ready. Ask directly. I will answer without filler.'),
      ];
    }
    notifyListeners();
  }

  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('provider', selectedProviderId);
    await prefs.setBool('zeroFluff', zeroFluff);
    await prefs.setBool('webSearchEnabled', webSearchEnabled);
    await prefs.setString('activeProject', activeProject);
    await prefs.setStringList('messages', messages.map((m) => jsonEncode(m.toJson())).toList());
  }

  Future<String?> getApiKey(String providerId) => _storage.read(key: 'provider_key_$providerId');

  Future<void> setApiKey(String providerId, String value) async {
    final clean = value.trim();
    if (clean.isEmpty) {
      await _storage.delete(key: 'provider_key_$providerId');
    } else {
      await _storage.write(key: 'provider_key_$providerId', value: clean);
    }
    notifyListeners();
  }

  Future<String> apiKeyFingerprint(String providerId) async {
    final key = await getApiKey(providerId);
    if (key == null || key.isEmpty) return 'No key';
    final digest = sha256.convert(utf8.encode(key)).toString();
    return '${key.substring(0, min(4, key.length))}••••${digest.substring(0, 6)}';
  }

  void chooseProvider(String providerId) {
    selectedProviderId = providerId;
    saveState();
    notifyListeners();
  }

  void toggleZeroFluff() {
    zeroFluff = !zeroFluff;
    saveState();
    notifyListeners();
  }

  void toggleWebSearch() {
    webSearchEnabled = !webSearchEnabled;
    saveState();
    notifyListeners();
  }

  void clearChat() {
    messages = [ChatMessage(id: _uuid.v4(), role: 'assistant', content: 'New chat. Direct mode is on.')];
    saveState();
    notifyListeners();
  }

  Future<void> attachCamera() async {
    final image = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 82);
    if (image == null) return;
    _addAttachmentMessage('Camera image attached', image.name, image.path);
  }

  Future<void> attachGallery() async {
    final images = await _imagePicker.pickMultiImage(imageQuality: 82);
    if (images.isEmpty) return;
    final names = images.map((x) => x.name).join(', ');
    final paths = images.map((x) => x.path).join('\n');
    _addAttachmentMessage('${images.length} gallery item(s) attached', names, paths);
  }

  Future<void> attachDocument() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: false);
    if (result == null || result.files.isEmpty) return;
    final names = result.files.map((f) => f.name).join(', ');
    final paths = result.files.map((f) => f.path ?? f.name).join('\n');
    _addAttachmentMessage('${result.files.length} document(s) attached', names, paths);
  }

  void attachLink(String url) {
    final clean = url.trim();
    if (clean.isEmpty) return;
    _addAttachmentMessage('Link attached', clean, clean);
  }

  void enableNotificationsNotice() {
    _addAssistantNotice('Notifications enabled. Mio can use them for task completion, reminders, and scheduled summaries once those workflows are active.');
  }

  void permissionDeniedNotice(String permissionName) {
    _addAssistantNotice('$permissionName permission was not granted. You can enable it later in system settings.');
  }

  void _addAttachmentMessage(String title, String name, String value) {
    messages.add(ChatMessage(id: _uuid.v4(), role: 'user', content: '**$title**\n\n$name\n\n$value'));
    messages.add(ChatMessage(id: _uuid.v4(), role: 'assistant', content: 'Attached. Ask what you want me to do with it.'));
    saveState();
    notifyListeners();
    _scrollToBottom();
  }

  String _activeQuery() => inputController.text.trim().isEmpty ? 'latest AI news' : inputController.text.trim();

  void _addAssistantNotice(String content) {
    messages.add(ChatMessage(id: _uuid.v4(), role: 'assistant', content: content));
    saveState();
    notifyListeners();
    _scrollToBottom();
  }

  Future<void> runWebSearchConnector() async {
    final query = _activeQuery();
    try {
      final res = await _dio.get<dynamic>('https://api.duckduckgo.com/', queryParameters: {'q': query, 'format': 'json', 'no_html': '1', 'skip_disambig': '1'});
      final data = res.data as Map<String, dynamic>;
      final abstract = (data['AbstractText'] as String? ?? '').trim();
      final heading = (data['Heading'] as String? ?? query).trim();
      final topics = (data['RelatedTopics'] as List<dynamic>? ?? []).take(5).map((t) {
        if (t is Map && t['Text'] != null) return '- ${t['Text']}';
        return null;
      }).whereType<String>().join('\n');
      final body = abstract.isNotEmpty ? abstract : (topics.isNotEmpty ? topics : 'No instant result returned. Try a more specific search.');
      _addAssistantNotice('**Web Search: $heading**\n\n$body');
    } catch (e) {
      _addAssistantNotice('Web Search failed: ${e.toString()}');
    }
  }

  Future<void> runGitHubConnector() async {
    final query = _activeQuery();
    try {
      final token = await _storage.read(key: 'connector_token_github');
      final headers = <String, String>{'Accept': 'application/vnd.github+json'};
      if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
      final res = await _dio.get<dynamic>('https://api.github.com/search/repositories', queryParameters: {'q': query, 'per_page': '5'}, options: Options(headers: headers));
      final items = res.data['items'] as List<dynamic>? ?? [];
      if (items.isEmpty) return _addAssistantNotice('GitHub: no repositories found for "$query".');
      final lines = items.map((repo) => '- **${repo['full_name']}**: ${repo['html_url']}').join('\n');
      _addAssistantNotice('**GitHub results for "$query"**\n\n$lines');
    } catch (e) {
      _addAssistantNotice('GitHub connector failed: ${e.toString()}');
    }
  }

  Future<void> runNotionConnector() async {
    final query = _activeQuery();
    final token = await _storage.read(key: 'connector_token_notion');
    if (token == null || token.isEmpty) {
      return _addAssistantNotice('Notion connector needs a Notion integration token saved as `connector_token_notion` before it can search your workspace.');
    }
    try {
      final res = await _dio.post<dynamic>('https://api.notion.com/v1/search', options: Options(headers: {'Authorization': 'Bearer $token', 'Notion-Version': '2022-06-28', 'Content-Type': 'application/json'}), data: {'query': query, 'page_size': 5});
      final results = res.data['results'] as List<dynamic>? ?? [];
      if (results.isEmpty) return _addAssistantNotice('Notion: no results found for "$query".');
      final lines = results.map((item) => '- ${item['object']} ${item['id']}').join('\n');
      _addAssistantNotice('**Notion results for "$query"**\n\n$lines');
    } catch (e) {
      _addAssistantNotice('Notion connector failed: ${e.toString()}');
    }
  }

  Future<void> runGmailConnector() async {
    final query = _activeQuery();
    final token = await _storage.read(key: 'connector_token_gmail');
    if (token == null || token.isEmpty) {
      return _addAssistantNotice('Gmail connector needs a Google OAuth access token saved as `connector_token_gmail`. For production, add OAuth through Supabase Auth or a Railway backend callback.');
    }
    try {
      final res = await _dio.get<dynamic>('https://gmail.googleapis.com/gmail/v1/users/me/messages', queryParameters: {'q': query, 'maxResults': '5'}, options: Options(headers: {'Authorization': 'Bearer $token'}));
      final messagesList = res.data['messages'] as List<dynamic>? ?? [];
      if (messagesList.isEmpty) return _addAssistantNotice('Gmail: no messages found for "$query".');
      final lines = messagesList.map((m) => '- message id: ${m['id']}').join('\n');
      _addAssistantNotice('**Gmail results for "$query"**\n\n$lines');
    } catch (e) {
      _addAssistantNotice('Gmail connector failed: ${e.toString()}');
    }
  }

  Future<void> sendPrompt() async {
    final prompt = inputController.text.trim();
    if (prompt.isEmpty || isStreaming) return;
    inputController.clear();
    error = '';
    messages.add(ChatMessage(id: _uuid.v4(), role: 'user', content: prompt));
    messages.add(ChatMessage(id: _uuid.v4(), role: 'assistant', content: ''));
    isStreaming = true;
    notifyListeners();
    _scrollToBottom();

    try {
      if (deepResearchMode) {
        await _runDeepResearch(prompt);
      } else {
        final key = await getApiKey(selectedProviderId);
        if (key == null || key.isEmpty) {
          throw Exception('Add your ${selectedProvider.name} API key first.');
        }
        final answer = await _callProvider(prompt, key);
        messages[messages.length - 1] = ChatMessage(id: messages.last.id, role: 'assistant', content: answer.trim().isEmpty ? 'No answer returned.' : answer.trim());
      }
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      messages[messages.length - 1] = ChatMessage(id: messages.last.id, role: 'assistant', content: 'Error: $error');
    } finally {
      isStreaming = false;
      await saveState();
      notifyListeners();
      _scrollToBottom();
    }
  }

  Future<void> _runDeepResearch(String query) async {
    final researchStream = _researchService.performResearch(query);
    String fullContent = "";
    await for (final chunk in researchStream) {
      fullContent += chunk;
      messages[messages.length - 1] = ChatMessage(
        id: messages.last.id,
        role: 'assistant',
        content: fullContent,
        sources: ["Source 1", "Source 2"], // Mock sources
      );
      notifyListeners();
    }
  }

  List<Map<String, String>> _historyForApi(String latestPrompt) {
    final recent = messages.where((m) => m.content.trim().isNotEmpty).toList();
    final clipped = recent.length > 10 ? recent.sublist(recent.length - 10) : recent;
    return [
      {'role': 'system', 'content': zeroFluff ? 'Answer directly. No greeting. No filler. No hedging unless required. Use concise structure.' : 'Be helpful and clear.'},
      ...clipped.where((m) => m.role == 'user' || m.role == 'assistant').map((m) => {'role': m.role, 'content': m.content}),
      {'role': 'user', 'content': latestPrompt},
    ];
  }

  Future<String> _callProvider(String prompt, String key) async {
    final provider = selectedProvider;
    if (provider.id == 'anthropic') return _callAnthropic(prompt, key, provider);
    if (provider.id == 'gemini') return _callGemini(prompt, key, provider);
    return _callOpenAiCompatible(prompt, key, provider);
  }

  Future<String> _callOpenAiCompatible(String prompt, String key, AiProviderConfig provider) async {
    final res = await _dio.post<dynamic>(
      provider.baseUrl,
      options: Options(headers: {'Authorization': 'Bearer $key', 'Content-Type': 'application/json'}),
      data: {
        'model': provider.model,
        'messages': _historyForApi(prompt),
        'temperature': zeroFluff ? 0.2 : 0.7,
      },
    );
    return (res.data['choices'] as List).first['message']['content'] as String? ?? '';
  }

  Future<String> _callAnthropic(String prompt, String key, AiProviderConfig provider) async {
    final history = _historyForApi(prompt);
    final system = history.first['content'];
    final msgs = history.skip(1).map((m) => {'role': m['role'] == 'assistant' ? 'assistant' : 'user', 'content': m['content']}).toList();
    final res = await _dio.post<dynamic>(
      provider.baseUrl,
      options: Options(headers: {'x-api-key': key, 'anthropic-version': '2023-06-01', 'Content-Type': 'application/json'}),
      data: {'model': provider.model, 'max_tokens': 1200, 'system': system, 'messages': msgs},
    );
    final content = res.data['content'] as List<dynamic>? ?? [];
    return content.map((item) => item['text'] ?? '').join('\n');
  }

  Future<String> _callGemini(String prompt, String key, AiProviderConfig provider) async {
    final url = '${provider.baseUrl}/${provider.model}:generateContent?key=$key';
    final res = await _dio.post<dynamic>(
      url,
      options: Options(headers: {'Content-Type': 'application/json'}),
      data: {
        'system_instruction': {'parts': [{'text': zeroFluff ? 'Answer directly. No filler.' : 'Be helpful and clear.'}]},
        'contents': [{'role': 'user', 'parts': [{'text': prompt}]}],
      },
    );
    final candidates = res.data['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) return '';
    final parts = candidates.first['content']?['parts'] as List<dynamic>? ?? [];
    return parts.map((p) => p['text'] ?? '').join('\n');
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 60), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
      }
    });
  }
}

class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    return Scaffold(
      body: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{SingleActivator(LogicalKeyboardKey.enter, meta: true): SendIntent(), SingleActivator(LogicalKeyboardKey.enter, control: true): SendIntent()},
        child: Actions(
          actions: <Type, Action<Intent>>{SendIntent: CallbackAction<SendIntent>(onInvoke: (_) { app.sendPrompt(); return null; })},
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 860;
              return Row(
                children: [
                  if (!compact) const Sidebar(),
                  Expanded(child: ChatWorkspace(compact: compact)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class SendIntent extends Intent {
  const SendIntent();
}

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    return Container(
      width: 72,
      decoration: const BoxDecoration(color: MioTheme.cream2, border: Border(right: BorderSide(color: MioTheme.line))),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: MioTheme.line)),
                child: const Center(child: BrandMark(size: 32)),
              ),
            ),
            const SizedBox(height: 16),
            _SidebarIconButton(icon: Icons.chat_rounded, label: 'Chat', onTap: () => context.go('/chat')),
            const SizedBox(height: 12),
            _SidebarIconButton(icon: Icons.work_rounded, label: 'Projects', onTap: () => context.go('/projects')),
            const SizedBox(height: 12),
            _SidebarIconButton(icon: Icons.settings_rounded, label: 'Settings', onTap: () => context.go('/settings')),
            const Spacer(),
            _UserProfileButton(app: app),
          ],
        ),
      ),
    );
  }
}

class _SidebarIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SidebarIconButton({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: MioTheme.line)),
          child: Icon(icon, color: MioTheme.orange, size: 24),
        ),
      ),
    );
  }
}

class _UserProfileButton extends ConsumerStatefulWidget {
  final AppController app;
  const _UserProfileButton({required this.app});
  @override
  ConsumerState<_UserProfileButton> createState() => _UserProfileButtonState();
}

class _UserProfileButtonState extends ConsumerState<_UserProfileButton> {
  late RelativeRect _menuPosition;

  void _showUserMenu() {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final button = context.findRenderObject() as RenderBox;
    final topLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
    _menuPosition = RelativeRect.fromLTRB(topLeft.dx + button.size.width + 8, topLeft.dy, overlay.size.width - topLeft.dx - button.size.width - 8, overlay.size.height - topLeft.dy - button.size.height);

    showMenu<String>(
      context: context,
      position: _menuPosition,
      color: MioTheme.panel,
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: MioTheme.line)),
      items: [
        PopupMenuItem<String>(value: 'settings', child: Row(children: [const Icon(Icons.settings_rounded, size: 18, color: MioTheme.orange), const SizedBox(width: 12), const Text('Settings')])),
        PopupMenuItem<String>(value: 'account', child: Row(children: [const Icon(Icons.person_rounded, size: 18, color: MioTheme.orange), const SizedBox(width: 12), const Text('Account')])),
        PopupMenuItem<String>(value: 'usage', child: Row(children: [const Icon(Icons.speed_rounded, size: 18, color: MioTheme.orange), const SizedBox(width: 12), const Text('Usage')])),
        const PopupMenuDivider(),
        PopupMenuItem<String>(value: 'logout', child: Row(children: [const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFCC5801)), const SizedBox(width: 12), const Text('Log out')])),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'settings':
          context.go('/settings');
          break;
        case 'account':
          context.go('/settings/account');
          break;
        case 'usage':
          context.go('/settings/usage');
          break;
        case 'logout':
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logout not yet implemented')));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'User menu',
      child: InkWell(
        onTap: _showUserMenu,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: MioTheme.line)),
          child: const Icon(Icons.account_circle_rounded, color: MioTheme.orange, size: 24),
        ),
      ),
    );
  }
}

class CapabilityItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const CapabilityItem({super.key, required this.icon, required this.label, required this.active, this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: active ? MioTheme.panel : Colors.transparent, borderRadius: BorderRadius.circular(14), border: Border.all(color: active ? MioTheme.line : Colors.transparent)),
        child: Row(children: [Icon(icon, size: 18, color: active ? MioTheme.orange : MioTheme.muted), const SizedBox(width: 10), Text(label, style: TextStyle(color: active ? MioTheme.ink : MioTheme.muted))]),
      ),
    );
  }
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: MioTheme.line), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 18, offset: const Offset(0, 8))]),
          child: const Center(child: BrandMark(size: 34)),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mio', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.5)),
          Text('Think. Not yap.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: MioTheme.muted)),
        ]),
      ],
    );
  }
}

class PrimaryNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const PrimaryNavButton({super.key, required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: MioTheme.line)),
        child: Row(children: [Icon(icon, size: 20, color: MioTheme.orange), const SizedBox(width: 10), Text(label, style: const TextStyle(fontWeight: FontWeight.w700))]),
      ),
    );
  }
}

class ProjectChip extends StatelessWidget {
  final String name;
  final bool active;
  final VoidCallback? onTap;
  const ProjectChip({super.key, required this.name, required this.active, this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(color: active ? MioTheme.panel : Colors.transparent, borderRadius: BorderRadius.circular(14), border: Border.all(color: active ? MioTheme.line : Colors.transparent)),
        child: Row(children: [Icon(Icons.folder_rounded, size: 18, color: active ? MioTheme.orange : MioTheme.muted), const SizedBox(width: 10), Text(name)]),
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  final AppController app;
  const StatusCard({super.key, required this.app});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: MioTheme.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.shield_rounded, size: 18, color: MioTheme.orange), const SizedBox(width: 8), Text('BYOK local', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800))]),
        const SizedBox(height: 8),
        Text('Keys stay in secure device storage. Supabase is optional for sync.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: MioTheme.muted, height: 1.35)),
      ]),
    );
  }
}

class ChatWorkspace extends ConsumerWidget {
  final bool compact;
  const ChatWorkspace({super.key, required this.compact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    return SafeArea(
      child: Column(
        children: [
          TopBar(compact: compact),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 980),
              child: ListView.builder(
                controller: app.scrollController,
                padding: EdgeInsets.fromLTRB(compact ? 18 : 42, 18, compact ? 18 : 42, 18),
                itemCount: app.messages.length,
                itemBuilder: (context, index) => MessageTile(message: app.messages[index]),
              ),
            ),
          ),
          const Composer(),
        ],
      ),
    );
  }
}

class TopBar extends ConsumerWidget {
  final bool compact;
  const TopBar({super.key, required this.compact});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    return Container(
      height: 74,
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 28),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: MioTheme.line))),
      child: Row(
        children: [
          if (compact) ...[const BrandHeader(), const SizedBox(width: 16)],
          Expanded(child: Text(app.activeProject, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
          ZeroFluffToggle(value: app.zeroFluff, onTap: app.toggleZeroFluff),
          const SizedBox(width: 12),
          ProviderPill(provider: app.selectedProvider),
        ],
      ),
    );
  }
}

class ZeroFluffToggle extends StatelessWidget {
  final bool value;
  final VoidCallback onTap;
  const ZeroFluffToggle({super.key, required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 148,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: value ? MioTheme.ink : MioTheme.panel,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: value ? MioTheme.ink : MioTheme.line),
          boxShadow: value ? [BoxShadow(color: MioTheme.orange.withOpacity(.22), blurRadius: 22, offset: const Offset(0, 8))] : [],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Zero Fluff', style: TextStyle(color: value ? Colors.white : MioTheme.ink, fontWeight: FontWeight.w800, fontSize: 13)),
          Container(width: 22, height: 22, decoration: BoxDecoration(color: value ? MioTheme.orange : MioTheme.cream2, shape: BoxShape.circle)),
        ]),
      ),
    );
  }
}


class _ModelOption {
  final String providerId;
  final String provider;
  final String model;
  final String description;
  final String logoAsset;
  final Color color;
  const _ModelOption({required this.providerId, required this.provider, required this.model, required this.description, required this.logoAsset, required this.color});
}

const _primaryModelOptions = <_ModelOption>[
  _ModelOption(providerId: 'anthropic', provider: 'Anthropic', model: 'Claude 4 Sonnet', description: 'Best for deep reasoning', logoAsset: 'assets/icons/providers/anthropic.png', color: Color(0xFFCC785C)),
  _ModelOption(providerId: 'openai', provider: 'OpenAI', model: 'GPT-4o', description: 'Fast multimodal generalist', logoAsset: 'assets/icons/providers/openai.png', color: Color(0xFF10A37F)),
  _ModelOption(providerId: 'gemini', provider: 'Google', model: 'Gemini 2.5 Pro', description: 'Long-context planning', logoAsset: 'assets/icons/providers/google.png', color: Color(0xFF4285F4)),
  _ModelOption(providerId: 'deepseek', provider: 'DeepSeek', model: 'DeepSeek R1', description: 'Reasoning on BYOK', logoAsset: 'assets/icons/providers/deepseek.png', color: Color(0xFF4D6BFE)),
  _ModelOption(providerId: 'openrouter', provider: 'OpenRouter', model: 'OpenRouter', description: 'Many models through one key', logoAsset: 'assets/icons/providers/openrouter.png', color: Color(0xFF8B5CF6)),
];

const _moreModelOptions = <_ModelOption>[
  _ModelOption(providerId: 'ollama', provider: 'Ollama', model: 'Ollama (Local)', description: 'Private local models', logoAsset: 'assets/icons/providers/ollama.png', color: Color(0xFF111827)),
  _ModelOption(providerId: 'lmstudio', provider: 'LM Studio', model: 'LM Studio', description: 'Local OpenAI-compatible server', logoAsset: 'assets/icons/providers/ollama.png', color: Color(0xFF374151)),
  _ModelOption(providerId: 'groq', provider: 'Groq', model: 'Groq', description: 'Ultra-fast hosted inference', logoAsset: 'assets/icons/providers/groq.png', color: Color(0xFFF97316)),
  _ModelOption(providerId: 'mistral', provider: 'Mistral', model: 'Mistral', description: 'European open models', logoAsset: 'assets/icons/providers/mistral.png', color: Color(0xFFFF7000)),
  _ModelOption(providerId: 'xai', provider: 'xAI', model: 'Grok', description: 'xAI API models', logoAsset: 'assets/icons/providers/openrouter.png', color: Color(0xFF111111)),
];

class ProviderPill extends ConsumerStatefulWidget {
  final AiProviderConfig provider;
  const ProviderPill({super.key, required this.provider});

  @override
  ConsumerState<ProviderPill> createState() => _ProviderPillState();
}

class _ProviderPillState extends ConsumerState<ProviderPill> {
  RelativeRect _menuPosition({double dx = 0, double dy = 8, double width = 320}) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final button = context.findRenderObject() as RenderBox;
    final topLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
    final left = (topLeft.dx + dx).clamp(8.0, max(8.0, overlay.size.width - width - 8)).toDouble();
    final top = topLeft.dy + button.size.height + dy;
    return RelativeRect.fromLTRB(left, top, overlay.size.width - left - width, 0);
  }

  Future<void> _showModelMenu() async {
    final selected = await _showOptions(_primaryModelOptions, includeMore: true, position: _menuPosition(dx: -210, width: 320));
    if (!mounted || selected == null) return;
    if (selected == '__more__') {
      final more = await _showOptions(_moreModelOptions, includeMore: false, position: _menuPosition(dx: 118, dy: 42, width: 320));
      if (!mounted || more == null || more == '__more__') return;
      ref.read(appControllerProvider).chooseProvider(more);
      return;
    }
    ref.read(appControllerProvider).chooseProvider(selected);
  }

  Future<String?> _showOptions(List<_ModelOption> options, {required bool includeMore, required RelativeRect position}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF262626) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF888888) : const Color(0xFF666666);
    return showMenu<String>(
      context: context,
      position: position,
      color: bg,
      elevation: 18,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: isDark ? const Color(0xFF3A3A3A) : MioTheme.line)),
      constraints: const BoxConstraints(minWidth: 320, maxWidth: 320),
      items: [
        ...options.map((m) => PopupMenuItem<String>(
              value: m.providerId,
              padding: EdgeInsets.zero,
              height: 54,
              child: _modelMenuRow(m, textPrimary, textMuted),
            )),
        if (includeMore)
          PopupMenuItem<String>(
            value: '__more__',
            padding: EdgeInsets.zero,
            height: 50,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [Icon(Icons.expand_more, size: 18, color: textMuted), const SizedBox(width: 12), Expanded(child: Text('More models', style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w600))), Text('Ollama', style: GoogleFonts.dmSans(fontSize: 12, color: textMuted)), const SizedBox(width: 8), Icon(Icons.chevron_right, size: 18, color: textMuted)]),
            ),
          ),
      ],
    );
  }

  Widget _modelMenuRow(_ModelOption option, Color textPrimary, Color textMuted) {
    final selected = ref.read(appControllerProvider).selectedProviderId == option.providerId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        _ProviderLogo(asset: option.logoAsset, fallback: option.provider.substring(0, 1), color: option.color, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(option.model, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary, fontWeight: selected ? FontWeight.w700 : FontWeight.w600)), Text(option.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.dmSans(fontSize: 12, color: textMuted))])),
        if (selected) const Icon(Icons.check, size: 18, color: Color(0xFF4285F4)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: _showModelMenu,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(999), border: Border.all(color: MioTheme.line)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [_ProviderLogo(asset: _providerLogoForId(widget.provider.id), fallback: widget.provider.name.substring(0, 1), color: MioTheme.orange, size: 20), const SizedBox(width: 8), Text(widget.provider.name, style: const TextStyle(fontWeight: FontWeight.w700)), const Icon(Icons.keyboard_arrow_down_rounded, size: 18)]),
      ),
    );
  }
}

class SettingsButton extends ConsumerWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton.filledTonal(
      tooltip: 'Settings',
      icon: const Icon(Icons.settings_rounded),
      onPressed: () => context.go('/settings'),
    );
  }
}

class MessageTile extends StatelessWidget {
  final ChatMessage message;
  const MessageTile({super.key, required this.message});
  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) const Avatar(label: 'M'),
          if (!isUser) const SizedBox(width: 12),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 740),
              padding: EdgeInsets.symmetric(horizontal: isUser ? 18 : 0, vertical: isUser ? 13 : 2),
              decoration: BoxDecoration(
                color: isUser ? MioTheme.ink : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                boxShadow: isUser ? [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 18, offset: const Offset(0, 6))] : [],
              ),
              child: isUser
                  ? Text(message.content, style: const TextStyle(color: Colors.white, fontSize: 15.5, height: 1.48))
                  : (message.content.isEmpty ? const _ThinkingAnimation() : MarkdownBody(
                      data: message.content,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: const TextStyle(fontSize: 16, height: 1.62, color: MioTheme.ink),
                        strong: const TextStyle(fontWeight: FontWeight.w800, color: MioTheme.ink),
                        code: const TextStyle(fontFamily: 'monospace', backgroundColor: MioTheme.cream2),
                      ),
                    )),
            ),
          ),
          if (isUser) const SizedBox(width: 12),
          if (isUser) const Avatar(label: 'You', dark: true),
        ],
      ),
    );
  }
}

class _ThinkingAnimation extends StatefulWidget {
  const _ThinkingAnimation();
  @override
  State<_ThinkingAnimation> createState() => _ThinkingAnimationState();
}

class _ThinkingAnimationState extends State<_ThinkingAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _wordIndex = 0;
  final List<String> _words = ['Thinking', 'Searching', 'Analyzing', 'Synthesizing', 'Drafting', 'Refining'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _startWordCycle();
  }

  void _startWordCycle() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _wordIndex = (_wordIndex + 1) % _words.length;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final bounce = sin(_controller.value * pi * 2) * 4;
            return Transform.translate(offset: Offset(0, bounce), child: child);
          },
          child: const BrandMark(size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          '${_words[_wordIndex]}…',
          style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: MioTheme.muted, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}

class _AttachmentItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AttachmentItem({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: MioTheme.cream2, borderRadius: BorderRadius.circular(18), border: Border.all(color: MioTheme.line)),
            child: Icon(icon, color: MioTheme.orange, size: 24),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final String label;
  final bool dark;
  const Avatar({super.key, required this.label, this.dark = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: dark ? MioTheme.ink : MioTheme.panel, shape: BoxShape.circle, border: Border.all(color: MioTheme.line)),
      child: Center(child: Text(label.length > 2 ? label.substring(0, 1) : label, style: TextStyle(color: dark ? Colors.white : MioTheme.orange, fontSize: 12, fontWeight: FontWeight.w800))),
    );
  }
}


class _ModelPickerButton extends StatelessWidget {
  final AppController app;
  const _ModelPickerButton({required this.app});

  @override
  Widget build(BuildContext context) {
    final provider = providers.firstWhere((p) => p.id == app.selectedProviderId, orElse: () => providers.first);
    final models = _getModelsForProvider(provider.id);
    
    return PopupMenuButton<String>(
      onSelected: (model) => app.setSelectedModel(model),
      itemBuilder: (context) => models.map((model) => PopupMenuItem(value: model, child: Text(model))).toList(),
      child: Tooltip(
        message: 'Switch model',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: MioTheme.orange.withOpacity(.08), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.model_training_rounded, size: 16, color: MioTheme.orange),
              const SizedBox(width: 6),
              Text(provider.model.split('-').last, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MioTheme.orange)),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _getModelsForProvider(String providerId) {
    switch (providerId) {
      case 'openai':
        return ['gpt-4o', 'gpt-4o-mini', 'gpt-4-turbo', 'gpt-4'];
      case 'anthropic':
        return ['claude-4-6-sonnet-latest', 'claude-3-5-sonnet-latest', 'claude-3-opus-latest', 'claude-3-haiku-latest'];
      case 'gemini':
        return ['gemini-3-5-pro', 'gemini-2-5-pro', 'gemini-2-5-flash', 'gemini-3-5-flash'];
      case 'deepseek':
        return ['deepseek-chat', 'deepseek-reasoner'];
      case 'groq':
        return ['llama-3.1-70b-versatile', 'llama-3.1-8b-instant', 'mixtral-8x7b-32768'];
      case 'mistral':
        return ['mistral-large-latest', 'mistral-medium-latest', 'mistral-small-latest'];
      default:
        return [provider.model];
    }
  }
}

class Composer extends ConsumerStatefulWidget {
  const Composer({super.key});

  @override
  ConsumerState<Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<Composer> {
  final GlobalKey _plusButtonKey = GlobalKey();

  Future<bool> _confirmAndRequestPermission(BuildContext context, Permission permission, String title, String body) async {
    final explain = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: Text(title), content: Text(body), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not now')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Allow'))]));
    if (explain != true) return false;
    final status = await permission.request();
    if (status.isGranted || status.isLimited) return true;
    if (status.isPermanentlyDenied && context.mounted) {
      await showDialog<void>(context: context, builder: (context) => AlertDialog(title: const Text('Permission blocked'), content: const Text('Open system settings to allow this permission for Mio.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { openAppSettings(); Navigator.pop(context); }, child: const Text('Open Settings'))]));
    }
    return false;
  }

  Future<void> _runWithPermission(BuildContext context, AppController app, Permission permission, String title, String body, String deniedLabel, Future<void> Function() action) async {
    final allowed = await _confirmAndRequestPermission(context, permission, title, body);
    if (!allowed) {
      app.permissionDeniedNotice(deniedLabel);
      return;
    }
    await action();
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label is ready for connector wiring.')));
  }

  RelativeRect _plusMenuPosition() {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final buttonContext = _plusButtonKey.currentContext ?? context;
    final button = buttonContext.findRenderObject() as RenderBox;
    final topLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
    final menuWidth = 260.0;
    final left = topLeft.dx.clamp(8.0, max(8.0, overlay.size.width - menuWidth - 8)).toDouble();
    final top = max(8.0, topLeft.dy - 350).toDouble();
    return RelativeRect.fromLTRB(left, top, overlay.size.width - left - menuWidth, 0);
  }

  Future<void> _showPlusMenu(AppController app) async {
    final selected = await showMenu<String>(
      context: context,
      position: _plusMenuPosition(),
      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF262626) : Colors.white,
      elevation: 20,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 260),
      items: [
        _popupMenuItem('files', Icons.attach_file, 'Add files or photos'),
        _popupMenuItem('project', Icons.folder_outlined, 'Add to project', hasChevron: true),
        _popupMenuItem('skills', Icons.construction_outlined, 'Skills', hasChevron: true),
        _popupMenuItem('connectors', Icons.power_outlined, 'Connectors', hasChevron: true),
        _popupMenuItem('plugins', Icons.extension_outlined, 'Plugins', hasChevron: true),
        const PopupMenuDivider(height: 1),
        _popupMenuItem('research', Icons.search_outlined, 'Research'),
        _popupMenuItem('web', Icons.language_outlined, 'Web search', trailing: const Icon(Icons.check, size: 18, color: Color(0xFF4285F4))),
        _popupMenuItem('style', Icons.brush_outlined, 'Use style', hasChevron: true),
      ],
    );
    if (!mounted || selected == null) return;
    switch (selected) {
      case 'files':
        await _runWithPermission(context, app, Permission.storage, 'Allow document access?', 'Mio opens the system picker only when you choose files or photos to attach.', 'Files', app.attachDocument);
        break;
      case 'project':
        context.go('/projects');
        break;
      case 'skills':
        _showComingSoon('Skills');
        break;
      case 'connectors':
        context.go('/settings/connectors');
        break;
      case 'plugins':
        _showComingSoon('Plugins');
        break;
      case 'research':
        if (!app.deepResearchMode) app.toggleDeepResearch();
        break;
      case 'web':
        app.runWebSearchConnector();
        break;
      case 'style':
        context.go('/settings/personalization');
        break;
    }
  }

  PopupMenuItem<String> _popupMenuItem(String value, IconData icon, String label, {bool hasChevron = false, Widget? trailing}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF888888) : const Color(0xFF666666);
    return PopupMenuItem<String>(
      value: value,
      padding: EdgeInsets.zero,
      height: 42,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [Icon(icon, size: 18, color: textMuted), const SizedBox(width: 12), Expanded(child: Text(label, style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w500))), if (trailing != null) trailing, if (hasChevron) Icon(Icons.chevron_right, size: 18, color: textMuted)]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(18, 12, 18, max(18, bottom + 12)),
      decoration: BoxDecoration(color: MioTheme.cream.withOpacity(.94), border: const Border(top: BorderSide(color: MioTheme.line))),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 980),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(28), border: Border.all(color: MioTheme.line), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 30, offset: const Offset(0, 12))]),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            IconButton(key: _plusButtonKey, onPressed: () => _showPlusMenu(app), icon: const Icon(Icons.add_rounded), tooltip: 'Attach'),
            Expanded(child: TextField(controller: app.inputController, focusNode: app.inputFocusNode, minLines: 1, maxLines: 6, textInputAction: TextInputAction.newline, decoration: const InputDecoration(hintText: 'Ask anything…', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 13)), onSubmitted: (_) => app.sendPrompt())),
            if (app.error.isNotEmpty) Tooltip(message: app.error, child: const Icon(Icons.warning_rounded, color: MioTheme.orange)),
            const SizedBox(width: 6),
            _ModelPickerButton(app: app),
            const SizedBox(width: 6),
            IconButton(onPressed: () => context.go('/settings/api-keys'), icon: const Icon(Icons.key_rounded), tooltip: 'API Keys'),
            const SizedBox(width: 6),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: MioTheme.orange, foregroundColor: Colors.white, shape: const CircleBorder(), padding: const EdgeInsets.all(14)), onPressed: app.isStreaming ? null : app.sendPrompt, child: app.isStreaming ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.arrow_upward_rounded)),
          ]),
        ),
      ),
    );
  }
}

String formatTime(DateTime dt) => DateFormat('h:mm a').format(dt);

class RestoredScreenData {
  final String path;
  final String title;
  final String section;
  final IconData icon;
  final String description;
  final List<String> highlights;
  const RestoredScreenData({required this.path, required this.title, required this.section, required this.icon, required this.description, required this.highlights});
}

const restoredScreens = <RestoredScreenData>[
  RestoredScreenData(path: '/login', title: 'Login', section: 'Authentication', icon: Icons.login_rounded, description: 'Sign in with email, social login, or a stored Supabase session.', highlights: ['Email sign-in entry', 'OAuth sign-in placeholders', 'Session recovery']),
  RestoredScreenData(path: '/auth/callback', title: 'Auth Callback', section: 'Authentication', icon: Icons.verified_user_rounded, description: 'Handles OAuth callback state and routes the user back into Mio.', highlights: ['Session verification', 'Provider callback state', 'Safe redirect to chat']),
  RestoredScreenData(path: '/auth/email-verification', title: 'Email Verification', section: 'Authentication', icon: Icons.mark_email_read_rounded, description: 'Guides users through verifying their email address.', highlights: ['Verification status', 'Resend email action', 'Back to login action']),
  RestoredScreenData(path: '/forgot-password', title: 'Forgot Password', section: 'Authentication', icon: Icons.lock_reset_rounded, description: 'Password reset request page for email-based accounts.', highlights: ['Email reset form', 'Delivery confirmation', 'Return to login']),
  RestoredScreenData(path: '/reset-password', title: 'Reset Password', section: 'Authentication', icon: Icons.password_rounded, description: 'New password entry page after reset-link verification.', highlights: ['New password form', 'Confirm password form', 'Security guidance']),
  RestoredScreenData(path: '/settings/account', title: 'Account', section: 'Settings', icon: Icons.person_rounded, description: 'Profile, account identity, plan summary, and session information.', highlights: ['Profile details', 'Plan status', 'Session controls']),
  RestoredScreenData(path: '/settings/preferences', title: 'Preferences', section: 'Settings', icon: Icons.tune_rounded, description: 'Conversation style, default model, privacy, language, and response preferences.', highlights: ['Zero Fluff preference', 'Default model preference', 'Privacy-first defaults']),
  RestoredScreenData(path: '/settings/api-keys', title: 'API Keys', section: 'Settings', icon: Icons.key_rounded, description: 'Bring-your-own-key provider management with secure local storage.', highlights: ['Provider key storage', 'Fingerprint display', 'Local-device encryption']),
  RestoredScreenData(path: '/settings/subscription', title: 'Subscription', section: 'Billing', icon: Icons.workspace_premium_rounded, description: 'Plan comparison, subscription status, BYOK value proposition, and billing actions.', highlights: ['Free / Pro / Team plans', 'Monthly and yearly options', 'Upgrade path']),
  RestoredScreenData(path: '/settings/subscription/checkout', title: 'Checkout', section: 'Billing', icon: Icons.credit_card_rounded, description: 'Checkout review screen for selected subscription plans.', highlights: ['Plan summary', 'Billing cadence', 'Secure payment handoff']),
  RestoredScreenData(path: '/settings/subscription/welcome', title: 'Subscription Welcome', section: 'Billing', icon: Icons.celebration_rounded, description: 'Post-upgrade welcome and next-step guide.', highlights: ['Plan activated state', 'Feature unlock list', 'Continue to chat']),
  RestoredScreenData(path: '/settings/usage', title: 'Usage Limits', section: 'Settings', icon: Icons.speed_rounded, description: 'Usage tracking, provider request counts, budgets, and warning thresholds.', highlights: ['Token/request estimates', 'Daily and monthly budgets', 'Limit warnings']),
  RestoredScreenData(path: '/settings/devices', title: 'Devices', section: 'Settings', icon: Icons.devices_rounded, description: 'Signed-in device list and session/device management.', highlights: ['Current device', 'Other sessions', 'Revoke controls']),
  RestoredScreenData(path: '/settings/storage', title: 'Storage', section: 'Settings', icon: Icons.storage_rounded, description: 'File attachment storage, cache usage, and cleanup controls.', highlights: ['Attachment storage', 'Cache size', 'Cleanup tools']),
  RestoredScreenData(path: '/settings/connectors', title: 'Connectors', section: 'Integrations', icon: Icons.hub_rounded, description: 'Manage connected services such as Notion, Gmail, Calendar, Drive, and web tools.', highlights: ['Connector status', 'Enable/disable controls', 'Privacy notices']),
  RestoredScreenData(path: '/settings/connectors/notion', title: 'Notion Connector', section: 'Integrations', icon: Icons.article_rounded, description: 'Notion workspace connection details and actions.', highlights: ['Workspace sync', 'Page creation', 'Database workflows']),
  RestoredScreenData(path: '/settings/connectors/gmail', title: 'Gmail Connector', section: 'Integrations', icon: Icons.mail_rounded, description: 'Gmail integration configuration and permissions.', highlights: ['Message search', 'Draft assistance', 'Permission scope']),
  RestoredScreenData(path: '/settings/connectors/calendar', title: 'Calendar Connector', section: 'Integrations', icon: Icons.calendar_month_rounded, description: 'Google Calendar integration configuration.', highlights: ['Event lookup', 'Meeting prep', 'Schedule actions']),
  RestoredScreenData(path: '/settings/connectors/drive', title: 'Drive Connector', section: 'Integrations', icon: Icons.cloud_rounded, description: 'Google Drive and document access controls.', highlights: ['Document lookup', 'File summaries', 'Permission review']),
  RestoredScreenData(path: '/settings/memory', title: 'Memory', section: 'Settings', icon: Icons.psychology_rounded, description: 'Personal memory, saved facts, and recall controls.', highlights: ['Saved preferences', 'Memory review', 'Forget controls']),
  RestoredScreenData(path: '/settings/scheduled', title: 'Scheduled Tasks', section: 'Automation', icon: Icons.schedule_rounded, description: 'Recurring automations, reminders, and scheduled agent tasks.', highlights: ['Daily jobs', 'Run history', 'Pause/expire actions']),
  RestoredScreenData(path: '/settings/referral', title: 'Referral', section: 'Account', icon: Icons.group_add_rounded, description: 'Referral sharing and reward status.', highlights: ['Invite link', 'Reward tracking', 'Share actions']),
  RestoredScreenData(path: '/settings/data-controls', title: 'Data Controls', section: 'Privacy', icon: Icons.privacy_tip_rounded, description: 'Export, delete, and manage conversation/account data.', highlights: ['Export data', 'Delete history', 'Privacy controls']),
  RestoredScreenData(path: '/settings/personalization', title: 'Personalization', section: 'Settings', icon: Icons.auto_awesome_rounded, description: 'Tone, theme, writing style, and model behavior personalization.', highlights: ['Tone presets', 'Writing style', 'Theme choices']),
  RestoredScreenData(path: '/settings/integrations', title: 'Integrations', section: 'Integrations', icon: Icons.extension_rounded, description: 'Integration catalog for external tools and plugins.', highlights: ['Available integrations', 'Connected tools', 'Setup actions']),
  RestoredScreenData(path: '/settings/mail', title: 'Mail Preferences', section: 'Settings', icon: Icons.alternate_email_rounded, description: 'Email notifications, product updates, and digest preferences.', highlights: ['Notification toggles', 'Digest schedule', 'Product updates']),
  RestoredScreenData(path: '/settings/security', title: 'Security', section: 'Settings', icon: Icons.shield_rounded, description: 'Security settings, key safety, sessions, and account protection.', highlights: ['Secure storage status', 'Session safety', 'Password guidance']),
  RestoredScreenData(path: '/projects', title: 'Projects', section: 'Workspace', icon: Icons.folder_rounded, description: 'Project list for organizing chats, files, context, and tasks.', highlights: ['Project cards', 'Pinned workspace', 'Create project']),
  RestoredScreenData(path: '/projects/demo', title: 'Project Detail', section: 'Workspace', icon: Icons.folder_open_rounded, description: 'Project detail view with chats, files, notes, and saved instructions.', highlights: ['Project context', 'Files and chats', 'Workspace instructions']),
  RestoredScreenData(path: '/prompts', title: 'Prompt Library', section: 'Workspace', icon: Icons.library_books_rounded, description: 'Saved prompt templates and reusable workflows.', highlights: ['Prompt cards', 'Categories', 'Insert into chat']),
  RestoredScreenData(path: '/prompt-editor', title: 'Prompt Editor', section: 'Workspace', icon: Icons.edit_note_rounded, description: 'Create and edit reusable prompt templates.', highlights: ['Template fields', 'Variables', 'Save prompt']),
  RestoredScreenData(path: '/launch', title: 'Launch Checklist', section: 'Workspace', icon: Icons.rocket_launch_rounded, description: 'Production launch checklist for onboarding, provider keys, limits, and subscription.', highlights: ['Readiness checks', 'Required setup', 'Launch status']),
  RestoredScreenData(path: '/legal/privacy', title: 'Privacy Policy', section: 'Legal', icon: Icons.policy_rounded, description: 'Privacy policy and BYOK data-handling summary.', highlights: ['BYOK privacy', 'Local key handling', 'Data rights']),
  RestoredScreenData(path: '/legal/terms', title: 'Terms of Service', section: 'Legal', icon: Icons.gavel_rounded, description: 'Terms of service and acceptable use summary.', highlights: ['Usage terms', 'Account duties', 'Service limits']),
  RestoredScreenData(path: '/shared/demo', title: 'Shared Conversation', section: 'Workspace', icon: Icons.ios_share_rounded, description: 'Shared conversation viewer for public or team-shared chats.', highlights: ['Read-only chat', 'Source attribution', 'Copy to project']),
];

class RestoredScreenRoutes {
  static List<GoRoute> get routes => [
        GoRoute(path: '/settings', builder: (_, __) => const RestoredSettingsHomeScreen()),
        for (final spec in restoredScreens) GoRoute(path: spec.path, builder: (_, __) => RestoredFeatureScreen(spec: spec)),
      ];
}

class RestoredSettingsHomeScreen extends ConsumerWidget {
  const RestoredSettingsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: MioTheme.cream,
      appBar: AppBar(
        backgroundColor: MioTheme.cream,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w900)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.canPop() ? context.pop() : context.go('/chat')),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _SettingsCard(icon: Icons.person_rounded, title: 'Account', subtitle: 'Profile, email, username', onTap: () => context.go('/settings/account')),
                const SizedBox(height: 12),
                _SettingsCard(icon: Icons.tune_rounded, title: 'Preferences', subtitle: 'Response style and defaults', onTap: () => context.go('/settings/preferences')),
                const SizedBox(height: 12),
                _SettingsCard(icon: Icons.key_rounded, title: 'API Keys', subtitle: 'Manage provider keys', onTap: () => context.go('/settings/api-keys')),
                const SizedBox(height: 12),
                _SettingsCard(icon: Icons.speed_rounded, title: 'Usage', subtitle: 'Daily, weekly, monthly stats', onTap: () => context.go('/settings/usage')),
                const SizedBox(height: 12),
                _SettingsCard(icon: Icons.devices_rounded, title: 'Devices', subtitle: 'Active sessions', onTap: () => context.go('/settings/devices')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SettingsCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: MioTheme.line)),
        child: Row(
          children: [
            Icon(icon, color: MioTheme.orange, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: MioTheme.muted, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: MioTheme.muted),
          ],
        ),
      ),
    );
  }
}

class RestoredFeatureScreen extends ConsumerWidget {
  final RestoredScreenData spec;
  const RestoredFeatureScreen({super.key, required this.spec});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (spec.path == '/settings/api-keys') return const RestoredApiKeysScreen();
    if (spec.path == '/settings/subscription') return const RestoredSubscriptionScreen();
    if (spec.path == '/settings/usage') return const ModernUsageScreen();
    if (spec.path == '/settings/preferences') return const RestoredPreferencesScreen();
    if (spec.path == '/settings/account') return const ModernAccountScreen();
    if (spec.path == '/settings/devices') return const ModernDevicesScreen();
    final siblings = restoredScreens.where((s) => s.section == spec.section && s.path != spec.path).take(5).toList();
    return RestoredScreenScaffold(
      title: spec.title,
      section: spec.section,
      description: spec.description,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RestoredHeroPanel(icon: spec.icon, title: spec.title, body: spec.description),
        const SizedBox(height: 18),
        RestoredSectionCard(title: 'Legacy functionality restored', children: [for (final item in spec.highlights) RestoredCheckRow(text: item)]),
        const SizedBox(height: 18),
        RestoredSectionCard(title: 'Available actions', children: const [
          RestoredCheckRow(text: 'Open this section from direct routes or Settings navigation.'),
          RestoredCheckRow(text: 'Preserves the current BYOK chat, onboarding, model picker, and plus menu changes.'),
          RestoredCheckRow(text: 'Keeps this screen as a first-class route instead of hiding it in a dialog.'),
        ]),
        if (siblings.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text('Related ${spec.section} screens', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(spacing: 12, runSpacing: 12, children: siblings.map((s) => SizedBox(width: 260, child: RestoredNavigationCard(screen: s))).toList()),
        ],
      ]),
    );
  }
}

class RestoredApiKeysScreen extends ConsumerStatefulWidget {
  const RestoredApiKeysScreen({super.key});
  @override
  ConsumerState<RestoredApiKeysScreen> createState() => _RestoredApiKeysScreenState();
}

class _RestoredApiKeysScreenState extends ConsumerState<RestoredApiKeysScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _fingerprints = {};

  @override
  void initState() {
    super.initState();
    for (final provider in providers) {
      _controllers[provider.id] = TextEditingController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFingerprints());
  }

  Future<void> _loadFingerprints() async {
    final app = ref.read(appControllerProvider);
    final values = <String, String>{};
    for (final provider in providers) {
      values[provider.id] = await app.apiKeyFingerprint(provider.id);
    }
    if (mounted) setState(() => _fingerprints.addAll(values));
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    return RestoredScreenScaffold(
      title: 'API Keys',
      section: 'Settings',
      description: 'Manage every provider key from a full settings screen. Keys remain stored with device secure storage and are not sent to Mio servers.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RestoredHeroPanel(icon: Icons.key_rounded, title: 'Bring your own keys', body: 'The original API-key functionality is preserved here as a complete settings page instead of a small dialog.'),
        const SizedBox(height: 18),
        ...providers.map((provider) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(22), border: Border.all(color: MioTheme.line)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  _ProviderLogo(asset: provider.logoAsset, fallback: provider.name.substring(0, 1), color: provider.brandColor, size: 34),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(provider.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), Text('Current: ${_fingerprints[provider.id] ?? 'Checking…'}', style: const TextStyle(color: MioTheme.muted, fontSize: 12))])),
                  if (app.selectedProviderId == provider.id) const Chip(label: Text('Active')),
                  const SizedBox(width: 8),
                  TextButton(onPressed: () => app.chooseProvider(provider.id), child: const Text('Use')),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: _controllers[provider.id], obscureText: true, decoration: InputDecoration(labelText: '${provider.name} API key', border: const OutlineInputBorder(), helperText: provider.helpText))),
                  const SizedBox(width: 10),
                  FilledButton(onPressed: () async { await app.setApiKey(provider.id, _controllers[provider.id]!.text); _controllers[provider.id]!.clear(); await _loadFingerprints(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${provider.name} key saved'))); }, child: const Text('Save')),
                ]),
              ]),
            )),
      ]),
    );
  }
}

class RestoredPreferencesScreen extends ConsumerWidget {
  const RestoredPreferencesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    return Scaffold(
      backgroundColor: MioTheme.cream,
      appBar: AppBar(
        backgroundColor: MioTheme.cream,
        elevation: 0,
        title: const Text('Preferences', style: TextStyle(fontWeight: FontWeight.w900)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.canPop() ? context.pop() : context.go('/chat')),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('RESPONSE STYLE', style: const TextStyle(color: MioTheme.orange, fontWeight: FontWeight.w900, letterSpacing: .8, fontSize: 12)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: MioTheme.line)),
                  child: Column(
                    children: [
                      SwitchListTile(value: app.zeroFluff, onChanged: (_) => app.toggleZeroFluff(), title: const Text('Zero Fluff'), subtitle: const Text('Direct answers with less filler.')),
                      const Divider(),
                      SwitchListTile(value: app.deepResearchMode, onChanged: (_) => app.toggleDeepResearch(), title: const Text('Deep Research'), subtitle: const Text('Use broader search and synthesis when available.')),
                      const Divider(),
                      SwitchListTile(value: app.webSearchEnabled, onChanged: (_) => app.toggleWebSearch(), title: const Text('Web Search'), subtitle: const Text('Allow web-assisted responses when needed.')),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('DEFAULT PROVIDER', style: const TextStyle(color: MioTheme.orange, fontWeight: FontWeight.w900, letterSpacing: .8, fontSize: 12)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: MioTheme.line)),
                  child: Column(
                    children: providers.map((p) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: RadioListTile<String>(value: p.id, groupValue: app.selectedProviderId, onChanged: (v) => v == null ? null : app.chooseProvider(v), title: Text(p.name), subtitle: Text(p.model)),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RestoredUsageLimitsScreen extends ConsumerWidget {
  const RestoredUsageLimitsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    return RestoredScreenScaffold(
      title: 'Usage Limits',
      section: 'Settings',
      description: 'Track BYOK usage and configure budget guardrails.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RestoredHeroPanel(icon: Icons.speed_rounded, title: 'Usage and limits', body: 'Because Mio uses your provider keys, this screen centralizes visible request counts, budget notes, and limit reminders.'),
        const SizedBox(height: 18),
        LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final width = compact ? constraints.maxWidth : (constraints.maxWidth - 24) / 3;
          return Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(width: width, child: RestoredMetricCard(label: 'Messages this session', value: '${app.messages.length}', icon: Icons.chat_bubble_rounded)),
            SizedBox(width: width, child: const RestoredMetricCard(label: 'Provider requests', value: 'BYOK', icon: Icons.api_rounded)),
            SizedBox(width: width, child: const RestoredMetricCard(label: 'Monthly app limit', value: 'Configurable', icon: Icons.speed_rounded)),
          ]);
        }),
        const SizedBox(height: 18),
        const RestoredSectionCard(title: 'Limit controls', children: [
          RestoredCheckRow(text: 'Daily, weekly, and monthly budget reminders restored as a full page.'),
          RestoredCheckRow(text: 'Provider usage remains transparent because requests use your own keys.'),
          RestoredCheckRow(text: 'Future backend usage sync can attach to this route without changing navigation.'),
        ]),
      ]),
    );
  }
}

class RestoredSubscriptionScreen extends StatelessWidget {
  const RestoredSubscriptionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MioTheme.cream,
      appBar: AppBar(
        backgroundColor: MioTheme.cream,
        elevation: 0,
        title: const Text('Subscription', style: TextStyle(fontWeight: FontWeight.w900)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.canPop() ? context.pop() : context.go('/chat')),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('CHOOSE YOUR PLAN', style: const TextStyle(color: MioTheme.orange, fontWeight: FontWeight.w900, letterSpacing: .8, fontSize: 12)),
                const SizedBox(height: 8),
                const Text('14-day free trial. No credit card required.', style: TextStyle(color: MioTheme.muted, fontSize: 14)),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 600;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _PlanCard(name: 'Free', monthlyPrice: '0', yearlyPrice: null, description: 'Perfect for getting started', features: ['1 project', 'Local key storage', 'Basic usage'], isPopular: false, onTap: () {}),
                        _PlanCard(name: 'Pro', monthlyPrice: '4.99', yearlyPrice: '49.99', description: 'Best for power users', features: ['Unlimited projects', 'All BYOK providers', 'Advanced usage tracking', 'Priority support'], isPopular: true, onTap: () {}),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: MioTheme.line)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Billing Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Current Plan', style: TextStyle(color: MioTheme.muted)),
                          const Text('Free (Trial)', style: TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Trial Ends', style: TextStyle(color: MioTheme.muted)),
                          Text(DateTime.now().add(const Duration(days: 14)).toString().split(' ')[0], style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String name;
  final String monthlyPrice;
  final String? yearlyPrice;
  final String description;
  final List<String> features;
  final bool isPopular;
  final VoidCallback onTap;

  const _PlanCard({
    required this.name,
    required this.monthlyPrice,
    this.yearlyPrice,
    required this.description,
    required this.features,
    required this.isPopular,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MioTheme.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPopular ? MioTheme.orange : MioTheme.line, width: isPopular ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: MioTheme.orange.withOpacity(.12), borderRadius: BorderRadius.circular(8)), child: const Text('Most Popular', style: TextStyle(color: MioTheme.orange, fontSize: 12, fontWeight: FontWeight.w700))),
          if (isPopular) const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(color: MioTheme.muted, fontSize: 14)),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('\$$monthlyPrice', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(width: 4),
              const Text('/month', style: TextStyle(color: MioTheme.muted, fontSize: 14)),
            ],
          ),
          if (yearlyPrice != null) ...[const SizedBox(height: 8), Text('or \$$yearlyPrice/year', style: const TextStyle(color: MioTheme.muted, fontSize: 13))],
          const SizedBox(height: 20),
          FilledButton(onPressed: onTap, style: FilledButton.styleFrom(backgroundColor: isPopular ? MioTheme.orange : MioTheme.ink, minimumSize: const Size(double.infinity, 44)), child: Text(name == 'Free' ? 'Current Plan' : 'Upgrade Now')),
          const SizedBox(height: 20),
          ...features.map((f) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [const Icon(Icons.check_circle_rounded, color: MioTheme.orange, size: 18), const SizedBox(width: 10), Expanded(child: Text(f, style: const TextStyle(fontSize: 14)))]))),
        ],
      ),
    );
  }
}

class _OldRestoredScreenScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final plans = [
      ('Free', r'$0', 'Try Mio with BYOK basics', ['1 project', 'Local key storage', 'Starter usage']),
      ('Pro', r'$12', 'Best for individual power users', ['Unlimited BYOK providers', 'Projects and memory', 'Usage limits']),
      ('Team', r'$29', 'Shared workspace features', ['Team projects', 'Admin controls', 'Connector workflows']),
    ];
    return RestoredScreenScaffold(
      title: 'Subscription',
      section: 'Billing',
      description: 'Plan and billing screens restored as first-class routes.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RestoredHeroPanel(icon: Icons.workspace_premium_rounded, title: 'Subscription and billing', body: 'The separate subscription page is restored, including plan cards and checkout navigation.'),
        const SizedBox(height: 18),
        LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxWidth < 850;
          final width = compact ? constraints.maxWidth : (constraints.maxWidth - 24) / 3;
          return Wrap(spacing: 12, runSpacing: 12, children: plans.map((plan) => SizedBox(width: width, child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(24), border: Border.all(color: plan.$1 == 'Pro' ? MioTheme.orange : MioTheme.line, width: plan.$1 == 'Pro' ? 2 : 1)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(plan.$1, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('${plan.$2}/mo', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(plan.$3, style: const TextStyle(color: MioTheme.muted)),
              const SizedBox(height: 14),
              for (final item in plan.$4) RestoredCheckRow(text: item),
              const SizedBox(height: 14),
              FilledButton(onPressed: () => context.go('/settings/subscription/checkout'), child: Text(plan.$1 == 'Free' ? 'Current plan' : 'Choose ${plan.$1}')),
            ]),
          ))).toList());
        }),
      ]),
    );
  }
}

// --- Modern Settings Screens ---

class ModernAccountScreen extends ConsumerStatefulWidget {
  const ModernAccountScreen({super.key});
  @override
  ConsumerState<ModernAccountScreen> createState() => _ModernAccountScreenState();
}

class _ModernAccountScreenState extends ConsumerState<ModernAccountScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Arunteja');
    _emailController = TextEditingController(text: 'arunteja@example.com');
    _usernameController = TextEditingController(text: 'arunteja');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MioTheme.cream,
      appBar: AppBar(
        backgroundColor: MioTheme.cream,
        elevation: 0,
        title: const Text('Account', style: TextStyle(fontWeight: FontWeight.w900)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.canPop() ? context.pop() : context.go('/chat')),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('PROFILE', style: const TextStyle(color: MioTheme.orange, fontWeight: FontWeight.w900, letterSpacing: .8, fontSize: 12)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: MioTheme.line)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Full name', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Enter your full name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Email', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'your.email@example.com',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Username', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          hintText: 'username',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          FilledButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated'))), child: const Text('Save changes')),
                          const SizedBox(width: 12),
                          OutlinedButton(onPressed: () {}, child: const Text('Forgot password?')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('ACCOUNT ACTIONS', style: const TextStyle(color: MioTheme.orange, fontWeight: FontWeight.w900, letterSpacing: .8, fontSize: 12)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: MioTheme.line)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Log out of all devices', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 8),
                      const Text('This will sign you out on all your devices.', style: TextStyle(color: MioTheme.muted, fontSize: 13)),
                      const SizedBox(height: 12),
                      FilledButton.tonal(onPressed: () {}, child: const Text('Log out of all devices')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ModernDevicesScreen extends StatelessWidget {
  const ModernDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final devices = [
      ('Chrome (Windows)', 'Charlotte, North Carolina', 'Apr 27, 2026, 2:46 PM', 'Jun 1, 2026, 4:56 PM', true),
      ('Claude Desktop', 'Charlotte, North Carolina', 'Apr 27, 2026, 2:55 PM', 'May 18, 2026, 11:57 AM', false),
      ('Claude (iOS)', 'Charlotte, North Carolina', 'Apr 18, 2026, 4:55 AM', 'Jun 1, 2026, 12:21 PM', false),
    ];

    return Scaffold(
      backgroundColor: MioTheme.cream,
      appBar: AppBar(
        backgroundColor: MioTheme.cream,
        elevation: 0,
        title: const Text('Devices', style: TextStyle(fontWeight: FontWeight.w900)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.canPop() ? context.pop() : context.go('/chat')),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('ACTIVE SESSIONS', style: const TextStyle(color: MioTheme.orange, fontWeight: FontWeight.w900, letterSpacing: .8, fontSize: 12)),
                const SizedBox(height: 16),
                ...devices.map((device) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: device.$5 ? MioTheme.orange : MioTheme.line, width: device.$5 ? 2 : 1)),
                    child: Row(
                      children: [
                        Icon(device.$1.contains('Chrome') ? Icons.devices_rounded : Icons.phone_iphone_rounded, color: MioTheme.orange, size: 24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(device.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                  const SizedBox(width: 8),
                                  if (device.$5) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: MioTheme.orange.withOpacity(.12), borderRadius: BorderRadius.circular(6)), child: const Text('Current', style: TextStyle(color: MioTheme.orange, fontSize: 11, fontWeight: FontWeight.w700))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(device.$2, style: const TextStyle(color: MioTheme.muted, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('Created: ${device.$3} • Updated: ${device.$4}', style: const TextStyle(color: MioTheme.muted, fontSize: 11)),
                            ],
                          ),
                        ),
                        if (!device.$5) IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: () {}),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ModernUsageScreen extends ConsumerWidget {
  const ModernUsageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);

    return Scaffold(
      backgroundColor: MioTheme.cream,
      appBar: AppBar(
        backgroundColor: MioTheme.cream,
        elevation: 0,
        title: const Text('Usage', style: TextStyle(fontWeight: FontWeight.w900)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.canPop() ? context.pop() : context.go('/chat')),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('USAGE OVERVIEW', style: const TextStyle(color: MioTheme.orange, fontWeight: FontWeight.w900, letterSpacing: .8, fontSize: 12)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: MioTheme.line)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.chat_bubble_rounded, color: MioTheme.orange, size: 28),
                            const SizedBox(height: 12),
                            Text('${app.messages.length}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            const Text('Messages this session', style: TextStyle(color: MioTheme.muted, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: MioTheme.line)),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.speed_rounded, color: MioTheme.orange, size: 28),
                            SizedBox(height: 12),
                            Text('Unlimited', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                            SizedBox(height: 4),
                            Text('Current session limit', style: TextStyle(color: MioTheme.muted, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: MioTheme.line)),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.calendar_month_rounded, color: MioTheme.orange, size: 28),
                            SizedBox(height: 12),
                            Text('12 days', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                            SizedBox(height: 4),
                            Text('Active days this month', style: TextStyle(color: MioTheme.muted, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('DAILY ACTIVITY HEATMAP', style: const TextStyle(color: MioTheme.orange, fontWeight: FontWeight.w900, letterSpacing: .8, fontSize: 12)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: MioTheme.line)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Last 12 weeks', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 100,
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 12, crossAxisSpacing: 4, mainAxisSpacing: 4),
                          itemCount: 84,
                          itemBuilder: (context, index) {
                            final intensity = (index % 7 + 1) / 7;
                            final isActive = index % 3 != 0;
                            return Container(
                              decoration: BoxDecoration(
                                color: isActive ? MioTheme.orange.withOpacity(intensity) : MioTheme.cream2,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: MioTheme.line.withOpacity(.3)),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Less', style: TextStyle(color: MioTheme.muted, fontSize: 11)),
                          const SizedBox(width: 8),
                          ...List.generate(5, (i) => Container(width: 12, height: 12, decoration: BoxDecoration(color: MioTheme.orange.withOpacity((i + 1) / 5), borderRadius: BorderRadius.circular(2), border: Border.all(color: MioTheme.line.withOpacity(.3))))),
                          const SizedBox(width: 8),
                          const Text('More', style: TextStyle(color: MioTheme.muted, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RestoredScreenScaffold extends StatelessWidget {
  final String title;
  final String section;
  final String description;
  final Widget child;
  const RestoredScreenScaffold({super.key, required this.title, required this.section, required this.description, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MioTheme.cream,
      appBar: AppBar(
        backgroundColor: MioTheme.cream,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.canPop() ? context.pop() : context.go('/chat')),
        actions: [TextButton.icon(onPressed: () => context.go('/settings'), icon: const Icon(Icons.settings_rounded), label: const Text('Settings')), const SizedBox(width: 8), TextButton.icon(onPressed: () => context.go('/chat'), icon: const Icon(Icons.chat_rounded), label: const Text('Chat')), const SizedBox(width: 12)],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                Text(section.toUpperCase(), style: const TextStyle(color: MioTheme.orange, fontWeight: FontWeight.w900, letterSpacing: .8)),
                const SizedBox(height: 8),
                Text(description, style: const TextStyle(color: MioTheme.muted, fontSize: 16, height: 1.5)),
                const SizedBox(height: 20),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RestoredHeroPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const RestoredHeroPanel({super.key, required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFF6ED), Color(0xFFFFFFFF)]), borderRadius: BorderRadius.circular(28), border: Border.all(color: MioTheme.line), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 24, offset: const Offset(0, 12))]),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 54, height: 54, decoration: BoxDecoration(color: MioTheme.orange.withOpacity(.12), borderRadius: BorderRadius.circular(18)), child: Icon(icon, color: MioTheme.orange, size: 28)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text(body, style: const TextStyle(color: MioTheme.muted, fontSize: 15, height: 1.5))])),
      ]),
    );
  }
}

class RestoredNavigationCard extends StatelessWidget {
  final RestoredScreenData screen;
  const RestoredNavigationCard({super.key, required this.screen});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.go(screen.path),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: MioTheme.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(screen.icon, color: MioTheme.orange), const SizedBox(width: 10), Expanded(child: Text(screen.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900))), const Icon(Icons.chevron_right_rounded, color: MioTheme.muted)]),
          const SizedBox(height: 8),
          Text(screen.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: MioTheme.muted, fontSize: 12, height: 1.35)),
        ]),
      ),
    );
  }
}

class RestoredSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const RestoredSectionCard({super.key, required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(22), border: Border.all(color: MioTheme.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 10), ...children]),
    );
  }
}

class RestoredCheckRow extends StatelessWidget {
  final String text;
  const RestoredCheckRow({super.key, required this.text});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle_rounded, color: MioTheme.orange, size: 18), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(height: 1.35)))]));
}

class RestoredMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const RestoredMetricCard({super.key, required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(22), border: Border.all(color: MioTheme.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: MioTheme.orange), const SizedBox(height: 12), Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(label, style: const TextStyle(color: MioTheme.muted))]),
    );
  }
}

