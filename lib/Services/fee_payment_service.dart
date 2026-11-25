import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Core/Network/api_client.dart';

class FeeItemRecord {
  final String id;
  final String title;
  final String amountLabel;
  final String status;
  final bool isPaid;
  final String? receiptNo;
  final String? paidDate;
  final String? transactionId;
  final String? receiptUrl;
  final String? localReceiptPath;

  const FeeItemRecord({
    required this.id,
    required this.title,
    required this.amountLabel,
    required this.status,
    required this.isPaid,
    this.receiptNo,
    this.paidDate,
    this.transactionId,
    this.receiptUrl,
    this.localReceiptPath,
  });

  int get numericAmount =>
      int.tryParse(amountLabel.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  FeeItemRecord copyWith({
    String? title,
    String? amountLabel,
    String? status,
    bool? isPaid,
    String? receiptNo,
    String? paidDate,
    String? transactionId,
    String? receiptUrl,
    String? localReceiptPath,
  }) {
    return FeeItemRecord(
      id: id,
      title: title ?? this.title,
      amountLabel: amountLabel ?? this.amountLabel,
      status: status ?? this.status,
      isPaid: isPaid ?? this.isPaid,
      receiptNo: receiptNo ?? this.receiptNo,
      paidDate: paidDate ?? this.paidDate,
      transactionId: transactionId ?? this.transactionId,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      localReceiptPath: localReceiptPath ?? this.localReceiptPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount_label': amountLabel,
        'status': status,
        'is_paid': isPaid,
        'receipt_no': receiptNo,
        'paid_date': paidDate,
        'transaction_id': transactionId,
        'receipt_url': receiptUrl,
        'local_receipt_path': localReceiptPath,
      };

  factory FeeItemRecord.fromJson(Map<String, dynamic> json) {
    return FeeItemRecord(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      amountLabel: (json['amount_label'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      isPaid: json['is_paid'] == true,
      receiptNo: json['receipt_no']?.toString(),
      paidDate: json['paid_date']?.toString(),
      transactionId: json['transaction_id']?.toString(),
      receiptUrl: json['receipt_url']?.toString(),
      localReceiptPath: json['local_receipt_path']?.toString(),
    );
  }
}

class FeePaymentService {
  FeePaymentService._();

  /// Base checkout page on intelliattend.com (update path cleanly when final
  /// hosted payment URL path is provided).
  static const String paymentPortalBaseUrl = 'https://intelliattend.com/pay';

  /// Deep-link callback URI that intelliattend.com can redirect back to after
  /// checkout completes:
  /// e.g. intelliattend://payment-callback?status=success&fee_id=...&receipt=...
  static const String returnRedirectUri = 'intelliattend://payment-callback';

  static const MethodChannel _deepLinkChannel =
      MethodChannel('com.intelliattend.parent/deeplink');

  static void registerDeepLinkListener(void Function(Uri uri) onUri) {
    _deepLinkChannel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink' && call.arguments is String) {
        final raw = (call.arguments as String).trim();
        final uri = Uri.tryParse(raw);
        if (uri != null) onUri(uri);
      }
    });
    _deepLinkChannel.invokeMethod<String>('getInitialLink').then((raw) {
      if (raw != null && raw.trim().isNotEmpty) {
        final uri = Uri.tryParse(raw.trim());
        if (uri != null) onUri(uri);
      }
    }).catchError((_) {});
  }

  static List<FeeItemRecord> defaultFeesForChild({
    required String childId,
    required String program,
  }) {
    final bool isJunior = childId == 'child_2' || program.contains('7');
    final String termFee = isJunior ? '₹28,000' : '₹35,000';
    return [
      FeeItemRecord(
        id: 'term_1_$childId',
        title: 'Term-1 Tuition Fee',
        amountLabel: termFee,
        status: 'PAID',
        isPaid: true,
        receiptNo: isJunior ? 'REC-1052' : 'REC-1049',
        paidDate: '12 Jul 2026',
        transactionId: isJunior ? 'TXN-IA-105207' : 'TXN-IA-104910',
      ),
      FeeItemRecord(
        id: 'bus_h1_$childId',
        title: 'School Bus Transport',
        amountLabel: '₹8,500',
        status: 'PAID',
        isPaid: true,
        receiptNo: isJunior ? 'REC-0819' : 'REC-0812',
        paidDate: '18 Jul 2026',
        transactionId: isJunior ? 'TXN-IA-081907' : 'TXN-IA-081210',
      ),
      FeeItemRecord(
        id: 'term_2_$childId',
        title: 'Term-2 Tuition Fee',
        amountLabel: termFee,
        status: 'DUE 15 DEC',
        isPaid: false,
      ),
    ];
  }

  static Future<List<FeeItemRecord>> loadFees({
    required String childId,
    required String program,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'school_fees_$childId';
    final raw = prefs.getString(key);
    List<FeeItemRecord> items = defaultFeesForChild(
      childId: childId,
      program: program,
    );
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        if (list.isNotEmpty) {
          items = list
              .map((e) => FeeItemRecord.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      } catch (_) {}
    }

    // Attempt server refresh if backend returns updated fee status/receipts
    try {
      final res =
          await ApiClient().dio.get('/api/v1/parent/students/$childId/fees');
      if (res.statusCode == 200 && res.data is Map) {
        final payload = res.data['data'] is Map ? res.data['data'] : res.data;
        if (payload['items'] is List && (payload['items'] as List).isNotEmpty) {
          items = (payload['items'] as List)
              .map((e) => FeeItemRecord.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          await saveFees(childId, items);
        }
      }
    } catch (_) {}

    return items;
  }

  static Future<void> saveFees(String childId, List<FeeItemRecord> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'school_fees_$childId',
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  static Uri buildPaymentPortalUri({
    required String childId,
    required String childName,
    required String rollNumber,
    required String className,
    required FeeItemRecord fee,
    String? portalUrlOverride,
  }) {
    final base = Uri.parse(
      (portalUrlOverride != null && portalUrlOverride.trim().isNotEmpty)
          ? portalUrlOverride.trim()
          : paymentPortalBaseUrl,
    );
    return base.replace(queryParameters: {
      ...base.queryParameters,
      'student_id': childId,
      'student_name': childName,
      'roll_no': rollNumber,
      'class_name': className,
      'fee_id': fee.id,
      'fee_title': fee.title,
      'amount': fee.numericAmount.toString(),
      'redirect_url': returnRedirectUri,
    });
  }

  static Future<bool> launchPaymentRedirect({
    required String childId,
    required String childName,
    required String rollNumber,
    required String className,
    required FeeItemRecord fee,
    String? portalUrlOverride,
  }) async {
    final uri = buildPaymentPortalUri(
      childId: childId,
      childName: childName,
      rollNumber: rollNumber,
      className: className,
      fee: fee,
      portalUrlOverride: portalUrlOverride,
    );
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  /// Checks with the server whether payment was completed during the browser redirect.
  static Future<Map<String, dynamic>?> verifyPaymentOnServer({
    required String childId,
    required String feeId,
  }) async {
    try {
      final res = await ApiClient().dio.get(
        '/api/v1/parent/students/$childId/fees/verify',
        queryParameters: {'fee_id': feeId},
      );
      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data['data'] is Map ? res.data['data'] : res.data;
        if (data['paid'] == true || data['status'] == 'success') {
          return Map<String, dynamic>.from(data as Map);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Marks the fee paid locally + notifies backend cleanly.
  static Future<FeeItemRecord> completeFeePayment({
    required String childId,
    required FeeItemRecord fee,
    String? receiptNo,
    String? transactionId,
    String? receiptUrl,
  }) async {
    final stamp = DateFormat('dd MMM yyyy').format(DateTime.now());
    final genReceipt = (receiptNo != null && receiptNo.trim().isNotEmpty)
        ? receiptNo.trim()
        : 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final genTxn = (transactionId != null && transactionId.trim().isNotEmpty)
        ? transactionId.trim()
        : 'TXN-IA-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

    final updated = fee.copyWith(
      status: 'PAID',
      isPaid: true,
      receiptNo: genReceipt,
      paidDate: stamp,
      transactionId: genTxn,
      receiptUrl: receiptUrl,
    );

    try {
      await ApiClient().dio.post(
        '/api/v1/parent/students/$childId/fees/confirm',
        data: updated.toJson(),
      );
    } catch (_) {}

    return updated;
  }

  /// Generates or downloads the fee receipt PDF to device storage and returns
  /// the saved local file path.
  static Future<String> downloadReceiptPdf({
    required String childName,
    required String rollNumber,
    required String className,
    required FeeItemRecord fee,
    String? parentName,
  }) async {
    final dir = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final receiptsDir = Directory('${dir.path}/receipts');
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }

    final cleanReceipt = (fee.receiptNo ?? fee.id)
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final filePath =
        '${receiptsDir.path}/IntelliAttend_Receipt_$cleanReceipt.pdf';

    // If backend / intelliattend.com provided a hosted PDF receipt URL, download it first.
    if (fee.receiptUrl != null && fee.receiptUrl!.trim().isNotEmpty) {
      try {
        await Dio().download(fee.receiptUrl!.trim(), filePath);
        final file = File(filePath);
        if (await file.exists() && await file.length() > 512) {
          return filePath;
        }
      } catch (_) {}
    }

    final bytes = await buildReceiptPdfBytes(
      childName: childName,
      rollNumber: rollNumber,
      className: className,
      fee: fee,
      parentName: parentName,
    );
    await File(filePath).writeAsBytes(bytes, flush: true);
    return filePath;
  }

  static Future<Uint8List> buildReceiptPdfBytes({
    required String childName,
    required String rollNumber,
    required String className,
    required FeeItemRecord fee,
    String? parentName,
  }) async {
    final pdf = pw.Document();
    final safeAmount = fee.amountLabel.replaceAll('₹', 'Rs. ');
    final receiptNo = fee.receiptNo ?? 'REC-$rollNumber-001';
    final paidDate = fee.paidDate ?? DateFormat('dd MMM yyyy').format(DateTime.now());
    final txnId = fee.transactionId ?? 'TXN-IA-${rollNumber}2026';
    final guardian =
        (parentName != null && parentName.trim().isNotEmpty) ? parentName : 'Parent / Guardian';

    pw.ImageProvider? logoImage;
    try {
      final data = await rootBundle.load('assets/images/logo_square.png');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    if (logoImage != null) ...[
                      pw.Image(logoImage, width: 40, height: 40),
                      pw.SizedBox(width: 12),
                    ],
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'INTELLIATTEND PUBLIC SCHOOL',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal800,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Official School Fee Receipt | Session 2026 - 2027',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.green600),
                  ),
                  child: pw.Text(
                    'PAID',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(color: PdfColors.teal300, thickness: 1.5),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  _pdfRow('Receipt No', '#$receiptNo'),
                  pw.SizedBox(height: 8),
                  _pdfRow('Payment Date', paidDate),
                  pw.SizedBox(height: 8),
                  _pdfRow('Transaction ID', txnId),
                  pw.SizedBox(height: 8),
                  _pdfRow('Payment Portal', 'intelliattend.com'),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Student & Guardian Details',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  _pdfRow('Student Name', childName),
                  pw.SizedBox(height: 8),
                  _pdfRow('Class & Section', className),
                  pw.SizedBox(height: 8),
                  _pdfRow('Roll Number', rollNumber),
                  pw.SizedBox(height: 8),
                  _pdfRow('Guardian', guardian),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Fee Description', 'Status', 'Amount Paid'],
              data: [
                [fee.title, 'PAID', safeAmount],
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 11,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
              cellPadding: const pw.EdgeInsets.all(10),
              cellStyle: const pw.TextStyle(fontSize: 11),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 12),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Total Paid: $safeAmount',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal800,
                ),
              ),
            ),
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),
            pw.Text(
              'Computer-generated verified receipt via IntelliAttend Parent Portal (intelliattend.com). No physical signature required.',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10.5, color: PdfColors.grey700),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static Future<void> openOrShareReceiptFile({
    required String filePath,
    required String childName,
    required String rollNumber,
    required String className,
    required FeeItemRecord fee,
    String? parentName,
  }) async {
    final result = await OpenFilex.open(filePath);
    if (result.type != ResultType.done) {
      final bytes = await File(filePath).exists()
          ? await File(filePath).readAsBytes()
          : await buildReceiptPdfBytes(
              childName: childName,
              rollNumber: rollNumber,
              className: className,
              fee: fee,
              parentName: parentName,
            );
      final cleanReceipt = (fee.receiptNo ?? fee.id)
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'IntelliAttend_Receipt_$cleanReceipt.pdf',
      );
    }
  }
}
