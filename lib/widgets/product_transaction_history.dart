import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lung_chaing_farm/services/api_service.dart';
import 'package:lung_chaing_farm/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ProductTransactionHistory extends StatefulWidget {
  final int productId;
  const ProductTransactionHistory({super.key, required this.productId});

  @override
  State<ProductTransactionHistory> createState() =>
      _ProductTransactionHistoryState();
}

class _ProductTransactionHistoryState extends State<ProductTransactionHistory> {
  late Future<List<Map<String, dynamic>>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  void _fetchTransactions() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated && authProvider.token != null) {
      _transactionsFuture = ApiService.instance.getProductTransactions(
        widget.productId,
        days: 30, // Default to last 30 days, can be made configurable
      );
    } else {
      _transactionsFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _transactionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No transactions found.'));
        } else {
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final transaction = snapshot.data![index];
              final String formattedDate = DateFormat('MMM d, yyyy HH:mm')
                  .format(
                    DateTime.fromMillisecondsSinceEpoch(
                      transaction['date_of_sale'] * 1000,
                    ),
                  );
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  '${transaction['quantity_sold']}kg sold on $formattedDate',
                  style: const TextStyle(fontSize: 14.0),
                ),
              );
            },
          );
        }
      },
    );
  }
}
