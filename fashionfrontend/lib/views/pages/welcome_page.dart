import 'package:Axent/views/pages/signup_page.dart';
import 'package:Axent/utils/page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:Axent/app_colors.dart';
import 'dart:math';
import 'package:particles_flutter/component/particle/particle.dart';
import 'package:particles_flutter/particles_engine.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      child: Stack(
        children: [
          // Background gradient layer
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary,
                  AppColors.blue,
                  scheme.surfaceContainerHighest,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, .5, 1],
              ),
            ),
          ),
          // Particles layer
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  scheme.surface.withAlpha(255),
                  scheme.surface.withAlpha(255),
                  scheme.surface.withAlpha(0),
                ],
                stops: [0.0, 0.5, 0.65],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: Particles(
              awayRadius: 150,
              particles: createParticles(),
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              onTapAnimation: true,
              awayAnimationDuration: const Duration(milliseconds: 100),
              awayAnimationCurve: Curves.linear,
              enableHover: true,
              hoverRadius: 90,
              connectDots: false,
            ),
          ),
          // Content layer (squares and text)
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double screenWidth = constraints.maxWidth;
                final double screenHeight = constraints.maxHeight;
                final double imageSize =
                    screenWidth * 0.25; // Increased size for squares
                final double paddingLeft = screenWidth * 0.06; // IK these are magic numbers but you get the memo
                final double paddingBottom = screenHeight * 0.04;
                final double titleFontSize = screenWidth * 0.11;
                final double subtitleFontSize = screenWidth * 0.035;
                final double buttonWidth = screenWidth * 0.95;
                final double buttonHeight = screenHeight * 0.07;
                final double shoeSquareOpacity = 0.85;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Opacity(
                        opacity: shoeSquareOpacity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              flex: 1,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShoeSquare(
                                    imagePath: 'assets/images/Shoes1.jpg',
                                    imageSize: imageSize,
                                    rotationAngle: 30,
                                  ),
                                  ShoeSquare(
                                    imagePath: 'assets/images/Shoes4.jpg',
                                    imageSize: imageSize,
                                    rotationAngle: 20,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ShoeSquare(
                                        imagePath: 'assets/images/Shoes2.jpg',
                                        imageSize: imageSize,
                                        rotationAngle: -40,
                                      ),
                              ],
                            ),
                            Flexible(
                              flex: 1,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShoeSquare(
                                    imagePath: 'assets/images/Shoes3.jpg',
                                    imageSize: imageSize,
                                    rotationAngle: -15,
                                  ),
                                  ShoeSquare(
                                    imagePath: 'assets/images/Shoes5.jpg',
                                    imageSize: imageSize,
                                    rotationAngle: 25,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: paddingLeft,
                          bottom: paddingBottom,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DefaultTextStyle(
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.normal,
                                  color: scheme.onPrimary,
                                ),
                                child: Text.rich(
                                  textAlign: TextAlign.center,
                                  TextSpan(children: [
                                    TextSpan(text: 'Welcome to\n',),
                                    TextSpan(
                                      text: 'Axent.',
                                      style:
                                          TextStyle(fontWeight: FontWeight.w800, color: scheme.surface),
                                    ),
                                  ]),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              DefaultTextStyle(
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.normal,
                                  fontSize: subtitleFontSize,
                                  color: scheme.onPrimary,
                                ),
                                child: Text(
                                  'Find your fashion, one swipe at a time.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.04),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding:  EdgeInsets.all(paddingLeft),
                      child: ElevatedButton(
                        onPressed: () {
                          // Professional fade-slide transition to Signup
                          Navigator.push(
                            context,
                            PageTransitions.fadeSlideTransition(
                              page: const SignupPage(),
                              duration: const Duration(milliseconds: 500),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          fixedSize: Size(buttonWidth, buttonHeight),
                        ),
                        child: DefaultTextStyle(
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: subtitleFontSize,
                            color: scheme.onPrimary,
                          ),
                          child: Text("Get Started"),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ShoeSquare extends StatelessWidget {
  final String imagePath;
  final double imageSize;
  final double rotationAngle;

  const ShoeSquare(
      {super.key,
      required this.imagePath,
      required this.imageSize,
      required this.rotationAngle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Transform.rotate(
      angle: rotationAngle * (pi / 180), // Convert degrees to radians
      child: Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          color: scheme.surface,
          boxShadow: AppColors.getCardShadow(context),
        ),
        child: Padding(
          padding: EdgeInsets.all(imageSize * 0.05),
          child: Image.asset(imagePath, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

List<Particle> createParticles() {
  var rng = Random();
  List<Particle> particles = [];
  for (int i = 0; i < 150; i++) {
    particles.add(Particle(
      color: (() {
        int outcome = rng.nextInt(4);
        switch (outcome) {
          case 0:
            return AppColors.redLight
                .withAlpha((255 * rng.nextDouble()).toInt());
          case 1:
            return AppColors.blue
                .withAlpha((255 * rng.nextDouble()).toInt());
          case 2:
            return AppColors.paleGray
                .withAlpha((255 * rng.nextDouble()).toInt());
          case 3:
            return AppColors.offWhite
                .withAlpha((255 * rng.nextDouble()).toInt());
          default:
            return AppColors.blue
                .withAlpha((255 * rng.nextDouble()).toInt());
        }
      })(),
      size: rng.nextDouble() * 5,
      velocity: Offset(rng.nextDouble() * 20 * randomSign(),
          rng.nextDouble() * 20 * randomSign()),
    ));
  }
  return particles;
}

double randomSign() {
  var rng = Random();
  return rng.nextBool() ? 1 : -1;
}