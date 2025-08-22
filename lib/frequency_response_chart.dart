import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class FrequencyResponseChart extends StatefulWidget {
  final Map<String, double>? initialData; // Dane początkowe dla wykresu (opcjonalne)
  final ValueChanged<Map<String, double>?> onDataChanged; // Funkcja, która zostanie wywołana po zmianie danych

  const FrequencyResponseChart({
    super.key,
    this.initialData,
    required this.onDataChanged,
  });

  @override
  State<FrequencyResponseChart> createState() => _FrequencyResponseChartState();
}

class _FrequencyResponseChartState extends State<FrequencyResponseChart> {
  List<FlSpot> _spots = [];
  Map<String, double>? _freqMap;

  static const double fMin = 20.0;
  static const double fMax = 20000.0;

  @override
  void initState() {
    super.initState();

    // Jeśli mamy dane początkowe
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      _freqMap = widget.initialData;
      _spots = widget.initialData!.entries.map((e) {
        final double freq = double.tryParse(e.key) ?? 0.0;
        return FlSpot(_xFromFreq(freq), e.value);
      }).toList()
        ..sort((a, b) => a.x.compareTo(b.x));
    }
  }

  double _xFromFreq(double f) => // Obliczanie położenia na osi X dla danej częstotliwości
      (math.log(f / fMin) / math.log(fMax / fMin)).clamp(0.0, 1.0);

  String _formatXLabel(double x) { // Formatowanie etykiet na osi X
    final double f = fMin * math.pow(fMax / fMin, x).toDouble();
    if (f >= 1000.0) return "${(f / 1000.0).toStringAsFixed(1)}k";
    return f.toStringAsFixed(0);
  }

  Future<void> _pickFile() async { // Funkcja do wyboru pliku JSON i wczytywania go
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final decoded = jsonDecode(await file.readAsString());

    final Map<String, double> freqMap = {};
    final List<FlSpot> parsed = [];

    if (decoded is Map) {
      for (final e in decoded.entries) {
        final double freq = double.parse(e.key);
        final double db = (e.value as num).toDouble();
        parsed.add(FlSpot(_xFromFreq(freq), db));
        freqMap[freq.toString()] = db;
      }
    }

    parsed.sort((a, b) => a.x.compareTo(b.x));

    setState(() {
      _spots = parsed;
      _freqMap = freqMap;
    });

    widget.onDataChanged(freqMap);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_spots.isNotEmpty)
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 1,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) =>
                          Text(_formatXLabel(v), style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, interval: 5),
                  ),
                ),
                extraLinesData: ExtraLinesData(horizontalLines: [
                  HorizontalLine(y: 0, color: Colors.grey, strokeWidth: 1, dashArray: [6, 4])
                ]),
                lineBarsData: [
                  LineChartBarData(
                    spots: _spots,
                    isCurved: false,
                    color: Colors.purple,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        TextButton.icon(
          icon: const Icon(Icons.folder_open),
          label: const Text("Wczytaj plik JSON"),
          onPressed: _pickFile,
        )
      ],
    );
  }
}
