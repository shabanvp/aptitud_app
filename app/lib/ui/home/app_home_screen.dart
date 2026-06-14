import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_state_provider.dart';

class AppHomeScreen extends StatelessWidget {
  const AppHomeScreen({
    super.key,
    required this.onPractice,
    required this.onBattle,
  });

  final VoidCallback onPractice;
  final VoidCallback onBattle;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final gameState = context.watch<GameStateProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 720;
    final phone = width < 430;
    final titleSize = phone ? 36.0 : (compact ? 44.0 : 72.0);
    final horizontalPadding = phone ? 22.0 : (compact ? 28.0 : 48.0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomPaint(
        painter: const _GridPainter(),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              phone ? 24 : (compact ? 30 : 54),
              horizontalPadding,
              28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  children: [
                    if (compact)
                      Center(
                        child: _UserPill(username: user?.username ?? 'Player'),
                      )
                    else
                      Row(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFF6366F1), AppTheme.primary],
                            ).createShader(bounds),
                            child: const Text(
                              'Aptitude GO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          const Spacer(),
                          _UserPill(username: user?.username ?? 'Player'),
                        ],
                      ),
                    SizedBox(height: phone ? 40 : (compact ? 52 : 76)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: phone ? 14 : 18,
                        vertical: phone ? 9 : 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.34),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.rocket_launch_rounded,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 9),
                          Text(
                            'Level Up Your Career',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: phone ? 14 : 16,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: phone ? 34 : (compact ? 46 : 82)),
                    Text(
                      'Master Aptitude',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: titleSize,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF6366F1), AppTheme.primary],
                      ).createShader(bounds),
                      child: Text(
                        'Like a Pro Gamer',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleSize,
                          height: 1.08,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    SizedBox(height: phone ? 22 : 30),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Text(
                        'Compete in tournaments, earn XP, and unlock rewards while preparing for your dream job. The most engaging way to learn.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: phone ? 16 : (compact ? 18 : 24),
                          height: phone ? 1.48 : 1.55,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    SizedBox(height: phone ? 30 : 34),
                    _ActionButtons(
                      compact: compact,
                      onPractice: onPractice,
                      onBattle: onBattle,
                    ),
                    SizedBox(height: phone ? 32 : 42),
                    _StatsStrip(gameState: gameState),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserPill extends StatelessWidget {
  const _UserPill({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;

    return Container(
      constraints: BoxConstraints(maxWidth: compact ? 210 : 260),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 9 : 10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.25),
            child: Text(
              username.isEmpty ? 'P' : username[0].toUpperCase(),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.compact,
    required this.onPractice,
    required this.onBattle,
  });

  final bool compact;
  final VoidCallback onPractice;
  final VoidCallback onBattle;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GradientButton(
              label: 'Start Practice',
              icon: Icons.play_arrow_rounded,
              onTap: onPractice,
              expanded: true,
            ),
            const SizedBox(height: 12),
            _OutlineButton(
              label: 'Battle',
              icon: Icons.sports_esports_rounded,
              onTap: onBattle,
              expanded: true,
            ),
          ],
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        _GradientButton(
          label: 'Start Practice',
          icon: Icons.play_arrow_rounded,
          onTap: onPractice,
        ),
        _OutlineButton(
          label: 'Battle',
          icon: Icons.sports_esports_rounded,
          onTap: onBattle,
        ),
      ],
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.gameState});

  final GameStateProvider gameState;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 14,
      children: [
        _StatChip(
          icon: Icons.star_rounded,
          label: 'Level',
          value: '${gameState.level}',
          color: AppTheme.accent,
        ),
        _StatChip(
          icon: Icons.bolt_rounded,
          label: 'XP',
          value: '${gameState.exp}',
          color: AppTheme.secondary,
        ),
        _StatChip(
          icon: Icons.monetization_on_rounded,
          label: 'Coins',
          value: '${gameState.coins}',
          color: AppTheme.accent,
        ),
        _StatChip(
          icon: Icons.favorite_rounded,
          label: 'Lives',
          value: '${gameState.lives}',
          color: AppTheme.error,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.expanded = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), AppTheme.primary],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.24),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.expanded = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.textPrimary,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
      ),
    );

    if (!expanded) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..strokeWidth = 1;
    const gap = 40.0;

    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}
