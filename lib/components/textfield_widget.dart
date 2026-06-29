import 'package:flutter/material.dart';
import 'measurement.dart';

class TextFieldWidget extends StatefulWidget {
  final TextInputType textInputType;
  final String hintText;
  final Widget? prefixIcon;
  final String labelText;
  final bool obsecureText;
  final TextEditingController textEditingController;
  final String? Function(String) functionValidate; // proper type

  const TextFieldWidget({
    super.key,
    required this.textInputType,
    required this.hintText,
    this.prefixIcon,
    required this.labelText,
    this.obsecureText = false,
    required this.textEditingController,
    required this.functionValidate,
  });

  @override
  State<TextFieldWidget> createState() => _TextFieldWidgetState();
}

class _TextFieldWidgetState extends State<TextFieldWidget> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: widget.obsecureText,
      controller: widget.textEditingController,
      keyboardType: widget.textInputType,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(
          vertical: Measurement.getTextFieldHeight(context),
          horizontal: 5,
        ),
        prefixIcon: widget.prefixIcon,
        hintText: widget.hintText,
        labelText: widget.labelText,
      ),
      validator: (value) {
        return widget.functionValidate(value ?? "");
      },
      onSaved: (value) {
        if (value != null) {
          widget.textEditingController.text = value;
        }
      },
    );
  }
}
