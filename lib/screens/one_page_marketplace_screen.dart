import 'package:flutter/material.dart';
import 'package:lung_chaing_farm/sections/hero_section.dart';
import 'package:lung_chaing_farm/sections/product_list_section.dart';
import 'package:provider/provider.dart';
import 'package:lung_chaing_farm/providers/auth_provider.dart';

class OnePageMarketplaceScreen extends StatelessWidget {
  const OnePageMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final String? farmName = authProvider.user?.farmName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lung Chaing Farm'),
        actions: [
          if (farmName != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  'Welcome, $farmName!',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: const [
            HeroSection(),
            ProductListSection(
              category: 'Vegetable',
              title: 'Fresh Vegetables',
            ),
            ProductListSection(category: 'Fruit', title: 'Delicious Fruits'),
            // Add more sections as needed
          ],
        ),
      ),
    );
  }
}
