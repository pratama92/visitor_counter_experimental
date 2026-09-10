import 'package:flutter/material.dart';
import 'package:playground_counter/database/app_database.dart';

import 'visitor_recognition_page.dart';

import '../models/visit.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final List<Visit> visits = [];

  DateTime selectedDate = DateTime.now();

  bool showInvalid = false;

  double sessionTime = 1.0;
  int sessionCost = 10000;
  String appTitle = 'Playground Counter';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadSettings();
    await _loadVisits();
  }

  Future<void> _loadSettings() async {
    final settings = await AppDatabase.instance.getSettings();

    if (!mounted) return;

    if (settings != null) {
      setState(() {
        appTitle = settings['title'] as String;
        sessionTime = (settings['session_time'] as num).toDouble();
        sessionCost = (settings['session_cost'] as num).toInt();
      });
    }
  }

  Future<void> _loadVisits() async {
    final rows = await AppDatabase.instance.getVisits();

    final loadedVisits = rows.map((row) {
      return Visit(
        id: row['id'] as int,
        counter: row['counter'] as int,
        startTime: DateTime.parse(row['start_time'] as String),
        endTime: row['end_time'] == null
            ? null
            : DateTime.parse(row['end_time'] as String),
        sessionCost: row['session_cost'] as int,
        isInvalid: (row['is_invalid'] as int) == 1,
      );
    }).toList();

    if (!mounted) return;

    setState(() {
      visits.clear();
      visits.addAll(loadedVisits);
    });
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();

    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _formatCurrency(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );

    return 'Rp $formatted';
  }

  List<Visit> get selectedVisits {
    return visits
        .where(
          (visit) =>
              visit.startTime.year == selectedDate.year &&
              visit.startTime.month == selectedDate.month &&
              visit.startTime.day == selectedDate.day &&
              (showInvalid || !visit.isInvalid),
        )
        .toList();
  }

  int get totalVisitors {
    return selectedVisits
        .where((visit) => !visit.isInvalid)
        .fold(0, (total, visit) => total + visit.counter);
  }

  int get totalEarnings {
    return selectedVisits
        .where((visit) => !visit.isInvalid)
        .fold(0, (total, visit) => total + (visit.counter * visit.sessionCost));
  }

  void _showAddVisitDialog() {
    int counter = 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Visit'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: counter > 1
                            ? () {
                                setDialogState(() {
                                  counter--;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '$counter',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () {
                          setDialogState(() {
                            counter++;
                          });
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Session: $sessionTime hours',
                    style: const TextStyle(fontSize: 16),
                  ),

                  Text(
                    'Cost: ${_formatCurrency(sessionCost)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final startTime = DateTime.now();

                    final endTime = startTime.add(
                      Duration(minutes: (sessionTime * 60).round()),
                    );

                    final id = await AppDatabase.instance.insertVisit(
                      counter: counter,
                      startTime: startTime,
                      endTime: endTime,
                      sessionCost: sessionCost,
                    );

                    if (!mounted) return;

                    setState(() {
                      visits.add(
                        Visit(
                          id: id,
                          counter: counter,
                          startTime: startTime,
                          endTime: endTime,
                          sessionCost: sessionCost,
                        ),
                      );
                    });

                    if (!context.mounted) return;

                    Navigator.pop(context);
                  },
                  child: const Text('Start'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _markInvalid(Visit visit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mark as Invalid?'),
          content: const Text(
            'This visit will remain in the list but will not be included in the total visitors or earnings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Invalid'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirm == true) {
      if (visit.id != null) {
        await AppDatabase.instance.updateVisit(visit.id!, {'is_invalid': 1});
      }

      if (!mounted) return;

      setState(() {
        visit.isInvalid = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(selectedDate);

    return Scaffold(
      appBar: AppBar(title: Text(appTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                OutlinedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_formatDate(selectedDate)),
                ),

                const SizedBox(height: 12),

                Text(
                  isToday ? 'Today' : 'Selected Date',
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 4),

                Text(
                  '$totalVisitors visitors',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _formatCurrency(totalEarnings),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          SwitchListTile(
            title: const Text('Show Invalid'),
            value: showInvalid,
            onChanged: (value) {
              setState(() {
                showInvalid = value;
              });
            },
          ),

          Expanded(
            child: selectedVisits.isEmpty
                ? const Center(child: Text('No visits yet'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: selectedVisits.length,
                    itemBuilder: (context, index) {
                      final visit = selectedVisits[index];

                      return Card(
                        child: ListTile(
                          title: Text(
                            '${visit.counter} visitors',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Start: ${_formatTime(visit.startTime)}\n'
                            'End: ${visit.endTime == null ? '-' : _formatTime(visit.endTime!)}',
                          ),
                          trailing: visit.isInvalid
                              ? const Text('Invalid')
                              : isToday
                              ? TextButton(
                                  onPressed: () => _markInvalid(visit),
                                  child: const Text('Mark Invalid'),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: isToday
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VisitorRecognitionPage(),
                  ),
                );
              }
            : null,
        child: const Icon(Icons.add),
      ),
    );
  }
}
