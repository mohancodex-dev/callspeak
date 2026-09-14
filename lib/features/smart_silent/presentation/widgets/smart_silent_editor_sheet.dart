import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../models/smart_silent_schedule.dart';

class SmartSilentEditorSheet extends StatefulWidget {
  final SmartSilentSchedule? initialSchedule;
  final AppStrings strings;
  final Function(SmartSilentSchedule) onSave;

  const SmartSilentEditorSheet({
    super.key,
    this.initialSchedule,
    required this.strings,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    SmartSilentSchedule? schedule,
    required AppStrings strings,
    required Function(SmartSilentSchedule) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SmartSilentEditorSheet(
        initialSchedule: schedule,
        strings: strings,
        onSave: onSave,
      ),
    );
  }

  @override
  State<SmartSilentEditorSheet> createState() => _SmartSilentEditorSheetState();
}

class _SmartSilentEditorSheetState extends State<SmartSilentEditorSheet> {
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late int _startHour;
  late int _startMinute;
  late int _endHour;
  late int _endMinute;
  late Set<int> _selectedDays;
  late String _silenceScope;
  late bool _isLocationEnabled;
  late double _radiusMeters;

  @override
  void initState() {
    super.initState();
    final s = widget.initialSchedule;
    _titleController = TextEditingController(text: s?.title ?? 'Meeting');
    _locationController = TextEditingController(text: s?.locationName ?? 'Office');
    _startHour = s?.startHour ?? 10;
    _startMinute = s?.startMinute ?? 0;
    _endHour = s?.endHour ?? 11;
    _endMinute = s?.endMinute ?? 0;
    _selectedDays = s != null ? s.daysOfWeek.toSet() : {1, 2, 3, 4, 5};
    _silenceScope = s?.silenceScope ?? 'both';
    _isLocationEnabled = s?.isLocationEnabled ?? false;
    _radiusMeters = s?.radiusMeters ?? 200.0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String _formatTime(int hour, int minute) {
    final tod = TimeOfDay(hour: hour, minute: minute);
    return tod.format(context);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _startHour, minute: _startMinute),
    );
    if (picked != null) {
      setState(() {
        _startHour = picked.hour;
        _startMinute = picked.minute;
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _endHour, minute: _endMinute),
    );
    if (picked != null) {
      setState(() {
        _endHour = picked.hour;
        _endMinute = picked.minute;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = widget.strings;
    final isEditing = widget.initialSchedule != null;

    final dayLabels = [
      {'val': 1, 'label': 'M'},
      {'val': 2, 'label': 'T'},
      {'val': 3, 'label': 'W'},
      {'val': 4, 'label': 'T'},
      {'val': 5, 'label': 'F'},
      {'val': 6, 'label': 'S'},
      {'val': 7, 'label': 'S'},
    ];

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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.schedule_rounded, color: Colors.amber.shade800, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? strings.editSchedule : strings.addSchedule,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        strings.smartSilentSubtitle,
                        style: TextStyle(fontSize: 12, color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Title Field
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: strings.scheduleTitleLabel,
                hintText: 'e.g. Meeting, Office, Focus',
                prefixIcon: const Icon(Icons.label_outline_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: colorScheme.surfaceContainerLowest,
              ),
            ),
            const SizedBox(height: 10),

            // Quick preset chips
            Wrap(
              spacing: 8,
              children: [
                _buildQuickPreset('Meeting', Icons.business_center_rounded),
                _buildQuickPreset('Office', Icons.apartment_rounded),
                _buildQuickPreset('College / Class', Icons.school_rounded),
                _buildQuickPreset('Prayer', Icons.self_improvement_rounded),
                _buildQuickPreset('Night Rest', Icons.nightlight_round),
              ],
            ),
            const SizedBox(height: 20),

            // Visual Time Flow Card (Start -> Silent, End -> Normal)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
              ),
              child: Column(
                children: [
                  // Start Time row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_off_rounded, color: Colors.redAccent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.startTimeLabel,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text(
                              strings.autoSilentIndicator,
                              style: TextStyle(fontSize: 11, color: theme.hintColor),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: _pickStartTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatTime(_startHour, _startMinute),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 19.0, top: 4, bottom: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(Icons.arrow_downward_rounded, size: 18, color: Colors.grey),
                    ),
                  ),
                  // End Time row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_active_rounded, color: Colors.green, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.endTimeLabel,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text(
                              strings.autoNormalIndicator,
                              style: TextStyle(fontSize: 11, color: theme.hintColor),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: _pickEndTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatTime(_endHour, _endMinute),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Days of Week
            Text('Repeat Days', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: dayLabels.map((day) {
                final isSelected = _selectedDays.contains(day['val']);
                return InkWell(
                  onTap: () {
                    setState(() {
                      final val = day['val'] as int;
                      if (isSelected) {
                        if (_selectedDays.length > 1) _selectedDays.remove(val);
                      } else {
                        _selectedDays.add(val);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      day['label'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Optional Location Trigger Section
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isLocationEnabled ? Colors.teal : colorScheme.outlineVariant.withAlpha(40),
                  width: _isLocationEnabled ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Row(
                      children: [
                        Icon(Icons.location_on_rounded, color: _isLocationEnabled ? Colors.teal : Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          strings.locationTriggerOptional,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      strings.locationTriggerDesc,
                      style: TextStyle(fontSize: 11.5, color: theme.hintColor),
                    ),
                    value: _isLocationEnabled,
                    onChanged: (val) => setState(() => _isLocationEnabled = val),
                  ),
                  if (_isLocationEnabled) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              labelText: strings.locationNameLabel,
                              hintText: 'e.g. Main Office, Meeting Room 402',
                              prefixIcon: const Icon(Icons.place_outlined, color: Colors.teal),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildLocationPresetChip('Office'),
                              _buildLocationPresetChip('Meeting Hall'),
                              _buildLocationPresetChip('Library'),
                              _buildLocationPresetChip('Campus'),
                              _buildLocationPresetChip('Temple / Mosque'),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(strings.locationRadiusLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              Text('${_radiusMeters.toInt()}m', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                            ],
                          ),
                          Slider(
                            value: _radiusMeters,
                            min: 50,
                            max: 1000,
                            divisions: 19,
                            activeColor: Colors.teal,
                            onChanged: (val) => setState(() => _radiusMeters = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final title = _titleController.text.trim().isEmpty ? 'Meeting' : _titleController.text.trim();
                  final schedule = SmartSilentSchedule(
                    id: widget.initialSchedule?.id ?? 'sched_${DateTime.now().millisecondsSinceEpoch}',
                    title: title,
                    startHour: _startHour,
                    startMinute: _startMinute,
                    endHour: _endHour,
                    endMinute: _endMinute,
                    daysOfWeek: _selectedDays.toList()..sort(),
                    isEnabled: widget.initialSchedule?.isEnabled ?? true,
                    silenceScope: _silenceScope,
                    isLocationEnabled: _isLocationEnabled,
                    locationName: _isLocationEnabled ? _locationController.text.trim() : null,
                    radiusMeters: _radiusMeters,
                  );

                  widget.onSave(schedule);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: Text(
                  isEditing ? strings.saveChanges : strings.addSchedule,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPreset(String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11.5)),
      onPressed: () {
        setState(() {
          _titleController.text = label;
          if (label == 'Meeting') {
            _startHour = 10;
            _startMinute = 0;
            _endHour = 11;
            _endMinute = 0;
          } else if (label == 'Office') {
            _startHour = 9;
            _startMinute = 0;
            _endHour = 17;
            _endMinute = 0;
          } else if (label == 'Night Rest') {
            _startHour = 23;
            _startMinute = 0;
            _endHour = 7;
            _endMinute = 0;
          }
        });
      },
    );
  }

  Widget _buildLocationPresetChip(String name) {
    return ChoiceChip(
      label: Text(name, style: const TextStyle(fontSize: 11)),
      selected: _locationController.text == name,
      onSelected: (val) {
        if (val) {
          setState(() => _locationController.text = name);
        }
      },
    );
  }
}
