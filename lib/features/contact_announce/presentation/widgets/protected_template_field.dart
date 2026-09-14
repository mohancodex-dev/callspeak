import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Formatter that ensures a mandatory placeholder (e.g. `{name}` or `{number}`)
/// cannot be deleted or wiped from a TextField.
class MandatoryPlaceholderFormatter extends TextInputFormatter {
  final String placeholder;

  const MandatoryPlaceholderFormatter(this.placeholder);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the old value had the placeholder and the new value doesn't, reject the edit.
    if (oldValue.text.contains(placeholder) && !newValue.text.contains(placeholder)) {
      return oldValue;
    }
    return newValue;
  }
}

/// A specialized custom announcement template editor that protects `{name}`
/// and provides intelligent suggestions for writing text before (aage) or after (piche) `{name}`.
class ProtectedTemplateField extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final String? label;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onReset;

  const ProtectedTemplateField({
    super.key,
    required this.controller,
    this.placeholder = '{name}',
    this.label,
    this.onChanged,
    this.onReset,
  });

  @override
  State<ProtectedTemplateField> createState() => _ProtectedTemplateFieldState();
}

class _ProtectedTemplateFieldState extends State<ProtectedTemplateField> {
  int _selectedTab = 0; // 0: Aage (Before), 1: Piche (After), 2: Templates

  @override
  void initState() {
    super.initState();
    _ensurePlaceholderPresent();
    widget.controller.addListener(_onControllerTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerTextChange);
    super.dispose();
  }

  void _ensurePlaceholderPresent() {
    if (!widget.controller.text.contains(widget.placeholder)) {
      final current = widget.controller.text.trim();
      widget.controller.text = current.isEmpty
          ? '${widget.placeholder} is calling'
          : '$current ${widget.placeholder}';
    }
  }

  void _onControllerTextChange() {
    if (!widget.controller.text.contains(widget.placeholder)) {
      final current = widget.controller.text.trim();
      widget.controller.text = current.isEmpty
          ? widget.placeholder
          : '$current ${widget.placeholder}';
      widget.controller.selection = TextSelection.collapsed(
        offset: widget.controller.text.length,
      );
    }
    widget.onChanged?.call(widget.controller.text);
  }

  void _insertPrefix(String prefix) {
    final text = widget.controller.text;
    final p = widget.placeholder;
    final idx = text.indexOf(p);
    final cleanPrefix = prefix.trim();

    if (idx != -1) {
      final after = text.substring(idx); // includes '{name}...'
      final newText = '$cleanPrefix $after'.trim();
      widget.controller.text = newText;
      widget.controller.selection = TextSelection.collapsed(
        offset: cleanPrefix.length + 1,
      );
    } else {
      widget.controller.text = '$cleanPrefix $p'.trim();
    }
    setState(() {});
  }

  void _insertSuffix(String suffix) {
    final text = widget.controller.text;
    final p = widget.placeholder;
    final idx = text.indexOf(p);
    final cleanSuffix = suffix.trim();

    if (idx != -1) {
      final before = text.substring(0, idx + p.length); // '...{name}'
      final newText = '$before $cleanSuffix'.trim();
      widget.controller.text = newText;
      widget.controller.selection = TextSelection.collapsed(
        offset: newText.length,
      );
    } else {
      widget.controller.text = '$p $cleanSuffix'.trim();
    }
    setState(() {});
  }

  void _applyTemplate(String template) {
    widget.controller.text = template;
    widget.controller.selection = TextSelection.collapsed(
      offset: template.length,
    );
    setState(() {});
  }

  List<String> get _prefixSuggestions {
    if (widget.placeholder == '{number}') {
      return [
        'Call from',
        'Incoming call from',
        'Alert! Call from',
        'अज्ञात कॉल:',
      ];
    }
    return [
      'Call from',
      'Incoming call from',
      'Important call from',
      'Attention!',
      'Hey,',
      'Urgent call from',
      'ज़रूरी कॉल:',
      'फोन आया है:',
    ];
  }

  List<String> get _suffixSuggestions {
    if (widget.placeholder == '{number}') {
      return [
        'is calling',
        'unknown caller',
        'calling on phone',
        'का फोन आ रहा है',
      ];
    }
    return [
      'is calling',
      'is calling you',
      'is on the line',
      'calling, please answer',
      'ne phon aayrayo',
      'ka phone aa raha hai',
      'ka call hai',
      'urgent call, pick up',
    ];
  }

  List<String> get _fullTemplates {
    if (widget.placeholder == '{number}') {
      return [
        'Call from unknown number: {number}',
        '{number} is calling',
        'Incoming call: {number}',
        '{number} से फोन आ रहा है',
      ];
    }
    return [
      '{name} is calling',
      'Incoming call from {name}',
      'Important! VIP call from {name}',
      '{name} ne phon aayrayo',
      '{name} ka phone aa raha hai',
      'Hey, {name} is calling you',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final p = widget.placeholder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
        ],

        // Protected TextField
        TextField(
          controller: widget.controller,
          maxLines: 2,
          inputFormatters: [
            MandatoryPlaceholderFormatter(p),
          ],
          decoration: InputDecoration(
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withAlpha(90),
            hintText: '$p is calling you',
            prefixIcon: const Icon(Icons.record_voice_over_outlined),
            suffixIcon: Tooltip(
              message: '$p is locked and cannot be deleted.',
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withAlpha(150),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, size: 14, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      p,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Protection Info Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer.withAlpha(70),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.secondary.withAlpha(50)),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, size: 15, color: colorScheme.secondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$p cannot be removed. Add custom words before or after $p.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              if (widget.onReset != null)
                InkWell(
                  onTap: widget.onReset,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Suggestion Selector Tabs (Aage / Piche / Templates)
        Row(
          children: [
            _buildTabButton(
              index: 0,
              icon: Icons.arrow_back_rounded,
              label: 'Aage ($p से पहले)',
              activeColor: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            _buildTabButton(
              index: 1,
              icon: Icons.arrow_forward_rounded,
              label: 'Piche ($p के बाद)',
              activeColor: colorScheme.tertiary,
            ),
            const SizedBox(width: 6),
            _buildTabButton(
              index: 2,
              icon: Icons.auto_awesome_rounded,
              label: 'Templates',
              activeColor: Colors.amber.shade800,
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Suggestion Chips Content
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _buildSelectedSuggestions(colorScheme),
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
    required Color activeColor,
  }) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withAlpha(35) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? activeColor : Colors.grey.withAlpha(50),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: isSelected ? activeColor : Colors.grey),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? activeColor : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedSuggestions(ColorScheme colorScheme) {
    if (_selectedTab == 0) {
      // Prefix Suggestions (Aage)
      return Column(
        key: const ValueKey('prefix_suggestions'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _prefixSuggestions.map((prefix) {
              return ActionChip(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                avatar: const Icon(Icons.add_rounded, size: 14),
                label: Text('$prefix ${widget.placeholder}'),
                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: colorScheme.primaryContainer.withAlpha(70),
                onPressed: () => _insertPrefix(prefix),
              );
            }).toList(),
          ),
        ],
      );
    } else if (_selectedTab == 1) {
      // Suffix Suggestions (Piche)
      return Column(
        key: const ValueKey('suffix_suggestions'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _suffixSuggestions.map((suffix) {
              return ActionChip(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                avatar: const Icon(Icons.add_rounded, size: 14),
                label: Text('${widget.placeholder} $suffix'),
                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: colorScheme.tertiaryContainer.withAlpha(70),
                onPressed: () => _insertSuffix(suffix),
              );
            }).toList(),
          ),
        ],
      );
    } else {
      // Full Templates
      return Column(
        key: const ValueKey('full_templates'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _fullTemplates.map((template) {
              return ActionChip(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                avatar: const Icon(Icons.check_rounded, size: 14),
                label: Text(template),
                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: Colors.amber.withAlpha(35),
                onPressed: () => _applyTemplate(template),
              );
            }).toList(),
          ),
        ],
      );
    }
  }
}
