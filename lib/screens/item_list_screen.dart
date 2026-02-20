import 'dart:io';
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'add_item_screen.dart';
import 'stock_check_screen.dart';
import 'category_manager_screen.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> categories = [];
  String searchText = '';
  int? selectedCategory;
  double totalStockValue = 0.0;

  @override
  void initState() {
    super.initState();
    loadCategories();
    loadItems();
  }

  void loadCategories() async {
    final data = await DBHelper.instance.getCategories();
    setState(() => categories = data);
  }

  void loadItems() async {
    final data = await DBHelper.instance.getFilteredItems(searchText, selectedCategory);
    
    double tempTotal = 0.0;
    for (var item in data) {
      int qty = item['quantity'] ?? 0;
      double price = (item['price'] as num?)?.toDouble() ?? 0.0;
      tempTotal += (qty * price);
    }

    setState(() {
      items = data;
      totalStockValue = tempTotal;
    });
  }

  Future<void> _navigateAndRefresh(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    loadItems();
    loadCategories();
  }

  // --- Quick Add Stock Dialog ---
  void _showQuickAddStockDialog(Map<String, dynamic> item) {
    final TextEditingController addQtyCtrl = TextEditingController();
    int currentQty = item['quantity'] ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item: ${item['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Current Qty: $currentQty', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 16),
            TextField(
              controller: addQtyCtrl,
              keyboardType: TextInputType.number,
              autofocus: true, 
              decoration: const InputDecoration(
                labelText: 'How many new items arrived?',
                hintText: 'e.g., 10',
                prefixIcon: Icon(Icons.add_shopping_cart),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              int addedQty = int.tryParse(addQtyCtrl.text) ?? 0;
              if (addedQty > 0) {
                int newQty = currentQty + addedQty; 
                
                await DBHelper.instance.updateItem(item['id'], {'quantity': newQty});
                loadItems(); 
                
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$addedQty items added to ${item['name']}! (New Total: $newQty)'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('ADD STOCK'),
          ),
        ],
      ),
    );
  }

  // --- ALUTH KALLA: Delete Confirmation Dialog ---
  void _confirmDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Are you sure you want to delete "${item['name']}" from the inventory?\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              await DBHelper.instance.deleteItem(item['id']);
              if (mounted) Navigator.pop(ctx);
              loadItems();
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  // --- ALUTH KALLA: Custom Inline Icon Button Widget ---
  // Button 3ma lassanata eka wage pennanna hadapu podi widget eka
  Widget _buildActionBtn({required IconData icon, required Color color, required String tooltip, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        icon: Icon(icon, color: color, size: 20),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Categories',
            onPressed: () => _navigateAndRefresh(const CategoryManagerScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.checklist),
            tooltip: 'Month End Check',
            onPressed: () => _navigateAndRefresh(const StockCheckScreen()),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Search...', prefixIcon: Icon(Icons.search)),
              onChanged: (v) { searchText = v; loadItems(); },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<int>(
              hint: const Text('Filter by Category'),
              value: selectedCategory,
              items: [
                const DropdownMenuItem(value: null, child: Text('All Categories')),
                ...categories.map((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['name']))).toList(),
              ],
              onChanged: (v) { setState(() => selectedCategory = v); loadItems(); },
            ),
          ),
          const SizedBox(height: 8), 
          
          Expanded(
            child: items.isEmpty 
              ? Center(child: Text('No items found', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)))
              : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80), 
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                double price = (item['price'] as num?)?.toDouble() ?? 0.0;
                int qty = item['quantity'] ?? 0;
                int limit = item['min_limit'] ?? 5;
                int? physicalQty = item['physical_quantity'];
                
                int currentStockForCheck = physicalQty ?? qty;
                bool isLowStock = currentStockForCheck <= limit;

                Color? cardColor = isLowStock ? (isDark ? const Color(0xFF5A1A1A) : Colors.red.shade50) : null;

                return Card(
                  color: cardColor,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: item['image_path'] != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(item['image_path']), width: 50, height: 50, fit: BoxFit.cover))
                        : Container( 
                            width: 50, height: 50,
                            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.inventory_2, size: 28, color: theme.colorScheme.onSurfaceVariant),
                          ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(item['name'], style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                        if (isLowStock)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(4)),
                            child: Text('LOW', style: TextStyle(color: theme.colorScheme.onError, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text('Qty: $qty', style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15,
                              color: isLowStock ? (isDark ? Colors.redAccent : theme.colorScheme.error) : null
                            )),
                            if (physicalQty != null)
                              Text(' (Real: $physicalQty)', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(width: 8),
                            Text('/ Limit: $limit', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('Price: Rs. ${price.toStringAsFixed(2)}', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8))),
                      ],
                    ),
                    
                    // --- ALUTH KALLA: Inline Action Buttons (No more 3 dots) ---
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Add Stock Button (Teal/Primary)
                        _buildActionBtn(
                          icon: Icons.add_shopping_cart, 
                          color: theme.colorScheme.primary, 
                          tooltip: 'Add Stock', 
                          onTap: () => _showQuickAddStockDialog(item)
                        ),
                        // 2. Edit Button (Blue)
                        _buildActionBtn(
                          icon: Icons.edit, 
                          color: Colors.blue, 
                          tooltip: 'Edit Item', 
                          onTap: () => _navigateAndRefresh(AddItemScreen(editItem: item))
                        ),
                        // 3. Delete Button (Red/Error)
                        _buildActionBtn(
                          icon: Icons.delete_outline, 
                          color: theme.colorScheme.error, 
                          tooltip: 'Delete Item', 
                          onTap: () => _confirmDelete(item)
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface, 
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,-5))],
              border: Border(top: BorderSide(color: theme.dividerColor, width: 1))
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL STOCK VALUE:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Rs. ${totalStockValue.toStringAsFixed(2)}', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.primary)
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0), 
        child: FloatingActionButton(
          onPressed: () => _navigateAndRefresh(const AddItemScreen()),
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, 
    );
  }
}