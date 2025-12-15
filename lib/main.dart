import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'views/main_screen.dart';
import 'views/order_summary_view.dart';
import 'views/payment_view.dart';
import 'views/history_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CartProvider())],
      child: MaterialApp(
        title: 'AdvWeb UAS POS Kasir Resto',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const MainScreen(),
          '/summary': (context) => const OrderSummaryView(),
          '/payment': (context) => const PaymentView(),
          '/history': (context) => const HistoryView(),
        },
      ),
    );
  }
}
