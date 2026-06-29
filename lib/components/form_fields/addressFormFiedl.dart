import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/textfield_widget.dart';

class AddressFormField extends StatefulWidget {
  const AddressFormField(
      {super.key, required this.nameController, required this.hintText, required this.labelText});
  final TextEditingController nameController;
  final String hintText;
  final String labelText;
  @override
  State<AddressFormField> createState() => _NameFormFieldState();
}

class _NameFormFieldState extends State<AddressFormField> {
  @override
  Widget build(BuildContext context) {
    return TextFieldWidget(
      textEditingController: widget.nameController,
      hintText: widget.hintText,
      textInputType: TextInputType.name,
      labelText: widget.labelText,
      functionValidate: (String value) {
        if (value.isEmpty) {
          return  "${widget.labelText} is required.";
        }
        // else if (!RegExp(RegularExpression.emailRegEx).hasMatch(value)) {
        //   return "Invalid first name.";
        // }
        return null;
      },
    );
  }
}
