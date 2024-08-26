// ignore_for_file: unused_import, avoid_print

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class ChartSection extends StatelessWidget {
  final String title;
  final Map<String, double> categoryTotals;

  const ChartSection({
    super.key,
    required this.title,
    required this.categoryTotals,
  });

  @override
  Widget build(BuildContext context) {
    print('Category Totals for $title: $categoryTotals');

    if (categoryTotals.isEmpty) {
      return Center(
        child: Text('No data available for $title'),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: _buildPieChartSections(),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 0,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildLegend(),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final total =
        categoryTotals.values.fold<double>(0, (sum, value) => sum + value);

    return categoryTotals.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: _getColorForCategory(entry.key),
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categoryTotals.entries.map((entry) {
        return Row(
          children: [
            Container(
              width: 16,
              height: 16,
              color: _getColorForCategory(entry.key),
            ),
            const SizedBox(width: 8),
            Text(
              entry.key,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _getColorForCategory(String category) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.pink,
      Colors.teal,
      Colors.lime,
    ];

    final index = category.hashCode % colors.length;
    return colors[index];
  }
}
