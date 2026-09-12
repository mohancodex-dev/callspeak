import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/contact_rule.dart';
import '../../providers/contact_rule_provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/app_strings.dart';

class DefaultRulesScreen extends ConsumerWidget {
  const DefaultRulesScreen({super.key});

  String _getCategoryTitle(String id, String defaultTitle, AppStrings strings) {
    return switch (id) {
      'saved_contacts' => strings.savedContactsTitle,
      'unknown_numbers' => strings.unknownNumbersTitle,
      'vip_contacts' => strings.vipContactsTitle,
      _ => defaultTitle,
    };
  }

  String _getCategorySubtitle(String id, String defaultSubtitle, AppStrings strings) {
    return switch (id) {
      'saved_contacts' => strings.savedContactsSubtitle,
      'unknown_numbers' => strings.unknownNumbersSubtitle,
      'vip_contacts' => strings.vipContactsSubtitle,
      _ => defaultSubtitle,
    };
  }

  void _editCategoryRule(BuildContext context, WidgetRef ref, CategoryRule rule, Function(CategoryRule) onSave, AppStrings strings) {
    final templateCtrl = TextEditingController(text: rule.announcementTemplate);
    String repeatMode = (rule.repeatMode == 'twice') ? 'three_times' : rule.repeatMode;
    bool bluetoothOnly = rule.bluetoothOnly;
    String silentBehavior = rule.silentModeBehavior;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final theme = Theme.of(ctx);
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
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Text(
                      '${strings.editCategoryRule}: ${_getCategoryTitle(rule.key, rule.title, strings)}',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(_getCategorySubtitle(rule.key, rule.subtitle, strings), style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                    const SizedBox(height: 16),

                    // Template Text
                    Text(strings.announcementTemplate, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: templateCtrl,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withAlpha(80),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Repeat Mode
                    Text(strings.repeatMode, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text('${strings.repeatLabel3} (Default)'),
                          selected: repeatMode == 'three_times' || repeatMode == 'twice',
                          onSelected: (val) => setSheetState(() => repeatMode = 'three_times'),
                        ),
                        ChoiceChip(
                          label: Text(strings.repeatUntilAnswered),
                          selected: repeatMode == 'until_answered',
                          onSelected: (val) => setSheetState(() => repeatMode = 'until_answered'),
                        ),
                        ChoiceChip(
                          label: Text(strings.repeatLabel2),
                          selected: repeatMode == 'two_times',
                          onSelected: (val) => setSheetState(() => repeatMode = 'two_times'),
                        ),
                        ChoiceChip(
                          label: Text(strings.repeatLabel1),
                          selected: repeatMode == 'once',
                          onSelected: (val) => setSheetState(() => repeatMode = 'once'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Silent Mode Behavior
                    Text(strings.silentModeBehavior, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: Center(child: Text(strings.respectSilent)),
                            selected: silentBehavior == 'respect_silent',
                            onSelected: (val) => setSheetState(() => silentBehavior = 'respect_silent'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: Center(child: Text(strings.bypassSilent)),
                            selected: silentBehavior == 'bypass_silent',
                            onSelected: (val) => setSheetState(() => silentBehavior = 'bypass_silent'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      silentBehavior == 'respect_silent'
                          ? 'Muted when phone is in silent, vibrate, or DND mode.'
                          : 'Forces announcement even when phone is on Silent or DND.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                    const SizedBox(height: 16),

                    // Bluetooth Only
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(strings.bluetoothOnly),
                      subtitle: Text(strings.bluetoothOnlyDesc),
                      value: bluetoothOnly,
                      onChanged: (val) => setSheetState(() => bluetoothOnly = val),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final updated = rule.copyWith(
                            announcementTemplate: templateCtrl.text.trim().isNotEmpty
                                ? templateCtrl.text.trim()
                                : rule.announcementTemplate,
                            repeatMode: repeatMode,
                            bluetoothOnly: bluetoothOnly,
                            silentModeBehavior: silentBehavior,
                          );
                          onSave(updated);
                          Navigator.pop(sheetCtx);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(strings.saveCategoryRule, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final configAsync = ref.watch(categoryRulesProvider);
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.categoryRulesTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (config) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Intro Card
              Card(
                elevation: 0,
                color: colorScheme.primaryContainer.withAlpha(90),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.rule_folder_rounded, color: colorScheme.primary, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.categoryRulesTitle,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              strings.categoryRulesSubtitle,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 1. Saved Contacts Card
              _buildCategoryCard(
                context: context,
                ref: ref,
                rule: config.savedContacts,
                icon: Icons.contacts_rounded,
                iconColor: Colors.blueAccent,
                strings: strings,
                onToggle: (val) {
                  ref.read(categoryRulesProvider.notifier).updateConfig(
                        config.copyWith(savedContacts: config.savedContacts.copyWith(isEnabled: val)),
                      );
                },
                onEdit: () {
                  _editCategoryRule(context, ref, config.savedContacts, (updated) {
                    ref.read(categoryRulesProvider.notifier).updateConfig(config.copyWith(savedContacts: updated));
                  }, strings);
                },
              ),
              const SizedBox(height: 12),

              // 2. Unknown Numbers Card
              _buildCategoryCard(
                context: context,
                ref: ref,
                rule: config.unknownNumbers,
                icon: Icons.help_outline_rounded,
                iconColor: Colors.teal,
                strings: strings,
                onToggle: (val) {
                  ref.read(categoryRulesProvider.notifier).updateConfig(
                        config.copyWith(unknownNumbers: config.unknownNumbers.copyWith(isEnabled: val)),
                      );
                },
                onEdit: () {
                  _editCategoryRule(context, ref, config.unknownNumbers, (updated) {
                    ref.read(categoryRulesProvider.notifier).updateConfig(config.copyWith(unknownNumbers: updated));
                  }, strings);
                },
              ),
              const SizedBox(height: 12),

              // 3. Spam Callers Card
              _buildCategoryCard(
                context: context,
                ref: ref,
                rule: config.spamCallers,
                icon: Icons.warning_amber_rounded,
                iconColor: Colors.deepOrange,
                strings: strings,
                onToggle: (val) {
                  ref.read(categoryRulesProvider.notifier).updateConfig(
                        config.copyWith(spamCallers: config.spamCallers.copyWith(isEnabled: val)),
                      );
                },
                onEdit: () {
                  _editCategoryRule(context, ref, config.spamCallers, (updated) {
                    ref.read(categoryRulesProvider.notifier).updateConfig(config.copyWith(spamCallers: updated));
                  }, strings);
                },
              ),
              const SizedBox(height: 12),

              // 4. VIP Contacts Card
              _buildCategoryCard(
                context: context,
                ref: ref,
                rule: config.vipContacts,
                icon: Icons.star_rounded,
                iconColor: Colors.amber.shade700,
                strings: strings,
                onToggle: (val) {
                  ref.read(categoryRulesProvider.notifier).updateConfig(
                        config.copyWith(vipContacts: config.vipContacts.copyWith(isEnabled: val)),
                      );
                },
                onEdit: () {
                  _editCategoryRule(context, ref, config.vipContacts, (updated) {
                    ref.read(categoryRulesProvider.notifier).updateConfig(config.copyWith(vipContacts: updated));
                  }, strings);
                },
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required WidgetRef ref,
    required CategoryRule rule,
    required IconData icon,
    required Color iconColor,
    required Function(bool) onToggle,
    required VoidCallback onEdit,
    required AppStrings strings,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withAlpha(40),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getCategoryTitle(rule.key, rule.title, strings),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        _getCategorySubtitle(rule.key, rule.subtitle, strings),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: rule.isEnabled,
                  onChanged: onToggle,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${strings.announcementTemplate}:',
                        style: TextStyle(fontSize: 11, color: theme.hintColor, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rule.announcementTemplate,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: rule.isEnabled ? colorScheme.primary : theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildBadge(theme, colorScheme, '${strings.repeatMode}: ${rule.repeatMode == 'twice' || rule.repeatMode == 'three_times' ? strings.repeatLabel3 : (rule.repeatMode == 'until_answered' ? strings.repeatUntilAnswered : (rule.repeatMode == 'two_times' ? strings.repeatLabel2 : strings.repeatLabel1))}'),
                          if (rule.silentModeBehavior == 'bypass_silent')
                            _buildBadge(theme, colorScheme, strings.bypassSilent, color: Colors.amber.shade800),
                          if (rule.bluetoothOnly)
                            _buildBadge(theme, colorScheme, strings.bluetoothOnly, color: Colors.blue),
                        ],
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: onEdit,
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(10),
                  ),
                  child: const Icon(Icons.edit_outlined, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(ThemeData theme, ColorScheme colorScheme, String text, {Color? color}) {
    final effectiveColor = color ?? colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveColor.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: effectiveColor),
      ),
    );
  }
}
