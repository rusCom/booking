import 'package:flutter/material.dart';

class RoutePointTextField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController _controller = TextEditingController();
  final String hintText;
  final FocusNode? focusNode;
  final bool autoFocus;

  RoutePointTextField({super.key, required this.hintText, required this.onChanged, this.focusNode, this.autoFocus = false, this.onSubmitted});

  String get value {
    return _controller.value.text;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: onChanged,
      focusNode: focusNode,
      autofocus: autoFocus,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF757575), fontSize: 16),
        prefixIcon: const Icon(
          Icons.search,
          color: Color(0xFF757575),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        fillColor: const Color(0xFFEEEEEE),
        filled: true,
      ),
    );
  }
}
