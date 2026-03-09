import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'Widget/diamond_laser_tilt_card.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    const baseCardWidth = 400.0;
    const baseCardHeight = 600.0;
    const pagePadding = 16.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 可用寬度：扣掉左右 padding
          final availableWidth = constraints.maxWidth - pagePadding * 2;

          // 可用高度：扣掉上下 padding 與下方文字區預留空間
          final availableHeight = constraints.maxHeight - pagePadding * 2 - 110;

          // 根據可用空間算出縮放比例
          final scale = math.min(
            availableWidth / baseCardWidth,
            availableHeight / baseCardHeight,
          ).clamp(0.45, 1.0);

          final cardWidth = baseCardWidth * scale;
          final cardHeight = baseCardHeight * scale;

          // tileSize 也跟著縮，但不要縮太小，不然特效會變太密
          final tileSize = (40 * scale).clamp(24.0, 40.0);

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(pagePadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: DiamondLaserTiltCard(
                      tileSize: tileSize,
                      laserIntensity: 0.82,
                      maskOpacity: 0.72,
                      duration: const Duration(seconds: 5),
                      autoYawAmplitude: 0.10,
                      autoPitchAmplitude: 0.03,
                      threadsPerTile: 1,
                      enableGlints: true,
                      child: Image.asset(
                        'assets/card.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 16 * scale.clamp(0.8, 1.0)),
                  const Text('You have pushed the button this many times:'),
                  Text(
                    '$_counter',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}