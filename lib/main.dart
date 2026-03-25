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
  final double flattenFactor;

  EllipseTrack(this.rect, {this.flattenFactor = 1.0});

  double get a => rect.width / 2;

  double get b => (rect.height / 2) * flattenFactor;

  Offset get center => rect.center;

  Offset point(double t) {
    final x = center.dx + a * cos(t);
    final y = center.dy - b * sin(t);
    return Offset(x, y);
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

  double angle;

  bool isChoose;
  bool isSelected;

  CardModel({required this.id, this.x = 0, this.y = 0, this.rotation = 0, this.angle = 0, this.isChoose = false, this.isSelected = false})
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
  final double flattenFactor;

  EllipseGuidePainter({required this.rect, this.flattenFactor = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    /// 🎯 壓縮後的橢圓 rect（關鍵）
    final flattenedRect = Rect.fromCenter(
      center: rect.center,
      width: rect.width,
      height: rect.height * flattenFactor,
    );

    /// 上半橢圓
    canvas.drawArc(flattenedRect, pi, pi, false, paint);

    /// Debug：原始矩形（藍）
    final debugPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, debugPaint);

    /// Debug：壓縮後矩形（綠）
    final debugFlattenPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke;

    canvas.drawRect(flattenedRect, debugFlattenPaint);
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
  final flattenFactor = 0.5;

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

      final track = EllipseTrack(rect, flattenFactor: flattenFactor);

      final startAngle = pi * 0.2;
      final endAngle = pi * 0.8;

      for (int i = 0; i < cards.length; i++) {
        double t = i / (cards.length - 1);
        double angle = lerpDouble(startAngle, endAngle, t)!;
        cards[i].angle = angle; // 儲存卡片當前角度

        // 位置(XY軸)
        final point = track.point(angle);
        cards[i].targetX = point.dx - (cardWidth / 2);
        cards[i].targetY = point.dy - (cardHeight / 2) + (rect.height / 2);

        // 角度(R)
        double maxAngle = 15 * pi / 180;
        cards[i].targetR = lerpDouble(maxAngle, -maxAngle, t)!;
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
      body: GestureDetector(
        onPanUpdate: (details) {
          _handleTouch(details.localPosition);
        },
        child: Stack(
          children: [
            /// 🎯 橢圓基準線
            if (ellipseRect != null)
              CustomPaint(
                size: Size.infinite,
                painter: EllipseGuidePainter(
                  rect: ellipseRect!,
                  flattenFactor: flattenFactor,
                ),
              ),

            /// 🎴 卡片
            ...cards.map((card) {
              final offset = _getLiftOffset(card); // Choose時的偏移

              return Positioned(
                left: card.x + offset.dx,
                top: card.y + offset.dy,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateZ(card.rotation),
                  child: Stack(
                    clipBehavior: Clip.none, // ⭐ 讓文字可以超出卡片
                    alignment: Alignment.center,
                    children: [
                      /// 🎴 卡片（底層）
                      Container(
                        width: cardWidth,
                        height: cardHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(blurRadius: 6, color: Colors.black26),
                          ],
                        ),
                      ),

                      /// 🏷️ 文字（上層，往上浮）
                      if (card.isChoose)
                      Positioned(
                        top: -50, // ⭐ 關鍵：往上偏移
                        child: AnimatedOpacity(
                          duration: Duration(milliseconds: 150),
                          opacity: card.isChoose ? 1 : 0,
                          child: _cardLabelWidget(card),
                        ),
                      ),
                    ],
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
      ),
    );
  }

  Widget _cardLabelWidget(CardModel card) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        "Card ${card.id}",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _handleTouch(Offset touchPos) {
    CardModel? hitCard;

    // 從最上層往下找
    for (var card in cards.reversed) {
      final rect = Rect.fromLTWH(card.x, card.y, cardWidth, cardHeight);

      if (rect.contains(touchPos)) {
        hitCard = card;
        break;
      }
    }

    for (var card in cards) {
      card.isChoose = (card == hitCard);
    }

    setState(() {});
  }

  Offset _getLiftOffset(CardModel card) {
    if (!card.isChoose) return Offset.zero;

    const lift = 20.0;

    final dx = cos(card.angle);
    final dy = -sin(card.angle);

    return Offset(dx * lift, dy * lift);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
