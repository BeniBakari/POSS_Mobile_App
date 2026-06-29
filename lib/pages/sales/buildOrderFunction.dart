//  import 'package:flutter/material.dart';
// import 'package:path/path.dart';
// import 'package:poss/components/custom_dialogue_widget.dart';
// import 'package:poss/components/divider_widget.dart';
// import 'package:poss/components/measurement.dart';
// import 'package:poss/components/row_text_widget.dart';
// import 'package:poss/components/text_button_widget.dart';
// import 'package:poss/components/transitions/slide_transition.dart';
// import 'package:poss/pages/sales/sales.dart';
// import 'package:poss/time_diference.dart';

// Widget buildOder(Map order) {
//     String customerNames = order['customer_names'].toString();
//     String customerPhone = order['customer_phone'].toString();
//     String customerAddress = order['customer_address'].toString();
//     String customerEmail = order['customer_email'].toString();

//     Map seller = order['added_by'];
//     String sellerName = seller['first_name'] + " " + seller['last_name'];

//     String totalGrand = order['total_grand'].toString();
//     String discount = order['discount'].toString();
//     String time = TimeDifference.getDate(order['created_at'].toString());

//     return Column(
//       children: [
//         Row(
//           children: [
//             SizedBox(
//                 width: Measurement.getWidth(context) * 0.794,
//                 child: GestureDetector(
//                   onTap: () {
//                     Navigator.push(
//                         context,
//                         SlideRightRoute(
//                             page: Sales(
//                           sales: order['sales'],
//                           shop: widget.shop,
//                         )));
//                   },
//                   child: Column(
//                     children: [
//                       if (customerNames != "null")
//                         RowTextWidget(
//                           firstColumn: "Customer : ",
//                           secondColumn: customerNames,
//                         ),
//                       RowTextWidget(
//                         firstColumn: "Total : ",
//                         secondColumn: totalGrand,
//                       ),
//                       RowTextWidget(
//                         firstColumn: "Discount :",
//                         secondColumn: discount,
//                       ),
//                       RowTextWidget(
//                         firstColumn: "Sold at: ",
//                         secondColumn: time,
//                       )
//                     ],
//                   ),
//                 )),
//             Expanded(
//                 child: Column(
//               children: [
//                 // IconButton(
//                 //     onPressed: () {
//                 //       print("Hello");
//                 //     },
//                 //     icon: Icon(
//                 //       Icons.add_shopping_cart,
//                 //       color: ColorsWidget().buttonsColor,
//                 //     )),
//                 TextButtonWidget(
//                     textColor: Colors.blue,
//                     textButton: "More",
//                     onPressed: () {
//                       showDialog(
//                           barrierDismissible: false,
//                           context: context,
//                           builder: (context) {
//                             return CustomDialogBox(
//                                 title: "Order informations",
//                                 content: [
//                                   if (customerNames != "null")
//                                     RowTextWidget(
//                                       firstColumn: "Customer : ",
//                                       secondColumn: customerNames,
//                                     ),
//                                   if (customerAddress != "null")
//                                     RowTextWidget(
//                                       firstColumn: "Address : ",
//                                       secondColumn: customerAddress,
//                                     ),
//                                   if (customerEmail != "null")
//                                     RowTextWidget(
//                                       firstColumn: "Email : ",
//                                       secondColumn: customerEmail,
//                                     ),
//                                   if (customerPhone != "null")
//                                     RowTextWidget(
//                                       firstColumn: "Phone : ",
//                                       secondColumn: customerPhone,
//                                     ),
//                                   RowTextWidget(
//                                     firstColumn: "Discount :",
//                                     secondColumn: discount,
//                                   ),
//                                   RowTextWidget(
//                                     firstColumn: "Total : ",
//                                     secondColumn: totalGrand,
//                                   ),
//                                   RowTextWidget(
//                                     firstColumn: "Sold by : ",
//                                     secondColumn: sellerName,
//                                   ),
//                                   RowTextWidget(
//                                     firstColumn: "At : ",
//                                     secondColumn: time,
//                                   )
//                                 ],
//                                 actions: [
//                                   TextButtonWidget(
//                                       textColor: Colors.blue,
//                                       textButton: "Close",
//                                       onPressed: () {
//                                         Navigator.pop(context);
//                                       })
//                                 ]);
//                           });
//                     })
//               ],
//             ))
//           ],
//         ),
//         const DividerWidget()
//       ],
//     );
//   }
