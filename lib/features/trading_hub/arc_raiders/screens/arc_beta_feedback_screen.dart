import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/screens/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

import '../models/arc_beta_feedback.dart';
import '../repositories/arc_beta_feedback_repository.dart';
import '../widgets/arc_raiders_screen_shell.dart';

class ArcBetaFeedbackScreenArgs {
  const ArcBetaFeedbackScreenArgs({this.sourceRoute = 'unknown'});

  final String sourceRoute;
}

class ArcBetaFeedbackScreen extends StatefulWidget {
  const ArcBetaFeedbackScreen({super.key, this.sourceRoute = 'unknown'});

  static const routeName = '/arc-raiders/closed-beta-feedback';

  final String sourceRoute;

  @override
  State<ArcBetaFeedbackScreen> createState() => _ArcBetaFeedbackScreenState();
}

class _ArcBetaFeedbackScreenState extends State<ArcBetaFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _expectedController = TextEditingController();
  final _repository = ArcBetaFeedbackRepository();

  ArcBetaFeedbackCategory _category = ArcBetaFeedbackCategory.bug;
  ArcBetaFeedbackSeverity _severity = ArcBetaFeedbackSeverity.medium;
  ArcBetaFeedbackReproducibility _reproducibility =
      ArcBetaFeedbackReproducibility.sometimes;
  bool _submitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _expectedController.dispose();
    super.dispose();
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final media = MediaQuery.of(context);
      final id = await _repository.submit(
        ArcBetaFeedbackSubmission(
          uid: _repository.requireUserId(),
          category: _category,
          severity: _severity,
          reproducibility: _reproducibility,
          description: _descriptionController.text,
          expectedOutcome: _expectedController.text,
          currentRoute: widget.sourceRoute,
          platform: _platformLabel(),
          screenWidth: media.size.width,
          screenHeight: media.size.height,
          locale: Localizations.localeOf(context).toLanguageTag(),
        ),
      );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Text(
            'Feedback received',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Report ${id.substring(0, 8).toUpperCase()} was sent with screen and device context.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not send feedback: $error'),
          action: SnackBarAction(label: 'Retry', onPressed: _submit),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 620;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: const UagAppBar(
        title: 'Closed Beta Feedback',
        subtitle: 'Report issues with diagnostics attached',
      ),
      body: ArcRaidersScreenShell(
        showAdBanner: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _section(
                      title: 'What are you reporting?',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ArcBetaFeedbackCategory.values.map((value) {
                          return ChoiceChip(
                            selected: value == _category,
                            label: Text(value.label),
                            onSelected: (_) {
                              setState(() => _category = value);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _section(
                      title: 'Impact',
                      child: narrow
                          ? Column(
                              children: [
                                _severityField(),
                                const SizedBox(height: 12),
                                _reproducibilityField(),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: _severityField()),
                                const SizedBox(width: 12),
                                Expanded(child: _reproducibilityField()),
                              ],
                            ),
                    ),
                    const SizedBox(height: 12),
                    _section(
                      title: 'Tell us what happened',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _descriptionController,
                            minLines: 5,
                            maxLines: 9,
                            decoration: const InputDecoration(
                              labelText: 'What happened?',
                              hintText:
                                  'Include what you tapped, what appeared, and what stopped you.',
                              alignLabelWithHint: true,
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().length < 12) {
                                return 'Please provide at least 12 characters.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _expectedController,
                            minLines: 2,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: 'What did you expect? (optional)',
                              alignLabelWithHint: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _section(
                      title: 'Attached automatically',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _diagnosticChip(Icons.route, widget.sourceRoute),
                          _diagnosticChip(
                            Icons.devices_rounded,
                            _platformLabel(),
                          ),
                          _diagnosticChip(
                            Icons.aspect_ratio_rounded,
                            '${MediaQuery.sizeOf(context).width.round()} x '
                            '${MediaQuery.sizeOf(context).height.round()}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: FilledButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _submitting ? 'Sending...' : 'Send beta feedback',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _severityField() {
    return DropdownButtonFormField<ArcBetaFeedbackSeverity>(
      initialValue: _severity,
      decoration: const InputDecoration(labelText: 'Severity'),
      items: ArcBetaFeedbackSeverity.values
          .map(
            (value) => DropdownMenuItem(value: value, child: Text(value.label)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _severity = value);
        }
      },
    );
  }

  Widget _reproducibilityField() {
    return DropdownButtonFormField<ArcBetaFeedbackReproducibility>(
      initialValue: _reproducibility,
      decoration: const InputDecoration(labelText: 'Reproducibility'),
      items: ArcBetaFeedbackReproducibility.values
          .map(
            (value) => DropdownMenuItem(value: value, child: Text(value.label)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _reproducibility = value);
        }
      },
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTheme.neonTextStyle(
              fontSize: 16,
              color: AppTheme.neonCyan,
              isBold: true,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _diagnosticChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppTheme.neonCyan),
      label: Text(label),
    );
  }
}
