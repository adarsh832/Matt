import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile/theme/app_theme.dart';

class QrConnectionScreen extends StatefulWidget {
  const QrConnectionScreen({super.key});

  @override
  State<QrConnectionScreen> createState() => _QrConnectionScreenState();
}

class _QrConnectionScreenState extends State<QrConnectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isVisible = false;
  bool _isConnectedVisible = false;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isConnectedVisible = true;
          });
        }
      });

      Future.delayed(const Duration(seconds: 3), () {
        _navigateToChat();
      });
    });
  }

  void _navigateToChat() {
    if (mounted && !_navigating) {
      _navigating = true;
      Navigator.of(context).pushReplacementNamed('/chat');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: _navigateToChat,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          opacity: _isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                const Text(
                  "Connect to your Local AI",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 48),
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: CustomPaint(
                      painter: _QrPainter(),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Scan the QR code displayed on your laptop.",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.laptop_mac,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 16),
                    Text(
                      "↔",
                      style: TextStyle(
                        fontSize: 24,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(
                      Icons.phone_iphone,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const Spacer(flex: 2),
                AnimatedOpacity(
                  opacity: _isConnectedVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.check,
                        color: AppColors.connectedGreen,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Connected",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.textPrimary;
    final clearPaint = Paint()..color = AppColors.cardBackground;
    const gridSize = 21;
    final cellSize = size.width / gridSize;

    void drawFinderPattern(int gridX, int gridY) {
      // Outer 7x7
      canvas.drawRect(
        Rect.fromLTWH(
            gridX * cellSize, gridY * cellSize, 7 * cellSize, 7 * cellSize),
        paint,
      );
      // Inner clear 5x5
      canvas.drawRect(
        Rect.fromLTWH((gridX + 1) * cellSize, (gridY + 1) * cellSize,
            5 * cellSize, 5 * cellSize),
        clearPaint,
      );
      // Inner block 3x3
      canvas.drawRect(
        Rect.fromLTWH((gridX + 2) * cellSize, (gridY + 2) * cellSize,
            3 * cellSize, 3 * cellSize),
        paint,
      );
    }

    drawFinderPattern(0, 0); // Top-left
    drawFinderPattern(gridSize - 7, 0); // Top-right
    drawFinderPattern(0, gridSize - 7); // Bottom-left

    final rng = Random(12345);
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        // Skip finder patterns
        if ((i < 7 && j < 7) ||
            (i >= gridSize - 7 && j < 7) ||
            (i < 7 && j >= gridSize - 7)) {
          continue;
        }
        if (rng.nextDouble() > 0.45) {
          canvas.drawRect(
            Rect.fromLTWH(i * cellSize, j * cellSize, cellSize, cellSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
