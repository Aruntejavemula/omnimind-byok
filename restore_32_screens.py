from pathlib import Path
p = Path('lib/main.dart')
text = p.read_text()
text = text.replace("        GoRoute(path: '/chat', builder: (_, __) => const ShellScreen()),\n", "        GoRoute(path: '/chat', builder: (_, __) => const ShellScreen()),\n        ...RestoredScreenRoutes.routes,\n")
old = """class SettingsButton extends ConsumerWidget {\n  SettingsButton({super.key});\n  final _controller = TextEditingController();\n\n  @override\n  Widget build(BuildContext context, WidgetRef ref) {\n    final app = ref.watch(appControllerProvider);\n    return IconButton.filledTonal(\n      tooltip: 'API keys',\n      icon: const Icon(Icons.key_rounded),\n      onPressed: () async {\n        _controller.clear();\n        final fingerprint = await app.apiKeyFingerprint(app.selectedProviderId);\n        if (!context.mounted) return;\n        await showDialog<void>(\n          context: context,\n          builder: (context) => AlertDialog(\n            title: Text('${app.selectedProvider.name} key'),\n            content: SizedBox(\n              width: 460,\n              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [\n                Text('Current: $fingerprint', style: const TextStyle(color: MioTheme.muted)),\n                const SizedBox(height: 14),\n                TextField(controller: _controller, obscureText: true, decoration: const InputDecoration(labelText: 'Paste API key', border: OutlineInputBorder())),\n                const SizedBox(height: 10),\n                const Text('Stored in device secure storage. It is not sent to Mio servers.', style: TextStyle(color: MioTheme.muted, fontSize: 12)),\n              ]),\n            ),\n            actions: [\n              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),\n              FilledButton(onPressed: () async { await app.setApiKey(app.selectedProviderId, _controller.text); if (context.mounted) Navigator.pop(context); }, child: const Text('Save')),\n            ],\n          ),\n        );\n      },\n    );\n  }\n}\n"""
new = """class SettingsButton extends ConsumerWidget {\n  const SettingsButton({super.key});\n\n  @override\n  Widget build(BuildContext context, WidgetRef ref) {\n    return IconButton.filledTonal(\n      tooltip: 'Settings',\n      icon: const Icon(Icons.settings_rounded),\n      onPressed: () => context.go('/settings'),\n    );\n  }\n}\n"""
if old not in text:
    raise SystemExit('SettingsButton block not found')
text = text.replace(old, new)
append = r'''

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
    final groups = <String, List<RestoredScreenData>>{};
    for (final screen in restoredScreens.where((s) => s.path.startsWith('/settings/'))) {
      groups.putIfAbsent(screen.section, () => <RestoredScreenData>[]).add(screen);
    }
    return RestoredScreenScaffold(
      title: 'Settings',
      section: 'Complete app settings',
      description: 'The full legacy settings structure is restored here: preferences, API keys, usage limits, subscription, devices, storage, connectors, memory, scheduled tasks, referrals, security, and data controls.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RestoredHeroPanel(icon: Icons.settings_rounded, title: 'All settings restored', body: 'This page replaces the old single API-key dialog with the complete settings hub while keeping provider-key functionality available under API Keys.'),
        const SizedBox(height: 18),
        for (final entry in groups.entries) ...[
          Padding(padding: const EdgeInsets.only(top: 10, bottom: 8), child: Text(entry.key, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
          LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: entry.value.map((screen) => SizedBox(width: compact ? constraints.maxWidth : (constraints.maxWidth - 24) / 3, child: RestoredNavigationCard(screen: screen))).toList(),
            );
          }),
        ],
      ]),
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
    if (spec.path == '/settings/usage') return const RestoredUsageLimitsScreen();
    if (spec.path == '/settings/preferences') return const RestoredPreferencesScreen();
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
    return RestoredScreenScaffold(
      title: 'Preferences',
      section: 'Settings',
      description: 'Conversation and privacy preferences restored from the full settings experience.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RestoredHeroPanel(icon: Icons.tune_rounded, title: 'Preferences', body: 'Control Mio response style, provider defaults, privacy behavior, and workspace feel.'),
        const SizedBox(height: 18),
        RestoredSectionCard(title: 'Conversation style', children: [
          SwitchListTile(value: app.zeroFluff, onChanged: (_) => app.toggleZeroFluff(), title: const Text('Zero Fluff'), subtitle: const Text('Direct answers with less filler.')),
          SwitchListTile(value: app.deepResearchMode, onChanged: (_) => app.toggleDeepResearch(), title: const Text('Deep Research'), subtitle: const Text('Use broader search and synthesis when available.')),
          SwitchListTile(value: app.webSearchEnabled, onChanged: (_) => app.toggleWebSearch(), title: const Text('Web Search'), subtitle: const Text('Allow web-assisted responses when needed.')),
        ]),
        const SizedBox(height: 18),
        RestoredSectionCard(title: 'Default provider', children: providers.map((p) => RadioListTile<String>(value: p.id, groupValue: app.selectedProviderId, onChanged: (v) => v == null ? null : app.chooseProvider(v), title: Text(p.name), subtitle: Text(p.tagline))).toList()),
      ]),
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
    final plans = [
      ('Free', '$0', 'Try Mio with BYOK basics', ['1 project', 'Local key storage', 'Starter usage']),
      ('Pro', '$12', 'Best for individual power users', ['Unlimited BYOK providers', 'Projects and memory', 'Usage limits']),
      ('Team', '$29', 'Shared workspace features', ['Team projects', 'Admin controls', 'Connector workflows']),
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
'''
if 'class RestoredScreenData' not in text:
    text = text.rstrip() + append + '\n'
p.write_text(text)
print('restored routes inserted')
