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

  @override
  void initState() {
    super.initState();
    restoreState();
  }

  saveState() async {
    final prefs = await _prefs;
    await prefs.setString('val', _valController.text);
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
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('to do..'),
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
          TextInputFormatter.withFunction((old, newV) {
            if (RegExp(r'^\d*\.?\d*$').hasMatch(newV.text)) {
              return newV;
            }
            return old;
          }),
        ],
      ),
    );
  }
}
