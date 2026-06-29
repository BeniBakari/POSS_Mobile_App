import 'package:flutter/material.dart';

import 'package:poss_mobile_app/components/textfield_widget.dart';

class PhoneFormField extends StatefulWidget {
  final Widget? prefixIcon;
  final TextEditingController phoneController;
  final Function? functionValidate;
  const PhoneFormField(
      {super.key,
      this.prefixIcon,
      required this.phoneController,
      this.functionValidate});

  @override
  State<PhoneFormField> createState() => _PhoneFormFieldState();
}

class _PhoneFormFieldState extends State<PhoneFormField> {
  @override
  Widget build(BuildContext context) {
    return TextFieldWidget(
      textEditingController: widget.phoneController,
      hintText: "0755100100",
      textInputType: TextInputType.phone,
      labelText: "Phone number",
      functionValidate: (String value) {
        if (value.isEmpty) {
          return "Phone number is required.";
        } else if (value.toString().length < 10) {
          return "Must have 10 digits";
        }
        // else if (!RegExp(RegularExpression.emailRegEx).hasMatch(value)) {
        //   return "Invalid first name.";
        // }
        /*
         // This is just a regular expression for email addresses
  String p = "[a-zA-Z0-9\+\.\_\%\-\+]{1,256}" +
      "\\@" +
      "[a-zA-Z0-9][a-zA-Z0-9\\-]{0,64}" +
      "(" +
      "\\." +
      "[a-zA-Z0-9][a-zA-Z0-9\\-]{0,25}" +
      ")+";*/
        return null;
      },
    );
  }
}
