import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../domain/core.dart';
import '../domain/engine.dart';
import '../domain/machines.dart';
import '../domain/scan.dart';
import '../ui/kit.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  final _picker = ImagePicker();
  List<ScannedFact> _facts = const [];
  List<bool> _checked = const [];
  bool _busy = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final text = await _read(file.path);
      final facts = parseWorksheet(text);
      if (!mounted) return;
      setState(() {
        _facts = facts;
        _checked = facts.map((fact) => fact.countedWrong).toList();
        _busy = false;
        _error = facts.isEmpty
            ? 'Nothing to read. Use a printed page with problems like 8 + 7.'
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not read that photo. Try a brighter picture.';
      });
    }
  }

  Future<String> _read(String path) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(path));
      return result.text;
    } finally {
      await recognizer.close();
    }
  }

  List<ScannedFact> get _selected {
    final chosen = <ScannedFact>[];
    for (var i = 0; i < _facts.length; i++) {
      if (_checked[i]) {
        final fact = _facts[i];
        chosen.add(
          ScannedFact(
            left: fact.left,
            right: fact.right,
            operation: fact.operation,
            written: fact.written,
            markedWrong: true,
          ),
        );
      }
    }
    return chosen;
  }

  Future<void> _practice() async {
    final selected = _selected;
    if (selected.isEmpty) return;
    setState(() => _busy = true);
    final app = ref.read(appProvider);
    try {
      for (final fact in selected) {
        await app.recordAttempt(
          AttemptDraft(
            trickId: 'scan:${fact.operation}',
            prompt: fact.prompt,
            userAnswer: fact.written ?? '',
            correctAnswer: fact.computed,
            correct: false,
            failedStep: null,
            mode: 'scan',
            steps: [
              StepAsk(1, 'What is ${fact.prompt}?', fact.computed),
            ],
            reviewSlot: null,
            repairWrongId: null,
          ),
        );
      }
      final drill = targetedProblems(selected, rng: Random());
      await ref.read(practiceProvider).startScanDrill(drill);
      if (!mounted) return;
      final view = ref.read(practiceProvider).view;
      if (view == null) {
        setState(() => _busy = false);
        return;
      }
      context.go('/practice/${view.trickId}/${view.phase}');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not save. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final tally = tallyFacts(_selected);
    return PageFrame(
      title: 'Scan a paper',
      banner: _error ?? app.banner,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => context.go(app.childMode ? '/child' : '/adult'),
        icon: const Icon(Icons.arrow_back),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Photograph a printed page. Reading stays on this device. A wrong written answer is checked for you. Then practice five more like the ones you leave checked.',
          ),
          const SizedBox(height: AppSpace.s16),
          AppButton(
            label: 'Take a photo',
            busy: _busy,
            onPressed: _busy ? null : () => _pick(ImageSource.camera),
          ),
          const SizedBox(height: AppSpace.s12),
          AppButton(
            label: 'Choose a photo',
            secondary: true,
            onPressed: _busy ? null : () => _pick(ImageSource.gallery),
          ),
          if (_facts.isNotEmpty) ...[
            const SizedBox(height: AppSpace.s24),
            Text(
              tally.total == 0
                  ? 'Check the problems that were wrong.'
                  : '${tally.total} checked · ${operationLabel(tally.focus ?? 'addition')}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final entry in tally.counts.entries)
              Text('${operationLabel(entry.key)}: ${entry.value}'),
            const SizedBox(height: AppSpace.s8),
            for (var i = 0; i < _facts.length; i++)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _checked[i],
                onChanged: (value) {
                  setState(() => _checked[i] = value ?? false);
                },
                title: Text(_facts[i].prompt),
                subtitle: Text(
                  _facts[i].written == null
                      ? 'Answer ${ _facts[i].computed}'
                      : 'Page says ${_facts[i].written}. Answer ${_facts[i].computed}.',
                ),
              ),
            const SizedBox(height: AppSpace.s16),
            AppButton(
              label: 'Practice 5 more',
              busy: _busy,
              onPressed: _selected.isEmpty || _busy ? null : _practice,
            ),
          ],
        ],
      ),
    );
  }
}
