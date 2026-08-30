import 'package:flutter/material.dart';

import '../database/app_database.dart';

class MonthlyPage extends StatefulWidget {
  const MonthlyPage({super.key});

  @override
  State<MonthlyPage> createState() => _MonthlyPageState();
}

class _MonthlyPageState extends State<MonthlyPage> {
  List<Map<String, dynamic>> visits = [];

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    final rows = await AppDatabase.instance.getVisits();

    if (!mounted) return;

    setState(() {
      visits = rows;
    });
  }

  List<Map<String, dynamic>> _getMonthlyData() {
    final Map<String, Map<String, int>> monthlyData = {};

    for (final visit in visits) {
      final isInvalid = (visit['is_invalid'] as int) == 1;

      if (isInvalid) {
        continue;
      }

      final startTime = DateTime.parse(visit['start_time'] as String);

      final monthKey =
          '${startTime.year}-${startTime.month.toString().padLeft(2, '0')}';

      final counter = visit['counter'] as int;
      final sessionCost = visit['session_cost'] as int;

      final earning = counter * sessionCost;

      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = {
          'year': startTime.year,
          'month': startTime.month,
          'visits': 0,
          'visitors': 0,
          'earnings': 0,
        };
      }

      monthlyData[monthKey]!['visits'] = monthlyData[monthKey]!['visits']! + 1;

      monthlyData[monthKey]!['visitors'] =
          monthlyData[monthKey]!['visitors']! + counter;

      monthlyData[monthKey]!['earnings'] =
          monthlyData[monthKey]!['earnings']! + earning;
    }

    final result = monthlyData.values.toList();

    result.sort((a, b) {
      final dateA = DateTime(a['year'] as int, a['month'] as int);

      final dateB = DateTime(b['year'] as int, b['month'] as int);

      return dateB.compareTo(dateA);
    });

    return result;
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  String _formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final monthlyData = _getMonthlyData();

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly')),
      body: monthlyData.isEmpty
          ? const Center(child: Text('No data yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: monthlyData.length,
              itemBuilder: (context, index) {
                final data = monthlyData[index];

                final year = data['year'] as int;
                final month = data['month'] as int;
                final visitorCount = data['visitors'] as int;
                final earnings = data['earnings'] as int;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_monthName(month)} $year',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$visitorCount visitor',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(_formatCurrency(earnings)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
