import 'package:flutter/material.dart';

import '../../models/notification_settings_model.dart';
import '../../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  final String userId;

  const NotificationScreen({super.key, required this.userId});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<NotificationSettings> _settingsFuture;
  NotificationSettings? _currentSettings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _settingsFuture = NotificationService.getSettings(widget.userId).then((settings) {
      setState(() {
        _currentSettings = settings;
      });
      return settings;
    });
  }

  Future<void> _updateSettings(Map<String, dynamic> updates) async {
    // Optimistic update
    final oldSettings = _currentSettings;
    if (oldSettings == null) return;

    // Update local state immediately
    setState(() {
      // Create a new object with the updated value
      Map<String, dynamic> json = oldSettings.toJson();
      updates.forEach((key, value) {
        json[key] = value;
      });
      _currentSettings = NotificationSettings.fromJson(json);
    });

    try {
      await NotificationService.updateSettings(widget.userId, updates);
    } catch (e) {
      // Revert on failure
      setState(() {
        _currentSettings = oldSettings;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update setting: $e')),
      );
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    await _updateSettings({key: value});
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showJournalingSheet() {
    if (_currentSettings == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        bool enabled = _currentSettings!.journalingRoutineEnabled;
        TimeOfDay time = _parseTime(_currentSettings!.journalingTime);
        
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Journaling Routine',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF422006),
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Enable Reminder', style: TextStyle(fontSize: 16, fontFamily: 'Nunito')),
                      Switch(
                        value: enabled,
                        onChanged: (val) => setSheetState(() => enabled = val),
                        activeColor: const Color(0xFFF97316),
                      ),
                    ],
                  ),
                  if (enabled) ...[
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Reminder Time', style: TextStyle(fontFamily: 'Nunito')),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFED7AA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          time.format(context),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF422006),
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: time,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFFF97316),
                                  onPrimary: Colors.white,
                                  onSurface: Color(0xFF422006),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setSheetState(() => time = picked);
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _updateSettings({
                          'journaling_routine_enabled': enabled,
                          'journaling_time': _formatTimeOfDay(time),
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showHydrationSheet() {
    if (_currentSettings == null) return;
    
    final intervals = [30, 60, 90, 120, 180, 240];
    final intervalLabels = {
      30: 'Every 30 mins',
      60: 'Every 1 hour',
      90: 'Every 1.5 hours',
      120: 'Every 2 hours',
      180: 'Every 3 hours',
      240: 'Every 4 hours',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        bool enabled = _currentSettings!.hydrationRemindersEnabled;
        int interval = _currentSettings!.hydrationIntervalMinutes;
        if (!intervals.contains(interval)) interval = 120; // Default fallback
        
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hydration Reminders',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF422006),
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Enable Reminder', style: TextStyle(fontSize: 16, fontFamily: 'Nunito')),
                      Switch(
                        value: enabled,
                        onChanged: (val) => setSheetState(() => enabled = val),
                        activeColor: const Color(0xFFF97316),
                      ),
                    ],
                  ),
                  if (enabled) ...[
                    const SizedBox(height: 16),
                    const Text('Frequency', style: TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Nunito')),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: interval,
                          isExpanded: true,
                          items: intervals.map((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text(intervalLabels[value]!, style: const TextStyle(fontFamily: 'Nunito')),
                            );
                          }).toList(),
                          onChanged: (int? newValue) {
                            if (newValue != null) {
                              setSheetState(() => interval = newValue);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _updateSettings({
                          'hydration_reminders_enabled': enabled,
                          'hydration_interval_minutes': interval,
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBreathingSheet() {
    if (_currentSettings == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        bool enabled = _currentSettings!.breathingPracticesEnabled;
        TimeOfDay time = _parseTime(_currentSettings!.breathingTime);
        
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Breathing Practices',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF422006),
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Enable Reminder', style: TextStyle(fontSize: 16, fontFamily: 'Nunito')),
                      Switch(
                        value: enabled,
                        onChanged: (val) => setSheetState(() => enabled = val),
                        activeColor: const Color(0xFFF97316),
                      ),
                    ],
                  ),
                  if (enabled) ...[
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Daily Reminder Time', style: TextStyle(fontFamily: 'Nunito')),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFED7AA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          time.format(context),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF422006),
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: time,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFFF97316),
                                  onPrimary: Colors.white,
                                  onSurface: Color(0xFF422006),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setSheetState(() => time = picked);
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _updateSettings({
                          'breathing_practices_enabled': enabled,
                          'breathing_time': _formatTimeOfDay(time),
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8), // Beige background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF422006)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF422006),
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<NotificationSettings>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _currentSettings == null) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)));
          } else if (snapshot.hasError && _currentSettings == null) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final settings = _currentSettings ?? snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  children: [
                    _buildSwitchTile(
                      title: 'Allow Notifications',
                      subtitle: 'Enable or disable all notifications from Pawse.',
                      value: settings.allNotificationsEnabled,
                      onChanged: (val) => _updateSetting('all_notifications_enabled', val),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Opacity(
                  opacity: settings.allNotificationsEnabled ? 1.0 : 0.5,
                  child: IgnorePointer(
                    ignoring: !settings.allNotificationsEnabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionCard(
                          children: [
                            _buildSwitchTile(
                              title: 'Intelligent Nudges',
                              subtitle: 'Receive affirmations based on your mood.',
                              value: settings.intelligentNudges,
                              onChanged: (val) => _updateSetting('intelligent_nudges', val),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Custom Reminders',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF422006),
                            fontFamily: 'Nunito',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSectionCard(
                          children: [
                            _buildNavigationTile(
                              icon: Icons.book,
                              iconColor: Colors.purple,
                              title: 'Journaling Routine',
                              onTap: _showJournalingSheet,
                            ),
                            const Divider(height: 1, indent: 56),
                            _buildNavigationTile(
                              icon: Icons.water_drop,
                              iconColor: Colors.blue,
                              title: 'Hydration Reminders',
                              onTap: _showHydrationSheet,
                            ),
                            const Divider(height: 1, indent: 56),
                            _buildNavigationTile(
                              icon: Icons.air,
                              iconColor: Colors.teal,
                              title: 'Breathing Practices',
                              onTap: _showBreathingSheet,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Appointments',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF422006),
                            fontFamily: 'Nunito',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSectionCard(
                          children: [
                            _buildSwitchTile(
                              title: 'Therapy Sessions',
                              subtitle: 'Get a reminder 1 hour before your session.',
                              value: settings.therapySessions,
                              onChanged: (val) => _updateSetting('therapy_sessions', val),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF422006),
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFF97316), // Orange
            activeTrackColor: const Color(0xFFF97316).withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF422006),
          fontFamily: 'Nunito',
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
