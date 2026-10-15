import 'dart:convert';

import 'package:checkmk_api/checkmk_api.dart' as cmk_api;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:letscheck/cmk_colors.dart';
import 'package:letscheck/providers/providers.dart';
import 'package:letscheck/widget/site_stats_widget.dart';
import 'package:letscheck/screen/slim/slim_layout.dart';

/// Max number of metric graphs shown per service.
const _maxGraphs = 8;

const _ranges = <String, Duration>{
  '4h': Duration(hours: 4),
  '25h': Duration(hours: 25),
  '1w': Duration(days: 7),
};

class ServiceScreen extends ConsumerStatefulWidget {
  final String alias;
  final String hostname;
  final String service;

  ServiceScreen({
    required this.alias,
    required this.hostname,
    required this.service,
  });

  @override
  ServiceScreenState createState() => ServiceScreenState();
}

class ServiceScreenState extends ConsumerState<ServiceScreen> {
  String _range = '4h';
  late Future<_ServiceData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_ServiceData> _load() async {
    final client = await ref.read(clientProvider(widget.alias).future);
    final services = await client.getApiServices(filter: [
      jsonEncode({"op": "=", "left": "host_name", "right": widget.hostname}),
      jsonEncode({"op": "=", "left": "description", "right": widget.service}),
    ]);
    final names = await client.getApiServiceMetricNames(
        widget.hostname, widget.service);
    final series = await Future.wait(names.take(_maxGraphs).map((m) => client
        .getApiMetric(widget.hostname, widget.service, m,
            duration: _ranges[_range]!)
        .then<cmk_api.MetricSeries?>((s) => s)
        .catchError((_) => null)));
    return _ServiceData(
      service: services.isNotEmpty ? services.first : null,
      series: series.whereType<cmk_api.MetricSeries>().toList(),
    );
  }

  void _setRange(String r) {
    setState(() {
      _range = r;
      _data = _load();
    });
  }

  SlimLayoutSettings settings() {
    var serviceName = widget.service;
    if (serviceName.length > 25) {
      serviceName = serviceName.substring(0, 25);
    }
    return SlimLayoutSettings("Service $serviceName",
        showMenu: false, showSearch: false);
  }

  @override
  Widget build(BuildContext context) {
    return SlimLayout(
      layoutSettings: settings(),
      child: Column(
        children: [
          SiteStatsWidget(alias: widget.alias),
          Expanded(
            child: FutureBuilder<_ServiceData>(
              future: _data,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final d = snap.data!;
                return ListView(
                  padding: EdgeInsets.all(8),
                  children: [
                    if (d.service != null) _StatusCard(service: d.service!),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: SegmentedButton<String>(
                        segments: _ranges.keys
                            .map((k) => ButtonSegment(value: k, label: Text(k)))
                            .toList(),
                        selected: {_range},
                        onSelectionChanged: (s) => _setRange(s.first),
                      ),
                    ),
                    if (d.series.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                            child: Text('No metrics for this service',
                                style: TextStyle(color: CmkColors.textMuted))),
                      ),
                    ...d.series.map((s) => _MetricCard(series: s)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceData {
  final cmk_api.Service? service;
  final List<cmk_api.MetricSeries> series;
  _ServiceData({required this.service, required this.series});
}

Color _stateColor(int state) {
  switch (state) {
    case cmk_api.svcStateOk:
      return CmkColors.ok;
    case cmk_api.svcStateWarn:
      return CmkColors.warn;
    case cmk_api.svcStateCritical:
      return CmkColors.crit;
    default:
      return CmkColors.unknown;
  }
}

String _stateLabel(int state) {
  switch (state) {
    case cmk_api.svcStateOk:
      return 'OK';
    case cmk_api.svcStateWarn:
      return 'WARN';
    case cmk_api.svcStateCritical:
      return 'CRIT';
    default:
      return 'UNKN';
  }
}

class _StatusCard extends StatelessWidget {
  final cmk_api.Service service;
  _StatusCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              padding: EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: _stateColor(service.state),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(_stateLabel(service.state),
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(service.pluginOutput ?? '',
                  style: TextStyle(color: CmkColors.text)),
            ),
          ],
        ),
      ),
    );
  }
}

Color _parseColor(String? hex) {
  if (hex == null || !hex.startsWith('#') || hex.length != 7) {
    return CmkColors.accent;
  }
  return Color(int.parse('FF${hex.substring(1)}', radix: 16));
}

String _fmt(double v) {
  final a = v.abs();
  if (a >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}G';
  if (a >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
  if (a >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}k';
  if (a >= 10 || a == 0) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2);
}

class _MetricCard extends StatelessWidget {
  final cmk_api.MetricSeries series;
  _MetricCard({required this.series});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(series.color);
    final spots = <FlSpot>[];
    for (var i = 0; i < series.points.length; i++) {
      final v = series.points[i];
      spots.add(v == null ? FlSpot.nullSpot : FlSpot(i.toDouble(), v));
    }
    final values = series.points.whereType<double>();
    final last = values.isNotEmpty ? values.last : null;
    final span = series.points.length * series.step;
    final timeFmt = span > 86400 ? DateFormat('E HH:mm') : DateFormat('HH:mm');

    return Card(
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, 10, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 8, bottom: 8),
              child: Row(
                children: [
                  Container(width: 10, height: 10, color: color),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(series.title,
                        style: TextStyle(
                            color: CmkColors.text,
                            fontWeight: FontWeight.w600)),
                  ),
                  if (last != null)
                    Text(_fmt(last),
                        style: TextStyle(color: CmkColors.textMuted)),
                ],
              ),
            ),
            SizedBox(
              height: 150,
              child: values.isEmpty
                  ? Center(
                      child: Text('No data',
                          style: TextStyle(color: CmkColors.textMuted)))
                  : LineChart(
                      LineChartData(
                        minY: values.reduce((a, b) => a < b ? a : b) >= 0
                            ? 0
                            : null,
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) => CmkColors.surfaceHigh,
                            getTooltipItems: (items) => items.map((it) {
                              final t = series.start.add(Duration(
                                  seconds: it.x.toInt() * series.step));
                              return LineTooltipItem(
                                  '${timeFmt.format(t.toLocal())}\n${_fmt(it.y)}',
                                  TextStyle(color: CmkColors.text));
                            }).toList(),
                          ),
                        ),
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(
                              color: CmkColors.border, strokeWidth: 0.5),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: AxisTitles(),
                          rightTitles: AxisTitles(),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (v, meta) => Text(_fmt(v),
                                  style: TextStyle(
                                      color: CmkColors.textMuted,
                                      fontSize: 10)),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 20,
                              interval: (series.points.length / 4)
                                  .clamp(1, double.infinity)
                                  .toDouble(),
                              getTitlesWidget: (v, meta) {
                                final t = series.start.add(
                                    Duration(seconds: v.toInt() * series.step));
                                return Text(timeFmt.format(t.toLocal()),
                                    style: TextStyle(
                                        color: CmkColors.textMuted,
                                        fontSize: 10));
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            color: color,
                            barWidth: 1.5,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                                show: true,
                                color: color.withValues(alpha: 0.25)),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
