import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.height < 720;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            const _AmbientBackdrop(),
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(),
                    SizedBox(height: isCompact ? 26 : 42),
                    _HeroCard(isCompact: isCompact),
                    const SizedBox(height: 18),
                    const Center(
                      child: Text(
                        'A simple, secure way to manage driver identity and traffic records.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/branding/driveid_icon.png',
              width: 36,
              height: 36,
            ),
            const SizedBox(width: 12),
            const Text(
              'DriveID',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.textSecondary,
          ),
          child: const Text('Sign In'),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: AppTheme.cardDark.withAlpha(214),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(56),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _IdentityBadge(size: isCompact ? 170 : 220)),
          const SizedBox(height: 28),
          const Text(
            'Digital road identity, ready when it matters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 32,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Secure access for drivers and traffic officers in one trusted mobile workspace.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _IdentityBadge extends StatelessWidget {
  const _IdentityBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.gold.withAlpha(64),
                  AppTheme.gold.withAlpha(13),
                ],
              ),
            ),
          ),
          Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: AppTheme.background,
              border: Border.all(color: AppTheme.cardBorder),
              boxShadow: [
                BoxShadow(
                color: Colors.black.withAlpha(89),
                  blurRadius: 26,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Image.asset('assets/branding/driveid_icon.png'),
            ),
          ),
          Positioned(
            right: size * 0.10,
            bottom: size * 0.14,
            child: Container(
              width: size * 0.22,
              height: size * 0.22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondaryTeal,
                border: Border.all(color: AppTheme.background, width: 4),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientBackdrop extends StatelessWidget {
  const _AmbientBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AmbientBackdropPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _AmbientBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = AppTheme.primaryDeepBlue.withAlpha(64);
    canvas.drawCircle(
      Offset(size.width * 0.12, size.height * 0.18),
      130,
      paint,
    );

    paint.color = AppTheme.secondaryTeal.withAlpha(32);
    canvas.drawCircle(
      Offset(size.width * 0.94, size.height * 0.30),
      140,
      paint,
    );

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.gold.withAlpha(40),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.66, size.height * 0.14),
        radius: 88,
      ));
    canvas.drawCircle(Offset(size.width * 0.66, size.height * 0.14), 88, glow);

    final road = Paint()
      ..color = Colors.white.withAlpha(10)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.16, size.height)
      ..cubicTo(
        size.width * 0.38,
        size.height * 0.70,
        size.width * 0.56,
        size.height * 0.56,
        size.width * 0.82,
        0,
      );
    canvas.drawPath(path, road);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
