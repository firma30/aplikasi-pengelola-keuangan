// ignore_for_file: unused_field, library_private_types_in_public_api, use_build_context_synchronously, avoid_print, sort_child_properties_last, unused_import

import 'package:aplikasi_pengelola/pages/fitur%20tambahan/analisis.dart';
import 'package:aplikasi_pengelola/pages/login/login.dart';
import 'package:aplikasi_pengelola/pages/setting/export.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_pengelola/tema/tema.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:aplikasi_pengelola/database/db_helper.dart';
import 'package:aplikasi_pengelola/database/models/transaksi.dart';
import 'package:aplikasi_pengelola/pages/fitur%20tambahan/reset.dart';
import 'package:aplikasi_pengelola/pages/login/forgot.dart';
import 'package:aplikasi_pengelola/pages/setting/info.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  String userName = 'Nama pengguna';
  String userEmail = 'Email pengguna';
  File? _image;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> _resetLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await _resetLoginStatus(); // Pastikan fungsi ini ada
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print('Error saat logout: $e');
    }
  }

  void loadUserData() {
    if (user != null) {
      setState(() {
        userName = user!.displayName ?? 'Nama pengguna';
        userEmail = user!.email ?? 'Email pengguna';
        _imageUrl = user!.photoURL;
      });
    }
  }

  Future<String> uploadImageToFirebaseStorage(File imageFile) async {
    try {
      String fileName =
          'profileImages/${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageReference =
          FirebaseStorage.instance.ref().child(fileName);

      // Unggah file
      UploadTask uploadTask = storageReference.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  Future<void> _editProfile() async {
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Nama'),
              onChanged: (value) {
                userName = value;
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              child: const Text('Pilih Foto'),
              onPressed: _pickImage,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Simpan'),
            onPressed: () async {
              user?.updateDisplayName(userName);
              if (_image != null) {
                // Upload foto ke Firebase Storage
                String imageUrl = await uploadImageToFirebaseStorage(_image!);
                // Simpan URL ke profil pengguna
                await user?.updatePhotoURL(imageUrl);
              }
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Akun',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: mainFontColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _imageUrl != null
                              ? NetworkImage(_imageUrl!)
                              : const AssetImage('images/image.png')
                                  as ImageProvider,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: IconButton(
                            icon: const Icon(Icons.edit, color: mainFontColor),
                            onPressed: _editProfile,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: mainFontColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      userEmail,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pengaturan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: mainFontColor,
                      ),
                    ),
                    const SizedBox(height: 15),
                    // SettingItem(
                    //   title: 'Fitur ZAkat',
                    //   icon: Icons.featured_play_list,
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //           builder: (context) => const ZakatCalculator()),
                    //     );
                    //   },
                    // ),
                    SettingItem(
                      title: 'Analisis Pengeluaran',
                      icon: Icons.category,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AnalisisPage()),
                        );
                      },
                    ),
                    SettingItem(
                      title: 'Sandi',
                      icon: Icons.lock,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ForgotPasswordPage()),
                        );
                      },
                    ),
                    SettingItem(
                      title: 'Ekspor',
                      icon: Icons.file_download,
                      onTap: () {
                        exportData(context);
                      },
                    ),
                    SettingItem(
                      title: 'Nilai App',
                      icon: Icons.star,
                      onTap: () {
                        rateApp();
                      },
                    ),
                    SettingItem(
                      title: 'Bagikan',
                      icon: Icons.share,
                      onTap: () {
                        shareApp();
                      },
                    ),
                    SettingItem(
                      title: 'Info',
                      icon: Icons.info,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const InfoPage()),
                        );
                      },
                    ),
                    SettingItem(
                      title: 'Logout',
                      icon: Icons.exit_to_app,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Logout'),
                              content:
                                  const Text('Apakah Anda yakin ingin keluar?'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Batal'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: const Text('Logout'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _logout();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const SettingItem({
    required this.title,
    required this.icon,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: mainFontColor),
      title: Text(title, style: const TextStyle(color: mainFontColor)),
      trailing:
          const Icon(Icons.arrow_forward_ios, color: mainFontColor, size: 16),
      onTap: onTap,
    );
  }
}

// void exportData(BuildContext context) async {
//   final user = FirebaseAuth.instance.currentUser;
//   if (user == null) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('User not logged in')),
//     );
//     return;
//   }

//   try {
//     List<Transaction> transactions =
//         await DatabaseHelper.instance.readAllTransactions(user.uid);
//     List<List<dynamic>> data = [
//       ['ID', 'Description', 'Amount', 'Date', 'Category', 'Type'],
//       ...transactions.map((transaction) => [
//             transaction.id,
//             transaction.description,
//             transaction.amount,
//             transaction.transactionDate.toString(),
//             transaction.categoryName,
//             transaction.transactionType,
//           ]),
//     ];

//     String csvData = const ListToCsvConverter().convert(data);

//     final directory = await getApplicationDocumentsDirectory();
//     final path = '${directory.path}/transaksi_${user.uid}.csv';

//     final file = File(path);
//     await file.writeAsString(csvData);

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Data berhasil diekspor ke $path')),
//     );
//   } catch (e) {
//     print('Error exporting data: $e');
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Terjadi kesalahan saat mengekspor data')),
//     );
//   }
// }

void rateApp() async {
  final InAppReview inAppReview = InAppReview.instance;
  if (await inAppReview.isAvailable()) {
    inAppReview.requestReview();
  } else {
    inAppReview.openStoreListing(appStoreId: 'com.example.app');
  }
}

void shareApp() {
  Share.share('Cek aplikasi ini: https://example.com');
}
