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
      home: const MyHomePage(title: 'Voucher'),
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
      allowList: <String>{'val', 'items', 'useImplicitDecimalPoint'},
    ),
  );

  final TextEditingController _valController = TextEditingController();
  late final CartModel _cart;

  bool useImplicitDecimalPoint = false;
  var priceInputFormatter = priceInputFormatterExplicitDecimal;

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
    await prefs.setBool('useImplicitDecimalPoint', useImplicitDecimalPoint);
  }

  restoreState() async {
    final prefs = await _prefs;
    _valController.text = prefs.getString('val') ?? '0.00';
    _cart.setVal(_valController.text);
    _cart.itemStr = prefs.getStringList('items') ?? [];
    _cart.parseItemStr();
    useImplicitDecimalPoint = prefs.getBool('useImplicitDecimalPoint') ?? false;
    if (useImplicitDecimalPoint) {
      priceInputFormatter = priceInputFormatterImplcitDecimal;
    } else {
      priceInputFormatter = priceInputFormatterExplicitDecimal;
    }
    setState(() {});
  }

  // Main widget build starts here.
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: menu(context),
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
            MyGridView(context, cart: _cart),
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

  PopupMenuButton<int> menu(BuildContext context) {
    return PopupMenuButton(
      onSelected: (item) => menuAction(context, item),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 0,
          child: Text('Empty Cart'),
        ),
        const PopupMenuItem(
          value: 1,
          child: Text('ToggleImplicitDecimal'),
        ),
      ],
    );
  }

  void menuAction(context, item) {
    switch (item) {
      case 0:
        _cart.empty();
        saveState();
        break;

      case 1:
        if (useImplicitDecimalPoint) {
          useImplicitDecimalPoint = false;
          priceInputFormatter = priceInputFormatterExplicitDecimal;
        } else {
          useImplicitDecimalPoint = true;
          priceInputFormatter = priceInputFormatterImplcitDecimal;
        }
        saveState();
        setState(() {});
        break;
    }
  }

  Dialog addItem(BuildContext context) {
    final cart = Provider.of<CartModel>(context, listen: false);

    final itemController = TextEditingController();
    final costController = TextEditingController();

    FocusNode itemFocusNode = FocusNode();

    var itemField = TextField(
      decoration: const InputDecoration(labelText: 'item'),
      controller: itemController,
      focusNode: itemFocusNode,
      autofocus: true,
    );

    var costField = TextField(
      decoration: const InputDecoration(labelText: 'cost'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        TextInputFormatter.withFunction(priceInputFormatter),
      ],
      controller: costController,
    );

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            itemField,
            costField,
            addItemControls(
                context, cart, itemController, itemFocusNode, costController),
          ],
        ),
      ),
    );
  }

  Align addItemControls(
      BuildContext context,
      CartModel cart,
      TextEditingController itemController,
      FocusNode itemFocusNode,
      TextEditingController costController) {
    var closeButton = TextButton(
      onPressed: () {
        Navigator.pop(context);
      },
      child: const Text('Close'),
    );

    var addButton = TextButton(
      onPressed: () {
        if (itemController.text.trim() == '' ||
            costController.text.trim() == '') return;

        cart.add(itemController.text, costController.text);
        itemController.text = '';
        costController.text = '';
        itemFocusNode.requestFocus();
        saveState();
      },
      child: const Text('Add item'),
    );

    return Align(
      alignment: AlignmentDirectional.bottomEnd,
      child: SizedBox(
        width: 168,
        child: Row(
          children: [
            closeButton,
            addButton,
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
        inputFormatters: [
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
      return remainderText(cart, context);
    });
  }

  Text remainderText(CartModel cart, BuildContext context) {
    return Text(
      '${cart.activeItems()} '
      'items: \$${cart.total().toStringAsFixed(2)}: '
      'rem:${cart.remainder()?.toStringAsFixed(2) ?? ""}',
      style: Theme.of(context)
          .textTheme
          .copyWith(
            bodyLarge: TextStyle(
              fontSize: 20,
              color: remainderColor(context, cart),
            ),
          )
          .bodyLarge,
    );
  }
}

class MyGridView extends StatelessWidget {
  final CartModel cart;
  const MyGridView(BuildContext context, {super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartModel>(builder: (context, cart, child) {
      return SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 2,
          children: itemWidgets(context, cart),
        ),
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

  repaint() {
    notifyListeners();
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

  int activeItems() {
    int n = 0;
    for (final item in items) {
      if (item.leave) continue;
      n++;
    }
    return n;
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
    items.sort((a, b) => b.cost.compareTo(a.cost));

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

  toggle() {
    if (leave) {
      leave = false;
    } else {
      leave = true;
    }
  }
}

TextEditingValue priceInputFormatterExplicitDecimal(TextEditingValue old, neu) {
  if (RegExp(r'^\d*\.?\d*$').hasMatch(neu.text)) {
    return neu;
  }
  return old;
}

TextEditingValue priceInputFormatterImplcitDecimal(TextEditingValue old, neu) {
  String noDecimal = neu.text;
  noDecimal = noDecimal.replaceAll('.', '');
  var i = int.tryParse(noDecimal);
  if (i == null) return old;
  final outStr = (i * 0.01).toStringAsFixed(2);
  return TextEditingValue(
    text: outStr,
    selection: TextSelection.collapsed(
      offset: outStr.length,
    ),
  );
}

List<Widget> itemWidgets(BuildContext context, CartModel cart) {
  var outp = <Widget>[];
  for (final i in cart.items) {
    outp.add(
      Tooltip(
        message: 'tap to remove from / return to cart\ndouble-tap to delete',
        child: InkWell(
          onTap: () {
            i.toggle();
            cart.repaint();
          },
          onDoubleTap: () {
            cart.items.remove(i);
            cart.repaint();
          },
          child: Card(
            color: i.leave
                ? Colors.red[50]
                : Theme.of(context).colorScheme.surfaceContainer,
            child: Text('${i.desc}\n${i.cost}'),
          ),
        ),
      ),
    );
  }
  return outp;
}

Color remainderColor(BuildContext context, CartModel cart) {
  if (cart.remainder() == null) {
    return Theme.of(context).colorScheme.inverseSurface;
  }
  if (cart.remainder()! < 0) {
    return Theme.of(context).colorScheme.error;
  }
  return Theme.of(context).colorScheme.inverseSurface;
}
