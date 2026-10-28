import 'dart:math' as math;

import 'package:flutter/material.dart';

/// "Continue with Google" in Google's light button style: white surface,
/// grey outline, multicolour G, dark text.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.busy = false,
  });

  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Continue with Google',
      child: Opacity(
        opacity: onPressed == null && !busy ? 0.6 : 1,
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF747775)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: busy ? null : onPressed,
            child: SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (busy)
                    const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1F1F1F),
                      ),
                    )
                  else
                    const GoogleLogo(size: 20),
                  const SizedBox(width: 12),
                  const ExcludeSemantics(
                    child: Text(
                      'Continue with Google',
                      style: TextStyle(
                        color: Color(0xFF1F1F1F),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The multicolour Google "G", drawn with Google's brand colours.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _GPainter()),
  );
}

class _GPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = s * 0.2;
    final rect = Rect.fromCircle(
      center: Offset(s / 2, s / 2),
      radius: (s - stroke) / 2,
    );
    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    double deg(double d) => d * math.pi / 180;
    // Angles clockwise from 3 o'clock.
    canvas.drawArc(rect, deg(-40), deg(-95), false, arc(_red)); // top
    canvas.drawArc(rect, deg(-135), deg(-90), false, arc(_yellow)); // left
    canvas.drawArc(rect, deg(135), deg(-90), false, arc(_green)); // bottom
    canvas.drawArc(rect, deg(45), deg(-45), false, arc(_blue)); // lower right
    // Blue crossbar.
    canvas.drawRect(
      Rect.fromLTWH(s / 2, s / 2 - stroke / 2, s / 2 - stroke * 0.05, stroke),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
