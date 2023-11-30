import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lichess_mobile/src/styles/puzzle_icons.dart';
import 'package:lichess_mobile/src/utils/l10n.dart';
import 'package:lichess_mobile/src/utils/l10n_context.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'puzzle_theme.freezed.dart';
part 'puzzle_theme.g.dart';

@freezed
class PuzzleThemeData with _$PuzzleThemeData {
  const factory PuzzleThemeData({
    required int count,
    required String? desc,
    required PuzzleThemeKey key,
    required String name,
  }) = _PuzzleThemeData;
}

enum PuzzleThemeKey {
  mix,
  advancedPawn,
  advantage,
  anastasiaMate,
  arabianMate,
  attackingF2F7,
  attraction,
  backRankMate,
  bishopEndgame,
  bodenMate,
  capturingDefender,
  castling,
  clearance,
  crushing,
  defensiveMove,
  deflection,
  discoveredAttack,
  doubleBishopMate,
  doubleCheck,
  dovetailMate,
  equality,
  endgame,
  enPassant,
  exposedKing,
  fork,
  hangingPiece,
  hookMate,
  interference,
  intermezzo,
  kingsideAttack,
  knightEndgame,
  long,
  master,
  masterVsMaster,
  mate,
  mateIn1,
  mateIn2,
  mateIn3,
  mateIn4,
  mateIn5,
  smotheredMate,
  middlegame,
  oneMove,
  opening,
  pawnEndgame,
  pin,
  promotion,
  queenEndgame,
  queenRookEndgame,
  queensideAttack,
  quietMove,
  rookEndgame,
  sacrifice,
  short,
  skewer,
  superGM,
  trappedPiece,
  underPromotion,
  veryLong,
  xRayAttack,
  zugzwang,
  // checkFirst,

  // used internally to filter out unsupported keys
  unsupported,
}

final IMap<String, PuzzleThemeKey> puzzleThemeNameMap =
    IMap(PuzzleThemeKey.values.asNameMap());

typedef PuzzleThemeCategory = (String, List<PuzzleThemeKey>);

@Riverpod(keepAlive: true)
IList<PuzzleThemeCategory> puzzleThemeCategories(
  PuzzleThemeCategoriesRef ref,
) {
  final l10n = ref.watch(l10nProvider);

  return IList([
    (
      l10n.strings.puzzleRecommended,
      [
        PuzzleThemeKey.mix,
      ],
    ),
    (
      l10n.strings.puzzlePhases,
      [
        PuzzleThemeKey.opening,
        PuzzleThemeKey.middlegame,
        PuzzleThemeKey.endgame,
        PuzzleThemeKey.rookEndgame,
        PuzzleThemeKey.bishopEndgame,
        PuzzleThemeKey.pawnEndgame,
        PuzzleThemeKey.knightEndgame,
        PuzzleThemeKey.queenEndgame,
        PuzzleThemeKey.queenRookEndgame,
      ],
    ),
    (
      l10n.strings.puzzleMotifs,
      [
        PuzzleThemeKey.advancedPawn,
        PuzzleThemeKey.attackingF2F7,
        PuzzleThemeKey.capturingDefender,
        PuzzleThemeKey.discoveredAttack,
        PuzzleThemeKey.doubleCheck,
        PuzzleThemeKey.exposedKing,
        PuzzleThemeKey.fork,
        PuzzleThemeKey.hangingPiece,
        PuzzleThemeKey.kingsideAttack,
        PuzzleThemeKey.pin,
        PuzzleThemeKey.queensideAttack,
        PuzzleThemeKey.sacrifice,
        PuzzleThemeKey.skewer,
        PuzzleThemeKey.trappedPiece,
      ],
    ),
    (
      l10n.strings.puzzleAdvanced,
      [
        PuzzleThemeKey.attraction,
        PuzzleThemeKey.clearance,
        PuzzleThemeKey.defensiveMove,
        PuzzleThemeKey.deflection,
        PuzzleThemeKey.interference,
        PuzzleThemeKey.intermezzo,
        PuzzleThemeKey.quietMove,
        PuzzleThemeKey.xRayAttack,
        PuzzleThemeKey.zugzwang,
      ],
    ),
    (
      l10n.strings.puzzleMates,
      [
        PuzzleThemeKey.mate,
        PuzzleThemeKey.mateIn1,
        PuzzleThemeKey.mateIn2,
        PuzzleThemeKey.mateIn3,
        PuzzleThemeKey.mateIn4,
        PuzzleThemeKey.mateIn5,
        PuzzleThemeKey.anastasiaMate,
        PuzzleThemeKey.arabianMate,
        PuzzleThemeKey.backRankMate,
        PuzzleThemeKey.bodenMate,
        PuzzleThemeKey.doubleBishopMate,
        PuzzleThemeKey.dovetailMate,
        PuzzleThemeKey.hookMate,
        PuzzleThemeKey.smotheredMate,
      ],
    ),
    (
      l10n.strings.puzzleSpecialMoves,
      [
        PuzzleThemeKey.castling,
        PuzzleThemeKey.enPassant,
        PuzzleThemeKey.promotion,
        PuzzleThemeKey.underPromotion,
      ],
    ),
    (
      l10n.strings.puzzleGoals,
      [
        PuzzleThemeKey.equality,
        PuzzleThemeKey.advantage,
        PuzzleThemeKey.crushing,
        PuzzleThemeKey.mate,
      ],
    ),
    (
      l10n.strings.puzzleLengths,
      [
        PuzzleThemeKey.oneMove,
        PuzzleThemeKey.long,
        PuzzleThemeKey.short,
        PuzzleThemeKey.veryLong,
      ],
    ),
    (
      l10n.strings.puzzleOrigin,
      [
        PuzzleThemeKey.master,
        PuzzleThemeKey.masterVsMaster,
        PuzzleThemeKey.superGM,
      ],
    ),
  ]);
}

class PuzzleThemeL10n {
  const PuzzleThemeL10n({required this.name, required this.description});
  final String name;
  final String description;
}

PuzzleThemeL10n puzzleThemeL10n(BuildContext context, PuzzleThemeKey theme) {
  switch (theme) {
    case PuzzleThemeKey.mix:
    case PuzzleThemeKey.unsupported:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeHealthyMix,
        description: context.l10n.puzzleThemeHealthyMixDescription,
      );
    case PuzzleThemeKey.advancedPawn:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeAdvancedPawn,
        description: context.l10n.puzzleThemeAdvancedPawnDescription,
      );
    case PuzzleThemeKey.advantage:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeAdvantage,
        description: context.l10n.puzzleThemeAdvantageDescription,
      );
    case PuzzleThemeKey.anastasiaMate:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeAnastasiaMate,
        description: context.l10n.puzzleThemeAnastasiaMateDescription,
      );
    case PuzzleThemeKey.arabianMate:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeArabianMate,
        description: context.l10n.puzzleThemeArabianMateDescription,
      );
    case PuzzleThemeKey.attackingF2F7:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeAttackingF2F7,
        description: context.l10n.puzzleThemeAttackingF2F7Description,
      );
    case PuzzleThemeKey.attraction:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeAttraction,
        description: context.l10n.puzzleThemeAttractionDescription,
      );
    case PuzzleThemeKey.backRankMate:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeBackRankMate,
        description: context.l10n.puzzleThemeBackRankMateDescription,
      );
    case PuzzleThemeKey.bishopEndgame:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeBishopEndgame,
        description: context.l10n.puzzleThemeBishopEndgameDescription,
      );
    case PuzzleThemeKey.bodenMate:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeBodenMate,
        description: context.l10n.puzzleThemeBodenMateDescription,
      );
    case PuzzleThemeKey.capturingDefender:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeCapturingDefender,
        description: context.l10n.puzzleThemeCapturingDefenderDescription,
      );
    case PuzzleThemeKey.castling:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeCastling,
        description: context.l10n.puzzleThemeCastlingDescription,
      );
    case PuzzleThemeKey.clearance:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeClearance,
        description: context.l10n.puzzleThemeClearanceDescription,
      );
    case PuzzleThemeKey.crushing:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeCrushing,
        description: context.l10n.puzzleThemeCrushingDescription,
      );
    case PuzzleThemeKey.defensiveMove:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeDefensiveMove,
        description: context.l10n.puzzleThemeDefensiveMoveDescription,
      );
    case PuzzleThemeKey.deflection:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeDeflection,
        description: context.l10n.puzzleThemeDeflectionDescription,
      );
    case PuzzleThemeKey.discoveredAttack:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeDiscoveredAttack,
        description: context.l10n.puzzleThemeDiscoveredAttackDescription,
      );
    case PuzzleThemeKey.doubleBishopMate:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeDoubleBishopMate,
        description: context.l10n.puzzleThemeDoubleBishopMateDescription,
      );
    case PuzzleThemeKey.doubleCheck:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeDoubleCheck,
        description: context.l10n.puzzleThemeDoubleCheckDescription,
      );
    case PuzzleThemeKey.dovetailMate:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeDovetailMate,
        description: context.l10n.puzzleThemeDovetailMateDescription,
      );
    case PuzzleThemeKey.equality:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeEquality,
        description: context.l10n.puzzleThemeEqualityDescription,
      );
    case PuzzleThemeKey.endgame:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeEndgame,
        description: context.l10n.puzzleThemeEndgameDescription,
      );
    case PuzzleThemeKey.enPassant:
      return PuzzleThemeL10n(
        name: 'En passant',
        description: context.l10n.puzzleThemeEnPassantDescription,
      );
    case PuzzleThemeKey.exposedKing:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeExposedKing,
        description: context.l10n.puzzleThemeExposedKingDescription,
      );
    case PuzzleThemeKey.fork:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeFork,
        description: context.l10n.puzzleThemeForkDescription,
      );
    case PuzzleThemeKey.hangingPiece:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeHangingPiece,
        description: context.l10n.puzzleThemeHangingPieceDescription,
      );
    case PuzzleThemeKey.hookMate:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeHookMate,
        description: context.l10n.puzzleThemeHookMateDescription,
      );
    case PuzzleThemeKey.interference:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeInterference,
        description: context.l10n.puzzleThemeInterferenceDescription,
      );
    case PuzzleThemeKey.intermezzo:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeIntermezzo,
        description: context.l10n.puzzleThemeIntermezzoDescription,
      );
    case PuzzleThemeKey.kingsideAttack:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeKingsideAttack,
        description: context.l10n.puzzleThemeKingsideAttackDescription,
      );
    case PuzzleThemeKey.knightEndgame:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeKnightEndgame,
        description: context.l10n.puzzleThemeKnightEndgameDescription,
      );
    case PuzzleThemeKey.long:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeLong,
        description: context.l10n.puzzleThemeLongDescription,
      );
    case PuzzleThemeKey.master:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeMaster,
        description: context.l10n.puzzleThemeMasterDescription,
      );
    case PuzzleThemeKey.masterVsMaster:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeMasterVsMaster,
        description: context.l10n.puzzleThemeMasterVsMasterDescription,
      );
    case PuzzleThemeKey.mate:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeMate,
        description: context.l10n.puzzleThemeMateDescription,
      );
    case PuzzleThemeKey.mateIn1:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeMateIn1,
        description: context.l10n.puzzleThemeMateIn1Description,
      );
    case PuzzleThemeKey.mateIn2:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeMateIn2,
        description: context.l10n.puzzleThemeMateIn2Description,
      );
    case PuzzleThemeKey.mateIn3:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeMateIn3,
        description: context.l10n.puzzleThemeMateIn3Description,
      );
    case PuzzleThemeKey.mateIn4:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeMateIn4,
        description: context.l10n.puzzleThemeMateIn4Description,
      );
    case PuzzleThemeKey.mateIn5:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeMateIn5,
        description: context.l10n.puzzleThemeMateIn5Description,
      );
    case PuzzleThemeKey.smotheredMate:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeSmotheredMate,
        description: context.l10n.puzzleThemeSmotheredMateDescription,
      );
    case PuzzleThemeKey.middlegame:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeMiddlegame,
        description: context.l10n.puzzleThemeMiddlegameDescription,
      );
    case PuzzleThemeKey.oneMove:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeOneMove,
        description: context.l10n.puzzleThemeOneMoveDescription,
      );
    case PuzzleThemeKey.opening:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeOpening,
        description: context.l10n.puzzleThemeOpeningDescription,
      );
    case PuzzleThemeKey.pawnEndgame:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemePawnEndgame,
        description: context.l10n.puzzleThemePawnEndgameDescription,
      );
    case PuzzleThemeKey.pin:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemePin,
        description: context.l10n.puzzleThemePinDescription,
      );
    case PuzzleThemeKey.promotion:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemePromotion,
        description: context.l10n.puzzleThemePromotionDescription,
      );
    case PuzzleThemeKey.queenEndgame:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeQueenEndgame,
        description: context.l10n.puzzleThemeQueenEndgameDescription,
      );
    case PuzzleThemeKey.queenRookEndgame:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeQueenRookEndgame,
        description: context.l10n.puzzleThemeQueenRookEndgameDescription,
      );
    case PuzzleThemeKey.queensideAttack:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeQueensideAttack,
        description: context.l10n.puzzleThemeQueensideAttackDescription,
      );
    case PuzzleThemeKey.quietMove:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeQuietMove,
        description: context.l10n.puzzleThemeQuietMoveDescription,
      );
    case PuzzleThemeKey.rookEndgame:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeRookEndgame,
        description: context.l10n.puzzleThemeRookEndgameDescription,
      );
    case PuzzleThemeKey.sacrifice:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeSacrifice,
        description: context.l10n.puzzleThemeSacrificeDescription,
      );
    case PuzzleThemeKey.short:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeShort,
        description: context.l10n.puzzleThemeShortDescription,
      );
    case PuzzleThemeKey.skewer:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeSkewer,
        description: context.l10n.puzzleThemeSkewerDescription,
      );
    case PuzzleThemeKey.superGM:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeSuperGM,
        description: context.l10n.puzzleThemeSuperGMDescription,
      );
    case PuzzleThemeKey.trappedPiece:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeTrappedPiece,
        description: context.l10n.puzzleThemeTrappedPieceDescription,
      );
    case PuzzleThemeKey.underPromotion:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeUnderPromotion,
        description: context.l10n.puzzleThemeUnderPromotionDescription,
      );
    case PuzzleThemeKey.veryLong:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeVeryLong,
        description: context.l10n.puzzleThemeVeryLongDescription,
      );
    case PuzzleThemeKey.xRayAttack:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeXRayAttack,
        description: context.l10n.puzzleThemeXRayAttackDescription,
      );
    case PuzzleThemeKey.zugzwang:
      return PuzzleThemeL10n(
        name: context.l10n.puzzleThemeZugzwang,
        description: context.l10n.puzzleThemeZugzwangDescription,
      );
  }
}

IconData puzzleThemeIcon(PuzzleThemeKey theme) {
  switch (theme) {
    case PuzzleThemeKey.mix:
    case PuzzleThemeKey.unsupported:
      return PuzzleIcons.mix;
    case PuzzleThemeKey.advancedPawn:
      return PuzzleIcons.advancedPawn;
    case PuzzleThemeKey.advantage:
      return PuzzleIcons.advantage;
    case PuzzleThemeKey.anastasiaMate:
      return PuzzleIcons.anastasiaMate;
    case PuzzleThemeKey.arabianMate:
      return PuzzleIcons.arabianMate;
    case PuzzleThemeKey.attackingF2F7:
      return PuzzleIcons.attackingF2F7;
    case PuzzleThemeKey.attraction:
      return PuzzleIcons.attraction;
    case PuzzleThemeKey.backRankMate:
      return PuzzleIcons.backRankMate;
    case PuzzleThemeKey.bishopEndgame:
      return PuzzleIcons.bishopEndgame;
    case PuzzleThemeKey.bodenMate:
      return PuzzleIcons.bodenMate;
    case PuzzleThemeKey.capturingDefender:
      return PuzzleIcons.capturingDefender;
    case PuzzleThemeKey.castling:
      return PuzzleIcons.castling;
    case PuzzleThemeKey.clearance:
      return PuzzleIcons.clearance;
    case PuzzleThemeKey.crushing:
      return PuzzleIcons.crushing;
    case PuzzleThemeKey.defensiveMove:
      return PuzzleIcons.defensiveMove;
    case PuzzleThemeKey.deflection:
      return PuzzleIcons.deflection;
    case PuzzleThemeKey.discoveredAttack:
      return PuzzleIcons.discoveredAttack;
    case PuzzleThemeKey.doubleBishopMate:
      return PuzzleIcons.doubleBishopMate;
    case PuzzleThemeKey.doubleCheck:
      return PuzzleIcons.doubleCheck;
    case PuzzleThemeKey.dovetailMate:
      return PuzzleIcons.dovetailMate;
    case PuzzleThemeKey.equality:
      return PuzzleIcons.equality;
    case PuzzleThemeKey.endgame:
      return PuzzleIcons.endgame;
    case PuzzleThemeKey.enPassant:
      return PuzzleIcons.enPassant;
    case PuzzleThemeKey.exposedKing:
      return PuzzleIcons.exposedKing;
    case PuzzleThemeKey.fork:
      return PuzzleIcons.fork;
    case PuzzleThemeKey.hangingPiece:
      return PuzzleIcons.hangingPiece;
    case PuzzleThemeKey.hookMate:
      return PuzzleIcons.hookMate;
    case PuzzleThemeKey.interference:
      return PuzzleIcons.interference;
    case PuzzleThemeKey.intermezzo:
      return PuzzleIcons.intermezzo;
    case PuzzleThemeKey.kingsideAttack:
      return PuzzleIcons.kingsideAttack;
    case PuzzleThemeKey.knightEndgame:
      return PuzzleIcons.knightEndgame;
    case PuzzleThemeKey.long:
      return PuzzleIcons.long;
    case PuzzleThemeKey.master:
      return PuzzleIcons.master;
    case PuzzleThemeKey.masterVsMaster:
      return PuzzleIcons.masterVsMaster;
    case PuzzleThemeKey.mate:
      return PuzzleIcons.mate;
    case PuzzleThemeKey.mateIn1:
      return PuzzleIcons.mate;
    case PuzzleThemeKey.mateIn2:
      return PuzzleIcons.mate;
    case PuzzleThemeKey.mateIn3:
      return PuzzleIcons.mate;
    case PuzzleThemeKey.mateIn4:
      return PuzzleIcons.mate;
    case PuzzleThemeKey.mateIn5:
      return PuzzleIcons.mate;
    case PuzzleThemeKey.smotheredMate:
      return PuzzleIcons.smotheredMate;
    case PuzzleThemeKey.middlegame:
      return PuzzleIcons.middlegame;
    case PuzzleThemeKey.oneMove:
      return PuzzleIcons.oneMove;
    case PuzzleThemeKey.opening:
      return PuzzleIcons.opening;
    case PuzzleThemeKey.pawnEndgame:
      return PuzzleIcons.pawnEndgame;
    case PuzzleThemeKey.pin:
      return PuzzleIcons.pin;
    case PuzzleThemeKey.promotion:
      return PuzzleIcons.promotion;
    case PuzzleThemeKey.queenEndgame:
      return PuzzleIcons.queenEndgame;
    case PuzzleThemeKey.queenRookEndgame:
      return PuzzleIcons.queenRookEndgame;
    case PuzzleThemeKey.queensideAttack:
      return PuzzleIcons.queensideAttack;
    case PuzzleThemeKey.quietMove:
      return PuzzleIcons.quietMove;
    case PuzzleThemeKey.rookEndgame:
      return PuzzleIcons.rookEndgame;
    case PuzzleThemeKey.sacrifice:
      return PuzzleIcons.sacrifice;
    case PuzzleThemeKey.short:
      return PuzzleIcons.short;
    case PuzzleThemeKey.skewer:
      return PuzzleIcons.skewer;
    case PuzzleThemeKey.superGM:
      return PuzzleIcons.superGM;
    case PuzzleThemeKey.trappedPiece:
      return PuzzleIcons.trappedPiece;
    case PuzzleThemeKey.underPromotion:
      return PuzzleIcons.underPromotion;
    case PuzzleThemeKey.veryLong:
      return PuzzleIcons.veryLong;
    case PuzzleThemeKey.xRayAttack:
      return PuzzleIcons.xRayAttack;
    case PuzzleThemeKey.zugzwang:
      return PuzzleIcons.zugzwang;
  }
}
