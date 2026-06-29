import 'package:flutter/material.dart';
import 'measurement.dart';

class SearchWidget extends StatefulWidget {
  final TextEditingController textEditingController;
  final Function functionSearch;

  const SearchWidget({
    super.key,
    required this.textEditingController,
    required this.functionSearch,
  });

  @override
  State<SearchWidget> createState() => _TextFieldWidgetState();
}

class _TextFieldWidgetState extends State<SearchWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
        color: const Color.fromARGB(90, 148, 162, 207),
        child: Card(
          
          child: ListTile(
            contentPadding: const EdgeInsets.all(0),
            title: TextFormField(
              controller: widget.textEditingController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                      vertical: Measurement.getTextFieldHeight(context) * 0.3,
                      horizontal: 5),
                  prefixIcon: const Icon(Icons.search),
                  hintText: "Search",

                  // border: const OutlineInputBorder(
                  //   borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  // ),
                  labelText: "Search"),
              onChanged: (value) {
                widget.functionSearch(value);
              },
              onSaved: (value) {
                widget.textEditingController.text = value.toString();
              },
            ),
            trailing: IconButton(
              icon: const Icon(Icons.cancel, color: Color.fromARGB(255, 15, 73, 121),),
              onPressed: () {
                widget.textEditingController.clear();
              },
            ),
          ),
        ));
  }
}
