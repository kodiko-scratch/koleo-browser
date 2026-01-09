import 'package:flutter/material.dart' hide ThemeMode;
import '../../models/app_settings.dart';
import '../../services/settings_manager.dart';
import '../theme/theme.dart';

/// Settings screen with modern design.
/// Requirements: 5.1-5.5
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
            title: Text(
              'Настройки',
              style: KoleoTypography.headline.copyWith(color: textColor, fontSize: 22),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSection('Поиск', Icons.search_rounded, [
                  _buildOptionTile(
                    'Поисковая система',
                    _getSearchEngineLabel(_settings.searchEngine),
                    Icons.language_rounded,
                    () => _showSearchEngineDialog(),
                  ),
                  _buildSwitchTile(
                    'Подсказки поиска',
                    'Показывать при вводе',
                    _settings.showSearchSuggestions,
                    (v) => _updateSettings(_settings.copyWith(showSearchSuggestions: v)),
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSection('Безопасность', Icons.shield_rounded, [
                  _buildOptionTile(
                    'Уровень защиты',
                    _getSecurityLevelLabel(_settings.securityLevel),
                    Icons.security_rounded,
                    () => _showSecurityDialog(),
                  ),
                  _buildOptionTile(
                    'VPN',
                    'Обход блокировок',
                    Icons.vpn_lock_rounded,
                    () => widget.onOpenVpn?.call(),
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSection('Внешний вид', Icons.palette_rounded, [
                  _buildOptionTile(
                    'Тема',
                    _getThemeModeLabel(_settings.themeMode),
                    _getThemeIcon(_settings.themeMode),
                    () => _showThemeDialog(),
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSection('О браузере', Icons.info_outline_rounded, [
                  _buildInfoTile('Версия', '1.0.0'),
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
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFe0e0e0),
            ),
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

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final secondaryColor = isDark ? Colors.white60 : const Color(0xFF666666);
    final accentColor = isDark ? KoleoColors.darkAccent : KoleoColors.lightAccent;

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
            activeColor: accentColor,
            activeTrackColor: accentColor.withValues(alpha: 0.4),
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
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFe8e8e8),
    );
  }

  void _showSearchEngineDialog() => _showDialog<SearchEngineType>(
    'Поисковая система',
    SearchEngineType.values,
    _settings.searchEngine,
    _getSearchEngineLabel,
    (v) => _updateSettings(_settings.copyWith(searchEngine: v)),
  );

  void _showSecurityDialog() => _showDialog<SecurityLevel>(
    'Уровень защиты',
    SecurityLevel.values,
    _settings.securityLevel,
    _getSecurityLevelLabel,
    (v) => _updateSettings(_settings.copyWith(securityLevel: v)),
  );

  void _showThemeDialog() => _showDialog<ThemeMode>(
    'Тема оформления',
    ThemeMode.values,
    _settings.themeMode,
    _getThemeModeLabel,
    (v) => _updateSettings(_settings.copyWith(themeMode: v)),
  );

  void _showDialog<T>(String title, List<T> items, T selected, String Function(T) label, ValueChanged<T> onSelect) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1a1a1a) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final accentColor = isDark ? KoleoColors.darkAccent : KoleoColors.lightAccent;

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
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: KoleoTypography.headline.copyWith(color: textColor, fontSize: 18)),
            const SizedBox(height: 8),
            ...items.map((item) => Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  onSelect(item);
                  Navigator.pop(ctx);
                },
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
}
