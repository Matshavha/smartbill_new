import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dashboard_screen.dart'; // NEW IMPORT

void main() {
  runApp(SmartBillApp());
}

class SmartBillApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartBill+',
      theme: ThemeData(
        primaryColor: Color(0xFF003366),
        scaffoldBackgroundColor: Color(0xFFF5F5F5),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF003366),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF003366),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: TariffOfflineApp(),
    );
  }
}

class TariffOfflineApp extends StatefulWidget {
  @override
  _TariffOfflineAppState createState() => _TariffOfflineAppState();
}

class _TariffOfflineAppState extends State<TariffOfflineApp> {
  List<List<String>> _csvData = [];
  List<String>? _matchedRow;

  String? _selectedTransmission;
  String? _selectedVoltage;
  String? _selectedNmd;
  String? _selectedSeason;
  bool _includeVat = false;

  List<String> transmissionOptions = [];
  List<String> voltageOptions = [];
  List<String> nmdOptions = [];
  final List<String> seasonOptions = ['High Season', 'Low Season'];

  @override
  void initState() {
    super.initState();
    _loadCSV();
  }

  Future<void> _loadCSV() async {
    final raw = await rootBundle.loadString('assets/tariff_details.csv');
    final lines = raw.trim().split('\n');
    final parsed = lines.map((line) => line.split(',')).toList();

    final tSet = <String>{};
    final vSet = <String>{};
    final nSet = <String>{};

    for (var row in parsed.skip(1)) {
      if (row.length >= 3) {
        tSet.add(row[0].trim());
        vSet.add(row[1].trim());
        nSet.add(row[2].trim());
      }
    }

    setState(() {
      _csvData = parsed;
      transmissionOptions = tSet.toList()..sort();
      voltageOptions = vSet.toList()..sort();
      nmdOptions = nSet.toList()..sort();
    });
  }

  void _search() {
    final match = _csvData
        .skip(1)
        .firstWhere(
          (row) =>
              row[0] == _selectedTransmission &&
              row[1] == _selectedVoltage &&
              row[2] == _selectedNmd,
          orElse: () => [],
        );

    setState(() {
      _matchedRow = match.isEmpty ? null : match;
    });
  }

  @override
  Widget build(BuildContext context) {
    final headers = _csvData.isNotEmpty ? _csvData[0] : [];

    return Scaffold(
      appBar: AppBar(
        title: Text('SmartBill+ Tariff Viewer'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.dashboard),
            tooltip: 'Go to Dashboard',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DashboardScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Image.asset(
            'assets/eskom_logo.png',
            height: 80,
            alignment: Alignment.center,
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: 'Transmission Zone'),
            value: _selectedTransmission,
            items: transmissionOptions.map((zone) {
              return DropdownMenuItem(value: zone, child: Text(zone));
            }).toList(),
            onChanged: (value) => setState(() => _selectedTransmission = value),
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: 'Voltage'),
            value: _selectedVoltage,
            items: voltageOptions.map((v) {
              return DropdownMenuItem(value: v, child: Text(v));
            }).toList(),
            onChanged: (value) => setState(() => _selectedVoltage = value),
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: 'NMD'),
            value: _selectedNmd,
            items: nmdOptions.map((n) {
              return DropdownMenuItem(value: n, child: Text(n));
            }).toList(),
            onChanged: (value) => setState(() => _selectedNmd = value),
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: 'Season'),
            value: _selectedSeason,
            items: seasonOptions.map((s) {
              return DropdownMenuItem(value: s, child: Text(s));
            }).toList(),
            onChanged: (value) => setState(() => _selectedSeason = value),
          ),
          SizedBox(height: 12),
          SwitchListTile(
            title: Text('Include VAT (15%)'),
            value: _includeVat,
            onChanged: (value) => setState(() => _includeVat = value),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _search,
            child: Text('Find Applicable Tariff'),
          ),
          SizedBox(height: 20),
          if (_matchedRow != null && headers.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(headers.length, (i) {
                final header = headers[i];
                final value = _matchedRow![i];

                if (_selectedSeason == 'High Season' &&
                        header.startsWith('HS_') ||
                    _selectedSeason == 'Low Season' &&
                        header.startsWith('LS_') ||
                    (!header.startsWith('HS_') && !header.startsWith('LS_'))) {
                  final includeVat =
                      _includeVat &&
                      !header.toLowerCase().contains('loss factor');

                  final original = double.tryParse(value) ?? 0.0;
                  final displayedValue = includeVat
                      ? (original * 1.15).toStringAsFixed(2)
                      : value;

                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(
                        header,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(displayedValue),
                    ),
                  );
                } else {
                  return Container();
                }
              }),
            ),
          if (_matchedRow == null && _selectedTransmission != null)
            Text("No match found.", style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}
