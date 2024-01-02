import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lichess_mobile/src/model/analysis/analysis_controller.dart';
import 'package:lichess_mobile/src/model/analysis/analysis_preferences.dart';
import 'package:lichess_mobile/src/model/settings/general_preferences.dart';
import 'package:lichess_mobile/src/utils/l10n_context.dart';
import 'package:lichess_mobile/src/widgets/adaptive_bottom_sheet.dart';
import 'package:lichess_mobile/src/widgets/list.dart';
import 'package:lichess_mobile/src/widgets/non_linear_slider.dart';
import 'package:lichess_mobile/src/widgets/settings.dart';

class AnalysisSettings extends ConsumerWidget {
  const AnalysisSettings(this.options);

  final AnalysisOptions options;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrlProvider = analysisControllerProvider(options);
    final isLocalEvaluationAllowed =
        ref.watch(ctrlProvider.select((s) => s.isLocalEvaluationAllowed));
    final isEngineAvailable = ref.watch(
      ctrlProvider.select((s) => s.isEngineAvailable),
    );
    final prefs = ref.watch(analysisPreferencesProvider);
    final isSoundEnabled = ref.watch(
      generalPreferencesProvider.select((pref) => pref.isSoundEnabled),
    );

    return ModalSheetScaffold(
      title: Text(context.l10n.analysisOptions),
      child: ListView(
        shrinkWrap: true,
        children: [
          const SizedBox(height: 8.0),
          SwitchSettingTile(
            title: Text(context.l10n.toggleLocalEvaluation),
            value: prefs.enableLocalEvaluation,
            onChanged: isLocalEvaluationAllowed
                ? (_) {
                    ref.read(ctrlProvider.notifier).toggleLocalEvaluation();
                  }
                : null,
          ),
          PlatformListTile(
            title: Text.rich(
              TextSpan(
                text: '${context.l10n.multipleLines}: ',
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
                ),
                children: [
                  TextSpan(
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    text: prefs.numEvalLines.toString(),
                  ),
                ],
              ),
            ),
            subtitle: NonLinearSlider(
              value: prefs.numEvalLines,
              values: const [1, 2, 3],
              onChangeEnd: isEngineAvailable
                  ? (value) => ref
                      .read(ctrlProvider.notifier)
                      .setNumEvalLines(value.toInt())
                  : null,
            ),
          ),
          if (maxEngineCores > 1)
            PlatformListTile(
              title: Text.rich(
                TextSpan(
                  text: '${context.l10n.cpus}: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.normal,
                  ),
                  children: [
                    TextSpan(
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      text: prefs.numEngineCores.toString(),
                    ),
                  ],
                ),
              ),
              subtitle: NonLinearSlider(
                value: prefs.numEngineCores,
                values: List.generate(maxEngineCores, (index) => index + 1),
                onChangeEnd: isEngineAvailable
                    ? (value) => ref
                        .read(ctrlProvider.notifier)
                        .setEngineCores(value.toInt())
                    : null,
              ),
            ),
          SwitchSettingTile(
            title: Text(context.l10n.bestMoveArrow),
            value: prefs.showBestMoveArrow,
            onChanged: isEngineAvailable
                ? (value) => ref
                    .read(analysisPreferencesProvider.notifier)
                    .toggleShowBestMoveArrow()
                : null,
          ),
          SwitchSettingTile(
            title: Text(context.l10n.evaluationGauge),
            value: prefs.showEvaluationGauge,
            onChanged: (value) => ref
                .read(analysisPreferencesProvider.notifier)
                .toggleShowEvaluationGauge(),
          ),
          SwitchSettingTile(
            title: const Text('Show comments'),
            value: prefs.showPgnComments,
            onChanged: (_) => ref
                .read(analysisPreferencesProvider.notifier)
                .togglePgnComments(),
          ),
          SwitchSettingTile(
            title: Text(context.l10n.sound),
            value: isSoundEnabled,
            onChanged: (value) {
              ref
                  .read(generalPreferencesProvider.notifier)
                  .toggleSoundEnabled();
            },
          ),
        ],
      ),
    );
  }
}
