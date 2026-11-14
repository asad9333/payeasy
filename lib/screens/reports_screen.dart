
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/report_service.dart';
import '../utils/app_colors.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _service = ReportService();

  bool _monthly = true;
  late Future<ReportSummary> _report;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  void _loadReport() {
    setState(() {
      _report = _monthly ? _service.monthly() : _service.daily();
    });
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0');

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Reports',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              onPressed: _loadReport,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.lightGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              for (final entry in {'Daily': false, 'Monthly': true}.entries)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _monthly = entry.value);
                      _loadReport();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _monthly == entry.value
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _monthly == entry.value
                              ? Colors.white
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        FutureBuilder<ReportSummary>(
          future: _report,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(
                child: Text('Unable to load financial reports'),
              );
            }

            final report = snapshot.data!;
            final net = report.totalCredit - report.totalPayments;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        'Credit Entries',
                        report.totalCredit,
                        money,
                        Icons.trending_up,
                        AppColors.danger,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _summaryCard(
                        'Payments Received',
                        report.totalPayments,
                        money,
                        Icons.payments_outlined,
                        AppColors.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 13),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Net Outstanding (Credit - Payments)',
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Rs ${money.format(net)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: report.totalCredit == 0
                              ? 0
                              : (report.totalPayments / report.totalCredit)
                                  .clamp(0.0, 1.0),
                          backgroundColor: Colors.white,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        report.totalCredit == 0
                            ? 'Recovery rate: no credit entries yet'
                            : 'Recovery rate: ${(report.totalPayments / report.totalCredit * 100).clamp(0, 100).toStringAsFixed(0)}% of credit collected',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_monthly) ...[
                  const SizedBox(height: 27),

                  const Text(
                    'Monthly Transaction Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Container(
                    height: 270,
                    padding: const EdgeInsets.fromLTRB(8, 18, 18, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        gridData: const FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 35,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '${value.toInt()}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          for (int day = 1;
                              day <= DateTime(
                                DateTime.now().year,
                                DateTime.now().month + 1,
                                0,
                              ).day;
                              day++)
                            BarChartGroupData(
                              x: day,
                              barRods: [
                                BarChartRodData(
                                  toY: report.creditByDay[day] ?? 0,
                                  color: AppColors.danger,
                                  width: 5,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                BarChartRodData(
                                  toY: report.paymentByDay[day] ?? 0,
                                  color: AppColors.primary,
                                  width: 5,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.circle,
                        color: AppColors.danger,
                        size: 10,
                      ),
                      SizedBox(width: 5),
                      Text('Credit'),
                      SizedBox(width: 18),
                      Icon(
                        Icons.circle,
                        color: AppColors.primary,
                        size: 10,
                      ),
                      SizedBox(width: 5),
                      Text('Payments'),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _summaryCard(
    String title,
    double value,
    NumberFormat money,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Rs ${money.format(value)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
