import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/button_widget.dart';

import 'package:poss_mobile_app/components/scaffold_widget.dart';
import 'package:poss_mobile_app/components/text_widget.dart';
import 'package:poss_mobile_app/components/textfield_widget.dart';
import 'package:poss_mobile_app/components/toast_widget.dart';
import 'package:poss_mobile_app/models/shop.dart';
import 'package:poss_mobile_app/services/api_service.dart';
import 'package:poss_mobile_app/services/operations/shop_ops.dart';

class ShopUpdate extends StatefulWidget {
  final Map shop;
  final bool? isNew;
  const ShopUpdate(this.shop, {super.key, this.isNew});

  @override
  // ignore: no_logic_in_create_state
  State<ShopUpdate> createState() => _ShopUpdateState(shop);
}

class _ShopUpdateState extends State<ShopUpdate> {
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final Map shop;
  _ShopUpdateState(this.shop);
  String textButton = "";
  Column title = const Column();
  @override
  void initState() {
    super.initState();
    if (shop.isEmpty) {
      title = const Column(
        children: [Text("New Shop")],
      );
      textButton = "Add";
    } else {
      title = Column(
        children: [
          const TextWidget(
            text: "Update Shop",
            color: Colors.white,
          ),
          Text(
            shop['name'],
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
          )
        ],
      );
      textButton = "Update";
      nameController.text = shop['name'];
      addressController.text = shop['address'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      title: title,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 30, 20, 10),
        child: ListView(
          children: <Widget>[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300, minWidth: 200),
              child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      buildName(),
                      buildAdress(),
                      ButtonWidget(
                          btnText: textButton,
                          onBtnPressed: () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }
                            formKey.currentState!.save();
                            Map<String, String> data = {
                              "name": nameController.text,
                              "address": addressController.text
                            };
                            String shopId = shop['id'].toString();
                            var link = shop.isNotEmpty
                                ? "shops/update/$shopId"
                                : "shops/new";
                            //easyLoad("");
                            Map response =
                                await APIService.api("POST", link, data);
                            print(response.toString());
                            toast(response.toString());
                            //easyLoadDismiss();
                            if (response['httpCode'] == 401) {
                              //logout
                            } else if (response['httpCode'] == 200) {
                              Map body = jsonDecode(response['body']);
                              if (body['success'] == true) {
                                Map shopData = body['data'];
                                ShopOps.update(Shop(
                                    id: shopData['id'].toString(),
                                    name: shopData['name'],
                                    address: shopData['address'],
                                    ownerId: shopData['owner_id'].toString()));

                                if (shop.isEmpty) {
                                  //Adding locally
                                } else {
                                  //updating localy
                                }
                                toast("Success");
                                Navigator.pop(context);
                              }
                            } else if (response['httpCode'] == 300) {}
                          })
                    ],
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildName() {
    return TextFieldWidget(
      textEditingController: nameController,
      hintText: 'Your shop name',
      textInputType: TextInputType.emailAddress,
      labelText: 'Name',
      functionValidate: (String value) {
        if (value.isEmpty) {
          return "shop name is required";
        }
        // else if (!RegExp(RegularExpression.emailRegEx).hasMatch(value)) {
        //   return "Invalid shop name.";
        // }
        return null;
      },
    );
  }

  Widget buildAdress() {
    return TextFieldWidget(
      textEditingController: addressController,
      hintText: 'Your shop address',
      textInputType: TextInputType.emailAddress,
      labelText: 'Address',
      functionValidate: (String value) {
        if (value.isEmpty) {
          return "shop addess is required";
        }
        // else if (!RegExp(RegularExpression.emailRegEx).hasMatch(value)) {
        //   return "Invalid shop address.";
        // }
        return null;
      },
    );
  }
}
