import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../dashboard/dashboard_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  bool _isDark = true;

  void _openLogin() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _openSignup() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SignupScreen()));
  }

  void _openDashboard() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DashboardScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colors = _LandingColors(isDark: _isDark);
    final compact = MediaQuery.sizeOf(context).width < 620;

    return Scaffold(
      backgroundColor: colors.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          gradient: LinearGradient(
            colors: [colors.background, colors.background, colors.panel],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: CustomPaint(
          painter: _GridPainter(color: colors.grid),
          child: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _LandingHeader(
                    colors: colors,
                    isDark: _isDark,
                    isAuthenticated: auth.isAuthenticated,
                    onThemeToggle: () => setState(() => _isDark = !_isDark),
                    onLogin: _openLogin,
                    onSignup: _openSignup,
                    onDashboard: _openDashboard,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 16 : 22,
                          compact ? 28 : 44,
                          compact ? 16 : 22,
                          28,
                        ),
                        child: Column(
                          children: [
                            _HeroSection(
                              colors: colors,
                              isAuthenticated: auth.isAuthenticated,
                              onPrimary: auth.isAuthenticated
                                  ? _openDashboard
                                  : _openSignup,
                              onSecondary: _openLogin,
                            ),
                            SizedBox(height: compact ? 40 : 52),
                            _SectionTitle('Why Aptitude GO?', colors: colors),
                            SizedBox(height: compact ? 18 : 24),
                            _FeatureGrid(colors: colors),
                            SizedBox(height: compact ? 40 : 52),
                            _SectionTitle('Success Stories', colors: colors),
                            SizedBox(height: compact ? 18 : 24),
                            _Testimonials(colors: colors),
                            SizedBox(height: compact ? 40 : 52),
                            _SectionTitle(
                              'Frequently Asked Questions',
                              colors: colors,
                            ),
                            const SizedBox(height: 18),
                            _FaqList(colors: colors),
                            const SizedBox(height: 40),
                            _CtaSection(colors: colors, onSignup: _openSignup),
                            const SizedBox(height: 28),
                            _Footer(colors: colors),
                          ],
                        ),
                      ),
                    ),
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

class _LandingHeader extends StatelessWidget {
  const _LandingHeader({
    required this.colors,
    required this.isDark,
    required this.isAuthenticated,
    required this.onThemeToggle,
    required this.onLogin,
    required this.onSignup,
    required this.onDashboard,
  });

  final _LandingColors colors;
  final bool isDark;
  final bool isAuthenticated;
  final VoidCallback onThemeToggle;
  final VoidCallback onLogin;
  final VoidCallback onSignup;
  final VoidCallback onDashboard;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 620;
    final tiny = width < 360;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tiny ? 12 : (compact ? 16 : 48),
        vertical: compact ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: colors.header,
        border: Border(bottom: BorderSide(color: colors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
              ).createShader(bounds),
              child: Text(
                'Aptitude GO',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: tiny ? 21 : (compact ? 24 : 40),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          SizedBox(width: tiny ? 4 : 8),
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: onThemeToggle,
            icon: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
            ),
            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tightFor(
              width: tiny ? 36 : 40,
              height: tiny ? 36 : 40,
            ),
          ),
          SizedBox(width: tiny ? 4 : 8),
          if (isAuthenticated)
            compact
                ? IconButton(
                    tooltip: 'Dashboard',
                    onPressed: onDashboard,
                    icon: const Icon(Icons.dashboard_rounded),
                    color: colors.mutedText,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(
                      width: tiny ? 36 : 40,
                      height: tiny ? 36 : 40,
                    ),
                  )
                : _TextNavButton(
                    label: 'Dashboard',
                    color: colors.mutedText,
                    onTap: onDashboard,
                  )
          else ...[
            if (!compact)
              _TextNavButton(
                label: 'Log In',
                color: colors.mutedText,
                onTap: onLogin,
              ),
            if (!compact) const SizedBox(width: 10),
            compact
                ? IconButton(
                    tooltip: 'Sign Up',
                    onPressed: onSignup,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: colors.primary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(
                      width: tiny ? 36 : 40,
                      height: tiny ? 36 : 40,
                    ),
                  )
                : _GradientButton(
                    label: 'Sign Up',
                    onTap: onSignup,
                    small: true,
                  ),
          ],
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.colors,
    required this.isAuthenticated,
    required this.onPrimary,
    required this.onSecondary,
  });

  final _LandingColors colors;
  final bool isAuthenticated;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 720;
    final titleSize = compact ? 44.0 : 72.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 18 : 56,
        vertical: compact ? 70 : 120,
      ),
      decoration: BoxDecoration(
        color: colors.hero.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Rocket  Level Up Your Career',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 58),
          Text(
            'Master Aptitude',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.text,
              fontSize: titleSize,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
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
          const SizedBox(height: 34),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              'Compete in tournaments, earn XP, and unlock rewards while preparing for your dream job. The most engaging way to learn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.mutedText,
                fontSize: compact ? 19 : 24,
                height: 1.55,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 34),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 12,
            children: [
              _GradientButton(
                label: isAuthenticated ? 'Go to Dashboard' : 'Get Started',
                onTap: onPrimary,
              ),
              if (!isAuthenticated)
                _OutlineButton(
                  label: 'Log In',
                  colors: colors,
                  onTap: onSecondary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.colors});

  final _LandingColors colors;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _InfoCardData(
        Icons.sports_esports_rounded,
        'Gamified Learning',
        'Earn XP, Coins, and Badges. Turn boring practice into an addictive game.',
        const Color(0xFF6366F1),
      ),
      _InfoCardData(
        Icons.analytics_rounded,
        'Real-time Analytics',
        'Track your stats with pro-level dashboards. Spot weaknesses instantly.',
        const Color(0xFFF59E0B),
      ),
      _InfoCardData(
        Icons.emoji_events_rounded,
        'Battle Grounds',
        'Challenge friends in 1v1 duels or join daily tournaments.',
        const Color(0xFF10B981),
      ),
    ];

    return _ResponsiveGrid(
      children: cards
          .map((card) => _FeatureCard(data: card, colors: colors))
          .toList(),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.data, required this.colors});

  final _InfoCardData data;
  final _LandingColors colors;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(data.icon, color: data.color, size: 30),
          ),
          const SizedBox(height: 22),
          Text(
            data.title,
            style: TextStyle(
              color: colors.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.body,
            style: TextStyle(
              color: colors.mutedText,
              fontSize: 16,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _Testimonials extends StatelessWidget {
  const _Testimonials({required this.colors});

  final _LandingColors colors;

  @override
  Widget build(BuildContext context) {
    return _ResponsiveGrid(
      minItemWidth: 360,
      children: [
        _QuoteCard(
          quote:
              'I used to hate aptitude practice, but this feels like playing an RPG. I actually look forward to my daily tests now!',
          author: 'Sarah K., Software Engineer',
          colors: colors,
        ),
        _QuoteCard(
          quote:
              'The detailed explanations and level-up system kept me motivated. Cleared my placement exams with flying colors.',
          author: 'James R., Student',
          colors: colors,
        ),
      ],
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.quote,
    required this.author,
    required this.colors,
  });

  final String quote;
  final String author;
  final _LandingColors colors;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      colors: colors,
      accentBorder: colors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"$quote"',
            style: TextStyle(
              color: colors.text,
              fontSize: 16,
              height: 1.55,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '- $author',
            style: TextStyle(color: colors.text, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _FaqList extends StatelessWidget {
  const _FaqList({required this.colors});

  final _LandingColors colors;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Is it free to use?',
        'Yes! You get 5 free lives every day. You can refill lives using coins you earn by practicing.',
      ),
      (
        'What topics are covered?',
        'We cover Logical Reasoning, Quantitative Aptitude, Verbal Ability, and more.',
      ),
      (
        'Can I play with friends?',
        'Absolutely! Our Multiplayer mode allows you to create rooms and compete in real-time.',
      ),
    ];

    return Column(
      children: items
          .map(
            (item) => Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.$1,
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.$2,
                    style: TextStyle(
                      color: colors.mutedText,
                      fontSize: 16,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CtaSection extends StatelessWidget {
  const _CtaSection({required this.colors, required this.onSignup});

  final _LandingColors colors;
  final VoidCallback onSignup;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 54),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Ready to Level Up?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 34,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Join thousands of students mastering aptitude today.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFE0E7FF), fontSize: 18),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onSignup,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: colors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Create Free Account',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.colors});

  final _LandingColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '© 2026 Aptitude GO. All Rights Reserved.',
          style: TextStyle(color: colors.mutedText),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 24,
          runSpacing: 8,
          children: [
            Text(
              'Terms of Condition',
              style: TextStyle(color: colors.mutedText),
            ),
            Text('Privacy Policy', style: TextStyle(color: colors.mutedText)),
            Text('Contact Support', style: TextStyle(color: colors.mutedText)),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {required this.colors});

  final String title;
  final _LandingColors colors;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 620;

    return Text(
      title,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: colors.text,
        fontSize: compact ? 30 : 34,
        height: 1.16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({required this.children, this.minItemWidth = 280});

  final List<Widget> children;
  final double minItemWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / minItemWidth).floor().clamp(
          1,
          3,
        );
        final gap = columns == 1 ? 16.0 : 20.0;
        final itemWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.colors, required this.child, this.accentBorder});

  final _LandingColors colors;
  final Widget child;
  final Color? accentBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: accentBorder == null
          ? child
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 76,
                  decoration: BoxDecoration(
                    color: accentBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(child: child),
              ],
            ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onTap,
    this.small = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.24),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: small ? 20 : 30,
              vertical: small ? 12 : 16,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: small ? 15 : 17,
              ),
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
    required this.colors,
    required this.onTap,
  });

  final String label;
  final _LandingColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.text,
        side: BorderSide(color: colors.border),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
      ),
    );
  }
}

class _TextNavButton extends StatelessWidget {
  const _TextNavButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(foregroundColor: color),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
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
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _InfoCardData {
  const _InfoCardData(this.icon, this.title, this.body, this.color);

  final IconData icon;
  final String title;
  final String body;
  final Color color;
}

class _LandingColors {
  _LandingColors({required this.isDark});

  final bool isDark;

  Color get background =>
      isDark ? AppTheme.background : const Color(0xFFF8FAFC);
  Color get panel => isDark ? const Color(0xFF111827) : Colors.white;
  Color get header => isDark
      ? AppTheme.surface.withValues(alpha: 0.84)
      : Colors.white.withValues(alpha: 0.92);
  Color get hero => isDark ? AppTheme.surface : Colors.white;
  Color get card => isDark
      ? AppTheme.surface.withValues(alpha: 0.74)
      : Colors.white.withValues(alpha: 0.86);
  Color get border =>
      isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0);
  Color get grid => isDark
      ? Colors.white.withValues(alpha: 0.055)
      : const Color(0xFF94A3B8).withValues(alpha: 0.16);
  Color get text => isDark ? AppTheme.textPrimary : const Color(0xFF1E293B);
  Color get mutedText =>
      isDark ? AppTheme.textSecondary : const Color(0xFF64748B);
  Color get primary => isDark ? AppTheme.primary : const Color(0xFF4F46E5);
}
