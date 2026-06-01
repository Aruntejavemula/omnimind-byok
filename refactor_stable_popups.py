from pathlib import Path
p = Path('/home/ubuntu/omnimind-byok/lib/main.dart')
s = p.read_text()
provider_start = s.index('class ProviderPill extends ConsumerStatefulWidget')
provider_end = s.index('\nclass SettingsButton extends ConsumerWidget', provider_start)
new_provider = r'''class ProviderPill extends ConsumerStatefulWidget {
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
    final left = (topLeft.dx + dx).clamp(8.0, max(8.0, overlay.size.width - width - 8));
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

'''
s = s[:provider_start] + new_provider + s[provider_end+1:]
composer_start = s.index('class Composer extends ConsumerStatefulWidget')
composer_end = s.index('\nString formatTime', composer_start)
new_composer = r'''class Composer extends ConsumerStatefulWidget {
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
    final left = topLeft.dx.clamp(8.0, max(8.0, overlay.size.width - menuWidth - 8));
    final top = max(8.0, topLeft.dy - 350);
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
        _showComingSoon('Projects');
        break;
      case 'skills':
        _showComingSoon('Skills');
        break;
      case 'connectors':
        app.runNotionConnector();
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
        _showComingSoon('Use style');
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
            FilledButton(style: FilledButton.styleFrom(backgroundColor: MioTheme.orange, foregroundColor: Colors.white, shape: const CircleBorder(), padding: const EdgeInsets.all(14)), onPressed: app.isStreaming ? null : app.sendPrompt, child: app.isStreaming ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.arrow_upward_rounded)),
          ]),
        ),
      ),
    );
  }
}

'''
s = s[:composer_start] + new_composer + s[composer_end+1:]
p.write_text(s)
