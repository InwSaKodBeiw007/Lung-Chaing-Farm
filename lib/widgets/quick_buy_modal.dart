import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lung_chaing_farm/models/product.dart';

class QuickBuyModal extends StatefulWidget {
  final Product product;
  final Function(int productId, double quantity) onConfirmPurchase;

  const QuickBuyModal({
    super.key,
    required this.product,
    required this.onConfirmPurchase,
  });

  @override
  State<QuickBuyModal> createState() => _QuickBuyModalState();
}

class _QuickBuyModalState extends State<QuickBuyModal> {
  final TextEditingController _quantityController = TextEditingController();
  double _selectedQuantity = 1.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _quantityController.text = _selectedQuantity.toStringAsFixed(1);
    _quantityController.addListener(_validateQuantity);
  }

  @override
  void dispose() {
    _quantityController.removeListener(_validateQuantity);
    _quantityController.dispose();
    super.dispose();
  }

  void _validateQuantity() {
    setState(() {
      final double? value = double.tryParse(_quantityController.text);
      if (value == null || value <= 0) {
        _errorMessage = 'Quantity must be positive';
      } else if (value > widget.product.stock) {
        _errorMessage = 'Only ${widget.product.stock.toStringAsFixed(1)} kg available';
      } else {
        _errorMessage = null;
        _selectedQuantity = value;
      }
    });
  }

  void _incrementQuantity() {
    setState(() {
      double newQuantity = _selectedQuantity + 0.5;
      if (newQuantity <= widget.product.stock) {
        _selectedQuantity = newQuantity;
        _quantityController.text = _selectedQuantity.toStringAsFixed(1);
        _errorMessage = null;
      } else {
        _errorMessage = 'Only ${widget.product.stock.toStringAsFixed(1)} kg available';
      }
    });
  }

  void _decrementQuantity() {
    setState(() {
      double newQuantity = _selectedQuantity - 0.5;
      if (newQuantity >= 0.5) {
        _selectedQuantity = newQuantity;
        _quantityController.text = _selectedQuantity.toStringAsFixed(1);
        _errorMessage = null;
      } else {
        _errorMessage = 'Minimum quantity is 0.5 kg';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Buy ${widget.product.name}'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text('Price: ฿${widget.product.price.toStringAsFixed(2)}/kg'),
            Text('Available Stock: ${widget.product.stock.toStringAsFixed(1)} kg'),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle),
                  onPressed: _decrementQuantity,
                ),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                    ],
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: 'Quantity (kg)',
                      errorText: _errorMessage,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: _incrementQuantity,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          onPressed: _errorMessage == null && _selectedQuantity > 0
              ? () {
                  Navigator.of(context).pop();
                  widget.onConfirmPurchase(widget.product.id, _selectedQuantity);
                }
              : null,
          child: const Text('Buy'),
        ),
      ],
    );
  }
}