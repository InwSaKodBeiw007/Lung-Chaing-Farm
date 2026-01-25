import 'package:flutter/material.dart';
import 'package:lung_chaing_farm/screens/product_list_screen.dart'; // Import ProductListScreen

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.lightGreen.shade100, // Example background color
      child: Column(
        children: [
          Text(
            'KK Farm',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.lightGreen.shade800,
            ),
          ),
          const SizedBox(height: 16.0),
          // Placeholder for banner image
          Image.asset(
            'assets/icons/619596972_2462281857500309_4747521641832785357_n.jpg', // New image asset
            height: 200,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductListScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightGreen.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('View Today\'s Products'),
          ),
          // TODO: Implement anchor links later
        ],
      ),
    );
  }
}
