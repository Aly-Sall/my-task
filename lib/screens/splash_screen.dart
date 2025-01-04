import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  List<Particle> particles = [];
  final int numberOfParticles = 50;

  @override
  void initState() {
    super.initState();

    // Initialiser les particules
    for (int i = 0; i < numberOfParticles; i++) {
      particles.add(Particle());
    }

    // Animation Controller principal
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Animation pour le logo
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();

    // Animation des particules
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          for (var particle in particles) {
            particle.update();
          }
        });
      }
    });

    // Navigation
    Timer(const Duration(seconds: 4), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fond dégradé
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade900,
                  Colors.blue.shade500,
                  Colors.blue.shade300,
                ],
              ),
            ),
          ),

          // Particules animées
          CustomPaint(
            painter: ParticlePainter(particles),
            size: Size.infinite,
          ),

          // Contenu principal
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animé
                ScaleTransition(
                  scale: _animation,
                  child: FadeTransition(
                    opacity: _animation,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 200,
                      height: 200,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Texte avec animation
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(_animation),
                  child: FadeTransition(
                    opacity: _animation,
                    child: const Text(
                      "Bienvenue dans votre application\nde gestion des tâches !",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Sous-titre avec animation
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(_animation),
                  child: FadeTransition(
                    opacity: _animation,
                    child: const Text(
                      "Écrivez vos tâches avec facilité",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Classe pour gérer les particules
class Particle {
  double x = math.Random().nextDouble() * 400;
  double y = math.Random().nextDouble() * 800;
  double radius = math.Random().nextDouble() * 3 + 1;
  double speedX = (math.Random().nextDouble() - 0.5) * 2;
  double speedY = (math.Random().nextDouble() - 0.5) * 2;
  double opacity = math.Random().nextDouble();

  void update() {
    x += speedX;
    y += speedY;

    // Rebondissement sur les bords
    if (x < 0 || x > 400) speedX *= -1;
    if (y < 0 || y > 800) speedY *= -1;

    // Animation de l'opacité
    opacity += (math.Random().nextDouble() - 0.5) * 0.1;
    if (opacity < 0) opacity = 0;
    if (opacity > 1) opacity = 1;
  }
}

// Peintre personnalisé pour dessiner les particules
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(particle.opacity * 0.6)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
