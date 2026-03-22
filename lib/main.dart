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
/// 卡片資料模型（Card Model）
/// =========================
///
/// 此類別負責描述「單張卡片的狀態」，
/// 並作為 UI（Positioned + Transform）的資料來源。
///
/// 👉 設計核心：
/// - 使用「資料驅動 UI」
/// - 所有動畫 = start → target 的插值（lerp）
///
/// 👉 適用場景：
/// - 卡牌動畫（洗牌 / 發牌 / 攤牌）
/// - 塔羅系統
/// - 卡牌遊戲（撲克 / 爐石 / UNO）
///
class CardModel {
  /// 卡片唯一識別（用於顯示 / 邏輯判斷）
  final int id;

  // =========================
  // 📍 當前狀態（Current State）
  // =========================

  /// 卡片目前的 X 座標（對應 Positioned.left）
  double x;

  /// 卡片目前的 Y 座標（對應 Positioned.top）
  double y;

  /// 卡片目前的旋轉角度（弧度制，對應 Transform.rotateZ）
  double rotation;

  // =========================
  // 🎬 動畫起點（Animation Start）
  // =========================
  //
  // 在動畫開始前，會記錄當前狀態
  // 作為 lerp 的起始值
  //

  /// 動畫開始時的 X 座標
  double startX;

  /// 動畫開始時的 Y 座標
  double startY;

  /// 動畫開始時的旋轉角度
  double startR;

  // =========================
  // 🎯 動畫目標（Animation Target）
  // =========================
  //
  // 定義動畫結束後要到達的位置與角度
  //

  /// 動畫目標的 X 座標
  double targetX;

  /// 動畫目標的 Y 座標
  double targetY;

  /// 動畫目標的旋轉角度
  double targetR;

  // =========================
  // 🏗️ 建構子（Constructor）
  // =========================

  CardModel({
    required this.id,

    /// 初始化當前位置（預設為 0,0）
    this.x = 0,
    this.y = 0,

    /// 初始化旋轉角度（預設不旋轉）
    this.rotation = 0,
  })
    // 👉 初始時，動畫起點與當前狀態一致
    : startX = 0,
       startY = 0,
       startR = 0,

       // 👉 預設目標也為 0（避免未設定時出現錯誤）
       targetX = 0,
       targetY = 0,
       targetR = 0;
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
      return CardModel(
        id: i,
        x: pos.dx,
        y: pos.dy,
      );
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

  // =========================
  // 🌙 核心：弧形展開
  // =========================
  Future<void> arcSpread() async {
    await runAnimation(() {
      final double radius = MediaQuery.of(context).size.width / 2; // 弧形半徑
      final double centerX = (MediaQuery.of(context).size.width / 2) - (cardWidth / 2);
      double centerY = 0;

      // TODO: 以下這段的目標希望展開時卡牌能貼其畫面底部
      if (MediaQuery.of(context).size.width > MediaQuery.of(context).size.height) {
        centerY = MediaQuery.of(context).size.width - (cardHeight);
      } else {
        centerY = MediaQuery.of(context).size.height - (cardHeight);
      }

      final double startAngle = -pi / 2 - 0.6;
      final double endAngle = -pi / 2 + 0.6;

      for (int i = 0; i < cards.length; i++) {
        double t = i / (cards.length - 1);
        double angle = lerpDouble(startAngle, endAngle, t)!;

        cards[i].targetX = centerX + radius * cos(angle);
        cards[i].targetY = centerY + radius * sin(angle);

        // 讓卡片「跟著弧度旋轉」
        cards[i].targetR = angle + pi / 2;
      }
    });
  }

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

  // =========================
  // UI 結構總覽
  // =========================
  //
  // Scaffold（整個畫面容器）
  //  └── Stack（自由座標系畫布）
  //       ├── 卡片層（Positioned + Transform）
  //       └── 控制層（底部按鈕）
  //

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🎨 背景：營造桌面 / 卡牌場景氛圍
      backgroundColor: Colors.green[900],

      body: Stack(
        children: [
          // =========================
          // 🎴 卡片渲染層（Card Layer）
          // =========================
          //
          // 將 cards 資料轉為 UI
          // 每一張卡片都是「絕對定位 + 可旋轉」
          //
          ...cards.map((card) {
            return Positioned(
              // 📍 使用 left/top 進行「絕對定位」
              // 注意：這裡是「左上角座標」
              left: card.x,
              top: card.y,

              child: Transform(
                // 🎯 旋轉基準點：卡片中心
                alignment: Alignment.center,

                // 🔄 套用旋轉（弧形展開的關鍵）
                transform: Matrix4.identity()..rotateZ(card.rotation),

                child: Container(
                  // 📐 卡片尺寸（建議統一管理）
                  width: cardWidth,
                  height: cardHeight,

                  decoration: BoxDecoration(
                    color: Colors.white,

                    // 🎴 圓角：卡片視覺風格
                    borderRadius: BorderRadius.circular(10),

                    // 🌫️ 陰影：營造浮起來的層次感
                    boxShadow: const [
                      BoxShadow(blurRadius: 6, color: Colors.black26),
                    ],
                  ),

                  // 📌 卡片內容置中
                  alignment: Alignment.center,

                  // 🏷️ 顯示卡片資訊（目前為 id）
                  child: Text(
                    "${card.id}",
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            );
          }),

          // =========================
          // 🎮 控制操作層（Control Layer）
          // =========================
          //
          // 固定在畫面底部的操作區
          // 不受卡片動畫影響
          //
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,

            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                // 🌙 弧形展開按鈕
                ElevatedButton(
                  onPressed: arcSpread,
                  child: const Text("Arc Spread"),
                ),

                const SizedBox(width: 20),

                // 📦 收回卡片按鈕
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
