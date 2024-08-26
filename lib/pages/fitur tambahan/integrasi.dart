// ignore_for_file: unnecessary_to_list_in_spreads, library_private_types_in_public_api, sized_box_for_whitespace

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_pengelola/tema/tema.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MbankPage extends StatefulWidget {
  const MbankPage({super.key});

  @override
  _MbankPageState createState() => _MbankPageState();
}

class _MbankPageState extends State<MbankPage> {
  List<dynamic> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchBankTransactions();
  }

  Future<void> _fetchBankTransactions() async {
    final response = await http.get(Uri.parse('API_MBANK'));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _transactions = data['transactions'];
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
      throw Exception('Failed to load transactions');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : getBody(),
    );
  }

  Widget getBody() {
    var size = MediaQuery.of(context).size;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(color: primary, boxShadow: [
                BoxShadow(
                    color: grey.withOpacity(0.01),
                    spreadRadius: 10,
                    blurRadius: 3)
              ]),
              child: const Padding(
                padding:
                    EdgeInsets.only(top: 20, bottom: 25, right: 20, left: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(CupertinoIcons.back),
                        Icon(CupertinoIcons.search)
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            const Padding(
              padding: EdgeInsets.only(left: 25, right: 25, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Mbank Transactions",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: mainFontColor,
                      )),
                ],
              ),
            ),
            ..._transactions.map((transaction) => buildTransactionItem(transaction, size)).toList(),
          ],
        ),
      ),
    );
  }

  Widget buildTransactionItem(Map<String, dynamic> transaction, Size size) {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(
              top: 10,
              left: 25,
              right: 25,
            ),
            decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: grey.withOpacity(0.03),
                    spreadRadius: 10,
                    blurRadius: 3,
                  ),
                ]),
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 10, bottom: 20, right: 20, left: 20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    child: const Center(
                        child: Icon(
                      Icons.payment,
                      color: mainFontColor,
                    )),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Container(
                      width: (size.width - 90) * 0.7,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction['description'] ?? 'No Description',
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: black,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              transaction['date'] ?? '',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: black.withOpacity(0.5),
                                  fontWeight: FontWeight.w400),
                            ),
                          ]),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "Rp${transaction['amount']}",
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: black),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
