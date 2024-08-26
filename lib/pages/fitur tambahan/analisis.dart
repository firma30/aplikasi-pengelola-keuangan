// ignore_for_file: library_private_types_in_public_api, sized_box_for_whitespace, avoid_print, unused_local_variable, unused_field

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_pengelola/database/db_helper.dart';
import 'package:aplikasi_pengelola/database/models/transaksi.dart';
import 'package:aplikasi_pengelola/tema/tema.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalisisPage extends StatefulWidget {
  const AnalisisPage({super.key});

  @override
  _AnalisisPageState createState() => _AnalisisPageState();
}

class _AnalisisPageState extends State<AnalisisPage> {
  List<Transaction> _transactions = [];
  Map<String, double> _trendAnalysis = {};
  List<FlSpot> _trendSpots = [];
  List<String> _monthLabels = [];
  bool _isLoading = true;
  String _errorMessage = '';
  double _expensePercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _loadTransactions();
      await _performTrendAnalysis();
      _expensePercentage = await _calculateExpensePercentage();
      _showExpenseWarning(_expensePercentage);
    } catch (e) {
      print("Error in _loadData: $e");
      setState(() {
        _errorMessage = 'Terjadi kesalahan saat memuat data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _transactions =
          await DatabaseHelper.instance.readAllTransactions(user.uid);
      print("Loaded ${_transactions.length} transactions");
    } else {
      print("No user logged in");
    }
  }

  Future<void> _performTrendAnalysis() async {
    var expenses =
        _transactions.where((t) => t.transactionType == 'Pengeluaran').toList();
    print("Number of expense transactions: ${expenses.length}");

    if (expenses.length < 2) {
      print("Not enough data for trend analysis");
      setState(() {
        _trendAnalysis = {
          'nextMonthPrediction': 0,
          'averageExpense': expenses.isEmpty ? 0 : expenses.first.amount,
        };
        _trendSpots = [];
      });
      return;
    }

    var monthlyExpenses = <DateTime, double>{};
    for (var expense in expenses) {
      var key =
          DateTime(expense.transactionDate.year, expense.transactionDate.month);
      monthlyExpenses[key] = (monthlyExpenses[key] ?? 0) + expense.amount;
    }
    print("Monthly expenses: $monthlyExpenses");

    if (monthlyExpenses.length < 2) {
      print("Not enough monthly data for trend analysis");
      setState(() {
        _trendAnalysis = {
          'nextMonthPrediction': 0,
          'averageExpense': monthlyExpenses.values.first,
        };
        _trendSpots = [];
      });
      return;
    }

    // Simple linear regression
    var sortedData = monthlyExpenses.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    int n = sortedData.length;

    for (int i = 0; i < n; i++) {
      double x = i.toDouble();
      double y = sortedData[i].value;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    double intercept = (sumY - slope * sumX) / n;

    double nextMonthPrediction = slope * n + intercept;
    double averageExpense = sumY / n;

    setState(() {
      _trendAnalysis = {
        'nextMonthPrediction': nextMonthPrediction,
        'averageExpense': averageExpense,
      };

      _trendSpots = sortedData.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value.value);
      }).toList();
      _trendSpots.add(FlSpot(n.toDouble(), nextMonthPrediction));

      var seenMonths = <String>{};
      _monthLabels = sortedData.asMap().entries.map((entry) {
        var monthLabel = DateFormat('MMM').format(entry.value.key);
        if (seenMonths.contains(monthLabel)) {
          return '';
        } else {
          seenMonths.add(monthLabel);
          return monthLabel;
        }
      }).toList();
      _monthLabels.add('Pred'); // Label untuk bulan prediksi
    });

    print("Trend analysis completed: $_trendAnalysis");
    print("Trend spots: $_trendSpots");
  }

  Future<double> _calculateExpensePercentage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0.0;

    final now = DateTime.now();
    final income = await DatabaseHelper.instance
        .getTotalPendapatanByMonth(now.year, now.month, user.uid);
    final expense = await DatabaseHelper.instance
        .getTotalPengeluaranByMonth(now.year, now.month, user.uid);

    if (income == 0) return 100.0; // Untuk menghindari pembagian dengan nol
    return (expense / income) * 100;
  }

  void _showExpenseWarning(double percentage) {
    if (percentage >= 70) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Peringatan: Pengeluaran Anda sudah mencapai ${percentage.toStringAsFixed(1)}% dari pendapatan bulan ini.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    String userName =
        FirebaseAuth.instance.currentUser?.displayName ?? 'Pengguna Aplikasi';
    String userEmail = FirebaseAuth.instance.currentUser?.email ?? 'No email';

    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
        title: const Text('Analisis Tren'),
        backgroundColor: primary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 50),
              Container(
                margin: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.03),
                      spreadRadius: 10,
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTrendAnalysis(),
                      const SizedBox(height: 20),
                      _buildTrendChart(),
                      const SizedBox(height: 20),
                      _buildFinancialAdvice(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendAnalysis() {
    if (_trendAnalysis.isEmpty) {
      return const Center(
          child: Text('Tidak ada data yang cukup untuk analisis tren'));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Analisis Tren',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
                'Prediksi pengeluaran bulan depan: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(_trendAnalysis['nextMonthPrediction'])}'),
            Text(
                'Rata-rata pengeluaran bulanan: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(_trendAnalysis['averageExpense'])}'),
            Text(
                'Persentase pengeluaran bulan ini: ${_expensePercentage.toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    if (_trendSpots.isEmpty) {
      return Container(
        height: 300,
        child: const Center(
          child:
              Text('Tidak ada data yang cukup untuk menampilkan grafik tren'),
        ),
      );
    }
    return Container(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 &&
                      index < _monthLabels.length &&
                      _monthLabels[index].isNotEmpty) {
                    return Text(
                      _monthLabels[index],
                      style: const TextStyle(
                        color: Color(0xff68737d),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: true),
          minX: 0,
          maxX: _trendSpots.length.toDouble() - 1,
          minY: 0,
          maxY:
              _trendSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: _trendSpots,
              isCurved: true,
              color: blue,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: blue,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData:
                  BarAreaData(show: true, color: blue.withOpacity(0.3)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialAdvice() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saran Penggunaan Keuangan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('1. Buatlah anggaran bulanan dan patuhi.'),
            Text('2. Prioritaskan pengeluaran untuk kebutuhan dasar.'),
            Text('3. Sisihkan minimal 20% pendapatan untuk tabungan.'),
            Text('4. Hindari pengeluaran impulsif dan tidak perlu.'),
            Text('5. Pantau pengeluaran Anda secara teratur.'),
          ],
        ),
      ),
    );
  }
}
