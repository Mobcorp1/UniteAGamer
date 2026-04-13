import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class FeedbackScreen extends StatefulWidget {
  static const routeName = '/feedback';

  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _summaryController = TextEditingController();
  final _detailsController = TextEditingController();
  String _category = 'Bug';
  bool _submitting = false;

  static const _categories = ['Bug', 'Idea', 'UX', 'Trading flow', 'Other'];

  @override
  void dispose() {
    _summaryController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _submitting = true);
    try {
      await FirebaseFirestore.instance.collection('beta_feedback').add({
        'uid': uid,
        'category': _category,
        'summary': _summaryController.text.trim(),
        'details': _detailsController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for the feedback.')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(title: const Text('Beta Feedback')),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: AppTheme.pagePadding,
                  children: [
                    Container(
                      padding: AppTheme.sectionCardPadding,
                      decoration: AppTheme.tradingCardDecoration(),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thanks for testing the beta',
                              style: AppTheme.tradingHeading(fontSize: 24),
                            ),
                            const SizedBox(height: AppTheme.spaceS),
                            Text(
                              'Tell us what feels broken, confusing or worth improving before wider launch.',
                              style: TextStyle(color: AppTheme.tradingMutedText, height: 1.35),
                            ),
                            const SizedBox(height: AppTheme.spaceL),
                            DropdownButtonFormField<String>(
                              initialValue: _category,
                              items: _categories
                                  .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                                  .toList(growable: false),
                              onChanged: (value) => setState(() => _category = value ?? 'Bug'),
                              decoration: AppTheme.tradingInputDecoration(label: 'Category'),
                            ),
                            const SizedBox(height: AppTheme.spaceM),
                            TextFormField(
                              controller: _summaryController,
                              decoration: AppTheme.tradingInputDecoration(label: 'Quick summary'),
                              validator: (value) => (value == null || value.trim().isEmpty)
                                  ? 'Add a short summary'
                                  : null,
                            ),
                            const SizedBox(height: AppTheme.spaceM),
                            TextFormField(
                              controller: _detailsController,
                              minLines: 5,
                              maxLines: 9,
                              decoration: AppTheme.tradingInputDecoration(label: 'Details'),
                              validator: (value) => (value == null || value.trim().isEmpty)
                                  ? 'Add a bit more detail'
                                  : null,
                            ),
                            const SizedBox(height: AppTheme.spaceL),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _submitting ? null : _submit,
                                icon: const Icon(Icons.send_rounded),
                                label: Text(_submitting ? 'Sending...' : 'Send Feedback'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
