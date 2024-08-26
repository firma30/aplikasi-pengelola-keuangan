// forgot_password.dart
// ignore_for_file: prefer_final_fields

import 'package:aplikasi_pengelola/tema/tema.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  TextEditingController _email = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              height: 500,
            ),
            _buildTextField(
                "Email Address", "Email", _email, Icons.email_outlined),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: null,
              child: _buildButton("Reset"),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildTextField(
  String label,
  String hint,
  TextEditingController controller,
  IconData icon,
) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 25),
    decoration: BoxDecoration(
      color: white,
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: grey.withOpacity(0.03),
          spreadRadius: 10,
          blurRadius: 3,
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.only(left: 20, top: 15, bottom: 5, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            cursorColor: black,
            // obscureText: isPassword && !_isPasswordVisible,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: black,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon),
              prefixIconColor: black,
              hintText: hint,
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildButton(String text) {
  return Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.symmetric(horizontal: 25),
    decoration: BoxDecoration(
      color: buttoncolor,
      borderRadius: BorderRadius.circular(25),
    ),
    child: Center(
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
