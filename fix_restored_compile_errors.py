from pathlib import Path
p = Path('lib/main.dart')
s = p.read_text()

# 1) Dart requires escaping literal dollar signs inside string literals.
s = s.replace("('Free', '$0', 'Try Mio with BYOK basics', ['1 project', 'Local key storage', 'Starter usage']),", "('Free', r'$0', 'Try Mio with BYOK basics', ['1 project', 'Local key storage', 'Starter usage']),")
s = s.replace("('Pro', '$12', 'Best for individual power users', ['Unlimited BYOK providers', 'Projects and memory', 'Usage limits']),", "('Pro', r'$12', 'Best for individual power users', ['Unlimited BYOK providers', 'Projects and memory', 'Usage limits']),")
s = s.replace("('Team', '$29', 'Shared workspace features', ['Team projects', 'Admin controls', 'Connector workflows']),", "('Team', r'$29', 'Shared workspace features', ['Team projects', 'Admin controls', 'Connector workflows']),")

# 2) clamp() can infer num; force double for RelativeRect arguments.
s = s.replace("final left = (topLeft.dx + dx).clamp(8.0, max(8.0, overlay.size.width - width - 8));\n    final top = topLeft.dy + button.size.height + dy;\n    return RelativeRect.fromLTRB(left, top, overlay.size.width - left - width, 0);",
              "final left = (topLeft.dx + dx).clamp(8.0, max(8.0, overlay.size.width - width - 8)).toDouble();\n    final top = topLeft.dy + button.size.height + dy;\n    return RelativeRect.fromLTRB(left, top, overlay.size.width - left - width, 0);")
s = s.replace("final left = topLeft.dx.clamp(8.0, max(8.0, overlay.size.width - menuWidth - 8));\n    final top = max(8.0, topLeft.dy - 350);\n    return RelativeRect.fromLTRB(left, top, overlay.size.width - left - menuWidth, 0);",
              "final left = topLeft.dx.clamp(8.0, max(8.0, overlay.size.width - menuWidth - 8)).toDouble();\n    final top = max(8.0, topLeft.dy - 350).toDouble();\n    return RelativeRect.fromLTRB(left, top, overlay.size.width - left - menuWidth, 0);")

# 3) Add compatibility metadata getters for restored screens without changing the provider constructor.
marker = "const providers = <AiProviderConfig>[\n"
if "extension AiProviderConfigUiMetadata on AiProviderConfig" not in s:
    insert = r'''
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

'''
    s = s.replace(marker, insert + marker)

# 4) Add web-search preference support used by restored preference screen.
s = s.replace("bool deepResearchMode = false;\n  String error = '';", "bool deepResearchMode = false;\n  bool webSearchEnabled = false;\n  String error = '';")
s = s.replace("zeroFluff = prefs.getBool('zeroFluff') ?? true;\n    activeProject", "zeroFluff = prefs.getBool('zeroFluff') ?? true;\n    webSearchEnabled = prefs.getBool('webSearchEnabled') ?? false;\n    activeProject")
s = s.replace("await prefs.setBool('zeroFluff', zeroFluff);\n    await prefs.setString('activeProject'", "await prefs.setBool('zeroFluff', zeroFluff);\n    await prefs.setBool('webSearchEnabled', webSearchEnabled);\n    await prefs.setString('activeProject'")
if "void toggleWebSearch()" not in s:
    s = s.replace("  void toggleZeroFluff() {\n    zeroFluff = !zeroFluff;\n    saveState();\n    notifyListeners();\n  }\n",
                  "  void toggleZeroFluff() {\n    zeroFluff = !zeroFluff;\n    saveState();\n    notifyListeners();\n  }\n\n  void toggleWebSearch() {\n    webSearchEnabled = !webSearchEnabled;\n    saveState();\n    notifyListeners();\n  }\n")

p.write_text(s)
print('patched compile errors')
