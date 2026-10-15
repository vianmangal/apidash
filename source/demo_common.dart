import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final out = Platform.environment['DEMO_FRAMES'] ?? 'demo-frames';
final captureKey = GlobalKey();

Future<void> setupDemo(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 820);
  tester.view.devicePixelRatio = 1;
  await tester.runAsync(() async {
    final loader = FontLoader('DemoFont');
    loader.addFont(Future.value(ByteData.sublistView(await File(Platform.environment['DEMO_FONT'] ?? '/System/Library/Fonts/Supplemental/Arial.ttf').readAsBytes())));
    await loader.load();
    await Directory(out).create(recursive: true);
  });
}

Widget demoFrame(String pr, String title, String stage, String note, Widget body) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'DemoFont', colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff6366f1)), useMaterial3: true),
    home: RepaintBoundary(key: captureKey, child: Scaffold(
      backgroundColor: const Color(0xfff5f6fb),
      body: Padding(padding: const EdgeInsets.all(40), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('API DASH  /  PR #$pr  /  AUTOMATED REGRESSION DEMO', style: const TextStyle(fontSize: 14, letterSpacing: 1.4, color: Color(0xff6366f1), fontWeight: FontWeight.bold)),
        const SizedBox(height: 18),
        Text(title, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(stage, style: const TextStyle(fontSize: 22, color: Color(0xff475569))),
        const SizedBox(height: 28),
        Expanded(child: Container(width: double.infinity, padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xffe2e8f0))), child: body)),
        const SizedBox(height: 22),
        Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xffe8eafa), borderRadius: BorderRadius.circular(12)), child: Text(note, style: const TextStyle(fontSize: 19, height: 1.4))),
        const SizedBox(height: 16),
        const Text('Captured from Flutter tests at the original PR commit. Sample data only.', style: TextStyle(fontSize: 13, color: Color(0xff64748b))),
      ])),
    )),
  );
}

Future<void> capture(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  final boundary = captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final im = await boundary.toImage(pixelRatio: 1);
    final data = await im.toByteData(format: ui.ImageByteFormat.png);
    await File('$out/$name.png').writeAsBytes(data!.buffer.asUint8List());
    im.dispose();
  });
}
