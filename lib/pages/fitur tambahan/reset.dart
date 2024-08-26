// ignore_for_file: use_build_context_synchronously

import 'package:aplikasi_pengelola/database/db_helper.dart';
import 'package:flutter/material.dart';

class ResetDatabaseButton extends StatelessWidget {
  const ResetDatabaseButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        // Memanggil metode _resetDatabase
        await DatabaseHelper.instance.resetDatabase();

        // Berikan feedback kepada pengguna setelah reset
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Database telah di-reset dan diinisialisasi ulang!')),
        );
      },
      child: const Text('Reset Database'),
    );
  }
}
