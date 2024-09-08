// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:vcher/main.dart';

void main() {
  // testWidgets('Counter increments smoke test', (WidgetTester tester) async {
  //   // Build our app and trigger a frame.
  //   await tester.pumpWidget(const MyApp());

  //   // Verify that our counter starts at 0.
  //   expect(find.text('0'), findsOneWidget);
  //   expect(find.text('1'), findsNothing);

  //   // Tap the '+' icon and trigger a frame.
  //   await tester.tap(find.byIcon(Icons.add));
  //   await tester.pump();

  //   // Verify that our counter has incremented.
  //   expect(find.text('0'), findsNothing);
  //   expect(find.text('1'), findsOneWidget);
  // });

  test('find in list', () {
    final a = ['alpha', 'beta', 'gamma'];
    expect(a.indexOf('beta'), equals(1));
    expect(a.indexOf('alpha'), equals(0));
    expect(a.indexOf('boy'), equals(-1));
  });

  test('cart item parse', () {
    CartModel ct = CartModel();
    ct.val = '10';
    ct.itemStr = <String>['a|1.5|false', 'b|2|true', 'c|2.5|false'];
    ct.parseItemStr();

    const eps = 0.001;
    expect(ct.total(), closeTo(4, eps));
    expect(ct.remainder(), closeTo(10 - 4, eps));
  });


  test('item add to cart',(){
    var ct = CartModel();
    ct.add('a','1.5');
    final list = ct.dump();

    expect(list.length, equals(1));
    expect(list[0],equals('a|1.50|false'));

    const delta=0.001;
    expect(ct.total(),closeTo(1.5, delta));
  });

  test('priceInputFormatter',(){
    expect(priceInputFormatter(const TextEditingValue(text:'0'), const TextEditingValue(text:'2')),equals(const TextEditingValue(text:'2')));
    expect(priceInputFormatter(const TextEditingValue(text:'2'), const TextEditingValue(text:'2a')),equals(const TextEditingValue(text:'2')));
    expect(priceInputFormatter(const TextEditingValue(text:'2'), const TextEditingValue(text:'2.')),equals(const TextEditingValue(text:'2.')));
    expect(priceInputFormatter(const TextEditingValue(text:''), const TextEditingValue(text:'.')),equals(const TextEditingValue(text:'.')));
  });
}
