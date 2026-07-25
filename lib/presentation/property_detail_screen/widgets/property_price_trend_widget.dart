import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class PropertyPriceTrendWidget extends StatelessWidget {
  final String neighborhood;

  const PropertyPriceTrendWidget({super.key, required this.neighborhood});

  // Price per m² trend for the neighborhood over 12 months
  static const List<double> _priceTrend = [
    8900,
    9050,
    8980,
    9120,
    9300,
    9180,
    9250,
    9400,
    9520,
    9480,
    9620,
    9770,
  ];

  static const List<String> _months = [
    'A',
    'M',
    'J',
    'J',
    'A',
    'S',
    'O',
    'N',
    'D',
    'J',
    'F',
    'M',
  ];

  @override
  Widget build(BuildContext context) {
    final minPrice = _priceTrend.reduce((a, b) => a < b ? a : b) - 200;
    final maxPrice = _priceTrend.reduce((a, b) => a > b ? a : b) + 200;
    final changePercent =
        ((_priceTrend.last - _priceTrend.first) / _priceTrend.first * 100);

    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tendance des prix',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      neighborhood,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: changePercent > 0
                      ? AppTheme.successLight
                      : AppTheme.errorLight,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      changePercent > 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 14,
                      color: changePercent > 0
                          ? AppTheme.success
                          : AppTheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${changePercent > 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}% / 12m',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: changePercent > 0
                            ? AppTheme.success
                            : AppTheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 300,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.border,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _months.length) {
                          return const SizedBox();
                        }
                        return Text(
                          _months[idx],
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppTheme.muted,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 11,
                minY: minPrice,
                maxY: maxPrice,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      _priceTrend.length,
                      (i) => FlSpot(i.toDouble(), _priceTrend[i]),
                    ),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppTheme.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, __, ___, ____) {
                        final isLast = spot.x == 11;
                        return FlDotCirclePainter(
                          radius: isLast ? 5 : 0,
                          color: AppTheme.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withAlpha(46),
                          AppTheme.primary.withAlpha(0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AppTheme.primary,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(0)} €/m²',
                          GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prix moyen actuel: ${_priceTrend.last.toStringAsFixed(0)} €/m²',
            style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}
