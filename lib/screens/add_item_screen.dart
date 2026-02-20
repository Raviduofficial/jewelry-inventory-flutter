import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../database/db_helper.dart';

class AddItemScreen extends StatefulWidget {
  final Map<String, dynamic>? editItem;
  const AddItemScreen({super.key, this.editItem});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final nameCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final limitCtrl = TextEditingController(); 

  File? image;
  int? categoryId;
  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    loadCategories();

    qtyCtrl.addListener(() {
      if (qtyCtrl.text.isNotEmpty && widget.editItem == null) { 
        int qty = int.tryParse(qtyCtrl.text) ?? 0;
        int autoLimit = (qty * 0.20).round(); 
        if (autoLimit < 1 && qty > 0) autoLimit = 1; 
        limitCtrl.text = autoLimit.toString();
      }
    });

    if (widget.editItem != null) {
      nameCtrl.text = widget.editItem!['name'];
      qtyCtrl.text = widget.editItem!['quantity'].toString();
      priceCtrl.text = widget.editItem!['price'] != null ? widget.editItem!['price'].toString() : '';
      limitCtrl.text = widget.editItem!['min_limit'] != null ? widget.editItem!['min_limit'].toString() : '5';
      
      categoryId = widget.editItem!['category_id'];
      if (widget.editItem!['image_path'] != null) {
        image = File(widget.editItem!['image_path']);
      }
    }
  }

  void loadCategories() async {
    final data = await DBHelper.instance.getCategories();
    setState(() { categories = data; });
  }

  void _showAddCategoryDialog() {
    final catCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: TextField(
          controller: catCtrl, 
          decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (catCtrl.text.isNotEmpty) {
                await DBHelper.instance.insertCategory(catCtrl.text);
                loadCategories();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _pickImage(ImageSource source) async {
    Navigator.pop(context); 
    
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 80);
    
    if (picked != null) {
      final theme = Theme.of(context);
      
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: picked.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Item Photo',
            toolbarColor: theme.colorScheme.primary, 
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
          ),
          IOSUiSettings(
            title: 'Crop Item Photo',
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() => image = File(croppedFile.path));
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Select Image Source', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: theme.colorScheme.primary),
                title: const Text('Take a Photo (Camera)'),
                onTap: () => _pickImage(ImageSource.camera), 
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: theme.colorScheme.primary),
                title: const Text('Choose from Gallery'),
                onTap: () => _pickImage(ImageSource.gallery), 
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      }
    );
  }

  void save() async {
    if (nameCtrl.text.isEmpty || qtyCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Qty required')));
      return;
    }

    final data = {
      'name': nameCtrl.text,
      'quantity': int.tryParse(qtyCtrl.text) ?? 0,
      'price': double.tryParse(priceCtrl.text) ?? 0.0,
      'min_limit': int.tryParse(limitCtrl.text) ?? 5,
      'image_path': image?.path,
      'category_id': categoryId,
    };

    if (widget.editItem == null) {
      await DBHelper.instance.insertItem(data);
    } else {
      await DBHelper.instance.updateItem(widget.editItem!['id'], data);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.editItem == null ? 'Add Item' : 'Edit Item')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            
            TextField(
              controller: nameCtrl, 
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(), 
                prefixIcon: Icon(Icons.inventory_2_outlined), 
              )
            ),
            const SizedBox(height: 16),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Price', 
                      prefixText: 'Rs. ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: limitCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Min Limit',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.warning_amber),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: categoryId,
                    hint: const Text('Category'),
                    items: categories.map((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['name']))).toList(),
                    onChanged: (v) => setState(() => categoryId = v),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16), 
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 55, 
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5))
                  ),
                  child: IconButton(
                    icon: Icon(Icons.add, color: theme.colorScheme.primary, size: 28), 
                    onPressed: _showAddCategoryDialog
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            GestureDetector(
              onTap: _showImagePickerOptions,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest ?? theme.dividerColor.withOpacity(0.05), 
                  borderRadius: BorderRadius.circular(14), 
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5), width: 1.5, style: BorderStyle.solid) // Photo box eke border ekath lassan kara
                ),
                child: image != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(image!, fit: BoxFit.cover, width: double.infinity))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: [
                          Icon(Icons.add_a_photo, size: 48, color: theme.colorScheme.primary.withOpacity(0.7)), 
                          const SizedBox(height: 8),
                          Text('Tap to add photo', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold))
                        ]
                      ),
              ),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              height: 50, 
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                onPressed: save,
                label: const Text('SAVE ITEM', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}