import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/custom_dialogue_widget.dart';
import 'package:poss_mobile_app/components/text_button_widget.dart';
import 'package:poss_mobile_app/components/toast_widget.dart';
import 'package:poss_mobile_app/components/transitions/slide_transition.dart';
import 'package:poss_mobile_app/data/data.dart';
import 'package:poss_mobile_app/data/profileData.dart';
import 'package:poss_mobile_app/data/shopData.dart';
import 'package:poss_mobile_app/data/userData.dart';
import 'package:poss_mobile_app/pages/shops/shop_update.dart';
import 'package:poss_mobile_app/services/api_service.dart';
import 'package:poss_mobile_app/components/colors_widget.dart';
import 'package:poss_mobile_app/components/scaffold_widget.dart';
import 'package:poss_mobile_app/components/text_widget.dart';
import 'package:poss_mobile_app/services/operations/user_ops.dart';

import 'shops/shop.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    Data.setpageName("Home");
  }

  @override
  Widget build(BuildContext context) {
    Future<List> shops = ShopsData.getShops();

    return ScaffoldWidget(
      title: Text(
        "Shops",
        style: TextStyle(
            color: ColorsWidget().appBarColor, fontWeight: FontWeight.bold),
      ),
      actions: [
        PopupMenuButton(
          icon: Icon(
            Icons.more_vert,
            color: ColorsWidget().appBarColor,
          ),
          color: ColorsWidget().popMenuBackground,
          itemBuilder: (context) => [
            const PopupMenuItem<int>(
              value: 0,
              child: TextWidget(
                text: "Logout",
                color: Colors.white,
                fontsize: 15,
              ),
            ),
            const PopupMenuItem<int>(
              value: 1,
              child: TextWidget(
                text: "New Shop",
                color: Colors.white,
                fontsize: 15,
              ),
            ),
          ],
          onSelected: (item) async {
            if (item == 0) {
              showDialog(
                barrierDismissible: false,
                context: context,
                builder: (BuildContext context) {
                  return CustomDialogBox(
                    title: "Do you want to logout?",
                    actions: [
                      TextButtonWidget(
                        textColor: Colors.red,
                        textButton: "Yes",
                        onPressed: () async {
                          final response =
                              await APIService.api("GET", "logout", {});
                          if (response['httpCode'] == 200 ||
                              response['httpCode'] == 401 ||
                              response['httpCode'] == 300) {
                            Data.clearData();
                            toast("Logout successfully.");
                            Navigator.pushNamedAndRemoveUntil(
                                context, "login", (route) => false);
                          }
                        },
                      ),
                      TextButtonWidget(
                        textButton: "No",
                        textColor: Colors.green,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                },
              );
            } else if (item == 1) {
              Navigator.push(
                  context,
                  SlideRightRoute(
                      page: const ShopUpdate(
                    {},
                    isNew: true,
                  )));
            }
          },
        ),
      ],
      body: FutureBuilder(
        future: shops,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.connectionState == ConnectionState.done) {
            if (ShopsData.shops.isEmpty) {
              return const Center(
                  child: TextWidget(text: "You don't have shops."));
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: ShopsData.shops.length,
              itemBuilder: (context, index) {
                return buildShop(ShopsData.shops[index]);
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget buildShop(Map shop) {
    Map owner = {};
    if (shop.containsKey("owner")) {
      owner = shop['owner'];
    } else {
      owner = UserData.users[shop['owner_id'].toString()] ?? {};
    }

    UserOps.getUser(shop['owner_id'].toString()).then((shopOwner) {
      if (shopOwner.isEmpty) {
        UserOps.create(owner);
      }
    });

    return GestureDetector(
      onTap: () {
        Navigator.push(context, SlideRightRoute(page: Shop(shop)));
      },
      onLongPress: () {
        if ((int.tryParse(ProfileData.profile['role_id'].toString()) ?? 0) <=
            3) {
          Navigator.push(context, SlideRightRoute(page: ShopUpdate(shop)));
        }
      },
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.store, color: ColorsWidget().appBarColor),
                  const SizedBox(width: 8),
                  Text(
                    shop['name'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on, color: ColorsWidget().appBarColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      shop['address'],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.person, color: ColorsWidget().appBarColor),
                  const SizedBox(width: 8),
                  Text(
                    "${owner['first_name'] ?? ''} ${owner['last_name'] ?? ''}",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}