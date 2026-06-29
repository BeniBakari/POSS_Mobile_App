import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/button_widget.dart';
import 'package:poss_mobile_app/components/dialogue_widget.dart';
import 'package:poss_mobile_app/components/measurement.dart';
import 'package:poss_mobile_app/components/scaffold_widget.dart';
import 'package:poss_mobile_app/components/text_button_widget.dart';
import 'package:poss_mobile_app/components/text_widget.dart';
import 'package:poss_mobile_app/components/textfield_widget.dart';
import 'package:poss_mobile_app/components/toast_widget.dart';
import 'package:poss_mobile_app/services/api_service.dart';

class UpdateExpense extends StatefulWidget {
  final Map expense;
  final Map shop;
  const UpdateExpense(
      {this.expense = const {}, this.shop = const {}, super.key});

  @override
  State<UpdateExpense> createState() => _UpdateExpenseState();
}

class _UpdateExpenseState extends State<UpdateExpense> {
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late Map expense;
  @override
  void initState() {
    super.initState();
    expense = widget.expense;
    if (expense.isNotEmpty) {
      amountController.text = expense['amount'].toString();
      descriptionController.text = expense['description'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      title: TextWidget(
        text: expense.isNotEmpty ? "Update Expense" : "New Expense",
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
                            children: [Expanded(child: buildDescription())],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [Expanded(child: buildAmount())],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.fromLTRB(
                              Measurement.getWidth(context) * 0.0279,
                              0,
                              Measurement.getWidth(context) * 0.0279,
                              0),
                          child: ButtonWidget(
                              btnText: expense.isEmpty ? "Add" : "Update",
                              onBtnPressed: () async {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }
                                Map data = {
                                  "amount": amountController.text,
                                  "description": descriptionController.text
                                };
                                String link;
                                String method;
                                if (expense.isEmpty) {
                                  String shopId = widget.shop['id'].toString();
                                  method = "POST";
                                  link = "shops/$shopId/expenses/new";
                                } else {
                                  String expenseId = expense['id'].toString();
                                  link = "shops/expenses/update/$expenseId";
                                  method = "PUT";
                                }
                               // easyLoad("");
                                Map response =
                                    await APIService.api(method, link, data);
                                //easyLoadDismiss();
                                if (response['httpCode'] == 200 ||
                                    response['httpCode'] == 201) {
                                  Map body = jsonDecode(response['body']);
                                  if (body['success'] == false) {
                                    if (body['message'].toString() ==
                                        "Please open register first.") {
                                      // ignore: use_build_context_synchronously
                                      return showDialog(
                                          barrierDismissible: true,
                                          context: context,
                                          builder: (BuildContext context) {
                                            return DialogueWidget(
                                                title: "Information",
                                                // ignore: avoid_unnecessary_containers
                                                content: Container(
                                                    child: const TextWidget(
                                                  text:
                                                      "Oops! there is no opened register, please open first.",
                                                )),
                                                actions: [
                                                  TextButtonWidget(
                                                      textButton: "Ok",
                                                      textColor: Colors.blue,
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        Navigator.pop(context);
                                                      })
                                                ]);
                                          });
                                    }
                                  } else {
                                    toast("Successfully.");
                                    // ignore: use_build_context_synchronously
                                    Navigator.pop(context);
                                  }
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

  Widget buildAmount() {
    return TextFieldWidget(
      textEditingController: amountController,
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
