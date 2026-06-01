from pathlib import Path

p = Path('/home/ubuntu/omnimind-byok/lib/main.dart')
s = p.read_text()
if "import 'dart:ui' as ui;" not in s:
    s = s.replace("import 'dart:math';\n", "import 'dart:math';\nimport 'dart:ui' as ui;\n")

start = s.index('class OnboardingScreen extends StatefulWidget')
end = s.index('\n\nclass MioTheme {', start)
new_onboarding = r'''
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
    final fade = CurvedAnimation(parent: _pageEntranceController, curve: Interval(extraDelay, (0.6 + extraDelay).clamp(0.0, 1.0), curve: Curves.easeOut));
    final slide = CurvedAnimation(parent: _pageEntranceController, curve: Interval(extraDelay, (0.7 + extraDelay).clamp(0.0, 1.0), curve: Curves.easeOutCubic));
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
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) => Transform.translate(offset: Offset(0, -4 + 8 * _floatController.value), child: child),
              child: Image.asset('assets/images/sky_clouds.png', fit: BoxFit.cover),
            ),
          ),
          if (isDark) Positioned.fill(child: Container(color: Colors.black.withOpacity(.55))),
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
    showModalBottomSheet<void>(context: context, backgroundColor: MioTheme.panel, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (context) => SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Run locally with Ollama', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 10), const Text('Install Ollama, run a model like `ollama run llama3.1`, then choose Ollama from the model picker. Mio will use the local OpenAI-compatible endpoint.'), const SizedBox(height: 16), FilledButton(onPressed: () => launchUrl(Uri.parse('https://ollama.com/'), mode: LaunchMode.externalApplication), child: const Text('Open Ollama'))])));
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
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * .5), Paint()..color = p.color.withOpacity(opacity * .85));
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
'''
s = s[:start] + new_onboarding + s[end:]

start = s.index('class ProviderPill extends ConsumerWidget')
end = s.index('\n\nclass SettingsButton', start)
new_provider = r'''
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
  final LayerLink _modelLink = LayerLink();
  OverlayEntry? _modelOverlay;
  bool _isModelOpen = false;
  bool _showMore = false;

  @override
  void dispose() {
    _closeModelOverlay();
    super.dispose();
  }

  void _closeModelOverlay() {
    _modelOverlay?.remove();
    _modelOverlay = null;
    _isModelOpen = false;
    _showMore = false;
  }

  void _toggleModelOverlay() {
    if (_isModelOpen) {
      _closeModelOverlay();
    } else {
      _modelOverlay = _createModelOverlay();
      Overlay.of(context).insert(_modelOverlay!);
      _isModelOpen = true;
    }
  }

  OverlayEntry _createModelOverlay() {
    return OverlayEntry(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF262626) : Colors.white;
        final textPrimary = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A1A);
        final textMuted = isDark ? const Color(0xFF888888) : const Color(0xFF666666);
        final visible = _showMore ? [..._primaryModelOptions, ..._moreModelOptions] : _primaryModelOptions;
        return GestureDetector(
          onTap: _closeModelOverlay,
          behavior: HitTestBehavior.translucent,
          child: Stack(children: [
            CompositedTransformFollower(
              link: _modelLink,
              showWhenUnlinked: false,
              offset: const Offset(-210, 42),
              child: GestureDetector(
                onTap: () {},
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 320,
                    constraints: const BoxConstraints(maxHeight: 420),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? const Color(0xFF3A3A3A) : MioTheme.line), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.24), blurRadius: 22, offset: const Offset(0, 8))]),
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        ...visible.map((m) => _modelRow(m, textPrimary, textMuted)),
                        if (!_showMore)
                          InkWell(
                            onTap: () {
                              setState(() => _showMore = true);
                              _modelOverlay?.markNeedsBuild();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(children: [Icon(Icons.expand_more, size: 18, color: textMuted), const SizedBox(width: 12), Text('More models', style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w600)), const Spacer(), Text('Ollama', style: GoogleFonts.dmSans(fontSize: 12, color: textMuted)), const SizedBox(width: 8), Icon(Icons.chevron_right, size: 18, color: textMuted)]),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _modelRow(_ModelOption option, Color textPrimary, Color textMuted) {
    final selected = ref.read(appControllerProvider).selectedProviderId == option.providerId;
    return InkWell(
      onTap: () {
        ref.read(appControllerProvider).chooseProvider(option.providerId);
        _closeModelOverlay();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          _ProviderLogo(asset: option.logoAsset, fallback: option.provider.characters.first, color: option.color, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(option.model, style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary, fontWeight: selected ? FontWeight.w700 : FontWeight.w600)), Text(option.description, style: GoogleFonts.dmSans(fontSize: 12, color: textMuted))])),
          if (selected) const Icon(Icons.check, size: 18, color: Color(0xFF4285F4)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _modelLink,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: _toggleModelOverlay,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(999), border: Border.all(color: MioTheme.line)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [_ProviderLogo(asset: _providerLogoForId(widget.provider.id), fallback: widget.provider.name.characters.first, color: MioTheme.orange, size: 20), const SizedBox(width: 8), Text(widget.provider.name, style: const TextStyle(fontWeight: FontWeight.w700)), const Icon(Icons.keyboard_arrow_down_rounded, size: 18)]),
        ),
      ),
    );
  }
}

String _providerLogoForId(String id) {
  switch (id) {
    case 'openai': return 'assets/icons/providers/openai.png';
    case 'anthropic': return 'assets/icons/providers/anthropic.png';
    case 'gemini': return 'assets/icons/providers/google.png';
    case 'deepseek': return 'assets/icons/providers/deepseek.png';
    case 'groq': return 'assets/icons/providers/groq.png';
    case 'mistral': return 'assets/icons/providers/mistral.png';
    case 'openrouter': return 'assets/icons/providers/openrouter.png';
    case 'ollama': return 'assets/icons/providers/ollama.png';
    default: return 'assets/icons/providers/openrouter.png';
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(size * .28), border: Border.all(color: MioTheme.line.withOpacity(.7))),
      padding: EdgeInsets.all(size * .16),
      child: Image.asset(asset, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Center(child: Text(fallback, style: TextStyle(color: color, fontSize: size * .48, fontWeight: FontWeight.w900)))),
    );
  }
}
'''
s = s[:start] + new_provider + s[end:]

# Convert Composer into a stateful consumer widget with overlay plus menu.
start = s.index('class Composer extends ConsumerWidget')
end = s.index('\n\nString formatTime', start)
old_composer_tail = s[start:end]
# Keep helper methods by embedding a rewritten state class.
new_composer = r'''
class Composer extends ConsumerStatefulWidget {
  const Composer({super.key});

  @override
  ConsumerState<Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<Composer> {
  final LayerLink _menuLink = LayerLink();
  OverlayEntry? _menuOverlay;
  bool _isMenuOpen = false;

  @override
  void dispose() {
    _closeMenuOverlay();
    super.dispose();
  }

  void _closeMenuOverlay() {
    _menuOverlay?.remove();
    _menuOverlay = null;
    _isMenuOpen = false;
  }

  void _toggleMenu(AppController app) {
    if (_isMenuOpen) {
      _closeMenuOverlay();
    } else {
      _menuOverlay = _createMenuOverlay(app);
      Overlay.of(context).insert(_menuOverlay!);
      _isMenuOpen = true;
    }
  }

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

  Future<void> _enableNotifications(BuildContext context, AppController app) async {
    final allowed = await _confirmAndRequestPermission(context, Permission.notification, 'Allow notifications?', 'Mio will only notify you for task completion, reminders, and scheduled summaries you enable.');
    if (allowed) {
      app.enableNotificationsNotice();
    } else {
      app.permissionDeniedNotice('Notifications');
    }
  }

  void _showLinkDialog(BuildContext context, AppController app) {
    final controller = TextEditingController();
    showDialog<void>(context: context, builder: (context) => AlertDialog(title: const Text('Attach link'), content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'URL', border: OutlineInputBorder())), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { app.attachLink(controller.text); Navigator.pop(context); }, child: const Text('Attach'))]));
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label is ready for connector wiring.')));
  }

  OverlayEntry _createMenuOverlay(AppController app) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF262626) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF888888) : const Color(0xFF666666);
    final divider = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE8E2DA);

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _closeMenuOverlay,
        behavior: HitTestBehavior.translucent,
        child: Stack(children: [
          CompositedTransformFollower(
            link: _menuLink,
            showWhenUnlinked: false,
            offset: const Offset(0, -350),
            child: GestureDetector(
              onTap: () {},
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 260,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.3), blurRadius: 20, offset: const Offset(0, 4))]),
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _menuItem(Icons.attach_file, 'Add files or photos', textPrimary, textMuted, () { _closeMenuOverlay(); _runWithPermission(context, app, Permission.storage, 'Allow document access?', 'Mio opens the system picker only when you choose files or photos to attach.', 'Files', app.attachDocument); }),
                    _menuItem(Icons.folder_outlined, 'Add to project', textPrimary, textMuted, () { _closeMenuOverlay(); _showComingSoon('Projects'); }, hasChevron: true),
                    _menuItem(Icons.construction_outlined, 'Skills', textPrimary, textMuted, () { _closeMenuOverlay(); _showComingSoon('Skills'); }, hasChevron: true),
                    _menuItem(Icons.power_outlined, 'Connectors', textPrimary, textMuted, () { _closeMenuOverlay(); app.runNotionConnector(); }, hasChevron: true),
                    _menuItem(Icons.extension_outlined, 'Plugins', textPrimary, textMuted, () { _closeMenuOverlay(); _showComingSoon('Plugins'); }, hasChevron: true),
                    Divider(height: 1, color: divider, indent: 48),
                    _menuItem(Icons.search_outlined, 'Research', textPrimary, textMuted, () { _closeMenuOverlay(); if (!app.deepResearchMode) app.toggleDeepResearch(); }),
                    _menuItem(Icons.language_outlined, 'Web search', textPrimary, textMuted, () { _closeMenuOverlay(); app.runWebSearchConnector(); }, trailing: const Icon(Icons.check, size: 18, color: Color(0xFF4285F4))),
                    _menuItem(Icons.brush_outlined, 'Use style', textPrimary, textMuted, () { _closeMenuOverlay(); _showComingSoon('Use style'); }, hasChevron: true),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, Color textPrimary, Color textMuted, VoidCallback onTap, {bool hasChevron = false, Widget? trailing}) {
    return InkWell(
      onTap: onTap,
      child: Container(
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
            CompositedTransformTarget(
              link: _menuLink,
              child: IconButton(onPressed: () => _toggleMenu(app), icon: const Icon(Icons.add_rounded), tooltip: 'Attach'),
            ),
            Expanded(child: TextField(controller: app.inputController, focusNode: app.inputFocusNode, minLines: 1, maxLines: 6, textInputAction: TextInputAction.newline, decoration: const InputDecoration(hintText: 'Ask anything…', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 13)), onSubmitted: (_) => app.sendPrompt())),
            if (app.error.isNotEmpty) Tooltip(message: app.error, child: const Icon(Icons.warning_rounded, color: MioTheme.orange)),
            const SizedBox(width: 6),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: MioTheme.orange, foregroundColor: Colors.white, shape: const CircleBorder(), padding: const EdgeInsets.all(14)), onPressed: app.isStreaming ? null : app.sendPrompt, child: app.isStreaming ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.arrow_upward_rounded)),
          ]),
        ),
      ),
    );
  }
}
'''
s = s[:start] + new_composer + s[end:]

p.write_text(s)
print('updated main.dart')
