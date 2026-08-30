import 'package:flutter/material.dart';

import 'package:playground_counter/database/app_database.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController sessionTimeController = TextEditingController();
  final TextEditingController sessionCostController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await AppDatabase.instance.getSettings();

    if (!mounted) return;

    if (settings != null) {
      titleController.text = settings['title'] as String;
      sessionTimeController.text = (settings['session_time'] as num).toString();
      sessionCostController.text = (settings['session_cost'] as num).toString();
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final title = titleController.text.trim();
    final sessionTime = double.tryParse(sessionTimeController.text.trim());
    final sessionCost = int.tryParse(sessionCostController.text.trim());

    if (title.isEmpty || sessionTime == null || sessionCost == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid settings')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save Settings?'),
          content: Text(
            'Title: $title\n'
            'Session Time: $sessionTime hours\n'
            'Session Cost: Rp $sessionCost',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirm != true) {
      return;
    }

    await AppDatabase.instance.saveSettings(
      title: title,
      sessionTime: sessionTime,
      sessionCost: sessionCost,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Settings saved')));
  }

  @override
  void dispose() {
    titleController.dispose();
    sessionTimeController.dispose();
    sessionCostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: sessionTimeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Session Time',
              suffixText: 'hours',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: sessionCostController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Session Cost',
              prefixText: 'Rp ',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _saveSettings,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
