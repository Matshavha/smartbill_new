import 'package:flutter/material.dart';
import 'main.dart'; // ✅ Needed to access TariffOfflineApp widget

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to Megaflex Gen Urban'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Image.asset('assets/eskom_logo.png', height: 80),
            SizedBox(height: 16),
            Text(
              'Megaflex Gen Urban Tariff',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Divider(height: 24),
            Text(
              'This tariff applies to urban customers connected at medium, high, or transmission voltage who both generate and consume energy at the same Point of Delivery (POD). It is a Time-of-Use (TOU) tariff with seasonal variations.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            Text(
              'Key Charges:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            _bullet(
                'Active Energy Charges (c/kWh) – varies by TOU period and season.'),
            _bullet(
                'Generation Capacity Charge (R/kVA/month) – based on voltage and capacity.'),
            _bullet(
                'Legacy Charge (c/kWh) – applicable to all energy consumed.'),
            _bullet(
                'Administration Charge (R/day) – based on utilised or exported capacity.'),
            _bullet(
                'Transmission Network Charge – based on zone and capacity.'),
            _bullet('Losses Charge – accounts for technical energy losses.'),
            _bullet(
                'Ancillary Service Charge – recovers system operation costs.'),
            _bullet(
                'Reactive Energy Charge – for poor power factor during peak times.'),
            _bullet(
                'Electrification & Rural Subsidy – socio-economic support.'),
            _bullet('Affordability Subsidy – cross-subsidy for active energy.'),
            _bullet(
                'Excess Capacity Charge – applies when NMD or MEC is exceeded.'),
            SizedBox(height: 24),
            Text(
              'Tap below to view your applicable tariff rates.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => TariffOfflineApp()),
                );
              },
              child: Text('Continue to Tariff Viewer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("• ", style: TextStyle(fontSize: 18)),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
