import 'dart:async';
import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vision_score/services/app_settings.dart';
import 'package:vision_score/utils/model/extract_params.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double duration = AppSettings.duration;

  bool optimize = AppSettings.useOptimized;

  bool benchRunning = false;
  String benchStatus = "";
  List<Map<String, dynamic>> benchResults = [];

  Future<void> runBenchmark(BuildContext context) async {
    if (benchRunning) return;

    setState(() {
      benchRunning = true;
      benchStatus = "Preparing models…";
    });

    final extractor = ExtractParams();
    await extractor.init();
    benchResults = [];

    try {
      for (int i = 1; i <= 25; i++) {
        final imgAsset = "assets/sample/img_$i.jpg";

        setState(() {
          benchStatus = "Processing...";
        });

        final bytes = await DefaultAssetBundle.of(context).load(imgAsset);
        final Uint8List imgBytes = bytes.buffer.asUint8List();

        extractor.useOptimized = false;
        final unopt = await extractor.extractParamsFromImage(imgBytes);

        extractor.useOptimized = true;
        final opt = await extractor.extractParamsFromImage(imgBytes);

        benchResults.add({
          "image": "img_$i.png",
          "feat_unopt": unopt["feat_ms"],
          "feat_opt": opt["feat_ms"],
          "music_unopt": unopt["music_ms"],
          "music_opt": opt["music_ms"],
        });
        setState(() {});

        print(benchResults);

        
      }

      // setState(() => benchStatus = "Generating PDF…");

      // final pdfPath = await PDFGenerator.generateBenchmarkReport(benchResults);

      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Benchmark saved: $pdfPath")),
      // );
      setState(() {
        benchStatus = "Completed!";
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Benchmark failed: $e")));
    }

    setState(() {
      benchRunning = false;
      benchStatus = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Settings"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("Audio Duration"),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _box,
            child: Column(
              children: [
                Text(
                  "${duration.toStringAsFixed(0)} seconds",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Slider(
                  value: duration,
                  min: 4,
                  max: 20,
                  divisions: 16,
                  label: "${duration.toInt()}",
                  onChanged: (v) => setState(() => duration = v),
                  onChangeEnd: (v) {
                    AppSettings.setDuration(v);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _sectionTitle("Model Optimization"),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _box,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.greenAccent,
              value: optimize,
              title: const Text(
                "Use FP16 Optimized Models",
                style: TextStyle(color: Colors.white),
              ),
              onChanged: (v) {
                setState(() => optimize = v);
                AppSettings.setOptimized(v);
              },
            ),
          ),

          const SizedBox(height: 20),


          _sectionTitle("Benchmark Engine"),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: _box,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Run optimized + unoptimized models over sample images.",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),

                  ElevatedButton.icon(
                    icon: const Icon(LucideIcons.gauge),
                    label: Text(benchRunning ? "Running…" : "Run Benchmark"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                    onPressed: benchRunning
                        ? null
                        : () => runBenchmark(context),
                  ),

                  if (benchRunning || benchResults.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      benchStatus,
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ],

                  if (benchResults.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      "Performance Graph",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 20,),
                    SizedBox(
                      height: 350, // container height that can scroll inside
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildBenchmarkChart(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBenchmarkChart() {
    List<FlSpot> featUnopt = [];
    List<FlSpot> featOpt = [];
    List<FlSpot> mlpUnopt = [];
    List<FlSpot> mlpOpt = [];

    for (int i = 0; i < benchResults.length; i++) {
      final r = benchResults[i];
      final x = i.toDouble();

      featUnopt.add(FlSpot(x, (r["feat_unopt"] as num).toDouble()));
      featOpt.add(FlSpot(x, (r["feat_opt"] as num).toDouble()));
      mlpUnopt.add(FlSpot(x, (r["music_unopt"] as num).toDouble()));
      mlpOpt.add(FlSpot(x, (r["music_opt"] as num).toDouble()));
    }

    return Column(
      children: [
        SizedBox(
          height: 300, 
          child: LineChart(
            LineChartData(
              backgroundColor: Colors.transparent,

              minX: 0,
              maxX: benchResults.length.toDouble() - 1,


              gridData: FlGridData(show: false),

  
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),

              // SMOOTH LOOK
              lineBarsData: [
                _line(featUnopt, Colors.redAccent, "FE Unopt"),
                _line(featOpt, Colors.greenAccent, "FE Opt"),
                _line(mlpUnopt, Colors.orangeAccent, "MLP Unopt"),
                _line(mlpOpt, Colors.cyanAccent, "MLP Opt"),
              ],


              borderData: FlBorderData(
                show: true,
                border: const Border(
                  left: BorderSide(color: Colors.white24, width: 1),
                  bottom: BorderSide(color: Colors.white24, width: 1),
                ),
              ),
            ),
          ),
        ),
        _buildChartLegend(),
      ],
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color, String name) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: FlDotData(show: false),
    );
  }

  Widget _buildChartLegend() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem(Colors.redAccent, "FE Unopt"),
          _legendItem(Colors.greenAccent, "FE Opt"),
          _legendItem(Colors.orangeAccent, "MLP Unopt"),
          _legendItem(Colors.cyanAccent, "MLP Opt"),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  BoxDecoration get _box => BoxDecoration(
    color: const Color(0xFF171A22),
    borderRadius: BorderRadius.circular(14),
  );
}
