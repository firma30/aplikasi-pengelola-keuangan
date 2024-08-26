// ignore_for_file: unused_import, unused_local_variable, unnecessary_null_comparison, deprecated_member_use, avoid_print

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:aplikasi_pengelola/database/db_helper.dart';
import 'package:aplikasi_pengelola/database/models/transaksi.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';

Future<void> exportData(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengguna belum login')),
    );
    return;
  }

  // Minta izin penyimpanan
  var status = await Permission.storage.request();
  if (!status.isGranted) {
    if (status.isPermanentlyDenied) {
      openAppSettings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Izin penyimpanan diperlukan untuk ekspor')),
      );
    }
    return;
  }

  try {
    List<Transaction> transactions =
        await DatabaseHelper.instance.readAllTransactions(user.uid);

    String? format = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text('Pilih format ekspor'),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, 'csv'),
                child: const Text('CSV'),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, 'pdf'),
                child: const Text('PDF'),
              ),
            ],
          );
        });

    if (format == null) return;

    final directory = await getApplicationDocumentsDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    String fileName =
        'transaksi_${DateTime.now().millisecondsSinceEpoch}.$format';
    String initialPath = '${directory.path}/$fileName';

    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Pilih lokasi untuk menyimpan file',
      fileName: fileName,
      initialDirectory: directory.path,
    );

    if (outputFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ekspor dibatalkan')),
      );
      return;
    }

    late String message;

    switch (format) {
      case 'csv':
        List<List<dynamic>> data = [
          ['ID', 'Deskripsi', 'Jumlah', 'Tanggal', 'Kategori', 'Tipe'],
          ...transactions.map((transaction) => [
                transaction.id,
                transaction.description,
                transaction.amount,
                transaction.transactionDate.toString(),
                transaction.categoryName,
                transaction.transactionType,
              ]),
        ];

        String csvData = const ListToCsvConverter().convert(data);
        await File(outputFile).writeAsString(csvData);
        message = 'Data berhasil diekspor ke CSV';
        break;

      case 'pdf':
        final pdf = pw.Document();

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Table.fromTextArray(
                headers: [
                  'ID',
                  'Deskripsi',
                  'Jumlah',
                  'Tanggal',
                  'Kategori',
                  'Tipe'
                ],
                data: transactions
                    .map((transaction) => [
                          transaction.id.toString(),
                          transaction.description,
                          transaction.amount.toString(),
                          transaction.transactionDate.toString(),
                          transaction.categoryName,
                          transaction.transactionType,
                        ])
                    .toList(),
              );
            },
          ),
        );

        await File(outputFile).writeAsBytes(await pdf.save());
        message = 'Data berhasil diekspor ke PDF';
        break;

      default:
        throw Exception('Format tidak dikenal');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$message: $outputFile')),
    );
  } on FileSystemException catch (e) {
    print('Kesalahan sistem file: ${e.message}');
    print('Path: ${e.path}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal mengakses penyimpanan: ${e.message}')),
    );
  } catch (e) {
    print('Kesalahan lain saat mengekspor data: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Terjadi kesalahan saat mengekspor data: $e')),
    );
  }
}
