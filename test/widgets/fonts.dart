import 'package:flutter/services.dart';

/// The default test font draws every glyph as a full square, which makes
/// text far wider than on a phone. Loads the app's OpenSans, also under the
/// default family names, so layouts are measured realistically.
Future<void> loadRealFonts() async {
  for (final family in ['OpenSans', 'Roboto', '.SF UI Text', '.SF Pro Text']) {
    final loader = FontLoader(family)
      ..addFont(rootBundle.load('assets/fonts/OpenSans-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/OpenSans-Bold.ttf'));
    await loader.load();
  }
  await (FontLoader('NewAmsterdam')
        ..addFont(rootBundle.load('assets/fonts/NewAmsterdam-Regular.ttf')))
      .load();
}
