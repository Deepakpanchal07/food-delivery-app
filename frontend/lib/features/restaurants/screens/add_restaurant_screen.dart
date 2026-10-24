
import 'package:flutter/material.dart';
import '../services/restaurant_service.dart';

class AddRestaurantScreen extends StatefulWidget {
  const AddRestaurantScreen({super.key});

  @override
  State<AddRestaurantScreen> createState() =>
      _AddRestaurantScreenState();
}

class _AddRestaurantScreenState
    extends State<AddRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = RestaurantService();

  final _nameController = TextEditingController();
  final _cuisineController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _deliveryTimeController =
      TextEditingController(text: '30');
  final _deliveryFeeController =
      TextEditingController(text: '0');

  bool _isOpen = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cuisineController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _deliveryTimeController.dispose();
    _deliveryFeeController.dispose();
    super.dispose();
  }

  Future<void> _saveRestaurant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _service.addRestaurant(
        name: _nameController.text.trim(),
        cuisine: _cuisineController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        deliveryTime:
            int.parse(_deliveryTimeController.text.trim()),
        deliveryFee:
            double.parse(_deliveryFeeController.text.trim()),
        isOpen: _isOpen,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restaurant added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save restaurant: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Restaurant'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _field(
              'Restaurant Name',
              _nameController,
              validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Enter restaurant name'
                      : null,
            ),
            _field(
              'Cuisine',
              _cuisineController,
              validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Enter cuisine'
                      : null,
            ),
            _field('Description', _descriptionController),
            _field(
              'Image URL (optional)',
              _imageUrlController,
              keyboardType: TextInputType.url,
            ),
            _field(
              'Delivery Time (minutes)',
              _deliveryTimeController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (int.tryParse(value ?? '') == null ||
                    int.parse(value!) <= 0) {
                  return 'Enter valid delivery time';
                }
                return null;
              },
            ),
            _field(
              'Delivery Fee (₹)',
              _deliveryFeeController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                final fee = double.tryParse(value ?? '');
                if (fee == null || fee < 0) {
                  return 'Enter valid delivery fee';
                }
                return null;
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Restaurant is open'),
              value: _isOpen,
              onChanged: (value) {
                setState(() => _isOpen = value);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveRestaurant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'Save Restaurant',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
