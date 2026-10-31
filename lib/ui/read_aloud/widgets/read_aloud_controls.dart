import 'package:flutter/material.dart';

import '../../../data/services/text_to_speech_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../view_model/read_aloud_view_model.dart';


class ReadAloudControls extends StatefulWidget {
  const ReadAloudControls({super.key, required this.text, this.viewModel});

  final String text;

  /// Pass one in tests; otherwise the control builds and disposes its own.
  final ReadAloudViewModel? viewModel;

  @override
  State<ReadAloudControls> createState() => _ReadAloudControlsState();
}

class _ReadAloudControlsState extends State<ReadAloudControls> {
  late final ReadAloudViewModel _viewModel =
      widget.viewModel ?? ReadAloudViewModel(text: widget.text);
  late final bool _ownsViewModel = widget.viewModel == null;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Switching to another app pauses the voice instead of letting it talk on.
    _lifecycle = AppLifecycleListener(onHide: _viewModel.pause);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (_viewModel.available == false) {
          return Text(
            'Read aloud is not available on this phone. Check that it has a '
            'text-to-speech voice in English.',
            style: AppText.bodyMuted,
          );
        }
        final ready = _viewModel.available == true;
        final state = _viewModel.state;
        return Row(
          children: [
            FilledButton.icon(
              onPressed: ready ? _viewModel.toggle : null,
              icon: Icon(
                state == SpeechState.speaking ? Icons.pause : Icons.play_arrow,
              ),
              label: Text(switch (state) {
                SpeechState.idle => 'Listen',
                SpeechState.speaking => 'Pause',
                SpeechState.paused => 'Resume',
              }),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.background,
              ),
            ),
            if (state != SpeechState.idle) ...[
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _viewModel.stop,
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
