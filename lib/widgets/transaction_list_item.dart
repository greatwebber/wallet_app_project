import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class TransactionListItem extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final bool isCompact;

  const TransactionListItem({
    Key? key,
    required this.transaction,
    this.isCompact = false,
  }) : super(key: key);

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat(isCompact ? 'MMM dd, HH:mm' : 'MMM dd, yyyy HH:mm')
          .format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatAmount(dynamic amount) {
    try {
      final formatter = NumberFormat.currency(symbol: '₦', decimalDigits: 2);
      return formatter.format(double.parse(amount.toString()));
    } catch (e) {
      return '₦${amount.toString()}';
    }
  }

  IconData _getTransactionIcon(String type, String? category) {
    switch (type) {
      case "credit":
        return FontAwesomeIcons.moneyBillWave;
      case "bill_payment":
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
            return FontAwesomeIcons.receipt;
        }
      case "debit":
        return FontAwesomeIcons.arrowUp;
      default:
        return FontAwesomeIcons.moneyBill;
    }
  }

  Color _getTransactionColor(String type, String? category) {
    switch (type) {
      case "credit":
        return Colors.green;
      case "bill_payment":
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
      case "debit":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTransactionTitle(Map<String, dynamic> transaction) {
    final type = transaction["type"];
    final category = transaction["category"];
    final provider = transaction["provider"];
    final recipient = transaction["recipient"];

    if (type == "bill_payment") {
      if (provider != null) {
        return "$category - $provider";
      }
      return category ?? "Bill Payment";
    } else if (type == "credit") {
      return "Received from ${recipient ?? 'Unknown'}";
    } else if (type == "debit") {
      return "Sent to ${recipient ?? 'Unknown'}";
    }
    return "Transaction";
  }

  String _getTransactionSubtitle(Map<String, dynamic> transaction) {
    final type = transaction["type"];
    final category = transaction["category"];
    final number = transaction["number"];
    final date = _formatDate(transaction["created_at"]);

    if (type == "bill_payment") {
      return "${number ?? 'N/A'} • $date";
    }
    return date;
  }

  @override
  Widget build(BuildContext context) {
    final type = transaction["type"];
    final category = transaction["category"];
    final amount = transaction["amount"];

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
      ),
      elevation: isCompact ? 1 : 3,
      margin: EdgeInsets.symmetric(
        vertical: isCompact ? 4 : 8,
        horizontal: isCompact ? 0 : 8,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 4 : 8,
        ),
        leading: CircleAvatar(
          radius: isCompact ? 20 : 24,
          backgroundColor: _getTransactionColor(type, category).withOpacity(0.1),
          child: Icon(
            _getTransactionIcon(type, category),
            color: _getTransactionColor(type, category),
            size: isCompact ? 16 : 20,
          ),
        ),
        title: Text(
          _getTransactionTitle(transaction),
          style: TextStyle(
            fontSize: isCompact ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          _getTransactionSubtitle(transaction),
          style: TextStyle(
            color: Colors.grey,
            fontSize: isCompact ? 12 : 14,
          ),
        ),
        trailing: Text(
          (type == "credit" ? "+" : "-") + _formatAmount(amount),
          style: TextStyle(
            fontSize: isCompact ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: _getTransactionColor(type, category),
          ),
        ),
      ),
    );
  }
} 