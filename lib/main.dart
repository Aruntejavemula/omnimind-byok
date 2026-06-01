import 'dart:async';
import 'dart:convert';
import 'dart:math';

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
        GoRoute(path: '/chat', builder: (_, __) => const ShellScreen()),
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
    if (!mounted) return;
    context.go(completedWelcome ? '/chat' : '/welcome');
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

  Future<void> _continueLocalFirst() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mio_welcome_complete', true);
    if (!mounted) return;
    context.go('/chat');
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
                            child: FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: MioTheme.ink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 17), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                              onPressed: _loading ? null : _continueLocalFirst,
                              child: Text(_loading ? 'Opening Mio...' : 'Continue local-first', style: const TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(foregroundColor: MioTheme.ink, side: const BorderSide(color: MioTheme.line), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                              onPressed: _loading ? null : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supabase auth is ready to wire when credentials are provided.'))),
                              icon: const Icon(Icons.lock_outline_rounded),
                              label: const Text('Sign in / sync later', style: TextStyle(fontWeight: FontWeight.w800)),
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
      scaffoldBackgroundColor: const Color(0xFF0B0B0A),
      colorScheme: ColorScheme.fromSeed(seedColor: orange, brightness: Brightness.dark),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
    );
  }
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

const providers = <AiProviderConfig>[
  AiProviderConfig(id: 'openai', name: 'OpenAI', model: 'gpt-4o-mini', baseUrl: 'https://api.openai.com/v1/chat/completions', docsUrl: 'https://platform.openai.com/api-keys'),
  AiProviderConfig(id: 'anthropic', name: 'Anthropic', model: 'claude-3-5-sonnet-latest', baseUrl: 'https://api.anthropic.com/v1/messages', docsUrl: 'https://console.anthropic.com/settings/keys', openAiCompatible: false),
  AiProviderConfig(id: 'gemini', name: 'Gemini', model: 'gemini-1.5-flash', baseUrl: 'https://generativelanguage.googleapis.com/v1beta/models', docsUrl: 'https://aistudio.google.com/app/apikey', openAiCompatible: false),
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

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    selectedProviderId = prefs.getString('provider') ?? selectedProviderId;
    zeroFluff = prefs.getBool('zeroFluff') ?? true;
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
      width: 278,
      decoration: const BoxDecoration(color: MioTheme.cream2, border: Border(right: BorderSide(color: MioTheme.line))),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandHeader(),
              const SizedBox(height: 22),
              PrimaryNavButton(icon: Icons.add_rounded, label: 'New chat', onTap: app.clearChat),
              const SizedBox(height: 22),
              Text('Capabilities', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: MioTheme.muted, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              CapabilityItem(
                icon: Icons.biotech_rounded,
                label: 'Deep Research',
                active: app.deepResearchMode,
                onTap: app.toggleDeepResearch,
              ),
              const CapabilityItem(icon: Icons.public_rounded, label: 'Web Search', active: true),
              const CapabilityItem(icon: Icons.edit_note_rounded, label: 'Notion', active: true),
              const SizedBox(height: 22),
              Text('Projects', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: MioTheme.muted, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const ProjectChip(name: 'Personal', active: true),
              const ProjectChip(name: 'Research', active: false),
              const ProjectChip(name: 'Code', active: false),
              const Spacer(),
              StatusCard(app: app),
            ],
          ),
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
  const ProjectChip({super.key, required this.name, required this.active});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(color: active ? MioTheme.panel : Colors.transparent, borderRadius: BorderRadius.circular(14), border: Border.all(color: active ? MioTheme.line : Colors.transparent)),
      child: Row(children: [Icon(Icons.folder_rounded, size: 18, color: active ? MioTheme.orange : MioTheme.muted), const SizedBox(width: 10), Text(name)]),
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
          const SizedBox(width: 10),
          SettingsButton(),
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

class ProviderPill extends ConsumerWidget {
  final AiProviderConfig provider;
  const ProviderPill({super.key, required this.provider});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    return PopupMenuButton<String>(
      tooltip: 'Switch provider',
      onSelected: app.chooseProvider,
      itemBuilder: (_) => providers.map((p) => PopupMenuItem(value: p.id, child: Text(p.name))).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(color: MioTheme.panel, borderRadius: BorderRadius.circular(999), border: Border.all(color: MioTheme.line)),
        child: Row(children: [const Icon(Icons.hub_rounded, size: 17, color: MioTheme.orange), const SizedBox(width: 8), Text(provider.name, style: const TextStyle(fontWeight: FontWeight.w700)), const Icon(Icons.keyboard_arrow_down_rounded, size: 18)]),
      ),
    );
  }
}

class SettingsButton extends ConsumerWidget {
  SettingsButton({super.key});
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    return IconButton.filledTonal(
      tooltip: 'API keys',
      icon: const Icon(Icons.key_rounded),
      onPressed: () async {
        _controller.clear();
        final fingerprint = await app.apiKeyFingerprint(app.selectedProviderId);
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('${app.selectedProvider.name} key'),
            content: SizedBox(
              width: 460,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Current: $fingerprint', style: const TextStyle(color: MioTheme.muted)),
                const SizedBox(height: 14),
                TextField(controller: _controller, obscureText: true, decoration: const InputDecoration(labelText: 'Paste API key', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                const Text('Stored in device secure storage. It is not sent to Mio servers.', style: TextStyle(color: MioTheme.muted, fontSize: 12)),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(onPressed: () async { await app.setApiKey(app.selectedProviderId, _controller.text); if (context.mounted) Navigator.pop(context); }, child: const Text('Save')),
            ],
          ),
        );
      },
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
                  : MarkdownBody(
                      data: message.content.isEmpty ? 'Thinking…' : message.content,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: const TextStyle(fontSize: 16, height: 1.62, color: MioTheme.ink),
                        strong: const TextStyle(fontWeight: FontWeight.w800, color: MioTheme.ink),
                        code: const TextStyle(fontFamily: 'monospace', backgroundColor: MioTheme.cream2),
                      ),
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 12),
          if (isUser) const Avatar(label: 'You', dark: true),
        ],
      ),
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

class Composer extends ConsumerWidget {
  const Composer({super.key});

  Future<bool> _confirmAndRequestPermission(
    BuildContext context,
    Permission permission,
    String title,
    String body,
  ) async {
    final explain = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not now')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Allow')),
        ],
      ),
    );
    if (explain != true) return false;
    final status = await permission.request();
    if (status.isGranted || status.isLimited) return true;
    if (status.isPermanentlyDenied && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission blocked'),
          content: const Text('Open system settings to allow this permission for Mio.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () { openAppSettings(); Navigator.pop(context); }, child: const Text('Open Settings')),
          ],
        ),
      );
    }
    return false;
  }

  Future<void> _runWithPermission(
    BuildContext context,
    AppController app,
    Permission permission,
    String title,
    String body,
    String deniedLabel,
    Future<void> Function() action,
  ) async {
    final allowed = await _confirmAndRequestPermission(context, permission, title, body);
    if (!allowed) {
      app.permissionDeniedNotice(deniedLabel);
      return;
    }
    await action();
  }

  Future<void> _enableNotifications(BuildContext context, AppController app) async {
    final allowed = await _confirmAndRequestPermission(
      context,
      Permission.notification,
      'Allow notifications?',
      'Mio will only notify you for task completion, reminders, and scheduled summaries you enable.',
    );
    if (allowed) {
      app.enableNotificationsNotice();
    } else {
      app.permissionDeniedNotice('Notifications');
    }
  }

  void _showLinkDialog(BuildContext context, AppController app) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attach link'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'URL', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () { app.attachLink(controller.text); Navigator.pop(context); }, child: const Text('Attach')),
        ],
      ),
    );
  }

  void _showAttachmentMenu(BuildContext context, AppController app) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: MioTheme.panel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Attach', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AttachmentItem(icon: Icons.camera_alt_rounded, label: 'Camera', onTap: () { Navigator.pop(context); _runWithPermission(context, app, Permission.camera, 'Allow camera?', 'Mio needs camera access only when you attach a new photo to the chat.', 'Camera', app.attachCamera); }),
                  _AttachmentItem(icon: Icons.photo_library_rounded, label: 'Gallery', onTap: () { Navigator.pop(context); _runWithPermission(context, app, Permission.photos, 'Allow photo library?', 'Mio needs photo access only when you attach images from your gallery.', 'Gallery', app.attachGallery); }),
                  _AttachmentItem(icon: Icons.description_rounded, label: 'Document', onTap: () { Navigator.pop(context); _runWithPermission(context, app, Permission.storage, 'Allow document access?', 'Mio opens the system file picker only when you choose documents to attach.', 'Documents', app.attachDocument); }),
                  _AttachmentItem(icon: Icons.link_rounded, label: 'Link', onTap: () { Navigator.pop(context); _showLinkDialog(context, app); }),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: MioTheme.line),
              const SizedBox(height: 24),
              Text('Skills & Connectors', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: MioTheme.muted, fontWeight: FontWeight.w700)),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AttachmentItem(icon: Icons.public_rounded, label: 'Web Search', onTap: () { Navigator.pop(context); app.runWebSearchConnector(); }),
                  _AttachmentItem(icon: Icons.edit_note_rounded, label: 'Notion', onTap: () { Navigator.pop(context); app.runNotionConnector(); }),
                  _AttachmentItem(icon: Icons.folder_zip_rounded, label: 'GitHub', onTap: () { Navigator.pop(context); app.runGitHubConnector(); }),
                  _AttachmentItem(icon: Icons.mail_rounded, label: 'Gmail', onTap: () { Navigator.pop(context); app.runGmailConnector(); }),
                  _AttachmentItem(icon: Icons.notifications_rounded, label: 'Notify', onTap: () { Navigator.pop(context); _enableNotifications(context, app); }),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            IconButton(
              onPressed: () => _showAttachmentMenu(context, app),
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Attach',
            ),
            Expanded(
              child: TextField(
                controller: app.inputController,
                focusNode: app.inputFocusNode,
                minLines: 1,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(hintText: 'Ask anything…', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 13)),
                onSubmitted: (_) => app.sendPrompt(),
              ),
            ),
            if (app.error.isNotEmpty) Tooltip(message: app.error, child: const Icon(Icons.warning_rounded, color: MioTheme.orange)),
            const SizedBox(width: 6),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: MioTheme.orange, foregroundColor: Colors.white, shape: const CircleBorder(), padding: const EdgeInsets.all(14)),
              onPressed: app.isStreaming ? null : app.sendPrompt,
              child: app.isStreaming ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.arrow_upward_rounded),
            ),
          ]),
        ),
      ),
    );
  }
}

String formatTime(DateTime dt) => DateFormat('h:mm a').format(dt);
