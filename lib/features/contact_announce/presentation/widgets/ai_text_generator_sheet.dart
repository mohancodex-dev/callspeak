import 'package:flutter/material.dart';

class AiTextGeneratorSheet extends StatefulWidget {
  final String contactName;
  final String currentText;
  final Function(String selectedText) onSelect;

  const AiTextGeneratorSheet({
    super.key,
    required this.contactName,
    required this.currentText,
    required this.onSelect,
  });

  @override
  State<AiTextGeneratorSheet> createState() => _AiTextGeneratorSheetState();
}

class _AiTextGeneratorSheetState extends State<AiTextGeneratorSheet> {
  String _selectedRelationship = 'Family';
  String _selectedTone = 'Friendly';
  bool _isGenerating = false;
  List<String> _suggestions = [];

  final List<String> _relationships = [
    'Family',
    'Work / Office',
    'Best Friend',
    'Doctor / Medical',
    'Important Client',
    'General',
  ];

  final List<String> _tones = [
    'Friendly',
    'Professional',
    'Urgent',
    'Fun & Quirky',
    'Minimalist',
  ];

  @override
  void initState() {
    super.initState();
    _generateSuggestions();
  }

  void _generateSuggestions() {
    setState(() {
      _isGenerating = true;
    });

    final name = widget.contactName.isEmpty ? '{name}' : widget.contactName;

    // Smart generator templates based on relationship & tone
    List<String> templates = [];

    if (_selectedRelationship == 'Family') {
      if (_selectedTone == 'Friendly') {
        templates = [
          '$name is calling you with love, please pick up!',
          'Incoming family call from $name.',
          'Hey! $name is on the line, don’t miss it.',
        ];
      } else if (_selectedTone == 'Urgent') {
        templates = [
          'Attention! Urgent family call from $name. Please answer now!',
          'Priority family call: $name is waiting on the line.',
          'Important call from $name, answer immediately.',
        ];
      } else if (_selectedTone == 'Fun & Quirky') {
        templates = [
          'Ring ring! Your favorite family member $name is buzzing you!',
          'Look who decided to call, it’s $name! Pick up quick!',
          '$name wants some gossip! Tap answer now.',
        ];
      } else {
        templates = [
          'Incoming call from $name.',
          'Family call: $name.',
          '$name calling.',
        ];
      }
    } else if (_selectedRelationship == 'Work / Office') {
      if (_selectedTone == 'Professional') {
        templates = [
          'Incoming business call from $name.',
          'Work contact $name is requesting your attention.',
          'Official call from $name on line one.',
        ];
      } else if (_selectedTone == 'Urgent') {
        templates = [
          'Priority business call from $name. Action required.',
          'Urgent work alert: $name is calling you.',
          'High priority call from office contact $name.',
        ];
      } else {
        templates = [
          '$name from work is calling you.',
          'Office call: $name.',
          '$name calling.',
        ];
      }
    } else if (_selectedRelationship == 'Doctor / Medical') {
      templates = [
        'Urgent medical notification: Doctor $name is calling you.',
        'Healthcare appointment call from $name.',
        'Important medical update from $name. Please answer.',
      ];
    } else if (_selectedRelationship == 'Best Friend') {
      if (_selectedTone == 'Fun & Quirky') {
        templates = [
          'Yo! Bestie $name is blowing up your phone!',
          'Warning! $name is calling and won’t stop talking!',
          'Pick up, $name has hot tea to spill!',
        ];
      } else {
        templates = [
          'Hey, your friend $name is calling!',
          'Incoming call from buddy $name.',
          '$name wants to talk with you.',
        ];
      }
    } else {
      // General
      if (_selectedTone == 'Professional') {
        templates = [
          'Incoming phone call from $name.',
          'Please attend incoming call from $name.',
          'Call received from $name.',
        ];
      } else if (_selectedTone == 'Urgent') {
        templates = [
          'Important alert: $name is calling you now!',
          'Priority call from $name. Please answer.',
          'Urgent: $name on the line.',
        ];
      } else if (_selectedTone == 'Minimalist') {
        templates = [
          '$name calling.',
          'Call from $name.',
          '$name.',
        ];
      } else {
        templates = [
          'Incoming call from $name.',
          '$name is calling you.',
          'Hello, $name is on the phone.',
        ];
      }
    }

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _suggestions = templates;
          _isGenerating = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor.withAlpha(120),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome, color: colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Announcement Assistant',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Tailor voice announcement for ${widget.contactName}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Relationship Category Chips
          Text('Relationship', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _relationships.map((rel) {
                final isSelected = _selectedRelationship == rel;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(rel),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedRelationship = rel);
                        _generateSuggestions();
                      }
                    },
                    selectedColor: colorScheme.primaryContainer,
                    checkmarkColor: colorScheme.primary,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Tone Chips
          Text('Announcement Tone', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _tones.map((tone) {
                final isSelected = _selectedTone == tone;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(tone),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedTone = tone);
                        _generateSuggestions();
                      }
                    },
                    selectedColor: colorScheme.secondaryContainer,
                    checkmarkColor: colorScheme.secondary,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Generated Suggestions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Suggestions',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (_isGenerating)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),

          ..._suggestions.map((text) {
            final isCurrent = widget.currentText == text;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isCurrent ? colorScheme.primaryContainer.withAlpha(90) : colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isCurrent ? colorScheme.primary : colorScheme.outlineVariant.withAlpha(50),
                  width: isCurrent ? 1.5 : 1,
                ),
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: Icon(
                  isCurrent ? Icons.check_circle_rounded : Icons.auto_awesome,
                  color: isCurrent ? colorScheme.primary : colorScheme.primary.withAlpha(160),
                  size: 20,
                ),
                title: Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                trailing: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  ),
                  onPressed: () {
                    widget.onSelect(text);
                    Navigator.pop(context);
                  },
                  child: const Text('Use', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          }),

          const SizedBox(height: 12),
          Center(
            child: Text(
              'Tip: You can also use {name} and {number} placeholders manually.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}
