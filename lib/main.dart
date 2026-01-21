import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lung_chaing_farm/providers/auth_provider.dart';
import 'package:lung_chaing_farm/screens/product_list_screen.dart';
import 'package:lung_chaing_farm/screens/villager/villager_dashboard_screen.dart';
import 'package:lung_chaing_farm/screens/user/user_home_screen.dart'; // Will be implemented later

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        title: 'Lung Chaing Farm',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
          useMaterial3: true,
        ),
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
          if (authProvider.user!.role == 'VILLAGER') {
            return const VillagerDashboardScreen();
          } else if (authProvider.user!.role == 'USER') {
            return const UserHomeScreen(); // Placeholder for now
          }
        }
        // If not authenticated or role not handled, show the public product list
        return const ProductListScreen();
      },
    );
  }
}
