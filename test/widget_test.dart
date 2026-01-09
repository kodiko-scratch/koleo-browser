import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:koleo_browser/main.dart';
import 'package:koleo_browser/services/settings_manager.dart';

void main() {
  testWidgets('KoleoApp renders correctly', (WidgetTester tester) async {
    // Set up mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settingsManager = await SettingsManager.createWithPrefs(prefs);

    await tester.pumpWidget(KoleoApp(settingsManager: settingsManager));
    await tester.pumpAndSettle();

    // The app should render without errors - check for search hint text
    expect(find.textContaining('Поиск'), findsWidgets);
  });
}
