import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ArcSpreadDemo(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// =========================
/// 卡片資料模型
/// =========================
class CardModel {
  final int id;

  double x;
  double y;
  double rotation;

  double startX;
  double startY;
  double startR;

  double targetX;
  double targetY;
  double targetR;

  CardModel({required this.id, this.x = 0, this.y = 0, this.rotation = 0})
    : startX = 0,
      startY = 0,
      startR = 0,
      targetX = 0,
      targetY = 0,
      targetR = 0;
}

/// =========================
/// 🎨 圓弧基準線 Painter
/// =========================
class ArcGuidePainter extends CustomPainter {
  final double radius;
  final Offset center;
  final double startAngle;
  final double sweepAngle;

  ArcGuidePainter({
    required this.radius,
    required this.center,
    required this.startAngle,
    required this.sweepAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
      // ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4); // 🔥 發光感

    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ArcSpreadDemo extends StatefulWidget {
  const ArcSpreadDemo({super.key});

  @override
  State<ArcSpreadDemo> createState() => _ArcSpreadDemoState();
}

class _ArcSpreadDemoState extends State<ArcSpreadDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  final int cardCount = 22;
  List<CardModel> cards = [];

  final double cardWidth = 150;
  final double cardHeight = 320;

  /// =========================
  /// 🔵 圓弧參數（給 Painter 用）
  /// =========================
  double arcRadius = 0;
  double arcStartAngle = 0;
  double arcEndAngle = 0;
  Offset arcCenter = Offset.zero;

  @override
  void initState() {
    super.initState();

    controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 400),
        )..addListener(() {
          setState(() {
            for (var c in cards) {
              c.x = lerpDouble(c.startX, c.targetX, controller.value)!;
              c.y = lerpDouble(c.startY, c.targetY, controller.value)!;
              c.rotation = lerpDouble(c.startR, c.targetR, controller.value)!;
            }
          });
        });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        initCards();
      });
    });
  }

  void initCards() {
    final pos = getInitialCardPosition(context);

    cards = List.generate(cardCount, (i) {
      return CardModel(id: i, x: pos.dx, y: pos.dy);
    });
  }

  Future<void> runAnimation(void Function() setTargets) async {
    for (var c in cards) {
      c.startX = c.x;
      c.startY = c.y;
      c.startR = c.rotation;
    }

    setTargets();

    await controller.forward(from: 0);
  }

  /// =========================
  /// 🌙 弧形展開（升級版）
  /// =========================
  Future<void> arcSpread() async {
    await runAnimation(() {
      final size = MediaQuery.of(context).size;

      final double radius = size.width * 0.9;

      final double centerX = size.width / 2;
      final double centerY = size.height + radius * 0.2;

      final double startAngle = -pi / 2 - 0.7;
      final double endAngle = -pi / 2 + 0.7;

      /// 👉 記錄給 Painter
      arcRadius = radius;
      arcStartAngle = startAngle;
      arcEndAngle = endAngle;
      arcCenter = Offset(centerX, centerY);

      for (int i = 0; i < cards.length; i++) {
        double t = i / (cards.length - 1);
        double angle = lerpDouble(startAngle, endAngle, t)!;

        /// 🔥 重點：用「卡片中心」貼圓
        final double cardCenterX = centerX + radius * cos(angle);
        final double cardCenterY = centerY + radius * sin(angle);

        cards[i].targetX = cardCenterX - cardWidth / 2;
        cards[i].targetY = cardCenterY - cardHeight / 2;

        cards[i].targetR = angle + pi / 2;
      }
    });
  }

  /// =========================
  /// 📦 收回
  /// =========================
  Future<void> gather() async {
    final pos = getInitialCardPosition(context);

    await runAnimation(() {
      for (var c in cards) {
        c.targetX = pos.dx;
        c.targetY = pos.dy;
        c.targetR = 0;
      }
    });
  }

  Offset getInitialCardPosition(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final double centerX = (size.width / 2) - (cardWidth / 2);
    final double centerY = size.height - (cardHeight * 0.7);

    return Offset(centerX, centerY);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[900],
      body: Stack(
        children: [
          /// =========================
          /// 🎯 圓弧基準線（重點）
          /// =========================
          if (arcRadius > 0)
            CustomPaint(
              size: Size.infinite,
              painter: ArcGuidePainter(
                radius: arcRadius,
                center: arcCenter,
                startAngle: arcStartAngle,
                sweepAngle: arcEndAngle - arcStartAngle,
              ),
            ),

          /// =========================
          /// 🎴 卡片層
          /// =========================
          ...cards.map((card) {
            return Positioned(
              left: card.x,
              top: card.y,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateZ(card.rotation),
                child: Container(
                  width: cardWidth,
                  height: cardHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(blurRadius: 6, color: Colors.black26),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "${card.id}",
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            );
          }),

          /// =========================
          /// 🎮 控制
          /// =========================
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: arcSpread,
                  child: const Text("Arc Spread"),
                ),
                const SizedBox(width: 20),
                ElevatedButton(onPressed: gather, child: const Text("Gather")),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
