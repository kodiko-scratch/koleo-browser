import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/wallpaper_service.dart';
import '../theme/koleo_typography.dart';

/// Home screen with animated background, time display and search bar.
/// Requirements: 4.1-4.4
class HomeScreen extends StatefulWidget {
  final ValueChanged<String>? onSearch;
  final WallpaperService? wallpaperService;

  const HomeScreen({
    super.key,
    this.onSearch,
    this.wallpaperService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late Timer _timeTimer;
  DateTime _currentTime = DateTime.now();
  late AnimationController _animController;
  final List<_Particle> _particles = [];
  int _themeIndex = 0;

  // Beautiful color themes
  static const List<_ColorTheme> _themes = [
    _ColorTheme('Северное сияние', Color(0xFF0a1628), Color(0xFF1a3a5c), Color(0xFF2d5a87), Color(0xFF64b5f6)),
    _ColorTheme('Закат', Color(0xFF1a0a1e), Color(0xFF4a1942), Color(0xFF7b2d5b), Color(0xFFe91e63)),
    _ColorTheme('Океан', Color(0xFF0a1a2e), Color(0xFF0d3b66), Color(0xFF1a5276), Color(0xFF00bcd4)),
    _ColorTheme('Лес', Color(0xFF0a1a0f), Color(0xFF1a472a), Color(0xFF2d6a4f), Color(0xFF4caf50)),
    _ColorTheme('Космос', Color(0xFF0a0a1a), Color(0xFF1a1a3e), Color(0xFF2d2d5a), Color(0xFF9c27b0)),
    _ColorTheme('Рассвет', Color(0xFF1a1020), Color(0xFF3d2352), Color(0xFF6a3a7d), Color(0xFFff9800)),
  ];

  @override
  void initState() {
    super.initState();
    _themeIndex = Random().nextInt(_themes.length);
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
    
    // Initialize particles
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
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    
    _animController.addListener(() {
      for (var p in _particles) {
        p.y -= p.speed;
        if (p.y < 0) p.y = 1;
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _timeTimer.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _changeTheme() {
    setState(() {
      _themeIndex = (_themeIndex + 1) % _themes.length;
    });
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
    const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 
                    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return '${weekdays[time.weekday % 7]}, ${time.day} ${months[time.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = _themes[_themeIndex];
    
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildAnimatedBackground(theme),
        _buildContent(theme),
      ],
    );
  }

  Widget _buildAnimatedBackground(_ColorTheme theme) {
    return CustomPaint(
      painter: _BackgroundPainter(
        particles: _particles,
        theme: theme,
      ),
      size: Size.infinite,
    );
  }

  Widget _buildContent(_ColorTheme theme) {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(flex: 2),
          _buildTimeDisplay(),
          const SizedBox(height: 48),
          _buildSearchBar(),
          const SizedBox(height: 24),
          _buildThemeButton(theme),
          const Spacer(flex: 3),
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
            shadows: [
              Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20),
            ],
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
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: KoleoTypography.body.copyWith(
                color: Colors.white,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Поиск или введите адрес',
                hintStyle: KoleoTypography.body.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 16,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 12),
                  child: Icon(
                    Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 24,
                  ),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
              onSubmitted: _onSearchSubmitted,
              textInputAction: TextInputAction.search,
              autocorrect: false,
              enableSuggestions: false,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeButton(_ColorTheme theme) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: _changeTheme,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [theme.accent, theme.mid],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                theme.name,
                style: KoleoTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.refresh_rounded,
                color: Colors.white.withValues(alpha: 0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorTheme {
  final String name;
  final Color dark;
  final Color mid;
  final Color light;
  final Color accent;

  const _ColorTheme(this.name, this.dark, this.mid, this.light, this.accent);
}

class _Particle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _BackgroundPainter extends CustomPainter {
  final List<_Particle> particles;
  final _ColorTheme theme;

  _BackgroundPainter({required this.particles, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw gradient background
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [theme.dark, theme.mid, theme.light],
      stops: const [0.0, 0.5, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // Draw particles
    final particlePaint = Paint()..color = theme.accent;
    for (var p in particles) {
      particlePaint.color = theme.accent.withValues(alpha: p.opacity);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        particlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) => true;
}
