import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/button_widget.dart';
import 'package:poss_mobile_app/components/measurement.dart';
import 'package:poss_mobile_app/components/scaffold_widget.dart';
import 'package:poss_mobile_app/components/text_widget.dart';
import 'package:poss_mobile_app/components/textfield_widget.dart';
import 'package:poss_mobile_app/services/api_service.dart';

class UpdateRegister extends StatefulWidget {
  final Map register;
  final Map shop;
  const UpdateRegister(
      {this.register = const {}, this.shop = const {}, super.key});

  @override
  State<UpdateRegister> createState() => _UpdateRegisterState();
}

class _UpdateRegisterState extends State<UpdateRegister> {
  final descriptionController = TextEditingController();
  final openingController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late Map register;
  @override
  void initState() {
    super.initState();
    register = widget.register;
    if (register.isNotEmpty) {
      openingController.text = register['opening_cash'].toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      title: TextWidget(
        text: register.isNotEmpty ? "Update Register" : "New Register",
        color: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(5),
        child: ListView(
          children: [
            Center(
              child: Card(
                elevation: 20,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 330),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [Expanded(child: buildOpening())],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.fromLTRB(
                              Measurement.getWidth(context) * 0.0279,
                              0,
                              Measurement.getWidth(context) * 0.0279,
                              0),
                          child: ButtonWidget(
                              btnText: register.isEmpty ? "Add" : "Update",
                              onBtnPressed: () async {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }
                                Map data = {
                                  "opening_cash": openingController.text,
                                };
                                String link;
                                String method;
                                if (register.isEmpty) {
                                  String shopId = widget.shop['id'].toString();
                                  method = "POST";
                                  link = "shops/$shopId/registers/new";
                                } else {
                                  String registerId = register['id'].toString();
                                  link = "shops/registers/update/$registerId";
                                  method = "PUT";
                                }

                                Map response =
                                    await APIService.api(method, link, data);
                                if (response['httpCode'] == 200) {
                                  Map body = jsonDecode(response['body']);
                                  print(body['success'] == false);
                                }
                                
                              }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildDescription() {
    return TextFieldWidget(
      textEditingController: descriptionController,
      hintText: 'Description',
      textInputType: TextInputType.text,
      labelText: 'Description',
      functionValidate: (String value) {
        if (value.isEmpty) {
          return "description is required";
        }
        // else if (!RegExp(RegularExpression.emailRegEx).hasMatch(value)) {
        //   return "Invalid shop name.";
        // }
        return null;
      },
    );
  }

  Widget buildOpening() {
    return TextFieldWidget(
      textEditingController: openingController,
      hintText: 'Amount eg. 800',
      textInputType: TextInputType.number,
      labelText: 'Price',
      functionValidate: (String value) {
        if (value.isEmpty) {
          return "amount is required";
        }
        // else if (!RegExp(RegularExpression.emailRegEx).hasMatch(value)) {
        //   return "Invalid shop name.";
        // }
        return null;
      },
    );
  }
}
