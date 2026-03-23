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
/// 🧠 橢圓軌道模型（核心）
/// =========================
class EllipseTrack {
  final Rect rect;

  EllipseTrack(this.rect);

  double get a => rect.width / 2;

  double get b => rect.height / 2;

  Offset get center => rect.center;

  Offset point(double t) {
    final x = center.dx + a * cos(t);
    final y = center.dy - b * sin(t);
    return Offset(x, y);
  }

  /// 切線角度（讓卡片貼弧）
  double tangent(double t) {
    return atan2(b * cos(t), -a * sin(t));
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
/// 🎨 橢圓基準線（上半部）
/// =========================
class EllipseGuidePainter extends CustomPainter {
  final Rect rect;

  EllipseGuidePainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    /// 上半橢圓
    canvas.drawArc(
      rect,
      pi, // 左
      pi, // 畫到右（上半）
      false,
      paint,
    );

    /// Debug：畫矩形（藍框）
    final debugPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, debugPaint);
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

  Rect? ellipseRect;

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
  /// 🌙 橢圓展開（重點）
  /// =========================
  Future<void> arcSpread() async {
    await runAnimation(() {
      final size = MediaQuery.of(context).size;

      /// 🔵 定義你的「控制矩形」
      final rect = Rect.fromLTWH(
        40,
        size.height * 0.3,
        size.width - 80,
        size.height * 0.4,
      );

      ellipseRect = rect;

      final track = EllipseTrack(rect);

      final startAngle = pi * 0.2;
      final endAngle = pi * 0.8;

      for (int i = 0; i < cards.length; i++) {
        double t = i / (cards.length - 1);
        double angle = lerpDouble(startAngle, endAngle, t)!;

        final point = track.point(angle);

        cards[i].targetX = point.dx - (cardWidth / 2);
        cards[i].targetY = point.dy - (cardHeight / 2) + (rect.height/2);

        final dx = track.center.dx - point.dx;
        final dy = track.center.dy - point.dy;

        // TODO: 這行要動態調整每張卡片的角度
        cards[i].targetR = 0;
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
          /// 🎯 橢圓基準線
          if (ellipseRect != null)
            CustomPaint(
              size: Size.infinite,
              painter: EllipseGuidePainter(rect: ellipseRect!),
            ),

          /// 🎴 卡片
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
                  child: Text("${card.id}"),
                ),
              ),
            );
          }),

          /// 🎮 控制
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
