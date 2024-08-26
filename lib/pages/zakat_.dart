// ignore_for_file: library_private_types_in_public_api, avoid_print, sort_child_properties_last, unused_local_variable

import 'package:aplikasi_pengelola/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_pengelola/database/db_helper.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ZakatCalculator extends StatefulWidget {
  const ZakatCalculator({super.key});

  @override
  _ZakatCalculatorState createState() => _ZakatCalculatorState();
}

class _ZakatCalculatorState extends State<ZakatCalculator> {
  double _pendapatanTahunan = 0.0;
  double _pendapatanBulanan = 0.0;
  double _zakat = 0.0;
  double _zakatBulanan = 0.0;
  final _formatCurrency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
  String? userId;
  final double _hargaEmasPerGram = 1570000.0; // Harga emas per gram
  final double _nishabTahunan = 1570000.0 * 85; // 85 gram emas

  @override
  void initState() {
    super.initState();
    _getUserIdAndLoadData();
  }

  Future<void> _getUserIdAndLoadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
      await _loadPendapatanDanHitungZakat();
    } else {
      print('User not logged in');
    }
  }

  Future<void> _loadPendapatanDanHitungZakat() async {
    if (userId == null) {
      print('UserId is null');
      return;
    }
    try {
      double pendapatanTahunan =
          await DatabaseHelper.instance.getPendapatanTahunan(userId!);
      setState(() {
        _pendapatanTahunan = pendapatanTahunan;
        _pendapatanBulanan = _pendapatanTahunan / 12;
        if (_pendapatanTahunan >= _nishabTahunan) {
          _zakat = _pendapatanTahunan * 0.025;
          _zakatBulanan = _zakat / 12;
        } else {
          _zakat = 0;
          _zakatBulanan = 0;
        }
      });
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    User? user = FirebaseAuth.instance.currentUser;
    String userName = user?.displayName ?? 'Pengguna Aplikasi';
    String userEmail = user?.email ?? 'No email';

    return Scaffold(
      backgroundColor: primary, // Match the background color
      appBar: AppBar(
        title: const Text('Perhitungan Zakat Tahunan'),
        backgroundColor: primary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPendapatanDanHitungZakat,
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
                    // mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Zakat Calculation Details
                      Text(
                        'Pendapatan Tahunan: ${_formatCurrency.format(_pendapatanTahunan)}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text(
                        'Rata-rata Pendapatan Bulanan: ${_formatCurrency.format(_pendapatanBulanan)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      if (_pendapatanTahunan >= _nishabTahunan)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Zakat yang Harus Dibayar Tahunan: ${_formatCurrency.format(_zakat)}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                            Text(
                              'Zakat yang Harus Dibayar Bulanan: ${_formatCurrency.format(_zakatBulanan)}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                          ],
                        )
                      else
                        const Text(
                          'Pendapatan belum mencapai nishab. Zakat tidak wajib.',
                          style: TextStyle(fontSize: 16, color: Colors.orange),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 25),
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
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Zakat dihitung sebesar 2.5% dari pendapatan tahunan jika pendapatan tahunan mencapai atau melebihi nishab ${_formatCurrency.format(_nishabTahunan)} '
                    '(setara dengan 85 gram emas dengan harga ${_formatCurrency.format(_hargaEmasPerGram)} per gram).',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadPendapatanDanHitungZakat,
        child: const Icon(Icons.refresh),
        tooltip: 'Refresh Data',
      ),
    );
  }
}
