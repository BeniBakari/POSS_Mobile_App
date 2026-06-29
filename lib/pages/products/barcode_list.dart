import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BarcodeList extends StatefulWidget {
  final Map product;
  const BarcodeList({super.key, required this.product});

  @override
  State<BarcodeList> createState() => _BarcodeListState();
}

class _BarcodeListState extends State<BarcodeList> {
  final pdf = pw.Document();
  @override
  Widget build(BuildContext context) {
    return PdfPreview(
      build: (format) => makePdf(),
    );
  }

  Future<Uint8List> makePdf() async {
    Map product = widget.product;
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      margin: const pw.EdgeInsets.all(10),
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Column(children: [
          pw.Header(child: pw.Column(children: [
            pw.Text( "128 ${product['name'].toString().toUpperCase()} BARCODES"),
            pw.Header(child: pw.Text(product['description'].toString())),
          ])),
          
          pw.GridView(
              crossAxisCount: 8,
              childAspectRatio: 0.5,
              mainAxisSpacing: 17.0,
              crossAxisSpacing: 17.0,
              children: [
                for (int i = 0; i < 128; i++)
                  pw.BarcodeWidget(
                      data: product['barcode'].toString(),
                      barcode: pw.Barcode.code128(),
                      width: 100,
                      height: 50),
              ]),
          pw.Footer(title: pw.Text(DateTime.now().toString().substring(0,16))),
        ]);
      },
    ));
    return pdf.save();
  }

  void generateBarcode() {}
}
