import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/contact_rule.dart';
import '../../providers/contact_rule_provider.dart';
import '../../../caller_announcement/providers/settings_provider.dart';
import '../../../../core/constants/announcement_languages.dart';
import '../widgets/ai_text_generator_sheet.dart';
import '../../../../core/localization/app_localizations.dart';

class ContactCustomizeScreen extends ConsumerStatefulWidget {
  final ContactRule contact;

  const ContactCustomizeScreen({
    super.key,
    required this.contact,
  });

  @override
  ConsumerState<ContactCustomizeScreen> createState() => _ContactCustomizeScreenState();
}

class _ContactCustomizeScreenState extends ConsumerState<ContactCustomizeScreen> {
  late TextEditingController _textController;
  late bool _isEnabled;
  late bool _isCustomized;
  late String _language;
  late double _speechRate;
  late double _volume;
  late String _repeatMode;
  late bool _bluetoothOnly;
  late bool _isVip;
  late String _relationshipTag;

  bool _isPreviewPlaying = false;

  final List<Color> _avatarColors = const [
    Color(0xFF7C4DFF),
    Color(0xFF00897B),
    Color(0xFF1E88E5),
    Color(0xFFE65100),
    Color(0xFFD81B60),
    Color(0xFF5E35B1),
  ];

  @override
  void initState() {
    super.initState();
    _isCustomized = widget.contact.isCustomized;
    _textController = TextEditingController(text: widget.contact.customText);
    _isEnabled = widget.contact.isEnabled;
    _language = widget.contact.language;
    _speechRate = widget.contact.speechRate;
    _volume = widget.contact.volume;
    _repeatMode = widget.contact.repeatMode == 'twice' ? 'three_times' : widget.contact.repeatMode;
    _bluetoothOnly = widget.contact.bluetoothOnly;
    _isVip = widget.contact.isVip;
    _relationshipTag = widget.contact.relationshipTag;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _insertPlaceholder(String tag) {
    final text = _textController.text;
    final selection = _textController.selection;
    final newText = selection.isValid
        ? text.replaceRange(selection.start, selection.end, tag)
        : '$text $tag';
    _textController.text = newText;
    _textController.selection = TextSelection.collapsed(
      offset: (selection.isValid ? selection.start : text.length) + tag.length,
    );
    _isCustomized = true;
    setState(() {});
  }

  Future<void> _playPreview(String globalLang) async {
    final nativeBridge = ref.read(nativeBridgeProvider);
    if (_isPreviewPlaying) {
      await nativeBridge.stopAnnouncement();
      if (mounted) setState(() => _isPreviewPlaying = false);
      return;
    }

    setState(() => _isPreviewPlaying = true);
    final effectiveLang = _isCustomized ? _language : globalLang;
    final text = _isCustomized
        ? (_textController.text.trim().replaceAll('{name}', widget.contact.name).replaceAll('{number}', widget.contact.phoneNumber).isNotEmpty
            ? _textController.text.trim().replaceAll('{name}', widget.contact.name).replaceAll('{number}', widget.contact.phoneNumber)
            : AnnouncementLanguages.getContactAnnouncement(language: effectiveLang, name: widget.contact.name))
        : AnnouncementLanguages.getContactAnnouncement(language: effectiveLang, name: widget.contact.name);

    await nativeBridge.previewAnnouncement(
      text: text,
      language: effectiveLang,
      speechRate: _speechRate,
      volume: _volume,
      repeatMode: _repeatMode,
    );

    final repeatSeconds = switch (_repeatMode) {
      'once' || '1' => 4,
      'two_times' || '2' => 8,
      'three_times' || 'twice' || '3' => 14,
      _ => 14,
    };

    Future.delayed(Duration(seconds: repeatSeconds), () {
      if (mounted && _isPreviewPlaying) {
        setState(() => _isPreviewPlaying = false);
      }
    });
  }

  void _saveChanges() {
    final updatedRule = widget.contact.copyWith(
      isEnabled: _isEnabled,
      customText: _textController.text.trim().isNotEmpty ? _textController.text.trim() : '{name} is calling',
      language: _language,
      speechRate: _speechRate,
      volume: _volume,
      repeatMode: _repeatMode,
      bluetoothOnly: _bluetoothOnly,
      isVip: _isVip,
      relationshipTag: _relationshipTag,
      isCustomized: _isCustomized,
    );

    ref.read(contactRulesProvider.notifier).saveRule(updatedRule);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved settings for ${widget.contact.name}'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF0B57D0),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final avatarColor = _avatarColors[widget.contact.avatarColorIndex % _avatarColors.length];
    final globalSettings = ref.watch(settingsProvider).value;
    final globalLanguage = globalSettings?.language ?? 'en-US';
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Details'),
        actions: [
          IconButton(
            tooltip: strings.delete,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () {
              ref.read(contactRulesProvider.notifier).deleteRule(widget.contact.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          // 1. Google Profile Hero Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: avatarColor.withAlpha(35),
                      child: Text(
                        widget.contact.name.isNotEmpty ? widget.contact.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: avatarColor,
                        ),
                      ),
                    ),
                    if (_isVip)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star_rounded, size: 20, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.contact.name,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.contact.phoneNumber,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 16),

                // Action Pills (Google Quick Action Row)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeroAction(
                      icon: _isPreviewPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      label: _isPreviewPlaying ? strings.playingPreview : strings.previewAnnouncement,
                      onTap: () => _playPreview(globalLanguage),
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(width: 12),
                    _buildHeroAction(
                      icon: _isVip ? Icons.star_rounded : Icons.star_outline_rounded,
                      label: 'VIP',
                      isActive: _isVip,
                      activeColor: Colors.amber.shade800,
                      onTap: () => setState(() => _isVip = !_isVip),
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(width: 12),
                    _buildHeroAction(
                      icon: _isEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      label: _isEnabled ? 'Active' : 'Muted',
                      isActive: _isEnabled,
                      onTap: () => setState(() => _isEnabled = !_isEnabled),
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Announcement Message Section (Gemini / Assistant card)
          _buildPixelGroupContainer(
            colorScheme: colorScheme,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isCustomized ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isCustomized ? Icons.tune_rounded : Icons.language_rounded,
                          color: _isCustomized ? colorScheme.primary : colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '${strings.personalizeFor} ${widget.contact.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Text(
                        _isCustomized
                            ? 'Custom announcement and language override active'
                            : 'Using Home Screen Language (${AnnouncementLanguages.languageNames[globalLanguage] ?? globalLanguage})',
                        style: TextStyle(fontSize: 12, color: theme.hintColor),
                      ),
                      value: _isCustomized,
                      onChanged: (val) {
                        setState(() {
                          _isCustomized = val;
                          if (val && (_textController.text.trim().isEmpty || _textController.text.trim() == '{name} is calling')) {
                            _textController.text = AnnouncementLanguages.getContactAnnouncement(
                              language: _language,
                              name: '{name}',
                            );
                          }
                        });
                      },
                    ),
                    if (_isCustomized) ...[
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              strings.customAnnouncementText,
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.auto_awesome, size: 14),
                            label: Text(strings.aiSuggest, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: FilledButton.styleFrom(
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => AiTextGeneratorSheet(
                                  contactName: widget.contact.name,
                                  currentText: _textController.text,
                                  onSelect: (newText) {
                                    setState(() {
                                      _textController.text = newText;
                                      _isCustomized = true;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _textController,
                        maxLines: 2,
                        onChanged: (_) {
                          if (!_isCustomized) setState(() => _isCustomized = true);
                        },
                        decoration: InputDecoration(
                          hintText: '{name} is calling you',
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text('Insert: ', style: TextStyle(fontSize: 12, color: theme.hintColor)),
                          ActionChip(
                            label: const Text('{name}'),
                            shape: const StadiumBorder(),
                            onPressed: () => _insertPlaceholder('{name}'),
                          ),
                          const SizedBox(width: 8),
                          ActionChip(
                            label: const Text('{number}'),
                            shape: const StadiumBorder(),
                            onPressed: () => _insertPlaceholder('{number}'),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isCustomized = false;
                                _language = globalLanguage;
                                _textController.text = AnnouncementLanguages.getContactAnnouncement(
                                  language: globalLanguage,
                                  name: '{name}',
                                );
                              });
                            },
                            child: const Text('Reset to Default', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. Repeat Mode (Google Segmented Button)
          _buildPixelGroupContainer(
            colorScheme: colorScheme,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Repeat Mode', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'once', label: Text('1x')),
                        ButtonSegment(value: 'two_times', label: Text('2x')),
                        ButtonSegment(value: 'three_times', label: Text('3x')),
                        ButtonSegment(value: 'until_answered', label: Text('Repeat')),
                      ],
                      selected: {_repeatMode == 'twice' ? 'three_times' : _repeatMode},
                      onSelectionChanged: (newSelection) {
                        setState(() => _repeatMode = newSelection.first);
                      },
                      style: SegmentedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. Voice, Volume & Language (Pixel Settings Group)
          _buildPixelGroupContainer(
            colorScheme: colorScheme,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: const Icon(Icons.language_rounded),
                title: const Text('Spoken Language', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: !_isCustomized
                    ? Text('Following Global (${AnnouncementLanguages.languageNames[globalLanguage] ?? globalLanguage})',
                        style: TextStyle(fontSize: 12, color: theme.hintColor))
                    : null,
                trailing: DropdownButton<String>(
                  value: AnnouncementLanguages.languageNames.containsKey(_language) ? _language : globalLanguage,
                  underline: const SizedBox.shrink(),
                  borderRadius: BorderRadius.circular(18),
                  items: AnnouncementLanguages.languageNames.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _language = val;
                        _isCustomized = true;
                      });
                    }
                  },
                ),
              ),
              const Divider(height: 1, indent: 56),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Volume', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('${(_volume * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                      ],
                    ),
                    Slider(
                      value: _volume,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      onChanged: (val) => setState(() => _volume = val),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Speech Speed', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('${_speechRate.toStringAsFixed(1)}x', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                      ],
                    ),
                    Slider(
                      value: _speechRate,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      onChanged: (val) => setState(() => _speechRate = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 5. Conditions (Bluetooth / VIP)
          _buildPixelGroupContainer(
            colorScheme: colorScheme,
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                secondary: const Icon(Icons.headphones_rounded),
                title: Text(strings.bluetoothOnly, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(strings.bluetoothOnlyDesc),
                value: _bluetoothOnly,
                onChanged: (val) => setState(() => _bluetoothOnly = val),
              ),
              const Divider(height: 1, indent: 56),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                secondary: const Icon(Icons.star_rounded, color: Colors.amber),
                title: const Text('VIP Priority Caller', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Always announce aloud even if phone is in Silent or DND mode'),
                value: _isVip,
                onChanged: (val) => setState(() => _isVip = val),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Google Pill Save Button
          FilledButton.icon(
            onPressed: _saveChanges,
            icon: const Icon(Icons.check_rounded),
            label: Text(strings.saveChanges, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeroAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color? activeColor,
    required ColorScheme colorScheme,
  }) {
    final effectiveColor = isActive ? (activeColor ?? colorScheme.primary) : colorScheme.onSurfaceVariant;
    final bgColor = isActive ? effectiveColor.withAlpha(25) : colorScheme.surfaceContainerLowest;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? effectiveColor : colorScheme.outlineVariant.withAlpha(80),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: effectiveColor),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: effectiveColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildPixelGroupContainer({required ColorScheme colorScheme, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
