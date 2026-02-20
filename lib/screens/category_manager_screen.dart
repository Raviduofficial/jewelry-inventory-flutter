import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});
  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  List<Map<String, dynamic>> categories = [];
  
  @override
  void initState() { 
    super.initState(); 
    load(); 
  }
  
  void load() async { 
    final data = await DBHelper.instance.getCategories(); 
    setState(() => categories = data); 
  }
  
  // මේ function එක Add කරන්නයි Edit කරන්නයි දෙකටම පාවිච්චි කරන්න පුළුවන් විදියට හැදුවා
  void _showCategoryDialog([Map<String, dynamic>? cat]) {
    final ctrl = TextEditingController(text: cat?['name'] ?? '');
    final isEdit = cat != null; // cat එකක් ආවොත් ඒ කියන්නේ Edit එකක්

    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Category' : 'Add New Category'), 
        // InputDecoration එක theme එකෙන් auto ලස්සනට හැදෙනවා
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Category Name'),
        ), 
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancel')
          ), 
          ElevatedButton(
            onPressed: () async { 
              if (ctrl.text.isNotEmpty) {
                if (isEdit) {
                  await DBHelper.instance.updateCategory(cat['id'], ctrl.text); 
                } else {
                  await DBHelper.instance.insertCategory(ctrl.text); 
                }
                load(); 
                if (mounted) Navigator.pop(context); 
              }
            }, 
            child: const Text('Save')
          )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    // Theme එක ගන්නවා පාට වලට
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: categories.isEmpty
        ? const Center(child: Text('No categories found.'))
        : ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80), // යට බට්න් එකට ඉඩ තිබ්බා
            itemCount: categories.length,
            itemBuilder: (_, i) {
              final cat = categories[i];
              return Card(
                // අනිත් Screens වල වගේම ලස්සනට Card එකක් ඇතුලට දැම්මා (Theme එකෙන් auto හැඩය එනවා)
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min, 
                    children: [
                      IconButton(
                        // Edit icon එකේ පාට theme එකේ primary color එකෙන් ගත්තා
                        icon: Icon(Icons.edit, color: theme.colorScheme.primary), 
                        onPressed: () => _showCategoryDialog(cat)
                      ), 
                      IconButton(
                        // Delete icon එකේ පාට theme එකේ error (රතු) color එකෙන් ගත්තා
                        icon: Icon(Icons.delete, color: theme.colorScheme.error), 
                        onPressed: () async { 
                          await DBHelper.instance.deleteCategory(cat['id']); 
                          load(); 
                        }
                      )
                    ]
                  ),
                ),
              );
            },
          ),
      // අලුතින් Category එකක් දාන්න Floating Action Button එකක් දැම්මා
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}