import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coach/main.dart';

/// The project ships no asset bundle, so `flutter test` has no asset manifest
/// and google_fonts throws while looking one up. Serve an empty manifest.
void _mockEmptyAssetManifest() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (ByteData? message) async {
    final key = utf8.decode(message!.buffer.asUint8List());
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage(<String, Object>{});
    }
    if (key == 'AssetManifest.json') {
      return ByteData.sublistView(Uint8List.fromList(utf8.encode('{}')));
    }
    return null;
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // No bundled fonts or network in tests; fall back to the default font.
    GoogleFonts.config.allowRuntimeFetching = false;
    _mockEmptyAssetManifest();
  });

  testWidgets('CoachApp builds and settles on a MaterialApp', (tester) async {
    // The default 800x600 test surface is shorter than a phone and overflows
    // the home screen column, so use phone-like metrics instead.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: CoachApp()));

    // Settings load asynchronously, so the first frame is the loader.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
