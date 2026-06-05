import 'package:flutter/material.dart';

import '../../../../commons/app_images.dart';
import '../../../../commons/enums.dart';
import '../../../../models/sprite_sheet_models.dart';
import 'sprite_animation_controller.dart';
import 'sprite_animator.dart';

class BattleSceneController extends ChangeNotifier {
  final TickerProvider vsync;

  // ── Sprite data (preloaded JSON) ────────────────────────────
  SpriteSheetData? playerIdleData;
  SpriteSheetData? playerAtkData;
  SpriteSheetData? enemyIdleData;
  SpriteSheetData? enemyHitData;
  bool spritesLoaded = false;

  // ── Sprite Animation Controllers ─────────────────────────────
  late final SpriteAnimationController playerCtrl;
  late final SpriteAnimationController enemyCtrl;

  // ── VFX Animation Controllers ────────────────────────────────
  late final AnimationController playerAttackController;
  late final AnimationController playerHurtController;
  late final AnimationController enemyHurtController;
  late final AnimationController enemyFaintController;
  late final AnimationController damagePopupController;

  late final Animation<double> enemyFaintAnim;
  late final Animation<double> damagePopupAnim;

  // ── State tracking ───────────────────────────────────────────
  BattleAnimState? lastBattleState;
  bool showDamage = false;
  String damageText = '';
  bool isDamageCorrect = true;

  // ── Image paths hiện tại (để SpriteAnimator biết load gì) ───
  String playerImagePath = AppImages.playerIdlePath;
  String enemyImagePath = AppImages.enemyIdlePath;

  bool _disposed = false;

  BattleSceneController({required this.vsync}) {
    playerCtrl = SpriteAnimationController(vsync: vsync);
    enemyCtrl = SpriteAnimationController(vsync: vsync);
    _initVfxControllers();
    _loadAllSprites();
  }

  void _initVfxControllers() {
    _playerAttackControllerInit();
    _playerHurtControllerInit();
    _enemyHurtControllerInit();
    _enemyFaintControllerInit();
    _damagePopupControllerInit();
  }

  void _playerAttackControllerInit() {
    playerAttackController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 400),
    );
    playerAttackController.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        playerAttackController.reverse();
        _triggerEnemyHitAnim();
      }
    });
  }

  void _playerHurtControllerInit() {
    playerHurtController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 500),
    );
    playerHurtController.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        playerCtrl.play(playerIdleData!, loop: true);
      }
    });
  }

  void _enemyHurtControllerInit() {
    enemyHurtController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 400),
    );
    enemyHurtController.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _setEnemyImage(AppImages.enemyIdlePath);
        enemyCtrl.play(enemyIdleData!, loop: true);
      }
    });
  }

  void _enemyFaintControllerInit() {
    enemyFaintController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 800),
    );
    enemyFaintAnim = Tween<double>(begin: 1.0, end: 0.0)
        .chain(CurveTween(curve: Curves.easeInQuad))
        .animate(enemyFaintController);
  }

  void _damagePopupControllerInit() {
    damagePopupController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 800),
    );
    damagePopupAnim = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(damagePopupController);
    damagePopupController.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        showDamage = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadAllSprites() async {
    try {
      final results = await Future.wait([
        SpriteSheetData.loadFromAsset(AppImages.playerIdlePathJson),
        SpriteSheetData.loadFromAsset(AppImages.playerAtkPathJson),
        SpriteSheetData.loadFromAsset(AppImages.enemyIdlePathJson),
        SpriteSheetData.loadFromAsset(AppImages.enemyHitPathJson),
        SpriteAnimator.preloadImage(AppImages.playerIdlePath),
        SpriteAnimator.preloadImage(AppImages.playerAtkPath),
        SpriteAnimator.preloadImage(AppImages.enemyIdlePath),
        SpriteAnimator.preloadImage(AppImages.enemyHitPath),
      ]);

      if (_disposed) return;

      playerIdleData = results[0] as SpriteSheetData;
      playerAtkData = results[1] as SpriteSheetData;
      enemyIdleData = results[2] as SpriteSheetData;
      enemyHitData = results[3] as SpriteSheetData;

      // Bắt đầu idle loop ngay
      playerCtrl.play(playerIdleData!, loop: true);
      enemyCtrl.play(enemyIdleData!, loop: true);

      spritesLoaded = true;
      notifyListeners();
    } catch (_) {
      // Silent fail
    }
  }

  // ─────────────────────────────────────────────────────────────
  // STATE MACHINE
  // ─────────────────────────────────────────────────────────────

  void onBattleStateChanged(BattleAnimState animState) {
    if (animState == lastBattleState) return;
    lastBattleState = animState;

    switch (animState) {
      case BattleAnimState.attack:
        _triggerPlayerAttack();
      case BattleAnimState.hurt:
        _triggerPlayerHurt();
      case BattleAnimState.faint:
        _triggerPlayerAttack();
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!_disposed) _triggerEnemyFaint();
        });
      case BattleAnimState.idle:
        if (playerIdleData != null && enemyIdleData != null) {
          playerCtrl.play(playerIdleData!, loop: true);
          enemyCtrl.play(enemyIdleData!, loop: true);
        }
        _setPlayerImage(AppImages.playerIdlePath);
        _setEnemyImage(AppImages.enemyIdlePath);
    }
  }

  void _triggerPlayerAttack() {
    if (playerAtkData == null || playerIdleData == null) return;
    _setPlayerImage(AppImages.playerAtkPath);
    playerCtrl.play(
      playerAtkData!,
      loop: false,
      onComplete: () {
        _setPlayerImage(AppImages.playerIdlePath);
        playerCtrl.play(playerIdleData!, loop: true);
      },
    );
    playerAttackController.forward(from: 0);
    _showDamagePopup(correct: true);
  }

  void _triggerPlayerHurt() {
    playerHurtController.forward(from: 0);
    _showDamagePopup(correct: false);
  }

  void _triggerEnemyHitAnim() {
    if (enemyHitData == null) return;
    _setEnemyImage(AppImages.enemyHitPath);
    enemyCtrl.play(enemyHitData!, loop: false);
    enemyHurtController.forward(from: 0);
  }

  void _triggerEnemyFaint() {
    enemyFaintController.forward(from: 0);
  }

  void _showDamagePopup({required bool correct}) {
    showDamage = true;
    isDamageCorrect = correct;
    damageText = correct ? 'HIT!' : 'MISS!';
    notifyListeners();
    damagePopupController.forward(from: 0);
  }

  void _setPlayerImage(String path) {
    if (playerImagePath != path) {
      playerImagePath = path;
      notifyListeners();
    }
  }

  void _setEnemyImage(String path) {
    if (enemyImagePath != path) {
      enemyImagePath = path;
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    playerCtrl.dispose();
    enemyCtrl.dispose();
    playerAttackController.dispose();
    playerHurtController.dispose();
    enemyHurtController.dispose();
    enemyFaintController.dispose();
    damagePopupController.dispose();
    super.dispose();
  }
}
