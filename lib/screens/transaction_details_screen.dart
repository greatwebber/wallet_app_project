import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:wallet_app/dashboard/home_screen.dart';

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
            onPressed: () {
              // TODO: Implement share functionality
            },
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
                      onPressed: () {
                        // TODO: Implement download receipt
                      },
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
                        // Navigate to HomeScreen
                        Get.offAll(() => HomeScreen());
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