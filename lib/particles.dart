import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class Particles extends StatefulWidget {
  final int numberOfParticles;

  const Particles(this.numberOfParticles, {super.key});

  @override
  _ParticlesState createState() => _ParticlesState();
}

class _ParticlesState extends State<Particles> {

  final Random random = Random();
  // final List<ParticleModel> particles = [];

  bool imageLoaded = false;
  ui.Image? image;

  @override
  void initState() {
    // List.generate(widget.numberOfParticles, (index) {
    //   particles.add(ParticleModel(random));
    // });
    super.initState();
    init();
  }

  Future<void> init() async {
    final ByteData data = await rootBundle.load("assets/elements/fire.png");
    image = await loadImage(Uint8List.view(data.buffer));
  }

  Future<ui.Image> loadImage(List<int> img) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(img as Uint8List, (ui.Image img) {
      setState(() {
        imageLoaded = true;
      });
      return completer.complete(img);
    });
    return completer.future;
  }

  Widget loadParticles(Duration time) {
    return Container();
    // return imageLoaded
    //     ? CustomPaint(painter: ParticlePainter(particles, time, image))
    //     : Container();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
    // return Rendering(
    //   startTime: const Duration(seconds: 30),
    //   onTick: _simulateParticles,
    //   builder: (context, time) {
    //     return loadParticles(time);
    //   },
    // );
  }

  // _simulateParticles(Duration time) {
  //   for (var particle in particles) {
  //     particle.maintainRestart(time);
  //   }
  // }
}

// class ParticleModel {
//   late Animatable tween;
//   double? size;
//   late AnimationProgress animationProgress;
//   Random random;
//
//   ParticleModel(this.random) {
//     restart();
//   }
//
//   restart({Duration time = Duration.zero}) {
//     final startPosition = Offset(-0.2 + 1.4 * random.nextDouble(), 1.2);
//     final endPosition = Offset(-0.2 + 1.4 * random.nextDouble(), -0.2);
//     final duration = Duration(milliseconds: 3000 + random.nextInt(6000));
//
//     tween = MultiTrackTween([
//       Track("x").add(
//           duration, Tween(begin: startPosition.dx, end: endPosition.dx),
//           curve: Curves.easeInOutSine),
//       Track("y").add(
//           duration, Tween(begin: startPosition.dy, end: endPosition.dy),
//           curve: Curves.easeIn),
//     ]);
//     animationProgress = AnimationProgress(duration: duration, startTime: time);
//     size = 0.2 + random.nextDouble() * 0.4;
//   }
//
//   maintainRestart(Duration time) {
//     if (animationProgress.progress(time) == 1.0) {
//       restart(time: time);
//     }
//   }
// }

// class ParticlePainter extends CustomPainter {
//   List<ParticleModel> particles;
//   Duration time;
//   ui.Image? image;
//
//   ParticlePainter(this.particles, this.time, this.image);
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.white.withAlpha(50);
//
//     for (var particle in particles) {
//       var progress = particle.animationProgress.progress(time);
//       final animation = particle.tween.transform(progress);
//       canvas.drawImage(image!, Offset(animation["x"] * size.width, animation["y"] * size.height), paint);
//     }
//   }
//
//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => true;
// }