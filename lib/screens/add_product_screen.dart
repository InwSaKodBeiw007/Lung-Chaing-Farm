// lib/screens/add_product_screen.dart
import 'dart:io';
import 'dart:typed_data'; // Add this import for Uint8List
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lung_chaing_farm/services/api_service.dart';
import 'package:lung_chaing_farm/services/audio_service.dart'; // Import AudioService

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  XFile? _imageFile;
  Uint8List? _pickedImageBytes; // New: Store image bytes for web preview
  bool _isLoading = false;

  Future<void> _pickImage() async {
    AudioService.playClickSound(); // Play sound on pick image
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = image;
      if (image != null) {
        image.readAsBytes().then((bytes) {
          setState(() {
            _pickedImageBytes = bytes; // Store bytes for web preview
          });
        });
      }
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      AudioService.playClickSound(); // Play sound on add product submit
      setState(() {
        _isLoading = true;
      });

      try {
        final String name = _nameController.text;
        final double price = double.parse(_priceController.text);
        final double stock = double.parse(_stockController.text);
        
        // Read image bytes and get the name for the multipart request
        final imageBytes = _imageFile != null ? await _imageFile!.readAsBytes() : null;
        final imageName = _imageFile?.name;

        await ApiService.addProduct(
          name,
          price,
          stock,
          imageBytes: imageBytes != null ? [imageBytes] : null,
          imageNames: imageName != null ? [imageName] : null
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully!')),
        );
        Navigator.pop(context, true); // Pop with true to indicate success
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
        backgroundColor: Colors.lightGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AudioService.playClickSound(); // Play sound
            Navigator.pop(context); // Then pop
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price per KG'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock in KG'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter stock quantity';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _imageFile == null
                  ? const Text('No image selected.')
                  // Use Image.memory for web compatibility with the blob URL from image_picker
                  : kIsWeb && _pickedImageBytes != null
                    ? Image.memory(_pickedImageBytes!, height: 150)
                    : Image.file(File(_imageFile!.path), height: 150),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Pick Image'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreen),
                child: const Text('Add Product', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
