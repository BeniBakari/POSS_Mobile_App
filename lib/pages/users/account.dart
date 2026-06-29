import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/floatingActionButton_widget.dart';
import 'package:poss_mobile_app/components/scaffold_widget.dart';
import 'package:poss_mobile_app/components/text_widget.dart';
import 'package:poss_mobile_app/components/transitions/slide_transition.dart';
import 'package:poss_mobile_app/data/data.dart';
import 'package:poss_mobile_app/pages/users/editProfile.dart';

class Account extends StatefulWidget {
  final Map profile;
  const Account({super.key, required this.profile});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final String name = profile['first_name'] + " " + profile['last_name'];
    final String role = profile['role_id'].toString() == "null"
        ? "N/A"
        : Data.getRole(profile['role_id'].toString());

    final List<Map<String, dynamic>> fields = [
      {"icon": Icons.email, "label": "Email", "value": profile['email']},
      {
        "icon": Icons.phone,
        "label": "Phone",
        "value": profile['phone'].toString() == "null"
            ? "N/A"
            : profile['phone'].toString()
      },
      {
        "icon": Icons.location_on,
        "label": "Address",
        "value": profile['address'].toString() == "null"
            ? "N/A"
            : profile['address'].toString()
      },
      {
        "icon": Icons.wc,
        "label": "Gender",
        "value": profile['gender'].toString() == "null"
            ? "N/A"
            : profile['gender'].toString() == "F"
                ? "Female"
                : "Male"
      },
      {
        "icon": Icons.cake,
        "label": "Birthdate",
        "value": profile['dob'].toString() == "null"
            ? "N/A"
            : profile['dob'].toString()
      },
      {
        "icon": Icons.task_alt,
        "label": "Completion",
        "value": "${profile['percent']}%"
      },
    ];

    return ScaffoldWidget(
      title: const TextWidget(
        text: "Account",
        color: Colors.white,
      ),
      body: Column(
        children: [
          // HEADER WITH NAME AND ROLE
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade800, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  role,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // INFO LIST WITHOUT LINES
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: fields.length,
              itemBuilder: (context, index) {
                final field = fields[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue.shade50,
                        child: Icon(field['icon'], color: Colors.blue.shade700),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            field['label'],
                            style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            field['value'],
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButtonWidget(
        icon: const Icon(Icons.edit),
        onBtnPressed: () {
          Navigator.push(
            context,
            SlideRightRoute(
              page: EditProfile(title: "My Profile", profile: profile),
            ),
          );
        },
      ),
    );
  }
}
