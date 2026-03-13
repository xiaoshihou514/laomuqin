import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/timer_analytics.dart';
import '../../l10n/app_localizations.dart';
import 'analytics_viewmodel.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AnalyticsView();
  }
}

class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView();

  static const _seriesColors = <Color>[
    Color(0xFF1976D2),
    Color(0xFF43A047),
    Color(0xFFFB8C00),
    Color(0xFF8E24AA),
    Color(0xFFE53935),
    Color(0xFF00897B),
    Color(0xFF6D4C41),
    Color(0xFF3949AB),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final viewModel = context.watch<AnalyticsViewModel>();
    final snapshot = viewModel.snapshot;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.analyticsTitle)),
      body: ListenableBuilder(
        listenable: viewModel.load,
        builder: (context, _) {
          if (viewModel.load.running && snapshot == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot == null || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bar_chart_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.analyticsEmptyTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.analyticsEmptyDesc,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }

          final colorMap = <String, Color>{};
          for (var i = 0; i < snapshot.series.length; i++) {
            colorMap[snapshot.series[i].key] =
                _seriesColors[i % _seriesColors.length];
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                title: l10n.analyticsRecentByTaskTitle,
                subtitle: l10n.analyticsRecentByTaskDesc,
                child: Column(
                  children: [
                    SizedBox(
                      height: 260,
                      child: BarChart(
                        _buildRecentByTaskChart(
                          context,
                          snapshot.dailyTaskStacks,
                          snapshot.series,
                          colorMap,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: snapshot.series
                            .map(
                              (series) => _LegendChip(
                                color: colorMap[series.key]!,
                                label: series.label,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: l10n.analyticsHourlyTitle,
                subtitle: l10n.analyticsHourlyDesc,
                child: SizedBox(
                  height: 260,
                  child: BarChart(
                    _buildHourlyChart(context, snapshot.hourlyBuckets),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: l10n.analyticsDailyTotalsTitle,
                subtitle: l10n.analyticsDailyTotalsDesc,
                child: SizedBox(
                  height: 260,
                  child: BarChart(
                    _buildDailyTotalsChart(context, snapshot.dailyTotals),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  BarChartData _buildRecentByTaskChart(
    BuildContext context,
    List<DailyTaskStack> dailyStacks,
    List<TimerAnalyticsSeries> series,
    Map<String, Color> colorMap,
  ) {
    final maxY = _maxHours(
      dailyStacks.map((item) => item.totalSeconds).toList(),
    );

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      barTouchData: BarTouchData(enabled: false),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        horizontalInterval: _intervalFor(maxY),
      ),
      titlesData: _titles(
        context,
        bottomBuilder: (value, _) {
          final index = value.toInt();
          if (index < 0 || index >= dailyStacks.length) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(DateFormat('M/d').format(dailyStacks[index].day)),
          );
        },
      ),
      barGroups: List.generate(dailyStacks.length, (index) {
        final day = dailyStacks[index];
        var cursor = 0.0;
        final stacks = <BarChartRodStackItem>[];
        for (final item in series) {
          final seconds = day.secondsBySeries[item.key] ?? 0;
          if (seconds == 0) continue;
          final next = cursor + seconds / 3600.0;
          stacks.add(
            BarChartRodStackItem(cursor, next, colorMap[item.key]!),
          );
          cursor = next;
        }
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: day.totalSeconds / 3600.0,
              width: 22,
              borderRadius: BorderRadius.circular(4),
              rodStackItems: stacks,
            ),
          ],
        );
      }),
    );
  }

  BarChartData _buildHourlyChart(
    BuildContext context,
    List<HourlyWorkBucket> buckets,
  ) {
    final maxY = _maxHours(buckets.map((item) => item.totalSeconds).toList());
    final colorScheme = Theme.of(context).colorScheme;

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      barTouchData: BarTouchData(enabled: false),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(show: true, horizontalInterval: _intervalFor(maxY)),
      titlesData: _titles(
        context,
        bottomBuilder: (value, _) {
          final hour = value.toInt();
          if (hour < 0 || hour > 23 || hour.isOdd) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(hour.toString().padLeft(2, '0')),
          );
        },
      ),
      barGroups: buckets
          .map(
            (bucket) => BarChartGroupData(
              x: bucket.hour,
              barRods: [
                BarChartRodData(
                  toY: bucket.totalSeconds / 3600.0,
                  width: 10,
                  color: colorScheme.secondary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  BarChartData _buildDailyTotalsChart(
    BuildContext context,
    List<DailyWorkBucket> buckets,
  ) {
    final maxY = _maxHours(buckets.map((item) => item.totalSeconds).toList());
    final colorScheme = Theme.of(context).colorScheme;

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      barTouchData: BarTouchData(enabled: false),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(show: true, horizontalInterval: _intervalFor(maxY)),
      titlesData: _titles(
        context,
        bottomBuilder: (value, _) {
          final index = value.toInt();
          if (index < 0 || index >= buckets.length) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(DateFormat('M/d').format(buckets[index].day)),
          );
        },
      ),
      barGroups: List.generate(
        buckets.length,
        (index) => BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: buckets[index].totalSeconds / 3600.0,
              width: 22,
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  FlTitlesData _titles(
    BuildContext context, {
    required Widget Function(double value, TitleMeta meta) bottomBuilder,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 42,
          getTitlesWidget: (value, meta) => Text(
            _formatHours(value),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          getTitlesWidget: bottomBuilder,
        ),
      ),
    );
  }

  double _maxHours(List<int> seconds) {
    final maxSeconds = seconds.fold<int>(0, math.max);
    final hours = maxSeconds / 3600.0;
    if (hours <= 1) return 1.0;
    return (hours * 1.2).ceilToDouble();
  }

  double _intervalFor(double maxY) {
    if (maxY <= 1) return 0.25;
    if (maxY <= 4) return 1;
    if (maxY <= 8) return 2;
    return (maxY / 4).ceilToDouble();
  }

  String _formatHours(double value) {
    if (value == 0) return '0';
    if (value < 1) return '${(value * 60).round()}m';
    if (value < 10) return '${value.toStringAsFixed(1)}h';
    return '${value.round()}h';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}
