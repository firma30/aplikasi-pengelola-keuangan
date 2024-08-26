// ignore_for_file: unused_field, library_prefixes, unused_import, library_private_types_in_public_api, avoid_print, use_build_context_synchronously, unused_element, unused_local_variable

import 'package:aplikasi_pengelola/database/db_helper.dart' as dbHelper;
import 'package:aplikasi_pengelola/database/db_helper.dart';
import 'package:aplikasi_pengelola/database/models/kategory.dart' as category;
import 'package:aplikasi_pengelola/database/models/kategory.dart';
import 'package:aplikasi_pengelola/database/models/transaksi.dart' as transaksi;
import 'package:aplikasi_pengelola/tema/tema.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:intl/intl.dart';
import 'package:sqflite_common/sqlite_api.dart';

class TransactionForm extends StatefulWidget {
  final transaksi.Transaction? transaction;

  const TransactionForm({super.key, this.transaction});

  @override
  _TransactionFormState createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm>
    with SingleTickerProviderStateMixin {
  String _transactionType = 'Pendapatan';
  String? _selectedCategory;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "id_ID");

  List<String> _incomeCategories = [];
  List<String> _expenseCategories = [];

  late AnimationController _controller;
  late Animation<double> _animation;

  transaksi.Transaction? _editingTransaction;

  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _editingTransaction = widget.transaction;
    if (_editingTransaction != null) {
      _transactionType = _editingTransaction!.transactionType;
      _selectedCategory = _editingTransaction!.categoryName;
      _amountController.text =
          _currencyFormat.format(_editingTransaction!.amount);
      _noteController.text = _editingTransaction!.description;
      _dateController.text =
          DateFormat('dd-MM-yyyy').format(_editingTransaction!.transactionDate);
    }
    _loadKategori();
    _amountController.addListener(_formatAmount);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _amountController.removeListener(_formatAmount);
    _amountController.dispose();
    _noteController.dispose();
    _dateController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _updateField(String field, String value) {
    if (field == 'amount') {
      value = value.toLowerCase();

      // Proses angka yang mengandung 'juta'
      if (value.contains('juta')) {
        value = value.replaceAll('juta', '').trim();

        // Jika tidak ada angka setelah 'juta', tambahkan 1
        if (value.isEmpty) {
          value = '1';
        }

        double numericValue = double.tryParse(value) ?? 0;
        value = (numericValue * 1000000).toString();
      }

      // Proses angka yang mengandung 'ribu'
      else if (value.contains('ribu')) {
        value = value.replaceAll('ribu', '').trim();

        // Jika tidak ada angka setelah 'ribu', tambahkan 1
        if (value.isEmpty) {
          value = '1';
        }

        double numericValue = double.tryParse(value) ?? 0;
        value = (numericValue * 1000).toString();
      }

      // Hapus karakter non-angka jika ada
      value = value.replaceAll(RegExp(r'[^0-9]'), '');

      _amountController.text = _currencyFormat.format(double.parse(value));
    } else if (field == 'note') {
      _noteController.text = value;
    } else if (field == 'date') {
      _dateController.text = value;
    }
  }

  void _formatAmount() {
    String text = _amountController.text.replaceAll('.', '');
    if (text.isEmpty) return;

    double value = double.parse(text);
    String formatted = _currencyFormat.format(value);

    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  void _saveTransaction() async {
    if (_amountController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Jumlah, Tanggal, dan Kategori harus diisi')),
      );
      return;
    }

    double amount =
        double.tryParse(_amountController.text.replaceAll('.', '')) ?? -1;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih besar dari nol')),
      );
      return;
    }

    try {
      final dateFormat = DateFormat('dd-MM-yyyy');

      if (!_isValidDateFormat(_dateController.text, dateFormat)) {
        throw const FormatException('Invalid date format');
      }

      DateTime parsedDate = dateFormat.parse(_dateController.text);
      DateTime currentTime = DateTime.now();

      DateTime combinedDateTime = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        currentTime.hour,
        currentTime.minute,
        currentTime.second,
      );

      int categoryId = _getCategoryId(_selectedCategory!);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final transaction = transaksi.Transaction(
          id: _editingTransaction?.id,
          userId: user.uid,
          categoryId: categoryId,
          categoryName: _selectedCategory!,
          amount: amount,
          transactionType: _transactionType,
          transactionDate: combinedDateTime,
          description: _noteController.text,
        );

        final databaseHelper = dbHelper.DatabaseHelper();
        if (_editingTransaction == null) {
          await databaseHelper.insertTransaction(transaction);
        } else {
          await databaseHelper.updateTransaction(transaction);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_editingTransaction == null
                  ? 'Transaksi berhasil disimpan'
                  : 'Transaksi berhasil diperbarui')),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan')),
      );
    }
  }

  bool _isValidDateFormat(String date, DateFormat format) {
    try {
      format.parseStrict(date);
      return true;
    } catch (e) {
      return false;
    }
  }

  int _getCategoryId(String categoryName) {
    // Implementasi untuk mendapatkan ID kategori berdasarkan nama
    return 0; // Ganti dengan ID kategori yang sesuai
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  void _addCategory() async {
    TextEditingController categoryController = TextEditingController();
    String selectedType = _transactionType;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Kategori Baru'),
          content: TextField(
            controller: categoryController,
            decoration: const InputDecoration(
              labelText: 'Nama Kategori',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final namaKategori = categoryController.text;

                if (namaKategori.isNotEmpty) {
                  final databaseHelper = dbHelper.DatabaseHelper();
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await databaseHelper.insertKategori(
                        namaKategori, selectedType, user.uid);

                    await _loadKategori();
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text('Tambah'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadKategori() async {
    final databaseHelper = dbHelper.DatabaseHelper();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final List<category.Category> kategoriList =
          await databaseHelper.getKategori(user.uid);

      setState(() {
        _incomeCategories = kategoriList
            .where((e) => e.type == 'Pendapatan')
            .map((e) => e.name)
            .toSet()
            .toList();

        _expenseCategories = kategoriList
            .where((e) => e.type == 'Pengeluaran')
            .map((e) => e.name)
            .toSet()
            .toList();

        if (_selectedCategory != null &&
            !_incomeCategories.contains(_selectedCategory) &&
            !_expenseCategories.contains(_selectedCategory)) {
          _selectedCategory = null;
        }
      });
    }
  }

  void _showAddCategoryDialog() {
    _addCategory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            _editingTransaction == null ? 'Tambah Transaksi' : 'Edit Transaksi',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: buttoncolor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [buttoncolor, Colors.white],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildTransactionTypeButton('Pendapatan'),
                            const SizedBox(width: 10),
                            _buildTransactionTypeButton('Pengeluaran'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _amountController,
                          label: 'Jumlah',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdownField(
                                label: 'Pilih Kategori',
                                value: _selectedCategory,
                                items: _transactionType == 'Pendapatan'
                                    ? _incomeCategories
                                    : _expenseCategories,
                                onChanged: (newValue) {
                                  setState(() {
                                    _selectedCategory = newValue;
                                  });
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle,
                                  color: buttoncolor),
                              onPressed: _showAddCategoryDialog,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _noteController,
                          label: 'Catatan',
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _dateController,
                          label: 'Tanggal',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(context),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              _controller.forward(from: 0.0);
                              _saveTransaction();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttoncolor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text(
                              'Simpan Transaksi',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        backgroundColor: buttoncolor,
        child: const Icon(Icons.mic),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
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
            _processSpeechInput(result.recognizedWords);
          }),
          localeId: 'id_ID', // Gunakan locale Bahasa Indonesia
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _processSpeechInput(String input) {
    input = input.toLowerCase();
    List<String> words = input.split(' ');

    // Cek tipe transaksi
    if (input.contains('tambahkan pendapatan')) {
      _transactionType = 'Pendapatan';
    } else if (input.contains('tambahkan pengeluaran')) {
      _transactionType = 'Pengeluaran';
    }

    // Cari jumlah
    RegExp amountRegex = RegExp(r'\d+(\.\d+)?');
    Match? amountMatch = amountRegex.firstMatch(input);
    if (amountMatch != null) {
      String amountStr = amountMatch.group(0)!;
      double amount = double.parse(amountStr.replaceAll('.', ''));
      if (input.contains('ribu')) {
        amount *= 1000;
      } else if (input.contains('juta')) {
        amount *= 1000000;
      }
      _amountController.text = _currencyFormat.format(amount);
    }

    List<String> availableCategories = _transactionType == 'Pendapatan'
        ? _incomeCategories
        : _expenseCategories;

    // Cari kategori
    for (String category in availableCategories) {
      if (input.toLowerCase().contains(category.toLowerCase())) {
        _selectedCategory = category;
        break;
      }
    }

    // Jika kategori tidak ditemukan, set ke null atau kategori default
    if (_selectedCategory == null) {}

    // Cari tanggal
    if (input.contains('hari ini')) {
      _dateController.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
    } else if (input.contains('kemarin')) {
      _dateController.text = DateFormat('dd-MM-yyyy')
          .format(DateTime.now().subtract(const Duration(days: 1)));
    } else if (input.contains('besok')) {
      _dateController.text = DateFormat('dd-MM-yyyy')
          .format(DateTime.now().add(const Duration(days: 1)));
    } else {
      // Coba cari tanggal spesifik dalam format dd-MM-yyyy
      RegExp dateRegex = RegExp(r'\d{2}-\d{2}-\d{4}');
      Match? dateMatch = dateRegex.firstMatch(input);
      if (dateMatch != null) {
        _dateController.text = dateMatch.group(0)!;
      }
    }

    // Update UI
    setState(() {});
  }

  String _getDateFromKeyword(String keyword) {
    DateTime now = DateTime.now();
    if (keyword == 'hari') {
      return DateFormat('dd-MM-yyyy').format(now);
    } else if (keyword == 'kemarin') {
      return DateFormat('dd-MM-yyyy')
          .format(now.subtract(const Duration(days: 1)));
    } else if (keyword == 'besok') {
      return DateFormat('dd-MM-yyyy').format(now.add(const Duration(days: 1)));
    }
    return '';
  }

  Widget _buildTransactionTypeButton(String type) {
    bool isSelected = _transactionType == type;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _transactionType = type;
          if (_selectedCategory != null) {
            if (type == 'Pendapatan' &&
                !_incomeCategories.contains(_selectedCategory)) {
              _selectedCategory = null;
            } else if (type == 'Pengeluaran' &&
                !_expenseCategories.contains(_selectedCategory)) {
              _selectedCategory = null;
            }
          }
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? buttoncolor : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(type),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[200],
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    // Pastikan value ada dalam items, jika tidak, set ke null
    if (value != null && !items.contains(value)) {
      value = null;
    }
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      onChanged: onChanged,
      items: items.map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
      hint: Text('Pilih $label'),
    );
  }
}
