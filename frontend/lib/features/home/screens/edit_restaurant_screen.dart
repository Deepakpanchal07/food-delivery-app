
import 'package:flutter/material.dart';
import 'package:frontend/features/restaurants/models/restaurant.dart';
import 'package:frontend/features/restaurants/services/restaurant_service.dart';

class EditRestaurantScreen extends StatefulWidget {
  final Restaurant restaurant;

  const EditRestaurantScreen({
    super.key,
    required this.restaurant,
  });

  @override
  State<EditRestaurantScreen> createState() =>
      _EditRestaurantScreenState();
}

class _EditRestaurantScreenState
    extends State<EditRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = RestaurantService();

  late final TextEditingController _nameController;
  late final TextEditingController _cuisineController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _ratingController;
  late final TextEditingController _deliveryTimeController;
  late final TextEditingController _deliveryFeeController;

  late bool _isOpen;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final r = widget.restaurant;

    _nameController = TextEditingController(text: r.name);
    _cuisineController = TextEditingController(text: r.cuisine);
    _descriptionController = TextEditingController(text: r.description);
    _imageUrlController = TextEditingController(text: r.imageUrl);
    _ratingController =
        TextEditingController(text: r.rating.toString());
    _deliveryTimeController =
        TextEditingController(text: r.deliveryTime.toString());
    _deliveryFeeController =
        TextEditingController(text: r.deliveryFee.toString());

    _isOpen = r.isOpen;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cuisineController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _ratingController.dispose();
    _deliveryTimeController.dispose();
    _deliveryFeeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _service.updateRestaurant(
        id: widget.restaurant.id,
        name: _nameController.text.trim(),
        cuisine: _cuisineController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        rating: double.parse(_ratingController.text.trim()),
        deliveryTime: int.parse(_deliveryTimeController.text.trim()),
        deliveryFee: double.parse(_deliveryFeeController.text.trim()),
        isOpen: _isOpen,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restaurant updated successfully!'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
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
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
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
        title: const Text('Edit Restaurant'),
        backgroundColor: const Color(0xFFFF6B35),
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
              validator: (v) =>
                  v == null || v.trim().isEmpty
                      ? 'Enter restaurant name'
                      : null,
            ),
            _field(
              'Cuisine',
              _cuisineController,
              validator: (v) =>
                  v == null || v.trim().isEmpty
                      ? 'Enter cuisine'
                      : null,
            ),
            _field('Description', _descriptionController),
            _field('Image URL', _imageUrlController),
            _field(
              'Rating (0–5)',
              _ratingController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n < 0 || n > 5) {
                  return 'Enter a rating from 0 to 5';
                }
                return null;
              },
            ),
            _field(
              'Delivery Time (minutes)',
              _deliveryTimeController,
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) {
                  return 'Enter a valid delivery time';
                }
                return null;
              },
            ),
            _field(
              'Delivery Fee (₹)',
              _deliveryFeeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n < 0) {
                  return 'Enter a valid delivery fee';
                }
                return null;
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Restaurant is open'),
              value: _isOpen,
              onChanged: (v) => setState(() => _isOpen = v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
