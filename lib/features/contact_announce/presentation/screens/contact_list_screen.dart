import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/contact_rule.dart';
import '../../providers/contact_rule_provider.dart';
import 'contact_customize_screen.dart';
import '../../../caller_announcement/providers/permission_provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/app_strings.dart';

class ContactListScreen extends ConsumerStatefulWidget {
  const ContactListScreen({super.key});

  @override
  ConsumerState<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends ConsumerState<ContactListScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Curated Google Material You pastel avatar palette
  final List<Color> _avatarColors = const [
    Color(0xFF7C4DFF), // Indigo
    Color(0xFF00897B), // Teal
    Color(0xFF1E88E5), // Blue
    Color(0xFFE65100), // Orange
    Color(0xFFD81B60), // Pink
    Color(0xFF5E35B1), // Deep Purple
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndAutoSyncContacts();
    });
  }

  Future<void> _checkAndAutoSyncContacts() async {
    await ref.read(contactsPermissionProvider.notifier).checkPermission();
    final isGranted = ref.read(contactsPermissionProvider);
    if (isGranted) {
      final currentRules = ref.read(contactRulesProvider).value ?? [];
      if (currentRules.isEmpty) {
        await ref.read(contactRulesProvider.notifier).refreshFromDevice();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddContactDialog([AppStrings? strings]) {
    final AppStrings s = strings ?? ref.read(appStringsProvider);
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final customTextCtrl = TextEditingController(text: '{name} is calling');
    bool isVip = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final theme = Theme.of(ctx);
            final colorScheme = theme.colorScheme;

            return AlertDialog(
              backgroundColor: colorScheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.person_add_rounded, color: colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(s.newContactRule, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: s.name,
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLowest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: s.phoneNumber,
                        prefixIcon: const Icon(Icons.phone_outlined),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLowest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: customTextCtrl,
                      decoration: InputDecoration(
                        labelText: s.customAnnouncementText,
                        hintText: '{name} is calling',
                        prefixIcon: const Icon(Icons.record_voice_over_outlined),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLowest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                        secondary: const Icon(Icons.star_rounded, color: Colors.amber),
                        title: Text(s.vipContact, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        value: isVip,
                        onChanged: (val) => setDialogState(() => isVip = val),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(s.cancel),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final phone = phoneCtrl.text.trim();
                    if (name.isEmpty || phone.isEmpty) return;

                    final newRule = ContactRule(
                      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      phoneNumber: phone,
                      avatarColorIndex: DateTime.now().millisecond % 6,
                      isEnabled: true,
                      customText: customTextCtrl.text.trim().isNotEmpty ? customTextCtrl.text.trim() : '$name is calling',
                      isVip: isVip,
                    );

                    ref.read(contactRulesProvider.notifier).saveRule(newRule);
                    Navigator.pop(dialogCtx);
                  },
                  child: Text(s.saveRule),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final allRulesAsync = ref.watch(contactRulesProvider);
    final filteredRules = ref.watch(filteredContactRulesProvider);
    final currentFilter = ref.watch(contactFilterProvider);
    final contactsGranted = ref.watch(contactsPermissionProvider);
    final isSyncing = ref.watch(isSyncingContactsProvider);
    final strings = ref.watch(appStringsProvider);

    final allRules = allRulesAsync.value ?? [];
    final vipCount = allRules.where((r) => r.isVip).length;
    final mutedCount = allRules.where((r) => !r.isEnabled).length;
    final customizedCount = allRules.where((r) => r.isCustomized).length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // 1. Google Search Pill Bar (Google Contacts / Phone style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(theme.brightness == Brightness.dark ? 40 : 10),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(Icons.search_rounded, color: colorScheme.onSurfaceVariant, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => ref.read(contactSearchProvider.notifier).state = val,
                        decoration: InputDecoration(
                          hintText: strings.searchContactsHint,
                          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withAlpha(160), fontSize: 15),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(contactSearchProvider.notifier).state = '';
                        },
                      ),
                    IconButton(
                      tooltip: isSyncing ? strings.syncingContacts : strings.syncContacts,
                      icon: isSyncing
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            )
                          : Icon(Icons.sync_rounded, color: colorScheme.onSurfaceVariant, size: 20),
                      onPressed: isSyncing
                          ? null
                          : () {
                              ref.read(contactRulesProvider.notifier).refreshFromDevice();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(strings.syncingContacts),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
            ),
            if (isSyncing) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(minHeight: 2.5),
                ),
              ),
            ],
            const SizedBox(height: 10),

            // Permission Request Banner if contacts permission is not yet granted
            if (!contactsGranted)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withAlpha(90),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colorScheme.primary.withAlpha(40)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.contact_phone_rounded, color: colorScheme.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.contactsPermissionNeeded,
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              strings.contactsPermissionBannerDesc,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          final granted = await ref.read(contactsPermissionProvider.notifier).requestPermission();
                          if (!context.mounted) return;
                          if (granted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(strings.contactsLoadedSuccess),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(strings.allow),
                      ),
                    ],
                  ),
                ),
              ),

            // 2. Horizontal Stadium Filter Chips (Google M3 Chips)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildFilterChip(
                    label: '${strings.filterAll} (${allRules.length})',
                    isSelected: currentFilter == ContactFilter.all,
                    onSelected: () => ref.read(contactFilterProvider.notifier).state = ContactFilter.all,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: '${strings.filterCustomized} ($customizedCount)',
                    isSelected: currentFilter == ContactFilter.customized,
                    onSelected: () => ref.read(contactFilterProvider.notifier).state = ContactFilter.customized,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: '${strings.filterVip} ($vipCount)',
                    isSelected: currentFilter == ContactFilter.vip,
                    onSelected: () => ref.read(contactFilterProvider.notifier).state = ContactFilter.vip,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: '${strings.filterMuted} ($mutedCount)',
                    isSelected: currentFilter == ContactFilter.muted,
                    onSelected: () => ref.read(contactFilterProvider.notifier).state = ContactFilter.muted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 3. Contact List
            Expanded(
              child: allRulesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error loading contacts: $err')),
                data: (_) {
                  if (filteredRules.isEmpty) {
                    if (!contactsGranted) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.no_accounts_rounded, size: 48, color: colorScheme.primary),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                strings.contactsPermissionRequired,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                strings.contactsPermissionRequiredDesc,
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: () => ref.read(contactsPermissionProvider.notifier).requestPermission(),
                                icon: const Icon(Icons.lock_open_rounded, size: 18),
                                label: Text(strings.grantPermission),
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.contacts_rounded, size: 48, color: colorScheme.primary),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? '${strings.noContactsFound} "${_searchController.text}"'
                                  : strings.noContactsInList,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              strings.tapSyncToReimport,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            OutlinedButton.icon(
                              onPressed: () => ref.read(contactRulesProvider.notifier).refreshFromDevice(),
                              icon: const Icon(Icons.sync_rounded, size: 18),
                              label: Text(strings.syncContacts),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    itemCount: filteredRules.length,
                    itemBuilder: (context, index) {
                      final contact = filteredRules[index];
                      return _buildGoogleContactCard(contact, theme, colorScheme, strings);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContactDialog(strings),
        icon: const Icon(Icons.add_rounded),
        label: Text(strings.addRule, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      shape: const StadiumBorder(),
      showCheckmark: isSelected,
      checkmarkColor: colorScheme.onPrimaryContainer,
      selectedColor: colorScheme.primaryContainer,
      backgroundColor: colorScheme.surfaceContainerHigh,
    );
  }

  Widget _buildGoogleContactCard(ContactRule contact, ThemeData theme, ColorScheme colorScheme, [AppStrings? strings]) {
    final avatarColor = _avatarColors[contact.avatarColorIndex % _avatarColors.length];
    final AppStrings s = strings ?? ref.read(appStringsProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: contact.isEnabled ? colorScheme.surfaceContainerLowest : colorScheme.surfaceContainerHigh.withAlpha(90),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: contact.isVip
              ? Colors.amber.withAlpha(160)
              : theme.dividerColor.withAlpha(30),
          width: contact.isVip ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ContactCustomizeScreen(contact: contact),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: Row(
              children: [
                // Google Material You Pastel Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: avatarColor.withAlpha(35),
                      child: Text(
                        contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: avatarColor,
                        ),
                      ),
                    ),
                    if (contact.isVip)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star_rounded, size: 11, color: Colors.black),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // Name & Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              contact.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: contact.isEnabled ? null : theme.hintColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (contact.relationshipTag != 'general') ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                contact.relationshipTag.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        contact.phoneNumber,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontSize: 12),
                      ),
                      const SizedBox(height: 4),

                      // Status Pill
                      Row(
                        children: [
                          Icon(
                            contact.isEnabled ? Icons.record_voice_over_rounded : Icons.voice_over_off_rounded,
                            size: 13,
                            color: contact.isEnabled
                                ? (contact.isVip ? Colors.amber.shade700 : colorScheme.primary)
                                : Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              contact.isEnabled
                                  ? (contact.isCustomized ? contact.customText : 'Using Home Screen Language (${contact.repeatMode})')
                                  : s.filterMuted,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: contact.isCustomized ? FontWeight.w600 : FontWeight.normal,
                                color: contact.isEnabled
                                    ? (contact.isCustomized ? colorScheme.primary : theme.hintColor)
                                    : Colors.redAccent,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Google Pixel Switch
                Switch(
                  value: contact.isEnabled,
                  onChanged: (val) {
                    ref.read(contactRulesProvider.notifier).toggleRule(contact.id);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
