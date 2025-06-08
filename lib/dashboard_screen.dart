import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<String> podOptions = [
    '1159364720',
    '9857665714',
    '7614718533',
    '5717941398',
  ];

  String? selectedPod;
  DateTimeRange? selectedDateRange;
  List<Map<String, String>> podData = [];
  Map<String, String> generalInfo = {};
  Map<String, dynamic> statistics = {};
  Map<String, Map<String, double>> touTotals = {};
  Map<String, String> selectedRow = {};
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Energy Dashboard'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Select POD'),
              value: selectedPod,
              items: podOptions
                  .map((pod) => DropdownMenuItem(value: pod, child: Text(pod)))
                  .toList(),
              onChanged: (value) async {
                setState(() {
                  selectedPod = value;
                  errorMessage = '';
                  selectedDateRange = null;
                });
                if (value != null) await _loadPodData(value);
              },
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => selectedDateRange = picked);
                  _extractInfoAndStats();
                }
              },
              child: Text('Select Date Range (Optional)'),
            ),
            SizedBox(height: 12),
            if (errorMessage.isNotEmpty)
              Text(errorMessage, style: TextStyle(color: Colors.red)),
            if (generalInfo.isNotEmpty)
              Expanded(
                child: ListView(
                  children: [
                    _buildInfoCards(),
                    _buildStatCards(),
                    _buildTOUCards(),
                    _buildSelectedTimeData(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadPodData(String podId) async {
    try {
      final raw = await rootBundle.loadString('assets/$podId.csv');
      final lines = raw
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
      final headers = lines.first.split(',').map((h) => h.trim()).toList();

      final rows = lines.skip(1).map((line) {
        final values = line.split(',');
        return Map<String, String>.fromIterables(
          headers,
          values.map((v) => v.trim()),
        );
      }).toList();

      if (rows.isEmpty) {
        setState(() => errorMessage = 'No data found for POD $podId.');
        return;
      }

      setState(() {
        podData = rows;
        errorMessage = '';
      });

      _extractInfoAndStats();
    } catch (e) {
      setState(() => errorMessage = 'Error loading data: $e');
    }
  }

  void _extractInfoAndStats() {
    final numericFields = ['kwh', 'kvarh', 'gkwh', 'gkvarh', 'kvah', 'gkvah'];
    final Map<String, List<double>> valuesMap = {
      for (var k in numericFields) k: [],
    };

    final filteredData = selectedDateRange != null
        ? podData.where((row) {
            final dt =
                DateTime.tryParse(row['datetime'] ?? '') ?? DateTime.now();
            return dt.isAfter(
                  selectedDateRange!.start.subtract(Duration(days: 1)),
                ) &&
                dt.isBefore(selectedDateRange!.end.add(Duration(days: 1)));
          }).toList()
        : podData;

    generalInfo = filteredData.isNotEmpty ? filteredData.first : {};

    for (var row in filteredData) {
      for (var field in numericFields) {
        valuesMap[field]!.add(
          double.tryParse(row[field]?.replaceAll('*', '') ?? '0') ?? 0,
        );
      }
    }

    statistics = {
      for (var field in numericFields)
        field: {
          'mean': _mean(valuesMap[field]!),
          'min': valuesMap[field]!.isEmpty
              ? 0
              : valuesMap[field]!.reduce((a, b) => a < b ? a : b),
          'max': valuesMap[field]!.isEmpty
              ? 0
              : valuesMap[field]!.reduce((a, b) => a > b ? a : b),
        },
      'Load Factor':
          _mean(valuesMap['kvah']!) /
          ((double.tryParse(generalInfo['nmd'] ?? '1') ?? 1)),
      'Power Factor':
          _mean(valuesMap['kwh']!) /
          (_mean(valuesMap['kvah']!) == 0 ? 1 : _mean(valuesMap['kvah']!)),
    };

    _aggregateTOU(filteredData);
    selectedRow = filteredData.isNotEmpty ? filteredData.last : {};
  }

  void _aggregateTOU(List<Map<String, String>> dataSubset) {
    touTotals = {'Peak': {}, 'Standard': {}, 'Off-Peak': {}};

    for (var row in dataSubset) {
      final datetime =
          DateTime.tryParse(row['datetime'] ?? '') ?? DateTime.now();
      final hour = datetime.hour;
      final day = datetime.weekday;
      final month = datetime.month;

      final isHighSeason = (month == 6 || month == 7 || month == 8);
      String tou;

      if (isHighSeason) {
        if (day <= 5) {
          if ([7, 8, 9, 10, 18, 19].contains(hour)) {
            tou = 'Peak';
          } else if ([6, 11, 12, 13, 14, 15, 16, 17, 21].contains(hour)) {
            tou = 'Standard';
          } else {
            tou = 'Off-Peak';
          }
        } else {
          tou = 'Off-Peak';
        }
      } else {
        if (day <= 5) {
          if ([7, 8, 9].contains(hour)) {
            tou = 'Peak';
          } else if ([6, 10, 11, 12, 13, 14, 15, 16, 17].contains(hour)) {
            tou = 'Standard';
          } else {
            tou = 'Off-Peak';
          }
        } else {
          tou = 'Off-Peak';
        }
      }

      for (var key in ['kwh', 'kvarh', 'gkwh', 'gkvarh', 'kvah', 'gkvah']) {
        final val = double.tryParse(row[key]?.replaceAll('*', '') ?? '0') ?? 0;
        touTotals[tou]![key] = (touTotals[tou]![key] ?? 0) + val;
      }
    }
  }

  Widget _buildInfoCards() {
    final keys = [
      'tariff',
      'account_id',
      'voltage_zone',
      'transmission_zone',
      'nmd',
      'mec',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: keys
          .map((k) => _buildCard(k, generalInfo[k] ?? 'N/A'))
          .toList(),
    );
  }

  Widget _buildStatCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: statistics.entries.map((entry) {
        if (entry.value is Map) {
          final map = Map<String, double>.from(entry.value as Map<String, num>);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.key.toUpperCase()}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Mean: ${map['mean']!.toStringAsFixed(2)}'),
              Text('Min: ${map['min']!.toStringAsFixed(2)}'),
              Text('Max: ${map['max']!.toStringAsFixed(2)}'),
              SizedBox(height: 8),
            ],
          );
        } else {
          return _buildCard(entry.key, entry.value.toStringAsFixed(2));
        }
      }).toList(),
    );
  }

  Widget _buildTOUCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: touTotals.entries.map((e) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${e.key} Usage',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...e.value.entries.map(
              (kv) => Text('${kv.key}: ${kv.value.toStringAsFixed(2)}'),
            ),
            SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSelectedTimeData() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sample Recent Data:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ...['kwh', 'kvarh', 'gkwh', 'gkvarh', 'kvah', 'gkvah'].map((k) {
          return Text('$k: ${selectedRow[k] ?? '0'}');
        }),
      ],
    );
  }

  Widget _buildCard(String title, String value) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: ListTile(
        title: Text(
          title.toUpperCase(),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Text(value),
      ),
    );
  }

  double _mean(List<double> list) {
    if (list.isEmpty) return 0;
    return list.reduce((a, b) => a + b) / list.length;
  }
}
