import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../utils/app_theme.dart';
import 'report_setup_screen.dart'; // Meka aluthin import kala (PDF Screen eka)

class StockCheckScreen extends StatefulWidget {
  const StockCheckScreen({super.key});

  @override
  State<StockCheckScreen> createState() => _StockCheckScreenState();
}

class _StockCheckScreenState extends State<StockCheckScreen> {
  List<Map<String, dynamic>> items = [];
  double totalSales = 0.0;
  double currentStockValue = 0.0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() async {
    final data = await DBHelper.instance.getFilteredItems('', null);
    double tempSales = 0.0;
    double tempStockVal = 0.0;

    for (var item in data) {
      int appQty = item['quantity'] ?? 0;
      int? physicalQty = item['physical_quantity'];
      double price = (item['price'] as num?)?.toDouble() ?? 0.0;

      // Sales Calculation
      if (physicalQty != null && physicalQty < appQty) {
        tempSales += ((appQty - physicalQty) * price);
      }
      // Stock Value
      tempStockVal += ((physicalQty ?? appQty) * price);
    }

    setState(() {
      items = data;
      totalSales = tempSales;
      currentStockValue = tempStockVal;
    });
  }

  // --- MONTH END FINALIZE LOGIC ---
  void _finishMonthEnd() {
    FocusScope.of(context).unfocus(); // Close keyboard

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalize Month End?'),
        content: const Text(
          'This will update your main inventory quantity to match the physical count.\n\n'
          'Ensure you have checked all items!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('Cancel')
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => isLoading = true);

              await DBHelper.instance.insertMonthlyRecord({
                'month': DateTime.now().toString().substring(0, 7),
                'total_sales': totalSales,
                'total_stock_value': currentStockValue,
                'record_date': DateTime.now().toString(),
              });

              await DBHelper.instance.finalizeStock();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Month End Completed! Inventory Updated.')),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>(); 
    final successColor = customColors?.success ?? Colors.green;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Stock Check'),
        // --- ALUTH KALLA: PDF BUTTON EKA ---
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generate Stock Report',
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const ReportSetupScreen())
              );
            },
          )
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return StockItemTile(
                    key: ValueKey(items[index]['id']),
                    item: items[index],
                    onChanged: load,
                  );
                },
              ),
            ),
            
            // --- SUMMARY & FINISH SECTION ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface, 
                border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,-5))
                ]
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      const Text('Total Sold Income:', style: TextStyle(fontWeight: FontWeight.w500)), 
                      Text('Rs. ${totalSales.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: successColor, fontSize: 16))
                    ]
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      const Text('Current Stock Value:', style: TextStyle(fontWeight: FontWeight.w500)), 
                      Text('Rs. ${currentStockValue.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 16))
                    ]
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('FINISH MONTH END & UPDATE'),
                      onPressed: _finishMonthEnd,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}

// --- STOCK ITEM TILE WIDGET ---
class StockItemTile extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onChanged;
  const StockItemTile({super.key, required this.item, required this.onChanged});

  @override
  State<StockItemTile> createState() => _StockItemTileState();
}

class _StockItemTileState extends State<StockItemTile> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.item['physical_quantity']?.toString() ?? '');
  }

  void _updateStock() async {
    if (_ctrl.text.isNotEmpty) {
      int? val = int.tryParse(_ctrl.text);
      if (val != null) {
        await DBHelper.instance.updateItem(widget.item['id'], {'physical_quantity': val, 'last_checked': DateTime.now().toString()});
        widget.onChanged();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.item['name']} Saved as Draft!'), duration: const Duration(milliseconds: 500)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>(); 
    final successColor = customColors?.success ?? Colors.green;
    final warningColor = customColors?.warning ?? Colors.orange;
    final infoColor = customColors?.info ?? Colors.blue;

    int appQty = widget.item['quantity'] ?? 0;
    int? physicalQty = widget.item['physical_quantity'];
    double price = (widget.item['price'] as num?)?.toDouble() ?? 0.0;
    
    int limit = widget.item['min_limit'] ?? 5;
    int currentStock = physicalQty ?? appQty; 
    bool isLowStock = currentStock <= limit;

    int diff = (physicalQty != null) ? (physicalQty - appQty) : 0;
    double income = (diff < 0) ? (diff.abs() * price) : 0.0;
    double currentItemValue = currentStock * price;

    Color? cardColor = isLowStock ? theme.colorScheme.errorContainer : null;

    Color statusBgColor;
    Color statusBorderColor;
    Color statusTextColor;

    if (diff == 0) {
      statusBgColor = successColor.withOpacity(0.1);
      statusBorderColor = successColor.withOpacity(0.5);
      statusTextColor = successColor;
    } else if (diff < 0) {
      statusBgColor = warningColor.withOpacity(0.1);
      statusBorderColor = warningColor.withOpacity(0.5);
      statusTextColor = warningColor;
    } else {
      statusBgColor = infoColor.withOpacity(0.1);
      statusBorderColor = infoColor.withOpacity(0.5);
      statusTextColor = infoColor;
    }

    return Card(
      color: cardColor, 
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              Text(widget.item['name'], style: theme.textTheme.titleMedium),
              if (isLowStock) 
                Container(
                  margin: const EdgeInsets.only(left: 8), 
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
                  decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(4)), 
                  child: Text('LOW', style: TextStyle(color: theme.colorScheme.onError, fontSize: 10, fontWeight: FontWeight.bold))
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('System Qty: $appQty', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
              if (physicalQty != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: statusBgColor, 
                    borderRadius: BorderRadius.circular(8), 
                    border: Border.all(color: statusBorderColor)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Text(diff == 0 ? 'Balanced' : (diff < 0 ? 'Sold: ${diff.abs()}' : 'Surplus: +$diff'), style: TextStyle(fontWeight: FontWeight.bold, color: statusTextColor)),
                            Text('Value: Rs. ${currentItemValue.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                        ]
                      ),
                      if (diff < 0) 
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text('+ Income: Rs. ${income.toStringAsFixed(2)}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          trailing: SizedBox(
            width: 110,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl, 
                    keyboardType: TextInputType.number, 
                    textAlign: TextAlign.center, 
                    decoration: const InputDecoration(
                      labelText: 'Real', 
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12)
                    ), 
                    onSubmitted: (_) => _updateStock()
                  )
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle), 
                  color: theme.colorScheme.primary, 
                  onPressed: _updateStock
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}