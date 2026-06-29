import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/custom_dialogue_widget.dart';
import 'package:poss_mobile_app/components/divider_widget.dart';
import 'package:poss_mobile_app/components/measurement.dart';
import 'package:poss_mobile_app/components/row_text_widget.dart';
import 'package:poss_mobile_app/components/scaffold_widget.dart';
import 'package:poss_mobile_app/components/text_button_widget.dart';
import 'package:poss_mobile_app/components/text_widget.dart';
import 'package:poss_mobile_app/components/toast_widget.dart';
import 'package:poss_mobile_app/data/unemployeeData.dart';
import 'package:poss_mobile_app/services/api_service.dart';

class FindEmployee extends StatefulWidget {
  final Map shop;
  const FindEmployee({required this.shop, super.key});

  @override
  State<FindEmployee> createState() => _FindEmployeeState();
}

class _FindEmployeeState extends State<FindEmployee> {
  @override
  Widget build(BuildContext context) {
    Future<List?> unmemployees =
        UnEmployeeData.getEmployees(widget.shop['id'].toString());
    return ScaffoldWidget(
      title: Column(children: [
        const TextWidget(
          text: "Employees nearby",
          color: Colors.white,
        ),
        Text(
          widget.shop['name'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
        )
      ]),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(5, 2, 5, 0),
        child: FutureBuilder(
          future: unmemployees,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              //easyLoad("");
            }

            if (snapshot.connectionState == ConnectionState.done) {
              //easyLoadDismiss();
              if (UnEmployeeData.unemployees
                  .containsKey(widget.shop['id'].toString())) {
                List unemps =
                    UnEmployeeData.unemployees[widget.shop['id'].toString()]!;
                return ListView(
                  children: [
                    for (Map unemp in unemps) buildUnEmployee(unemp),
                  ],
                );
              }
              return const TextWidget(text: "No available workers nearby.");
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget buildUnEmployee(Map employee) {
    String name = employee['first_name'] + " " + employee['last_name'];
    String email = employee['email'];
    String phone = employee['phone'].toString();
    String address = employee['address'];
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: Measurement.getWidth(context) * 0.794,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RowTextWidget(firstColumn: "Name: ", secondColumn: name),
                  RowTextWidget(firstColumn: "Email: ", secondColumn: email),
                  if (phone.toString() != "null")
                    RowTextWidget(firstColumn: "Phone: ", secondColumn: phone),
                  RowTextWidget(
                      firstColumn: "Address: ", secondColumn: address),
                ],
              ),
            ),
            Expanded(
              child: TextButtonWidget(
                  textColor: Colors.blue,
                  textButton: "Add",
                  onPressed: () {
                    showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (BuildContext context) {
                          return CustomDialogBox(
                            title: "New employee",
                            content: [
                              TextWidget(
                                text:
                                    "Do you want to add $name as new employee?",
                                fontsize: 17,
                              )
                            ],
                            actions: [
                              TextButtonWidget(
                                  textButton: "No",
                                  textColor: Colors.green,
                                  onPressed: () {
                                    Navigator.pop(context);
                                  }),
                              TextButtonWidget(
                                  textColor: Colors.blue,
                                  textButton: "Yes",
                                  onPressed: () async {
                                    String shopId =
                                        widget.shop['id'].toString();
                                    String link = "shops/$shopId/employees/new";
                                    Map data = {
                                      "user_id": employee['id'].toString()
                                    };
                                    //easyLoad("");
                                    var response = await APIService.api(
                                        "POST", link, data);
                                    // ignore: use_build_context_synchronously
                                    //easyLoadDismiss();
                                    print(response);
                                    if (response['httpCode'] == 201) {
                                      // ignore: use_build_context_synchronously
                                      Navigator.pop(context);
                                      toast("Successfully.");
                                    }
                                  })
                            ],
                          );
                        });
                  }),
            )
          ],
        ),
        const DividerWidget()
      ],
    );
  }

  String getRoleName(String roleId) {
    String roleName = "";
    if (roleId == "4") {
      roleName = "Worker";
    } else if (roleId == "3") {
      roleName = "Manager";
    }

    return roleName;
  }
}
