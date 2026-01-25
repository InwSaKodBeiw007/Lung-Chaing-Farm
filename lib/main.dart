import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lung_chaing_farm/providers/auth_provider.dart';
import 'package:lung_chaing_farm/providers/low_stock_provider.dart'; // Import LowStockProvider
import 'package:lung_chaing_farm/screens/villager/villager_dashboard_screen.dart';

import 'package:lung_chaing_farm/services/notification_service.dart'; // Import NotificationService
import 'package:lung_chaing_farm/services/api_service.dart'; // Import ApiService

import 'package:lung_chaing_farm/screens/one_page_marketplace_screen.dart'; // Import OnePageMarketplaceScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(
          create: (context) => LowStockProvider(ApiService.instance),
        ),
      ],
      child: MaterialApp(
        title: 'Lung Chaing Farm',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
          useMaterial3: true,
        ),
        scaffoldMessengerKey:
            NotificationService.messengerKey, // Set the messenger key
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isAuthenticated) {
          if (authProvider.user != null && authProvider.user!.role == 'VILLAGER') {
            return const VillagerDashboardScreen();
            // } else if (authProvider.user!.role == 'USER') {
            // return const UserHomeScreen(); // Placeholder for now
          }
        }
        // If not authenticated or role not handled, show the public product list
        return const OnePageMarketplaceScreen(); // Changed to OnePageMarketplaceScreen
      },
    );
  }
}
