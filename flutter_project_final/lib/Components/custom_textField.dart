import 'package:flutter/material.dart';

class CustomTextfield extends StatefulWidget {
  final Widget? suffixIcon;
  final String labelText;
  final TextEditingController? controller;
  final Color? textColor;
  final TextInputType? keyboard;
  final Function(String) onChanged;
  final bool isPassword;

  const CustomTextfield({
    super.key,
    required this.onChanged,
    required this.labelText,
    this.controller,
    this.suffixIcon,
    this.textColor,
    this.keyboard,
    this.isPassword = false,
  });

  @override
  State<CustomTextfield> createState() => _CustomTextfieldState();
}

class _CustomTextfieldState extends State<CustomTextfield> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboard ?? TextInputType.text,
      obscureText: widget.isPassword && !_isPasswordVisible,
      style: TextStyle(color: widget.textColor ?? Colors.white),
      decoration: InputDecoration(
        labelText: widget.labelText,
        labelStyle: TextStyle(color: widget.textColor ?? Colors.white70),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white30),
          borderRadius: BorderRadius.circular(10),
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : widget.suffixIcon,
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.deepPurpleAccent),
        ),
        filled: true,
        fillColor: Colors.white12,
      ),
    );
  }
}