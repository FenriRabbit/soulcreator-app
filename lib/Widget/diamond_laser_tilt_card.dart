import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

class DiamondLaserTiltCard extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;

  /// 單顆菱形的尺寸（越大越省效能）
  final double tileSize;

  /// 雷射強度
  final double laserIntensity;

  /// 遮罩透明度
  final double maskOpacity;

  /// 自動左右擺動週期
  final Duration duration;

  /// 左右擺動幅度（弧度）
  final double autoYawAmplitude;

  /// 上下微擺幅度（弧度）
  final double autoPitchAmplitude;

  /// 透視強度
  final double perspective;

  /// 每顆 diamond 的雷射絲數量
  final int threadsPerTile;

  /// 是否啟用細小閃點
  final bool enableGlints;

  /// 手指互動最大傾斜角度
  final double touchYawAmplitude;
  final double touchPitchAmplitude;

  const DiamondLaserTiltCard({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.tileSize = 36,
    this.laserIntensity = 0.9,
    this.maskOpacity = 0.82,
    this.duration = const Duration(seconds: 4),
    this.autoYawAmplitude = 0.12,
    this.autoPitchAmplitude = 0.04,
    this.perspective = 0.0018,
    this.threadsPerTile = 1,
    this.enableGlints = false,
    this.touchYawAmplitude = 0.22,
    this.touchPitchAmplitude = 0.18,
  });

  @override
  State<DiamondLaserTiltCard> createState() => _DiamondLaserTiltCardState();
}

class _DiamondLaserTiltCardState extends State<DiamondLaserTiltCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final GlobalKey _cardKey = GlobalKey();

  bool _isTouching = false;
  double _touchYaw = 0.0;
  double _touchPitch = 0.0;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void didUpdateWidget(covariant DiamondLaserTiltCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      _controller
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateTiltFromGlobalPosition(Offset globalPosition) {
    final renderObject =
    _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderObject == null || !renderObject.hasSize) return;

    final local = renderObject.globalToLocal(globalPosition);
    final size = renderObject.size;

    if (size.width <= 0 || size.height <= 0) return;

    // 轉成 -1 ~ 1
    final nx = ((local.dx / size.width) * 2 - 1).clamp(-1.0, 1.0);
    final ny = ((local.dy / size.height) * 2 - 1).clamp(-1.0, 1.0);

    setState(() {
      // 左右：手指在右邊，卡片右傾；在左邊，卡片左傾
      _touchYaw = nx * widget.touchYawAmplitude;

      // 上下：手指越往上，卡片上緣朝後；往下則相反
      _touchPitch = -ny * widget.touchPitchAmplitude;
    });
  }

  void _handlePanStart(DragStartDetails details) {
    _isTouching = true;
    _updateTiltFromGlobalPosition(details.globalPosition);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _updateTiltFromGlobalPosition(details.globalPosition);
  }

  void _handlePanEnd([Object? _]) {
    setState(() {
      _isTouching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        onPanCancel: () => _handlePanEnd(),
        child: AnimatedBuilder(
          animation: _controller,
          child: RepaintBoundary(
            key: _cardKey,
            child: widget.child,
          ),
          builder: (context, child) {
            final t = _controller.value * math.pi * 2.0;

            final autoYaw = math.sin(t) * widget.autoYawAmplitude;
            final autoPitch = math.cos(t * 0.8) * widget.autoPitchAmplitude;

            // 觸碰中：以手勢角度為主
            // 放手後：平滑回歸自動角度
            final yaw = _isTouching
                ? _touchYaw
                : lerpDouble(_touchYaw, autoYaw, 0.12) ?? autoYaw;

            final pitch = _isTouching
                ? _touchPitch
                : lerpDouble(_touchPitch, autoPitch, 0.12) ?? autoPitch;

            if (!_isTouching) {
              // 逐幀把殘留手勢角度收斂掉，避免放手時卡在半空中
              _touchYaw = yaw;
              _touchPitch = pitch;
            }

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, widget.perspective)
                ..rotateY(yaw)
                ..rotateX(pitch),
              child: ClipRRect(
                borderRadius: widget.borderRadius,
                child: CustomPaint(
                  isComplex: true,
                  willChange: true,
                  foregroundPainter: _DiamondLaserPainter(
                    yaw: yaw,
                    pitch: pitch,
                    tileSize: widget.tileSize,
                    laserIntensity: widget.laserIntensity,
                    maskOpacity: widget.maskOpacity,
                    threadsPerTile: widget.threadsPerTile,
                    enableGlints: widget.enableGlints,
                  ),
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DiamondLaserPainter extends CustomPainter {
  final double yaw;
  final double pitch;
  final double tileSize;
  final double laserIntensity;
  final double maskOpacity;
  final int threadsPerTile;
  final bool enableGlints;

  _DiamondLaserPainter({
    required this.yaw,
    required this.pitch,
    required this.tileSize,
    required this.laserIntensity,
    required this.maskOpacity,
    required this.threadsPerTile,
    required this.enableGlints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintDiamondLaserTiles(canvas, size);
    _paintDiamondLaserThreads(canvas, size);
    _paintDiamondSpecularSweep(canvas, size);

    if (enableGlints) {
      _paintTinyGlints(canvas, size);
    }
  }

  void _paintDiamondLaserTiles(Canvas canvas, Size size) {
    final spacing = tileSize * 0.74;
    final cols = (size.width / spacing).ceil() + 3;
    final rows = (size.height / spacing).ceil() + 3;

    final tiltEnergy = ((yaw.abs() + pitch.abs()) * 5.5).clamp(0.0, 1.0);
    final alignX = (yaw * 6.0).clamp(-1.0, 1.0);
    final alignY = (pitch * 8.0).clamp(-1.0, 1.0);

    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final cx = col * spacing + (row.isOdd ? spacing / 2 : 0);
        final cy = row * spacing;

        if ((row + col).isOdd) continue;

        final diamond = _diamondPath(Offset(cx, cy), tileSize * 0.50);

        final bounds = Rect.fromCenter(
          center: Offset(cx, cy),
          width: tileSize,
          height: tileSize,
        );

        final shader = LinearGradient(
          begin: Alignment(-0.9 + alignX, -0.9 + alignY),
          end: Alignment(0.9 + alignX, 0.9 + alignY),
          colors: const [
            Color(0x00000000),
            Color(0x8800E5FF),
            Color(0x88FF4FD8),
            Color(0x88B8FF6A),
            Color(0x88FFE066),
            Color(0x887C7DFF),
            Color(0x00000000),
          ],
          stops: const [0.00, 0.16, 0.34, 0.52, 0.70, 0.86, 1.00],
          transform: GradientRotation(-0.78 + yaw * 0.9 - pitch * 0.3),
          tileMode: TileMode.mirror,
        ).createShader(bounds);

        final paint = Paint()
          ..shader = shader
          ..blendMode = BlendMode.screen
          ..color = Colors.white.withValues(
            alpha: (maskOpacity * (0.50 + tiltEnergy * 0.65) * laserIntensity)
                .clamp(0.0, 1.0),
          );

        canvas.drawPath(diamond, paint);

        final borderPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..blendMode = BlendMode.plus
          ..color = Colors.white.withValues(
            alpha: (0.03 + tiltEnergy * 0.08) * laserIntensity,
          );

        canvas.drawPath(diamond, borderPaint);
      }
    }
  }

  void _paintDiamondLaserThreads(Canvas canvas, Size size) {
    final spacing = tileSize * 0.74;
    final cols = (size.width / spacing).ceil() + 3;
    final rows = (size.height / spacing).ceil() + 3;
    final rng = _StableRng(2026030901);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus;

    final tiltEnergy = ((yaw.abs() + pitch.abs()) * 5.0).clamp(0.0, 1.0);

    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final cx = col * spacing + (row.isOdd ? spacing / 2 : 0);
        final cy = row * spacing;

        if ((row + col).isOdd) continue;

        final diamond = _diamondPath(Offset(cx, cy), tileSize * 0.50);
        final rect = Rect.fromCenter(
          center: Offset(cx, cy),
          width: tileSize,
          height: tileSize,
        );

        canvas.save();
        canvas.clipPath(diamond);

        for (int i = 0; i < threadsPerTile; i++) {
          final seedA = rng.nextDouble();
          final seedB = rng.nextDouble();
          final seedC = rng.nextDouble();

          final baseX = rect.left +
              ((seedA + (yaw * 1.4 + pitch * 0.7)).abs() % 1.0) * rect.width;

          final path = Path();
          for (int step = 0; step <= 8; step++) {
            final p = step / 8.0;
            final y = rect.top + p * rect.height;
            final wobble = math.sin(
              p * 5.0 + seedC * math.pi * 2 + yaw * 7.0,
            ) *
                (1.0 + seedB * 1.2 + tiltEnergy * 1.6);

            final x = baseX + wobble;

            if (step == 0) {
              path.moveTo(x, y);
            } else {
              path.lineTo(x, y);
            }
          }

          paint
            ..strokeWidth = 0.7 + seedA * 0.7
            ..color = _laserPalette((row * 13 + col * 7 + i) / 50.0)
                .withValues(alpha: (0.05 + 0.12 * tiltEnergy) * laserIntensity);

          canvas.save();
          canvas.translate(rect.center.dx, rect.center.dy);
          canvas.rotate(-0.82 + yaw * 0.7);
          canvas.translate(-rect.center.dx, -rect.center.dy);
          canvas.drawPath(path, paint);
          canvas.restore();
        }

        canvas.restore();
      }
    }
  }

  void _paintDiamondSpecularSweep(Canvas canvas, Size size) {
    final spacing = tileSize * 0.74;
    final cols = (size.width / spacing).ceil() + 3;
    final rows = (size.height / spacing).ceil() + 3;

    final tiltEnergy = ((yaw.abs() + pitch.abs()) * 5.8).clamp(0.0, 1.0);

    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final cx = col * spacing + (row.isOdd ? spacing / 2 : 0);
        final cy = row * spacing;

        if ((row + col).isOdd) continue;

        final diamond = _diamondPath(Offset(cx, cy), tileSize * 0.50);
        final rect = Rect.fromCenter(
          center: Offset(cx, cy),
          width: tileSize,
          height: tileSize,
        );

        final localShift =
        ((yaw * 0.9) + (pitch * 0.6) + (col * 0.07) - (row * 0.04));
        final highlightX =
            rect.left + ((localShift + 0.5).clamp(0.0, 1.0)) * rect.width;

        final bandRect = Rect.fromCenter(
          center: Offset(highlightX, rect.center.dy),
          width: rect.width * (0.18 + tiltEnergy * 0.22),
          height: rect.height * 1.5,
        );

        final paint = Paint()
          ..blendMode = BlendMode.plus
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: (0.03 + tiltEnergy * 0.18)),
              Colors.transparent,
            ],
            stops: const [0.2, 0.5, 0.8],
          ).createShader(bandRect);

        canvas.save();
        canvas.clipPath(diamond);
        canvas.translate(rect.center.dx, rect.center.dy);
        canvas.rotate(-0.72 + yaw * 0.7 - pitch * 0.15);
        canvas.translate(-rect.center.dx, -rect.center.dy);
        canvas.drawRect(bandRect, paint);
        canvas.restore();
      }
    }
  }

  void _paintTinyGlints(Canvas canvas, Size size) {
    final rng = _StableRng(7777333);
    final spacing = tileSize * 0.74;
    final cols = (size.width / spacing).ceil() + 3;
    final rows = (size.height / spacing).ceil() + 3;
    final tiltEnergy = ((yaw.abs() + pitch.abs()) * 6.5).clamp(0.0, 1.0);

    final paint = Paint()..blendMode = BlendMode.plus;

    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final cx = col * spacing + (row.isOdd ? spacing / 2 : 0);
        final cy = row * spacing;

        if ((row + col).isOdd) continue;

        final diamond = _diamondPath(Offset(cx, cy), tileSize * 0.50);
        final rect = Rect.fromCenter(
          center: Offset(cx, cy),
          width: tileSize,
          height: tileSize,
        );

        canvas.save();
        canvas.clipPath(diamond);

        final x = rect.left + rng.nextDouble() * rect.width;
        final y = rect.top + rng.nextDouble() * rect.height;

        final gate = rng.nextDouble();
        if (gate <= tiltEnergy) {
          final alpha = (0.02 + tiltEnergy * 0.14) * laserIntensity;
          final r = 0.4 + rng.nextDouble() * 0.7;

          paint.color = Colors.white.withValues(alpha: alpha.clamp(0.0, 0.20));
          canvas.drawCircle(Offset(x, y), r, paint);
        }

        canvas.restore();
      }
    }
  }

  Path _diamondPath(Offset center, double radius) {
    return Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius, center.dy)
      ..close();
  }

  Color _laserPalette(double p) {
    final colors = <Color>[
      const Color(0xFF00E5FF),
      const Color(0xFFFF4FD8),
      const Color(0xFFB8FF6A),
      const Color(0xFFFFE066),
      const Color(0xFF7C7DFF),
    ];

    final scaled = (p.abs() % 1.0) * colors.length;
    final i = scaled.floor() % colors.length;
    final j = (i + 1) % colors.length;
    final lerpT = scaled - scaled.floor();

    return Color.lerp(colors[i], colors[j], lerpT)!;
  }

  @override
  bool shouldRepaint(covariant _DiamondLaserPainter oldDelegate) {
    return oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.tileSize != tileSize ||
        oldDelegate.laserIntensity != laserIntensity ||
        oldDelegate.maskOpacity != maskOpacity ||
        oldDelegate.threadsPerTile != threadsPerTile ||
        oldDelegate.enableGlints != enableGlints;
  }
}

class _StableRng {
  int _state;
  _StableRng(this._state);

  double nextDouble() {
    _state = (1664525 * _state + 1013904223) & 0xFFFFFFFF;
    return ((_state >> 8) & 0xFFFFFF) / 0xFFFFFF;
  }
}