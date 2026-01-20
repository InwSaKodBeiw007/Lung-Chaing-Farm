import 'package:flutter/material.dart';
import 'package:lung_chaing_farm/screens/product_list_screen.dart'; // Import your product list screen
import 'package:lung_chaing_farm/services/audio_service.dart'; // Import AudioService

void main() async { // Make main async
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized
  await AudioService.loadSound(); // Pre-load the click sound
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lung Chaing Farm', // Updated title
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen), // Farm-themed color
        useMaterial3: true,
      ),
      home: const ProductListScreen(), // Set ProductListScreen as the home screen
    );
  }
}
