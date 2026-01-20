// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lung_chaing_farm/providers/auth_provider.dart';
import 'package:lung_chaing_farm/screens/auth/login_screen.dart'; // Import LoginScreen
import 'package:lung_chaing_farm/services/audio_service.dart'; // Import AudioService

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _farmNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  
  String _selectedRole = 'USER';
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    AudioService.playClickSound(); // Play sound on submit
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<AuthProvider>(context, listen: false).register(
        email: _emailController.text,
        password: _passwordController.text,
        role: _selectedRole,
        farmName: _selectedRole == 'VILLAGER' ? _farmNameController.text : null,
        address: _addressController.text,
        contactInfo: _contactController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Please log in.')),
      );
      // Navigate to LoginScreen instead of just popping
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to register: ${error.toString()}')),
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
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Role Selector
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: ['USER', 'VILLAGER'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value == 'USER' ? 'I want to buy' : 'I am a Villager (Seller)'),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedRole = newValue!;
                  });
                },
                decoration: const InputDecoration(labelText: 'I am a...'),
              ),
              const SizedBox(height: 10),

              // Common Fields
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),

              // Conditional Villager Field
              if (_selectedRole == 'VILLAGER')
                TextFormField(
                  controller: _farmNameController,
                  decoration: const InputDecoration(labelText: 'Farm Name'),
                  validator: (value) {
                    if (_selectedRole == 'VILLAGER' && (value == null || value.isEmpty)) {
                      return 'Please enter your farm name';
                    }
                    return null;
                  },
                ),
              
              // Optional fields
               TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address (Optional)'),
              ),
               TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: 'Contact Info (Optional)'),
              ),
              
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Register'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
