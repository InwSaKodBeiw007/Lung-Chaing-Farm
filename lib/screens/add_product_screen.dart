// lib/screens/add_product_screen.dart
import 'dart:io';
// Add this import for Uint8List
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lung_chaing_farm/services/api_service.dart';
import 'package:lung_chaing_farm/services/audio_service.dart'; // Import AudioService
import 'package:lung_chaing_farm/services/notification_service.dart'; // Import NotificationService

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
  final _lowStockThresholdController = TextEditingController(
    text: '7',
  ); // New controller with default
  String? _selectedCategory; // New for category

  final List<XFile> _newImageFiles = []; // For new images
  final List<Uint8List> _newPickedImageBytes = []; // For new images on web
  bool _isLoading = false;

  Future<void> _pickNewImage() async {
    AudioService.playClickSound();
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _newImageFiles.addAll(images);
        if (kIsWeb) {
          for (var image in images) {
            image.readAsBytes().then((bytes) {
              setState(() {
                _newPickedImageBytes.add(bytes);
              });
            });
          }
        }
      });
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImageFiles.removeAt(index);
      if (kIsWeb) {
        _newPickedImageBytes.removeAt(index);
      }
    });
  }

  Future<void> _submitForm() async {
    AudioService.playClickSound(); // Play sound immediately on button press
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final String name = _nameController.text;
      final double price = double.parse(_priceController.text);
      final double stock = double.parse(_stockController.text);
      final double lowStockThreshold = double.parse(
        _lowStockThresholdController.text,
      );

      // Prepare new image bytes and names
      final List<Uint8List> imageBytesToUpload = [];
      final List<String> imageNamesToUpload = [];

      for (var i = 0; i < _newImageFiles.length; i++) {
        imageBytesToUpload.add(await _newImageFiles[i].readAsBytes());
        imageNamesToUpload.add(_newImageFiles[i].name);
      }

      await ApiService.instance.addProduct(
        name,
        price,
        stock,
        category: _selectedCategory,
        lowStockThreshold: lowStockThreshold,
        imageBytes: imageBytesToUpload,
        imageNames: imageNamesToUpload,
      );

      if (mounted) {
        // Add mounted check
        NotificationService.showSnackBar('Product added successfully!');
        Navigator.pop(context, true); // Pop with true to indicate success
      }
    } catch (e) {
      NotificationService.showSnackBar(
        'Failed to add product: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) {
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

                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                      ),

                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a product name';
                        }

                        return null;
                      },
                    ),

                    TextFormField(
                      controller: _priceController,

                      decoration: const InputDecoration(
                        labelText: 'Price per KG',
                      ),

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

                      decoration: const InputDecoration(
                        labelText: 'Stock in KG',
                      ),

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

                    TextFormField(
                      // New: Low Stock Threshold
                      controller: _lowStockThresholdController,

                      decoration: const InputDecoration(
                        labelText: 'Low Stock Threshold (kg)',
                      ),

                      keyboardType: TextInputType.number,

                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a low stock threshold';
                        }

                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }

                        return null;
                      },
                    ),

                    DropdownButtonFormField<String>(
                      // New: Category selection
                      initialValue: _selectedCategory,

                      decoration: const InputDecoration(labelText: 'Category'),

                      items: ['Sweet', 'Sour'].map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,

                          child: Text(category),
                        );
                      }).toList(),

                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      },

                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // New Images Preview
                    if (_newImageFiles.isNotEmpty ||
                        _newPickedImageBytes.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const Text(
                            'Images to Upload:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          SizedBox(
                            height: 100,

                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,

                              itemCount: kIsWeb
                                  ? _newPickedImageBytes.length
                                  : _newImageFiles.length,

                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),

                                      child: kIsWeb
                                          ? Image.memory(
                                              _newPickedImageBytes[index],
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.file(
                                              File(_newImageFiles[index].path),
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            ),
                                    ),

                                    Positioned(
                                      right: 0,

                                      top: 0,

                                      child: GestureDetector(
                                        onTap: () => _removeNewImage(index),

                                        child: const CircleAvatar(
                                          radius: 12,

                                          backgroundColor: Colors.red,

                                          child: Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 10),

                    ElevatedButton(
                      onPressed: _pickNewImage,

                      child: const Text('Add Image'),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _submitForm,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreen,
                      ),

                      child: const Text(
                        'Add Product',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
