import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voucher',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Voucher Optimiser'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Future<SharedPreferencesWithCache> _prefs =
      SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: <String>{'val', 'items'},
    ),
  );

  final TextEditingController _valController = TextEditingController();
  late final CartModel _cart;

  @override
  void initState() {
    super.initState();
    _cart = context.read<CartModel>();
    restoreState();
  }

  saveState() async {
    final prefs = await _prefs;
    await prefs.setString('val', _valController.text);
    await prefs.setStringList('items', _cart.dump());
    _cart.setVal(_valController.text);
  }

  restoreState() async {
    final prefs = await _prefs;
    _valController.text = prefs.getString('val') ?? '0.00';
    _cart.setVal(_valController.text);
    _cart.itemStr = prefs.getStringList('items') ?? [];
    _cart.parseItemStr();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: PopupMenuButton(
          onSelected: (item) => onSelected(context, item),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 0,
              child: Text('Empty Cart'),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          valueInput(context),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Summary(cart: _cart),
            Consumer<CartModel>(builder: (context, cart, child) {
              return Text('to do.. ${_cart.val}, ${_cart.dump().toString()}');
            }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (context) => addItem(context),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  void onSelected(context, item) {
    switch (item) {
      case 0:
        _cart.empty();
        saveState();
        break;
    }
  }

  Dialog addItem(BuildContext context) {
    final cart = Provider.of<CartModel>(context, listen: false);

    final itemController = TextEditingController();
    final costController = TextEditingController();

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'item'),
              controller: itemController,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'cost'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: const [
                TextInputFormatter.withFunction(priceInputFormatter),
              ],
              controller: costController,
            ),
            Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: SizedBox(
                width: 168,
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        saveState();
                        Navigator.pop(context);
                      },
                      child: const Text('Close'),
                    ),
                    TextButton(
                      onPressed: () =>
                          cart.add(itemController.text, costController.text),
                      child: const Text('Add item'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container valueInput(BuildContext context) {
    return Container(
      width: 144,
      padding: const EdgeInsets.only(right: 64),
      child: TextField(
        decoration: const InputDecoration(labelText: 'Value'),
        style: Theme.of(context).textTheme.headlineSmall,
        controller: _valController,
        onSubmitted: (_) => saveState(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: const [
          TextInputFormatter.withFunction(priceInputFormatter),
        ],
      ),
    );
  }
}

class Summary extends StatelessWidget {
  final CartModel cart;
  const Summary({
    super.key,
    required this.cart,
  });
  @override
  Widget build(BuildContext context) {
    return Consumer<CartModel>(builder: (context, cart, child) {
      return Text(
        '${cart.items.length} items in cart: remainder: ${cart.remainder()?.toStringAsFixed(2) ?? ""}',
      );
    });
  }
}

class CartModel extends ChangeNotifier {
  String val = '';
  List<String> itemStr = [];
  List<ItemModel> items = [];

  double? _val() {
    return double.tryParse(val);
  }

  parseItemStr() {
    for (final item in itemStr) {
      final part = item.split('|');
      final itemVal = double.tryParse(part[1]);
      ItemModel im = ItemModel();
      im.cost = itemVal ?? 0;
      im.desc = part[0];
      if (part[2] == 'true') {
        im.leave = true;
      }
      if (itemVal == null) {
        im.leave = true;
        im.desc += '-invalid';
      }
      items.add(im);
    }
    notifyListeners();
  }

  double total() {
    double sum = 0;
    for (final item in items) {
      if (item.leave) continue;
      sum += item.cost;
    }
    return sum;
  }

  add(String desc, cost) {
    ItemModel item = ItemModel();
    item.desc = desc;
    final itemVal = double.tryParse(cost);
    item.cost = itemVal ?? 0;
    if (itemVal == null) {
      item.leave = true;
      item.desc += '-invalid';
      item.cost = 0;
    }
    items.add(item);

    notifyListeners();
  }

  List<String> dump() {
    List<String> out = [];
    for (final item in items) {
      out.add('${item.desc}|${item.cost.toStringAsFixed(2)}|${item.leave}');
    }
    return out;
  }

  double? remainder() {
    if (_val() == null) return null;
    return (_val()! - total());
  }

  setVal(String val) {
    this.val = val;
    notifyListeners();
  }

  empty() {
    itemStr.clear();
    items.clear();
    remainder();
    notifyListeners();
  }
}

class ItemModel {
  String desc = '';
  double cost = 0;
  bool leave = false;
}

TextEditingValue priceInputFormatter(TextEditingValue old, neu) {
  if (RegExp(r'^\d*\.?\d*$').hasMatch(neu.text)) {
    return neu;
  }
  return old;
}
