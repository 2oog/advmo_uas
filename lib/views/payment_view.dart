import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../services/bluetooth_print_service.dart';

class PaymentView extends StatefulWidget {
  const PaymentView({super.key});

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  Order? _completedOrder;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    final cart = context.read<CartProvider>();
    setState(() {
      _isLoading = true;
    });

    try {
      // Mock payment delay
      await Future.delayed(const Duration(seconds: 2));

      // Prepare items for API
      final items = cart.items.map((item) {
        return {'id': item.menuItem.id, 'quantity': item.quantity};
      }).toList();

      // Create Order
      final tableNumber = cart.tableNumber ?? '';
      if (tableNumber.isEmpty) {
        throw Exception('Table number is missing');
      }

      final order = await _apiService.createOrder('QRIS', tableNumber, items);

      // Clear cart
      cart.clearCart();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _completedOrder = order;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
      }
    }
  }

  Future<void> _printReceipt() async {
    if (_completedOrder == null) return;
    try {
      final printService = context.read<BluetoothPrintService>();

      if (!printService.isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Printer not connected! Please go to Settings.'),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🖨️ Printing Receipt via Bluetooth...')),
      );

      await printService.printReceipt(_completedOrder!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Print error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_completedOrder != null) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'Payment',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          final formatter = NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp ',
            decimalDigits: 0,
          );

          // SUCCESS STATE
          if (_completedOrder != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 40,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Payment Successful!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Order #${_completedOrder!.id} has been processed.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _printReceipt,
                        icon: const Icon(Icons.print),
                        label: const Text('Print Receipt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[900],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          // Done (Go to History or Menu)
                          // The prompt asked for MainScreen to be persistent likely, but for now pop to root is easiest
                          // Ideally switch index to History tab if we can access it
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          foregroundColor: Colors.grey[800],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // SCAN STATE
          return Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'QRIS PAYMENT',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      formatter.format(cart.total),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 8),
                    Text(
                      'Table: ${cart.tableNumber ?? "-"}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Scan to pay',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    // QR Placeholder
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 4),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x1A000000),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Add pattern if possible or just simple blocks
                          const Icon(Icons.qr_code_2, size: 200),
                          Container(
                            padding: const EdgeInsets.all(4),
                            color: Colors.white,
                            child: const Text(
                              'QRIS',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_isLoading)
                      FadeTransition(
                        opacity: _animController,
                        child: const Text(
                          'Waiting for payment...',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      const Text(
                        'Waiting for payment...',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _processPayment,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      _isLoading ? 'Processing...' : 'Payment Received',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
