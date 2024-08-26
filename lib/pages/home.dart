// ignore_for_file: sort_child_properties_last, unused_element, use_build_context_synchronously, avoid_print

import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:aplikasi_pengelola/database/db_helper.dart';
import 'package:aplikasi_pengelola/pages/add.dart';
// import 'package:aplikasi_pengelola/pages/add.dart';r
import 'package:aplikasi_pengelola/pages/homepage.dart';
// import 'package:aplikasi_pengelola/pages/fitur%20tambahan/integrasi.dart';
import 'package:aplikasi_pengelola/pages/login/login.dart';
import 'package:aplikasi_pengelola/pages/setting/setttingpages.dart';
import 'package:aplikasi_pengelola/pages/transaksi.dart';
import 'package:aplikasi_pengelola/pages/zakat_.dart';
import 'package:aplikasi_pengelola/tema/tema.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int pageIndex = 0;

  List<Widget> pages = [
    const DailyPage(),
    const TransactionPage(),
    const ZakatCalculator(),
    const AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      body: getBody(),
      bottomNavigationBar: getFooter(),
      floatingActionButton: SafeArea(
        child: SizedBox(
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionForm(),
                ),
              );
            },
            child: const Icon(
              Icons.add,
              size: 20,
            ),
            backgroundColor: buttoncolor,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // appBar: AppBar(
      //   title: const Text('Home'),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.calculate),
      //       onPressed: () {
      //         Navigator.pushNamed(context, '/zakat');
      //       },
      //     ),
      //   ],
      // ),
    );
  }

  Widget getBody() {
    return IndexedStack(
      index: pageIndex,
      children: pages,
    );
  }

  Widget getFooter() {
    List<IconData> iconItems = [
      CupertinoIcons.home,
      CupertinoIcons.creditcard,
      CupertinoIcons.square_list_fill,
      CupertinoIcons.person,
    ];
    return AnimatedBottomNavigationBar(
        backgroundColor: primary,
        icons: iconItems,
        splashColor: secondary,
        inactiveColor: black.withOpacity(0.5),
        gapLocation: GapLocation.center,
        activeIndex: pageIndex,
        notchSmoothness: NotchSmoothness.softEdge,
        leftCornerRadius: 10,
        iconSize: 25,
        rightCornerRadius: 10,
        elevation: 2,
        onTap: (index) {
          setTabs(index);
        });
  }

  setTabs(index) {
    setState(() {
      pageIndex = index;
    });
  }

  Future<void> _logout() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await DatabaseHelper.instance.clearUserData(user.uid);
      }
      await FirebaseAuth.instance.signOut();
      await _resetLoginStatus();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print('Error saat logout: $e');
    }
  }

  Future<void> _resetLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
  }
}
