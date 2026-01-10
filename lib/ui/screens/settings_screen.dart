import 'package:flutter/material.dart' hide ThemeMode;
import '../../models/app_settings.dart';
import '../../services/settings_manager.dart';
import '../theme/theme.dart';

/// Settings screen with modern design.
class SettingsScreen extends StatefulWidget {
  final ISettingsManager settingsManager;
  final VoidCallback? onClose;
  final VoidCallback? onOpenVpn;

  const SettingsScreen({
    super.key,
    required this.settingsManager,
    this.onClose,
    this.onOpenVpn,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settingsManager.currentSettings;
    widget.settingsManager.settingsStream.listen((settings) {
      if (mounted) setState(() => _settings = settings);
    });
  }

  Future<void> _updateSettings(AppSettings newSettings) async {
    await widget.settingsManager.saveSettings(newSettings);
    setState(() => _settings = newSettings);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0a0a0a) : const Color(0xFFfafafa);
    final textColor = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final accentColor = _getAccentColorValue(_settings.accentColor);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: bgColor,
            elevation: 0,
            floating: true,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Material(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFe8e8e8),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: widget.onClose ?? () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(12),
                  child: Icon(Icons.arrow_back_rounded, color: textColor, size: 20),
                ),
              ),
            ),
            title: Text('Настройки', style: KoleoTypography.headline.copyWith(color: textColor, fontSize: 22)),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSection('Поиск', Icons.search_rounded, [
                  _buildOptionTile('Поисковая система', _getSearchEngineLabel(_settings.searchEngine), Icons.language_rounded, () => _showSearchEngineDialog()),
                  _buildSwitchTile('Подсказки поиска', 'Показывать при вводе', _settings.showSearchSuggestions, (v) => _updateSettings(_settings.copyWith(showSearchSuggestions: v)), accentColor),
                ]),
                const SizedBox(height: 16),
                _buildSection('Безопасность', Icons.shield_rounded, [
                  _buildOptionTile('Уровень защиты', _getSecurityLevelLabel(_settings.securityLevel), Icons.security_rounded, () => _showSecurityDialog()),
                  _buildOptionTile('VPN', 'Обход блокировок', Icons.vpn_lock_rounded, () => widget.onOpenVpn?.call()),
                ]),
                const SizedBox(height: 16),
                _buildSection('Внешний вид', Icons.palette_rounded, [
                  _buildOptionTile('Тема', _getThemeModeLabel(_settings.themeMode), _getThemeIcon(_settings.themeMode), () => _showThemeDialog()),
                  _buildColorPicker('Акцентный цвет', _settings.accentColor, accentColor),
                  _buildOptionTile('Фон главного экрана', _getHomeBackgroundLabel(_settings.homeBackground), Icons.wallpaper_rounded, () => _showHomeBackgroundDialog()),
                  _buildOptionTile('Стиль вкладок', _getTabBarStyleLabel(_settings.tabBarStyle), Icons.tab_rounded, () => _showTabBarStyleDialog()),
                  _buildSliderTile('Скругление углов', _settings.cornerRadius, 8.0, 24.0, (v) => _updateSettings(_settings.copyWith(cornerRadius: v)), accentColor, suffix: 'px'),
                  _buildSliderTile('Ширина вкладок', _settings.tabWidth, 120.0, 240.0, (v) => _updateSettings(_settings.copyWith(tabWidth: v)), accentColor, suffix: 'px'),
                  _buildSwitchTile('Компактный режим', 'Уменьшенные отступы', _settings.compactMode, (v) => _updateSettings(_settings.copyWith(compactMode: v)), accentColor),
                  _buildSwitchTile('Иконки вкладок', 'Показывать иконки сайтов', _settings.showTabIcons, (v) => _updateSettings(_settings.copyWith(showTabIcons: v)), accentColor),
                  _buildSwitchTile('Прозрачная шапка', 'Эффект стекла', _settings.transparentHeader, (v) => _updateSettings(_settings.copyWith(transparentHeader: v)), accentColor),
                  _buildOptionTile('Размытие фона', _getBlurLabel(_settings.backgroundBlur), Icons.blur_on_rounded, () => _showBlurDialog()),
                ]),
                const SizedBox(height: 16),
                _buildSection('О браузере', Icons.info_outline_rounded, [
                  _buildInfoTile('Версия', '1.0.4'),
                  _buildInfoTile('Разработчик', 'Koleo'),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : const Color(0xFF666666);
    final cardColor = isDark ? const Color(0xFF1a1a1a) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
              Text(title, style: KoleoTypography.caption.copyWith(color: textColor, fontSize: 13)),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFe0e0e0)),
          ),
          child: Column(
            children: children.asMap().entries.map((e) {
              final isLast = e.key == children.length - 1;
              return Column(children: [e.value, if (!isLast) _buildDivider()]);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final secondaryColor = isDark ? Colors.white60 : const Color(0xFF666666);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFf0f0f0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: textColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: KoleoTypography.body.copyWith(color: textColor, fontSize: 15)),
                    Text(subtitle, style: KoleoTypography.caption.copyWith(color: secondaryColor, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: secondaryColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker(String title, AccentColor selected, Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1a1a1a);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: KoleoTypography.body.copyWith(color: textColor, fontSize: 15)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AccentColor.values.map((color) {
              final isSelected = color == selected;
              final colorValue = _getAccentColorValue(color);
              return GestureDetector(
                onTap: () => _updateSettings(_settings.copyWith(accentColor: color)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorValue,
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                    boxShadow: isSelected ? [BoxShadow(color: colorValue.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)] : null,
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(String title, double value, double min, double max, ValueChanged<double> onChanged, Color accentColor, {String suffix = ''}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final secondaryColor = isDark ? Colors.white60 : const Color(0xFF666666);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: KoleoTypography.body.copyWith(color: textColor, fontSize: 15)),
              Text('${value.round()}$suffix', style: KoleoTypography.caption.copyWith(color: secondaryColor, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: accentColor,
              inactiveTrackColor: accentColor.withValues(alpha: 0.2),
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.1),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(value: value, min: min, max: max, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged, Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final secondaryColor = isDark ? Colors.white60 : const Color(0xFF666666);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: KoleoTypography.body.copyWith(color: textColor, fontSize: 15)),
                Text(subtitle, style: KoleoTypography.caption.copyWith(color: secondaryColor, fontSize: 13)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: accentColor,
            inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              return isDark ? Colors.white70 : Colors.white;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final secondaryColor = isDark ? Colors.white60 : const Color(0xFF666666);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: KoleoTypography.body.copyWith(color: textColor, fontSize: 15)),
          Text(value, style: KoleoTypography.body.copyWith(color: secondaryColor, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFe8e8e8));
  }

  void _showSearchEngineDialog() => _showDialog<SearchEngineType>(
    'Поисковая система', SearchEngineType.values, _settings.searchEngine, _getSearchEngineLabel,
    (v) => _updateSettings(_settings.copyWith(searchEngine: v)),
  );

  void _showSecurityDialog() => _showDialog<SecurityLevel>(
    'Уровень защиты', SecurityLevel.values, _settings.securityLevel, _getSecurityLevelLabel,
    (v) => _updateSettings(_settings.copyWith(securityLevel: v)),
  );

  void _showThemeDialog() => _showDialog<ThemeMode>(
    'Тема оформления', ThemeMode.values, _settings.themeMode, _getThemeModeLabel,
    (v) => _updateSettings(_settings.copyWith(themeMode: v)),
  );

  void _showTabBarStyleDialog() => _showDialog<TabBarStyle>(
    'Стиль вкладок', TabBarStyle.values, _settings.tabBarStyle, _getTabBarStyleLabel,
    (v) => _updateSettings(_settings.copyWith(tabBarStyle: v)),
  );

  void _showBlurDialog() => _showDialog<BackgroundBlur>(
    'Размытие фона', BackgroundBlur.values, _settings.backgroundBlur, _getBlurLabel,
    (v) => _updateSettings(_settings.copyWith(backgroundBlur: v)),
  );

  void _showHomeBackgroundDialog() => _showDialog<HomeBackgroundType>(
    'Фон главного экрана', HomeBackgroundType.values, _settings.homeBackground, _getHomeBackgroundLabel,
    (v) => _updateSettings(_settings.copyWith(homeBackground: v)),
  );

  void _showDialog<T>(String title, List<T> items, T selected, String Function(T) label, ValueChanged<T> onSelect) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1a1a1a) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final accentColor = _getAccentColorValue(_settings.accentColor);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(title, style: KoleoTypography.headline.copyWith(color: textColor, fontSize: 18)),
            const SizedBox(height: 8),
            ...items.map((item) => Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () { onSelect(item); Navigator.pop(ctx); },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(child: Text(label(item), style: KoleoTypography.body.copyWith(color: textColor, fontSize: 16))),
                      if (item == selected) Icon(Icons.check_rounded, color: accentColor, size: 22),
                    ],
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  String _getSearchEngineLabel(SearchEngineType e) => switch (e) {
    SearchEngineType.koleo => 'Koleo Search',
    SearchEngineType.google => 'Google',
    SearchEngineType.yandex => 'Яндекс',
    SearchEngineType.duckduckgo => 'DuckDuckGo',
    SearchEngineType.bing => 'Bing',
  };

  String _getSecurityLevelLabel(SecurityLevel l) => switch (l) {
    SecurityLevel.minimal => 'Минимальный',
    SecurityLevel.standard => 'Стандартный',
    SecurityLevel.strict => 'Строгий',
  };

  String _getThemeModeLabel(ThemeMode m) => switch (m) {
    ThemeMode.light => 'Светлая',
    ThemeMode.dark => 'Тёмная',
    ThemeMode.system => 'Системная',
  };

  IconData _getThemeIcon(ThemeMode m) => switch (m) {
    ThemeMode.light => Icons.light_mode_rounded,
    ThemeMode.dark => Icons.dark_mode_rounded,
    ThemeMode.system => Icons.brightness_auto_rounded,
  };

  String _getTabBarStyleLabel(TabBarStyle s) => switch (s) {
    TabBarStyle.standard => 'Стандартный',
    TabBarStyle.compact => 'Компактный',
    TabBarStyle.floating => 'Плавающий',
  };

  String _getBlurLabel(BackgroundBlur b) => switch (b) {
    BackgroundBlur.none => 'Отключено',
    BackgroundBlur.light => 'Лёгкое',
    BackgroundBlur.medium => 'Среднее',
    BackgroundBlur.heavy => 'Сильное',
  };

  String _getHomeBackgroundLabel(HomeBackgroundType t) => switch (t) {
    HomeBackgroundType.animatedGradient => 'Анимированный градиент',
    HomeBackgroundType.staticGradient => 'Статичный градиент',
    HomeBackgroundType.image => 'Фото природы',
  };

  Color _getAccentColorValue(AccentColor c) => switch (c) {
    AccentColor.blue => const Color(0xFF4a9eff),
    AccentColor.purple => const Color(0xFF9c27b0),
    AccentColor.green => const Color(0xFF4caf50),
    AccentColor.orange => const Color(0xFFff9800),
    AccentColor.red => const Color(0xFFf44336),
    AccentColor.pink => const Color(0xFFe91e63),
    AccentColor.teal => const Color(0xFF009688),
  };
}
