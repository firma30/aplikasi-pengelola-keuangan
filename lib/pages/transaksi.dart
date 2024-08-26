// ignore_for_file: library_private_types_in_public_api, unused_field, unused_element, avoid_print, unused_local_variable

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_pengelola/controlers/chart_section.dart';
import 'package:aplikasi_pengelola/database/db_helper.dart';
import 'package:aplikasi_pengelola/database/models/transaksi.dart';
import 'package:aplikasi_pengelola/tema/tema.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_pengelola/pages/add.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  _TransactionPageState createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  Map<String, double> _categoryTotals = {};
  String _selectedCategory = 'semua';
  List<Transaction> _transactions = [];
  DateTime? _selectedDate;
  final TextEditingController _searchController = TextEditingController();

  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadChartData();
    await _loadTransactions();
  }

  void _cancelDateSearch() {
    setState(() {
      _selectedDate = null;
      _searchController.text = '';
    });
    _loadTransactions();
  }

  Future<void> _loadChartData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      List<Transaction> transactions =
          await DatabaseHelper.instance.readAllTransactions(user.uid);
      Map<String, double> totals;

      if (_selectedCategory == 'All') {
        totals = _calculateCategoryTotals(transactions, 'Pendapatan');
        totals.addAll(_calculateCategoryTotals(transactions, 'Pengeluaran'));
      } else {
        totals = _calculateCategoryTotals(transactions, _selectedCategory);
      }

      setState(() {
        _categoryTotals = totals;
      });
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) => print('onStatus: $status'),
        onError: (errorNotification) => print('onError: $errorNotification'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) => setState(() {
            _searchController.text = result.recognizedWords;
            _processVoiceCommand(result.recognizedWords);
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _processVoiceCommand(String command) {
    final weekPattern = RegExp(r'(\d+)\s+minggu lalu');
    final match = weekPattern.firstMatch(command);

    if (match != null) {
      final weeks = int.parse(match.group(1)!);
      _searchByWeeks(weeks);
    } else if (command.contains('minggu lalu')) {
      _searchByWeeks(1);
    } else if (command.contains('bulan')) {
      _searchByMonth(command);
    } else if (command.contains('tahun')) {
      _searchByYear(command);
    }
  }

  void _searchByWeeks(int weeks) {
    final now = DateTime.now();
    final targetDate = now.subtract(Duration(days: 7 * weeks));
    setState(() {
      _selectedDate = targetDate;
      _searchController.text = '$weeks minggu lalu';
    });
    _loadTransactions();
  }

  void _searchByMonth(String command) {
    final months = [
      'januari',
      'februari',
      'maret',
      'april',
      'mei',
      'juni',
      'juli',
      'agustus',
      'september',
      'oktober',
      'november',
      'desember'
    ];
    for (int i = 0; i < months.length; i++) {
      if (command.toLowerCase().contains(months[i])) {
        setState(() {
          _selectedDate = DateTime(DateTime.now().year, i + 1);
          _searchController.text = 'Bulan ${months[i]}';
        });
        _loadTransactions();
        break;
      }
    }
  }

  void _searchByYear(String command) {
    final year = int.tryParse(command.replaceAll(RegExp(r'[^0-9]'), ''));
    if (year != null) {
      setState(() {
        _selectedDate = DateTime(year);
        _searchController.text = 'Tahun $year';
      });
      _loadTransactions();
    }
  }

  Future<void> _loadTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      List<Transaction> transactions =
          await DatabaseHelper.instance.readAllTransactions(user.uid);
      setState(() {
        _transactions = transactions.where((t) {
          bool categoryMatch = _selectedCategory == 'semua' ||
              t.transactionType == _selectedCategory;
          bool dateMatch = true;
          if (_selectedDate != null) {
            if (_searchController.text.contains('minggu lalu')) {
              dateMatch = t.transactionDate.isAfter(_selectedDate!) &&
                  t.transactionDate.isBefore(DateTime.now());
            } else if (_searchController.text.contains('Bulan')) {
              dateMatch = t.transactionDate.year == _selectedDate!.year &&
                  t.transactionDate.month == _selectedDate!.month;
            } else if (_searchController.text.contains('Tahun')) {
              dateMatch = t.transactionDate.year == _selectedDate!.year;
            } else {
              dateMatch = t.transactionDate.year == _selectedDate!.year &&
                  t.transactionDate.month == _selectedDate!.month &&
                  t.transactionDate.day == _selectedDate!.day;
            }
          }
          return categoryMatch && dateMatch;
        }).toList();
      });
    }
  }

  Map<String, double> _calculateCategoryTotals(
      List<Transaction> transactions, String type) {
    Map<String, double> totals = {};

    for (var transaction in transactions) {
      if (transaction.transactionType == type || type == 'semua') {
        if (totals.containsKey(transaction.categoryName)) {
          totals[transaction.categoryName] =
              totals[transaction.categoryName]! + transaction.amount;
        } else {
          totals[transaction.categoryName] = transaction.amount;
        }
      }
    }

    return totals;
  }

  void _updateSelectedCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadData();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _searchController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
      _loadTransactions();
    }
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    await DatabaseHelper.instance.deleteTransaction(transaction.id!);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi berhasil dihapus')),
    );
  }

  void _editTransaction(Transaction transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionForm(transaction: transaction),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              _buildSearchBar(),
              _buildCategoryFilter(),
              _buildHit(),
              _buildChart(),
              _buildTransactionList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHit() {
    return FutureBuilder<Widget>(
      future: _buildHitWidget(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return snapshot.data!;
        }
      },
    );
  }

  Future<Widget> _buildHitWidget() async {
    double totalIncome = 0.0;
    double totalExpense = 0.0;

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (_selectedDate != null) {
        // Jika ada filter tanggal, hitung data hanya untuk bulan yang dipilih
        totalIncome = await DatabaseHelper.instance.getTotalPendapatanByMonth(
          _selectedDate!.year,
          _selectedDate!.month,
          user.uid,
        );
        totalExpense = await DatabaseHelper.instance.getTotalPengeluaranByMonth(
          _selectedDate!.year,
          _selectedDate!.month,
          user.uid,
        );
      } else {
        // Jika tidak ada filter tanggal, tampilkan data untuk seluruh tahun
        totalIncome =
            await DatabaseHelper.instance.getPendapatanTahunan(user.uid);
        totalExpense =
            await DatabaseHelper.instance.getTotalPengeluaran(user.uid);
      }

      double balance = totalIncome - totalExpense;

      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Transaksi",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: mainFontColor,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pendapatan: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(totalIncome)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Pengeluaran: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(totalExpense)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                    if (_transactions.isNotEmpty)
                      Text(
                        'Sisa: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(balance)}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    if (_transactions.isEmpty)
                      Text(
                        'Saldo: Rp 0',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink(); // Return an empty widget if user is null
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Cari berdasarkan tanggal",
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context),
              ),
              if (_selectedDate != null)
                IconButton(
                  icon: const Icon(Icons.cancel_outlined),
                  onPressed: _cancelDateSearch,
                ),
              IconButton(
                icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                onPressed: _listen,
              ),
            ],
          ),
        ),
        readOnly: true,
        onTap: () => _selectDate(context),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCategoryButton('semua'),
          _buildCategoryButton('Pendapatan'),
          _buildCategoryButton('Pengeluaran'),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String category) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedCategory == category ? buttoncolor : white,
      ),
      onPressed: () => _updateSelectedCategory(category),
      child: Text(
        category,
        style: TextStyle(
          color: _selectedCategory == category ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildChart() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ChartSection(
        title: 'Grafik Pendapatan dan Pengeluaran',
        categoryTotals: _categoryTotals,
      ),
    );
  }

  Widget _buildTransactionList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return Dismissible(
          key: Key(transaction.id.toString()),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            _deleteTransaction(transaction);
          },
          child: ListTile(
            leading: Icon(
              transaction.transactionType == 'Pendapatan'
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: transaction.transactionType == 'Pendapatan'
                  ? Colors.green
                  : Colors.red,
            ),
            title: Text(transaction.categoryName),
            subtitle: Text(
                DateFormat('dd-MM-yyyy').format(transaction.transactionDate)),
            trailing: Text(
              NumberFormat.currency(
                      locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
                  .format(transaction.amount),
              style: TextStyle(
                color: transaction.transactionType == 'Pendapatan'
                    ? Colors.green
                    : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => _editTransaction(transaction),
          ),
        );
      },
    );
  }
}
