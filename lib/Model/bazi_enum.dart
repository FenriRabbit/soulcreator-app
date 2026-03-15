/// BaZi Core Enums
///
/// 子平八字核心資料模型
///
/// 包含：
///
/// - 陰陽
/// - 五行
/// - 十天干
/// - 十二地支
/// - 十神
///
/// 可作為：
///
/// - 命盤引擎
/// - AI命理分析
/// - 占卜牌卡
/// - Flutter App
///
/// 的基礎 Domain Model。

// ------------------------------------------------------------
// YinYang
// ------------------------------------------------------------

/// 陰陽 (Yin / Yang)
///
/// 宇宙運作的二元能量
enum YinYang {
  yin(
    label: '陰',
    description: '內斂、柔性、收斂、潛藏的能量',
  ),

  yang(
    label: '陽',
    description: '外放、主動、擴張、顯現的能量',
  );

  final String label;
  final String description;

  const YinYang({
    required this.label,
    required this.description,
  });
}

// ------------------------------------------------------------
// WuXing
// ------------------------------------------------------------

/// 五行
///
/// 木 火 土 金 水
enum WuXing {
  wood(label: '木'),
  fire(label: '火'),
  earth(label: '土'),
  metal(label: '金'),
  water(label: '水');

  final String label;

  const WuXing({
    required this.label,
  });

  /// 我生誰
  WuXing get generates {
    switch (this) {
      case WuXing.wood:
        return WuXing.fire;
      case WuXing.fire:
        return WuXing.earth;
      case WuXing.earth:
        return WuXing.metal;
      case WuXing.metal:
        return WuXing.water;
      case WuXing.water:
        return WuXing.wood;
    }
  }

  /// 誰生我
  WuXing get generatedBy {
    switch (this) {
      case WuXing.wood:
        return WuXing.water;
      case WuXing.fire:
        return WuXing.wood;
      case WuXing.earth:
        return WuXing.fire;
      case WuXing.metal:
        return WuXing.earth;
      case WuXing.water:
        return WuXing.metal;
    }
  }

  /// 我剋誰
  WuXing get controls {
    switch (this) {
      case WuXing.wood:
        return WuXing.earth;
      case WuXing.fire:
        return WuXing.metal;
      case WuXing.earth:
        return WuXing.water;
      case WuXing.metal:
        return WuXing.wood;
      case WuXing.water:
        return WuXing.fire;
    }
  }

  /// 誰剋我
  WuXing get controlledBy {
    switch (this) {
      case WuXing.wood:
        return WuXing.metal;
      case WuXing.fire:
        return WuXing.water;
      case WuXing.earth:
        return WuXing.wood;
      case WuXing.metal:
        return WuXing.fire;
      case WuXing.water:
        return WuXing.earth;
    }
  }
}

// ------------------------------------------------------------
// Heavenly Stems
// ------------------------------------------------------------

/// 十天干
///
/// 甲乙丙丁戊己庚辛壬癸
enum HeavenlyStem {
  jia(
    label: '甲',
    element: WuXing.wood,
    yinYang: YinYang.yang,
  ),

  yi(
    label: '乙',
    element: WuXing.wood,
    yinYang: YinYang.yin,
  ),

  bing(
    label: '丙',
    element: WuXing.fire,
    yinYang: YinYang.yang,
  ),

  ding(
    label: '丁',
    element: WuXing.fire,
    yinYang: YinYang.yin,
  ),

  wu(
    label: '戊',
    element: WuXing.earth,
    yinYang: YinYang.yang,
  ),

  ji(
    label: '己',
    element: WuXing.earth,
    yinYang: YinYang.yin,
  ),

  geng(
    label: '庚',
    element: WuXing.metal,
    yinYang: YinYang.yang,
  ),

  xin(
    label: '辛',
    element: WuXing.metal,
    yinYang: YinYang.yin,
  ),

  ren(
    label: '壬',
    element: WuXing.water,
    yinYang: YinYang.yang,
  ),

  gui(
    label: '癸',
    element: WuXing.water,
    yinYang: YinYang.yin,
  );

  final String label;
  final WuXing element;
  final YinYang yinYang;

  const HeavenlyStem({
    required this.label,
    required this.element,
    required this.yinYang,
  });

  /// 天干五合
  HeavenlyStem? get combineWith {
    switch (this) {
      case HeavenlyStem.jia:
        return HeavenlyStem.ji;
      case HeavenlyStem.ji:
        return HeavenlyStem.jia;

      case HeavenlyStem.yi:
        return HeavenlyStem.geng;
      case HeavenlyStem.geng:
        return HeavenlyStem.yi;

      case HeavenlyStem.bing:
        return HeavenlyStem.xin;
      case HeavenlyStem.xin:
        return HeavenlyStem.bing;

      case HeavenlyStem.ding:
        return HeavenlyStem.ren;
      case HeavenlyStem.ren:
        return HeavenlyStem.ding;

      case HeavenlyStem.wu:
        return HeavenlyStem.gui;
      case HeavenlyStem.gui:
        return HeavenlyStem.wu;
    }
  }
}

// ------------------------------------------------------------
// Ten Gods
// ------------------------------------------------------------

/// 十神
///
/// 描述「其他天干」與「日主」的關係
enum TenGod {
  biJian(label: '比肩'),
  jieCai(label: '劫財'),

  shiShen(label: '食神'),
  shangGuan(label: '傷官'),

  zhengCai(label: '正財'),
  pianCai(label: '偏財'),

  zhengGuan(label: '正官'),
  qiSha(label: '七殺'),

  zhengYin(label: '正印'),
  pianYin(label: '偏印');

  final String label;

  const TenGod({
    required this.label,
  });
}

/// 十神計算
extension TenGodResolver on HeavenlyStem {
  TenGod relationTo(HeavenlyStem dayMaster) {
    final sameYinYang = yinYang == dayMaster.yinYang;

    if (element == dayMaster.element) {
      return sameYinYang ? TenGod.biJian : TenGod.jieCai;
    }

    if (element == dayMaster.element.generates) {
      return sameYinYang ? TenGod.shiShen : TenGod.shangGuan;
    }

    if (element == dayMaster.element.controls) {
      return sameYinYang ? TenGod.pianCai : TenGod.zhengCai;
    }

    if (element == dayMaster.element.controlledBy) {
      return sameYinYang ? TenGod.qiSha : TenGod.zhengGuan;
    }

    if (element == dayMaster.element.generatedBy) {
      return sameYinYang ? TenGod.pianYin : TenGod.zhengYin;
    }

    throw StateError('Unknown TenGod relation');
  }
}

// ------------------------------------------------------------
// Zodiac Animal
// ------------------------------------------------------------

enum ZodiacAnimal {
  rat('鼠'),
  ox('牛'),
  tiger('虎'),
  rabbit('兔'),
  dragon('龍'),
  snake('蛇'),
  horse('馬'),
  goat('羊'),
  monkey('猴'),
  rooster('雞'),
  dog('狗'),
  pig('豬');

  final String label;

  const ZodiacAnimal(this.label);
}

// ------------------------------------------------------------
// Earthly Branch
// ------------------------------------------------------------

/// 十二地支
///
/// 子丑寅卯辰巳午未申酉戌亥
enum EarthlyBranch {
  zi(
    label: '子',
    animal: ZodiacAnimal.rat,
    element: WuXing.water,
    yinYang: YinYang.yang,
    hiddenStems: [HeavenlyStem.gui],
  ),

  chou(
    label: '丑',
    animal: ZodiacAnimal.ox,
    element: WuXing.earth,
    yinYang: YinYang.yin,
    hiddenStems: [
      HeavenlyStem.ji,
      HeavenlyStem.gui,
      HeavenlyStem.xin,
    ],
  ),

  yin(
    label: '寅',
    animal: ZodiacAnimal.tiger,
    element: WuXing.wood,
    yinYang: YinYang.yang,
    hiddenStems: [
      HeavenlyStem.jia,
      HeavenlyStem.bing,
      HeavenlyStem.wu,
    ],
  ),

  mao(
    label: '卯',
    animal: ZodiacAnimal.rabbit,
    element: WuXing.wood,
    yinYang: YinYang.yin,
    hiddenStems: [HeavenlyStem.yi],
  ),

  chen(
    label: '辰',
    animal: ZodiacAnimal.dragon,
    element: WuXing.earth,
    yinYang: YinYang.yang,
    hiddenStems: [
      HeavenlyStem.wu,
      HeavenlyStem.yi,
      HeavenlyStem.gui,
    ],
  ),

  si(
    label: '巳',
    animal: ZodiacAnimal.snake,
    element: WuXing.fire,
    yinYang: YinYang.yin,
    hiddenStems: [
      HeavenlyStem.bing,
      HeavenlyStem.wu,
      HeavenlyStem.geng,
    ],
  ),

  wu(
    label: '午',
    animal: ZodiacAnimal.horse,
    element: WuXing.fire,
    yinYang: YinYang.yang,
    hiddenStems: [
      HeavenlyStem.ding,
      HeavenlyStem.ji,
    ],
  ),

  wei(
    label: '未',
    animal: ZodiacAnimal.goat,
    element: WuXing.earth,
    yinYang: YinYang.yin,
    hiddenStems: [
      HeavenlyStem.ji,
      HeavenlyStem.yi,
      HeavenlyStem.ding,
    ],
  ),

  shen(
    label: '申',
    animal: ZodiacAnimal.monkey,
    element: WuXing.metal,
    yinYang: YinYang.yang,
    hiddenStems: [
      HeavenlyStem.geng,
      HeavenlyStem.ren,
      HeavenlyStem.wu,
    ],
  ),

  you(
    label: '酉',
    animal: ZodiacAnimal.rooster,
    element: WuXing.metal,
    yinYang: YinYang.yin,
    hiddenStems: [HeavenlyStem.xin],
  ),

  xu(
    label: '戌',
    animal: ZodiacAnimal.dog,
    element: WuXing.earth,
    yinYang: YinYang.yang,
    hiddenStems: [
      HeavenlyStem.wu,
      HeavenlyStem.xin,
      HeavenlyStem.ding,
    ],
  ),

  hai(
    label: '亥',
    animal: ZodiacAnimal.pig,
    element: WuXing.water,
    yinYang: YinYang.yin,
    hiddenStems: [
      HeavenlyStem.ren,
      HeavenlyStem.jia,
    ],
  );

  final String label;
  final ZodiacAnimal animal;
  final WuXing element;
  final YinYang yinYang;
  final List<HeavenlyStem> hiddenStems;

  const EarthlyBranch({
    required this.label,
    required this.animal,
    required this.element,
    required this.yinYang,
    required this.hiddenStems,
  });
}