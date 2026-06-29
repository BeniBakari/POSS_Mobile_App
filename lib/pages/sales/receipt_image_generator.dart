import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
import 'package:poss_mobile_app/components/toast_widget.dart';

// ─── Static capture helper ─────────────────────────────────────────────────
class ReceiptCaptureService {
  static Future<Uint8List?> capture(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Capture Error: $e");
      return null;
    }
  }
}

// ─── Entry point ──────────────────────────────────────────────────────────
class ReceiptImageGenerator {
  static void show({
    required BuildContext context,
    required Map order,
    required Map shop,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReceiptSheet(order: order, shop: shop),
    );
  }
}

class _ReceiptSheet extends StatefulWidget {
  final Map order;
  final Map shop;
  const _ReceiptSheet({required this.order, required this.shop});

  @override
  State<_ReceiptSheet> createState() => _ReceiptSheetState();
}

class _ReceiptSheetState extends State<_ReceiptSheet> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _isCapturing = false;

  // ─── Palette ───────────────────────────────────────────────────────────────
  static const Color _blue900 = Color(0xFF0D2B6E);
  static const Color _blue700 = Color(0xFF1A56DB);
  static const Color _blue200 = Color(0xFFBFDBFE);
  static const Color _blue50  = Color(0xFFEFF6FF);
  static const Color _green   = Color(0xFF00B87C);
  static const Color _greenBg = Color(0xFFE6FAF4);
  static const Color _sky     = Color(0xFF38BDF8);

  String get _transId =>
      "TXN-${(widget.order['id'] ?? '0').toString().padLeft(8, '0')}";

  String get _formattedDate {
    try {
      return DateFormat('MMM dd, yyyy')
          .format(DateTime.parse(widget.order['created_at']));
    } catch (_) {
      return DateFormat('MMM dd, yyyy').format(DateTime.now());
    }
  }

  String get _formattedTime => DateFormat('hh:mm a').format(DateTime.now());

  // ─── Capture → PNG bytes ──────────────────────────────────────────────────
  Future<Uint8List?> _captureReceipt() async {
    // Extra frame delay so CustomPaint finishes drawing
    await Future.delayed(const Duration(milliseconds: 120));
    return ReceiptCaptureService.capture(_boundaryKey);
  }

  // ─── PNG → single-page receipt-width PDF ──────────────────────────────────
  Future<Uint8List> _pngToPdf(Uint8List png) async {
    final doc = pw.Document();
    final img = pw.MemoryImage(png);
    doc.addPage(
      pw.Page(
        // 80 mm receipt width, auto height
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 0,
        ),
        build: (_) => pw.Image(img, fit: pw.BoxFit.contain),
      ),
    );
    return doc.save();
  }

  // ─── Tap handler: capture then show action sheet ──────────────────────────
  Future<void> _showShareOptions() async {
    setState(() => _isCapturing = true);
    HapticFeedback.lightImpact();

    Uint8List? png;
    try {
      png = await _captureReceipt();
    } catch (e) {
      debugPrint('Capture error: $e');
    }

    if (!mounted) return;
    setState(() => _isCapturing = false);

    if (png == null) {
      toast('Failed to capture receipt');
      return;
    }

    final Uint8List capturedPng = png;

    showModalBottomSheet(
      // ignore: use_build_context_synchronously
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareSheet(
        // ── Save as Image ──────────────────────────────────────────────────
        onSaveImage: () async {
  Navigator.pop(_);
  // try {
  //   final dir = await getTemporaryDirectory();
  //   final file = File(
  //       '${dir.path}/Receipt_${DateTime.now().millisecondsSinceEpoch}.png');
  //   await file.writeAsBytes(capturedPng);
  //   await Share.shareXFiles(
  //     [XFile(file.path, mimeType: 'image/png')],
  //     subject: 'Receipt',
  //   );
  // } catch (e) {
  //   toast('Save failed');
  // }
},
        // ── Share as PDF ───────────────────────────────────────────────────
        onShare: () async {
          Navigator.pop(_);
          try {
            final pdfBytes = await _pngToPdf(capturedPng);
            await Printing.sharePdf(
              bytes: pdfBytes,
              filename:
                  'Receipt_${DateTime.now().millisecondsSinceEpoch}.pdf',
            );
          } catch (e) {
            toast('Share failed');
          }
        },
        // ── Print ──────────────────────────────────────────────────────────
        onPrint: () async {
          Navigator.pop(_);
          try {
            final pdfBytes = await _pngToPdf(capturedPng);
            await Printing.layoutPdf(
              onLayout: (_) async => pdfBytes,
              name: 'Receipt_${DateTime.now().millisecondsSinceEpoch}.pdf',
            );
          } catch (e) {
            toast('Print failed');
          }
        },
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF3F4F6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Top bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  const Text('Receipt',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937))),
                  const Spacer(),
                  _actionBtn(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    RepaintBoundary(
                      key: _boundaryKey,
                      child: _buildReceiptCard(),
                    ),
                    const SizedBox(height: 24),
                    _buildActionButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Action button ─────────────────────────────────────────────────────────
  Widget _buildActionButton() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_blue700, _blue900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _blue700.withValues(alpha: 0.32),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _isCapturing ? null : _showShareOptions,
        child: _isCapturing
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.ios_share_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Save / Share / Print',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 15.5,
                          letterSpacing: 0.2)),
                ],
              ),
      ),
    );
  }

  // ─── Receipt card (captured by RepaintBoundary) ────────────────────────────
  Widget _buildReceiptCard() {
    final List<dynamic> sales = widget.order['sales'] ?? [];
    final String discount = widget.order['discount']?.toString() ?? '0';
    final String totalGrand =
        widget.order['total_grand']?.toString() ?? '0';
    final String customerName =
        widget.order['customer_names'] ?? 'Walk-in Customer';
    final String shopName =
        widget.shop['name']?.toString() ?? 'POS SHOP';

    return Container(
      color: const Color(0xFFF3F4F6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SerratedEdge(isTop: true, color: _sky),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(children: [
              const SizedBox(height: 20),
              // Brand
              Column(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _blue50,
                    shape: BoxShape.circle,
                    border: Border.all(color: _blue200, width: 1.5),
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      color: _blue700, size: 24),
                ),
                const SizedBox(height: 8),
                Text(shopName.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F2937),
                        letterSpacing: 1.2)),
                const SizedBox(height: 2),
                const Text('Sales Receipt',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5)),
              ]),
              _dashDivider(),
              // Date / Time
              Row(children: [
                Expanded(child: _infoCell('Date', _formattedDate, false)),
                Expanded(child: _infoCell('Time', _formattedTime, true)),
              ]),
              _dashDivider(),
              // Customer
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Customer'),
                      const SizedBox(height: 6),
                      _customerRow(
                          Icons.person_outline_rounded, customerName),
                      if ((widget.order['customer_phone'] ?? '')
                          .isNotEmpty)
                        _customerRow(Icons.phone_outlined,
                            widget.order['customer_phone']),
                      if ((widget.order['customer_email'] ?? '')
                          .isNotEmpty)
                        _customerRow(Icons.email_outlined,
                            widget.order['customer_email']),
                      if ((widget.order['customer_address'] ?? '')
                          .isNotEmpty)
                        _customerRow(Icons.location_on_outlined,
                            widget.order['customer_address']),
                    ]),
              ),
              _dashDivider(),
              // Items
              Align(
                  alignment: Alignment.centerLeft,
                  child: _sectionLabel('Items')),
              const SizedBox(height: 8),
              const Row(children: [
                Expanded(
                    flex: 5,
                    child: Text('PRODUCT',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD1D5DB),
                            letterSpacing: 0.8))),
                Text('QTY',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD1D5DB),
                        letterSpacing: 0.8)),
                SizedBox(width: 8),
                SizedBox(
                    width: 90,
                    child: Text('TOTAL',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD1D5DB),
                            letterSpacing: 0.8))),
              ]),
              const SizedBox(height: 6),
              ...sales.asMap().entries.map((e) {
                final i = e.key;
                final sale = e.value;
                final product = sale['product'] ?? {};
                final String name =
                    product['name'] ?? 'Unknown Product';
                final int qty = sale['quantity'] ?? 1;
                final double price = double.tryParse(
                        product['price']?.toString() ?? '0') ??
                    0;
                final double lineTotal = qty * price;
                final List<Color> bgColors = [
                  _blue50,
                  const Color(0xFFEEF2FF),
                  const Color(0xFFE0F2FE),
                  const Color(0xFFEDE9FE),
                ];
                final List<Color> fgColors = [
                  _blue700,
                  const Color(0xFF4F46E5),
                  const Color(0xFF3B82F6),
                  const Color(0xFF7C3AED),
                ];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: bgColors[i % bgColors.length],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.inventory_2_rounded,
                            color: fgColors[i % fgColors.length],
                            size: 15),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 5,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1F2937)),
                                  overflow: TextOverflow.ellipsis),
                              Text(
                                  '@${price.toStringAsFixed(0)}/unit',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF9CA3AF))),
                            ]),
                      ),
                      Text('×$qty',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280))),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 90,
                        child: Text(
                            '${lineTotal.toStringAsFixed(0)} TZS',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1F2937))),
                      ),
                    ],
                  ),
                );
              }),
              _dashDivider(),
              // Totals
              _totalLine('Subtotal', '$totalGrand TZS'),
              if (discount != '0' && discount != '0.0') ...[
                const SizedBox(height: 4),
                _totalLine('Discount', '-$discount TZS',
                    valueColor: const Color(0xFFFF6B6B)),
              ],
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _blue50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _blue200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(children: [
                      Icon(Icons.receipt_long_rounded,
                          size: 14, color: _blue700),
                      SizedBox(width: 6),
                      Text('Grand Total',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _blue700)),
                    ]),
                    Text('$totalGrand TZS',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _blue900)),
                  ],
                ),
              ),
              _dashDivider(),
              // Status + TXN ID + QR
              Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _greenBg,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: _green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                              color: _green,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('Order Confirmed',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _green)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(_transId,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFD1D5DB),
                        letterSpacing: 2)),
                const SizedBox(height: 12),
                CustomPaint(
                    size: const Size(80, 80), painter: _QrPainter()),
                const SizedBox(height: 10),
                const Text('Thank you for your purchase!',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFD1D5DB),
                        letterSpacing: 0.3)),
                const SizedBox(height: 20),
              ]),
            ]),
          ),
          const _SerratedEdge(isTop: false, color: _sky),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  Widget _dashDivider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: List.generate(
            40,
            (i) => Expanded(
              child: Container(
                height: 1,
                color: i % 2 == 0
                    ? const Color(0xFFE5E7EB)
                    : Colors.transparent,
              ),
            ),
          ),
        ),
      );

  Widget _infoCell(String label, String value, bool right) => Column(
        crossAxisAlignment:
            right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937))),
        ],
      );

  Widget _sectionLabel(String text) => Text(text.toUpperCase(),
      style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFFD1D5DB),
          letterSpacing: 1));

  Widget _customerRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Icon(icon, size: 13, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937)))),
        ]),
      );

  Widget _totalLine(String label, String value, {Color? valueColor}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? const Color(0xFF374151))),
      ]);

  Widget _actionBtn(
          {required IconData icon, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        ),
      );
}

// ─── Share action sheet ────────────────────────────────────────────────────
class _ShareSheet extends StatelessWidget {
  final VoidCallback onSaveImage;
  final VoidCallback onShare;
  final VoidCallback onPrint;

  static const Color _blue700 = Color(0xFF1A56DB);
  static const Color _blue50  = Color(0xFFEFF6FF);
  static const Color _green   = Color(0xFF00B87C);
  static const Color _greenBg = Color(0xFFE6FAF4);

  const _ShareSheet({
    required this.onSaveImage,
    required this.onShare,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text('Receipt Options',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 20),
          _optionTile(
            icon: Icons.image_rounded,
            iconBg: _greenBg,
            iconColor: _green,
            title: 'Save as Image',
            subtitle: 'Save receipt PNG to your device',
            onTap: onSaveImage,
          ),
          const SizedBox(height: 12),
          _optionTile(
            icon: Icons.share_rounded,
            iconBg: _blue50,
            iconColor: _blue700,
            title: 'Share Receipt',
            subtitle: 'Share via WhatsApp, Telegram, email…',
            onTap: onShare,
          ),
          const SizedBox(height: 12),
          _optionTile(
            icon: Icons.print_rounded,
            iconBg: const Color(0xFFF3F4F6),
            iconColor: const Color(0xFF6B7280),
            title: 'Print',
            subtitle: 'Send to a nearby printer',
            onTap: onPrint,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('Cancel',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937))),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9CA3AF))),
                ]),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 20, color: Color(0xFFD1D5DB)),
        ]),
      ),
    );
  }
}

// ─── Serrated edge ─────────────────────────────────────────────────────────
class _SerratedEdge extends StatelessWidget {
  final bool isTop;
  final Color color;
  const _SerratedEdge({required this.isTop, required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 20,
        child: CustomPaint(
            painter: _SerratedPainter(isTop: isTop, color: color)),
      );
}

class _SerratedPainter extends CustomPainter {
  final bool isTop;
  final Color color;
  const _SerratedPainter({required this.isTop, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const double scallop = 16.0;
    final int count = (size.width / scallop).ceil() + 1;

    if (isTop) {
      canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height), paint);
      final wPath = Path();
      wPath.moveTo(0, size.height);
      for (int i = 0; i < count; i++) {
        wPath.quadraticBezierTo(i * scallop + scallop / 2, 0,
            (i + 1) * scallop, size.height);
      }
      wPath.lineTo(size.width, size.height);
      wPath.close();
      canvas.drawPath(wPath, Paint()..color = Colors.white);
    } else {
      canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height), paint);
      final wPath = Path();
      wPath.moveTo(0, 0);
      for (int i = 0; i < count; i++) {
        wPath.quadraticBezierTo(i * scallop + scallop / 2, size.height,
            (i + 1) * scallop, 0);
      }
      wPath.lineTo(size.width, 0);
      wPath.close();
      canvas.drawPath(wPath, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_SerratedPainter old) =>
      old.isTop != isTop || old.color != color;
}

// ─── QR placeholder painter ────────────────────────────────────────────────
class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..style = PaintingStyle.fill;

    void dot(double x, double y, double w, double h) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, w, h), const Radius.circular(1)),
          p);
    }

    void finder(double x, double y) {
      dot(x, y, 18, 18);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x + 3, y + 3, 12, 12),
              const Radius.circular(1)),
          Paint()..color = Colors.white);
      dot(x + 5, y + 5, 8, 8);
    }

    finder(0, 0);
    finder(62, 0);
    finder(0, 62);

    for (final pos in [
      [28.0, 2.0],  [36.0, 2.0],  [44.0, 2.0],
      [28.0, 10.0], [44.0, 10.0], [36.0, 18.0],
      [2.0, 28.0],  [10.0, 28.0], [2.0, 36.0],  [18.0, 36.0],
      [10.0, 44.0], [28.0, 28.0], [36.0, 28.0], [44.0, 28.0], [52.0, 28.0],
      [28.0, 36.0], [44.0, 36.0], [36.0, 44.0], [52.0, 44.0],
      [28.0, 52.0], [44.0, 52.0], [44.0, 60.0], [60.0, 52.0],
      [60.0, 60.0], [52.0, 60.0],
    ]) {
      dot(pos[0], pos[1], 4, 4);
    }
  }

  @override
  bool shouldRepaint(_QrPainter _) => false;
}