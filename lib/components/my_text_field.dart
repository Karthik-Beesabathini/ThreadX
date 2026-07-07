import 'package:flutter/material.dart';
class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;

  const MyTextField({super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
  }
  );

  @override
  Widget build(BuildContext context) {
    return
      Padding(
        padding: const EdgeInsets.all(5),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(12),
            ),
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.black),
            fillColor: Colors.grey[200],
            filled: true,
          ),
        ),
      );

  }
}
