import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:wallet_app/dashboard/dashboard_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> transactionData;
  final String category;
  final String provider;
  final String number;
  final double amount;
  final String? plan;

  const TransactionDetailsScreen({
    Key? key,
    required this.transactionData,
    required this.category,
    required this.provider,
    required this.number,
    required this.amount,
    this.plan,
  }) : super(key: key);

  String _formatDate(String? dateStr) {
    try {
      if (dateStr == null) return 'N/A';
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatAmount(dynamic amount) {
    try {
      if (amount == null) return '₦0.00';
      final formatter = NumberFormat.currency(symbol: '₦', decimalDigits: 2);
      return formatter.format(double.parse(amount.toString()));
    } catch (e) {
      return '₦0.00';
    }
  }

  Color _getCategoryColor() {
    switch (category) {
      case "Airtime":
        return Colors.blue;
      case "Internet":
        return Colors.green;
      case "Electricity":
        return Colors.orange;
      case "TV Subscription":
        return Colors.red;
      default:
        return Colors.purple;
    }
  }

  IconData _getCategoryIcon() {
    switch (category) {
      case "Airtime":
        return FontAwesomeIcons.phone;
      case "Internet":
        return FontAwesomeIcons.wifi;
      case "Electricity":
        return FontAwesomeIcons.bolt;
      case "TV Subscription":
        return FontAwesomeIcons.tv;
      default:
        return FontAwesomeIcons.moneyBill;
    }
  }

  Future<void> _shareReceipt() async {
    final receiptText = '''
Payment Receipt

Amount: ${_formatAmount(amount)}
Category: $category
Provider: $provider
${category == "Electricity" ? "Meter Number" : "Phone Number"}: $number
${plan != null ? "Plan: $plan\n" : ""}Status: ${transactionData['status'] ?? 'Completed'}
Date: ${_formatDate(transactionData['created_at']?.toString())}
Transaction ID: ${transactionData['id']?.toString() ?? 'N/A'}
''';

    await Share.share(receiptText, subject: '$category Payment Receipt');
  }

  Future<void> _downloadReceipt(BuildContext context) async {
    try {
      // Create PDF document
      final pdf = pw.Document();

      // Add page to PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'Payment Receipt',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                _buildPdfRow('Amount', _formatAmount(amount)),
                _buildPdfRow('Category', category),
                _buildPdfRow('Provider', provider),
                _buildPdfRow(
                  category == "Electricity" ? "Meter Number" : "Phone Number",
                  number,
                ),
                if (plan != null) _buildPdfRow('Plan', plan!),
                _buildPdfRow(
                  'Status',
                  transactionData['status']?.toString() ?? 'Completed',
                ),
                _buildPdfRow(
                  'Date',
                  _formatDate(transactionData['created_at']?.toString()),
                ),
                _buildPdfRow(
                  'Transaction ID',
                  transactionData['id']?.toString() ?? 'N/A',
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  'Thank you for using our service!',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Get temporary directory
      final output = await getTemporaryDirectory();
      final file = File(
        '${output.path}/receipt_${transactionData['id'] ?? DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      // Save PDF
      await file.writeAsBytes(await pdf.save());

      // Open PDF
      await OpenFile.open(file.path);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt downloaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor();
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.black),
            onPressed: _shareReceipt,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status Card
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCategoryIcon(),
                      color: color,
                      size: 32,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Payment Successful",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _formatAmount(amount),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _formatDate(transactionData['created_at']?.toString()),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Transaction Details
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Transaction Details",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildDetailRow("Transaction ID", transactionData['id']?.toString() ?? 'N/A'),
                  _buildDetailRow("Category", category),
                  _buildDetailRow("Provider", provider),
                  _buildDetailRow(
                    category == "Electricity" ? "Meter Number" : "Phone Number",
                    number
                  ),
                  if (plan != null) _buildDetailRow("Plan", plan!),
                  _buildDetailRow("Status", transactionData['status']?.toString() ?? "Completed", valueColor: Colors.green),
                  _buildDetailRow(
                    "New Balance",
                    _formatAmount(transactionData['balance']),
                    valueColor: Colors.blue,
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Action Buttons
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _downloadReceipt(context),
                      child: Text(
                        "Download Receipt",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        side: BorderSide(color: color),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        // Navigate to DashboardScreen
                        Get.offAll(() => DashboardScreen());
                      },
                      child: Text(
                        "Back to Home",
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 