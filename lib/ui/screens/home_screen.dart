import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../services/settings_manager.dart';
import '../theme/koleo_typography.dart';

/// Home screen with animated background, time display and search bar.
class HomeScreen extends StatefulWidget {
  final ValueChanged<String>? onSearch;
  final ValueChanged<String>? onQuickLinkTap;

  const HomeScreen({super.key, this.onSearch, this.onQuickLinkTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late Timer _timeTimer;
  DateTime _currentTime = DateTime.now();
  late AnimationController _animController;
  late AnimationController _gradientAnimController;
  final List<_Particle> _particles = [];
  final Map<int, Uint8List> _loadedImages = {};
  
  // 10 background images
  static const List<String> backgroundImages = [
    'assets/backgrounds/1.jpg',
    'assets/backgrounds/2.jpg',
    'assets/backgrounds/3.jpg',
    'assets/backgrounds/4.jpg',
    'assets/backgrounds/5.jpg',
    'assets/backgrounds/6.jpg',
    'assets/backgrounds/7.jpg',
    'assets/backgrounds/8.jpg',
    'assets/backgrounds/9.jpg',
    'assets/backgrounds/10.jpg',
  ];

  static const List<GradientTheme> themes = [
    GradientTheme('Северное сияние', Color(0xFF0a1628), Color(0xFF1a3a5c), Color(0xFF2d5a87), Color(0xFF64b5f6)),
    GradientTheme('Закат', Color(0xFF1a0a1e), Color(0xFF4a1942), Color(0xFF7b2d5b), Color(0xFFe91e63)),
    GradientTheme('Океан', Color(0xFF0a1a2e), Color(0xFF0d3b66), Color(0xFF1a5276), Color(0xFF00bcd4)),
    GradientTheme('Лес', Color(0xFF0a1a0f), Color(0xFF1a472a), Color(0xFF2d6a4f), Color(0xFF4caf50)),
    GradientTheme('Космос', Color(0xFF0a0a1a), Color(0xFF1a1a3e), Color(0xFF2d2d5a), Color(0xFF9c27b0)),
    GradientTheme('Рассвет', Color(0xFF1a1020), Color(0xFF3d2352), Color(0xFF6a3a7d), Color(0xFFff9800)),
  ];

  @override
  void initState() {
    super.initState();
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
    
    final random = Random();
    for (int i = 0; i < 50; i++) {
      _particles.add(_Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 3 + 1,
        speed: random.nextDouble() * 0.0003 + 0.0001,
        opacity: random.nextDouble() * 0.5 + 0.2,
      ));
    }
    
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _animController.addListener(() {
      for (var p in _particles) {
        p.y -= p.speed;
        if (p.y < 0) p.y = 1;
      }
      if (mounted) setState(() {});
    });

    _gradientAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _preloadImages();
  }

  Future<void> _preloadImages() async {
    for (int i = 0; i < backgroundImages.length; i++) {
      try {
        final data = await rootBundle.load(backgroundImages[i]);
        if (mounted) {
          setState(() => _loadedImages[i] = data.buffer.asUint8List());
        }
      } catch (_) {
        // Image not found, skip
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _timeTimer.cancel();
    _animController.dispose();
    _gradientAnimController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;
    widget.onSearch?.call(query.trim());
    _searchController.clear();
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime time) {
    const weekdays = ['Воскресенье', 'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота'];
    const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return '${weekdays[time.weekday % 7]}, ${time.day} ${months[time.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final settingsManager = context.watch<SettingsManager>();
    final settings = settingsManager.currentSettings;
    final themeIndex = settings.gradientThemeIndex.clamp(0, themes.length - 1);
    final theme = themes[themeIndex];
    
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBackground(settings, theme),
        _buildContent(theme, settings, settingsManager),
      ],
    );
  }

  Widget _buildBackground(AppSettings settings, GradientTheme theme) {
    switch (settings.homeBackground) {
      case HomeBackgroundType.image:
        final imageIndex = settings.backgroundImageIndex.clamp(0, backgroundImages.length - 1);
        final imageBytes = _loadedImages[imageIndex];
        if (imageBytes != null) {
          return Image.memory(
            imageBytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        }
        return _buildAnimatedGradient(theme);
      case HomeBackgroundType.staticGradient:
        return _buildStaticGradient(theme);
      case HomeBackgroundType.animatedGradient:
        return _buildAnimatedGradient(theme);
    }
  }

  Widget _buildStaticGradient(GradientTheme theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.dark, theme.mid, theme.light],
        ),
      ),
    );
  }

  Widget _buildAnimatedGradient(GradientTheme theme) {
    return AnimatedBuilder(
      animation: _gradientAnimController,
      builder: (context, child) {
        return CustomPaint(
          painter: _AnimatedBackgroundPainter(
            particles: _particles,
            theme: theme,
            animValue: _gradientAnimController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildContent(GradientTheme theme, AppSettings settings, SettingsManager settingsManager) {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(flex: 2),
          _buildTimeDisplay(),
          const SizedBox(height: 48),
          _buildSearchBar(),
          const SizedBox(height: 24),
          _buildQuickLinks(settings, settingsManager),
          const SizedBox(height: 24),
          _buildThemeSelector(theme, settings, settingsManager),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildQuickLinks(AppSettings settings, SettingsManager settingsManager) {
    final links = settings.quickLinks.isEmpty ? QuickLink.defaults : settings.quickLinks;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...links.map((link) => _buildQuickLinkItem(link, settings, settingsManager)),
              _buildAddQuickLinkButton(settings, settingsManager),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLinkItem(QuickLink link, AppSettings settings, SettingsManager settingsManager) {
    final domain = Uri.tryParse(link.url)?.host ?? link.url;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => widget.onQuickLinkTap?.call(link.url),
          onLongPress: () => _showQuickLinkMenu(link, settings, settingsManager),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      link.name.isNotEmpty ? link.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  domain,
                  style: KoleoTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddQuickLinkButton(AppSettings settings, SettingsManager settingsManager) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showAddQuickLinkDialog(settings, settingsManager),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Icon(
              Icons.add,
              color: Colors.white.withValues(alpha: 0.5),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  void _showQuickLinkMenu(QuickLink link, AppSettings settings, SettingsManager settingsManager) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(link.name),
        content: Text('Удалить "${link.name}" из быстрых ссылок?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final newLinks = settings.quickLinks.isEmpty 
                  ? List<QuickLink>.from(QuickLink.defaults)
                  : List<QuickLink>.from(settings.quickLinks);
              newLinks.removeWhere((l) => l.url == link.url);
              settingsManager.saveSettings(settings.copyWith(quickLinks: newLinks));
              Navigator.pop(ctx);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddQuickLinkDialog(AppSettings settings, SettingsManager settingsManager) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Добавить ссылку'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Название',
                hintText: 'Google',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://google.com',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (urlController.text.isNotEmpty) {
                var url = urlController.text.trim();
                if (!url.startsWith('http://') && !url.startsWith('https://')) {
                  url = 'https://$url';
                }
                final newLink = QuickLink(
                  name: nameController.text.isEmpty ? Uri.tryParse(url)?.host ?? url : nameController.text,
                  url: url,
                );
                final newLinks = settings.quickLinks.isEmpty 
                    ? List<QuickLink>.from(QuickLink.defaults)
                    : List<QuickLink>.from(settings.quickLinks);
                newLinks.add(newLink);
                settingsManager.saveSettings(settings.copyWith(quickLinks: newLinks));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay() {
    return Column(
      children: [
        Text(
          _formatTime(_currentTime),
          style: KoleoTypography.headline.copyWith(
            color: Colors.white,
            fontSize: 80,
            fontWeight: FontWeight.w200,
            letterSpacing: 8,
            shadows: [Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _formatDate(_currentTime),
          style: KoleoTypography.body.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 18,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: KoleoTypography.body.copyWith(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Поиск или введите адрес',
                hintStyle: KoleoTypography.body.copyWith(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 12),
                  child: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.6), size: 24),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              onSubmitted: _onSearchSubmitted,
              textInputAction: TextInputAction.search,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector(GradientTheme currentTheme, AppSettings settings, SettingsManager settingsManager) {
    final isImageMode = settings.homeBackground == HomeBackgroundType.image;
    final hasImages = _loadedImages.isNotEmpty;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Theme/Image selector button
        Material(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: () {
              if (isImageMode && hasImages) {
                // Switch to next image
                final nextIndex = (settings.backgroundImageIndex + 1) % backgroundImages.length;
                settingsManager.saveSettings(settings.copyWith(backgroundImageIndex: nextIndex));
              } else {
                // Switch gradient theme
                final nextIndex = (settings.gradientThemeIndex + 1) % themes.length;
                settingsManager.saveSettings(settings.copyWith(gradientThemeIndex: nextIndex));
              }
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isImageMode && hasImages) ...[
                    Icon(Icons.image, color: Colors.white.withValues(alpha: 0.8), size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'Фото ${settings.backgroundImageIndex + 1}/${_loadedImages.length}',
                      style: KoleoTypography.caption.copyWith(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                    ),
                  ] else ...[
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [currentTheme.accent, currentTheme.mid]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(currentTheme.name, style: KoleoTypography.caption.copyWith(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Background type toggle
        Material(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: () {
              final types = HomeBackgroundType.values;
              final currentIndex = types.indexOf(settings.homeBackground);
              var nextIndex = (currentIndex + 1) % types.length;
              // Skip image if no images available
              if (types[nextIndex] == HomeBackgroundType.image && !hasImages) {
                nextIndex = 0;
              }
              settingsManager.saveSettings(settings.copyWith(homeBackground: types[nextIndex]));
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getBackgroundIcon(settings.homeBackground),
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getBackgroundLabel(settings.homeBackground),
                    style: KoleoTypography.caption.copyWith(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getBackgroundIcon(HomeBackgroundType type) => switch (type) {
    HomeBackgroundType.animatedGradient => Icons.auto_awesome,
    HomeBackgroundType.staticGradient => Icons.gradient,
    HomeBackgroundType.image => Icons.image,
  };

  String _getBackgroundLabel(HomeBackgroundType type) => switch (type) {
    HomeBackgroundType.animatedGradient => 'Анимация',
    HomeBackgroundType.staticGradient => 'Градиент',
    HomeBackgroundType.image => 'Фото',
  };
}

class GradientTheme {
  final String name;
  final Color dark;
  final Color mid;
  final Color light;
  final Color accent;

  const GradientTheme(this.name, this.dark, this.mid, this.light, this.accent);
}

class _Particle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;

  _Particle({required this.x, required this.y, required this.size, required this.speed, required this.opacity});
}

class _AnimatedBackgroundPainter extends CustomPainter {
  final List<_Particle> particles;
  final GradientTheme theme;
  final double animValue;

  _AnimatedBackgroundPainter({required this.particles, required this.theme, required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Animated gradient with shifting colors
    final shift = animValue * 0.3;
    final gradient = LinearGradient(
      begin: Alignment(-1 + shift, -1 + shift),
      end: Alignment(1 - shift, 1 - shift),
      colors: [
        Color.lerp(theme.dark, theme.mid, animValue * 0.3)!,
        Color.lerp(theme.mid, theme.light, animValue * 0.2)!,
        Color.lerp(theme.light, theme.accent, animValue * 0.15)!,
      ],
      stops: [0.0, 0.5 + animValue * 0.1, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // Animated glow effect
    final glowPaint = Paint()
      ..color = theme.accent.withValues(alpha: 0.1 + animValue * 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    canvas.drawCircle(
      Offset(size.width * (0.3 + animValue * 0.4), size.height * (0.3 + animValue * 0.4)),
      150 + animValue * 50,
      glowPaint,
    );

    // Draw particles
    final particlePaint = Paint();
    for (var p in particles) {
      particlePaint.color = theme.accent.withValues(alpha: p.opacity * (0.8 + animValue * 0.2));
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size * (1 + animValue * 0.3),
        particlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedBackgroundPainter oldDelegate) => true;
}
