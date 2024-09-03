import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
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
  final List<String> _items = <String>['a|2.50', 'b|5'];
  String _val = '';

  @override
  void initState() {
    super.initState();
    restoreState();
  }

  saveState() async {
    final prefs = await _prefs;
    await prefs.setString('val', _valController.text);

    setState(() {
      _val = _valController.text;
    });
  }

  restoreState() async {
    final prefs = await _prefs;
    _valController.text = prefs.getString('val') ?? '0.00';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
            Summary(val: _val, items: _items),
            Text('to do.. $_val, ${_items.toString()}'),
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

  Dialog addItem(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Add item"),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            )
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
          TextInputFormatter.withFunction((old, neu) {
            if (RegExp(r'^\d*\.?\d*$').hasMatch(neu.text)) {
              return neu;
            }
            return old;
          }),
        ],
      ),
    );
  }
}

class Summary extends StatelessWidget {
  const Summary({
    super.key,
    required String val,
    required List<String> items,
  }) : _items = items, _val = val;
  final String _val;
  final List<String> _items;

  @override
  Widget build(BuildContext context) {
    return Text('Summary $_val : ${_items.toString()}');
  }
}
