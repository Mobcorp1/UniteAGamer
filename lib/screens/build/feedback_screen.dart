import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uag_traders_hub/build/app_bar.dart';
import 'package:uag_traders_hub/build/app_drawer.dart';
import 'package:uag_traders_hub/screens/build/admin_console_screen.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class FeedbackScreenArgs {
  const FeedbackScreenArgs({this.initialTabIndex = 0});

  final int initialTabIndex;
}

class FeedbackScreen extends StatefulWidget {
  static const routeName = '/feedback';

  const FeedbackScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _summaryController = TextEditingController();
  final _detailsController = TextEditingController();

  String _category = 'Bug';
  bool _submitting = false;
  late int _selectedTab;

  static const _categories = ['Bug', 'Idea', 'UX', 'Trading flow', 'Other'];
  static const _statusOptions = [
    'new',
    'reviewing',
    'planned',
    'implemented',
    'closed',
  ];
  static const _adminReplyLabel = 'Mike, UAG Team';
  static const _autoAcknowledgement =
      'Thanks for your feedback. I will review it personally and look into whether it is something I can implement.';

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex.clamp(0, 2);
    if (_selectedTab == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _markFeedbackReplyNotificationsRead();
      });
    }
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _markFeedbackReplyNotificationsRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final unread = await FirebaseFirestore.instance
        .collection('trading_notifications')
        .where('targetUid', isEqualTo: uid)
        .where('type', isEqualTo: 'feedbackReply')
        .where('read', isEqualTo: false)
        .get();

    if (unread.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {
        'read': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _submitting = true);

    try {
      final feedbackRef = FirebaseFirestore.instance
          .collection('beta_feedback')
          .doc();

      await feedbackRef.set({
        'id': feedbackRef.id,
        'uid': user.uid,
        'email': user.email,
        'category': _category,
        'summary': _summaryController.text.trim(),
        'details': _detailsController.text.trim(),
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await feedbackRef.collection('replies').add({
        'actorUid': 'system',
        'actorLabel': _adminReplyLabel,
        'body': _autoAcknowledgement,
        'isAdminReply': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _summaryController.clear();
      _detailsController.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Thanks for the feedback.')));

      setState(() => _selectedTab = 1);
      await _markFeedbackReplyNotificationsRead();
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _onTabSelected(int index) {
    setState(() => _selectedTab = index);
    if (index == 1) {
      _markFeedbackReplyNotificationsRead();
    }
  }

  Widget _buildStandardChip(String label, int index) {
    final selected = _selectedTab == index;

    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => _onTabSelected(index),
      selectedColor: AppTheme.neonPink.withValues(alpha: 0.16),
      backgroundColor: AppTheme.cardBackground,
      labelStyle: TextStyle(
        color: selected ? AppTheme.neonPink : Colors.white,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(
        color: selected ? AppTheme.neonPink : AppTheme.tradingSoftBorder,
      ),
    );
  }

  Widget _buildFeedbackChip(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('trading_notifications')
          .where('targetUid', isEqualTo: uid)
          .where('type', isEqualTo: 'feedbackReply')
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.docs.length ?? 0;
        final selected = _selectedTab == 1;
        return ChoiceChip(
          selected: selected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('My Feedback'),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.neonCyan,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: AppTheme.bodyTextStyle(
                      fontSize: 11,
                      color: Colors.black,
                      isBold: true,
                    ),
                  ),
                ),
              ],
            ],
          ),
          onSelected: (_) => _onTabSelected(1),
          selectedColor: AppTheme.neonPink.withValues(alpha: 0.16),
          backgroundColor: AppTheme.cardBackground,
          labelStyle: TextStyle(
            color: selected ? AppTheme.neonPink : Colors.white,
            fontWeight: FontWeight.w700,
          ),
          side: BorderSide(
            color: selected ? AppTheme.neonPink : AppTheme.tradingSoftBorder,
          ),
        );
      },
    );
  }

  Widget _buildComposer() {
    return Container(
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
                  .map(
                    (value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) => setState(() => _category = value ?? 'Bug'),
              decoration: AppTheme.tradingInputDecoration(label: 'Category'),
            ),
            const SizedBox(height: AppTheme.spaceM),
            TextFormField(
              controller: _summaryController,
              decoration: AppTheme.tradingInputDecoration(
                label: 'Quick summary',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Add a short summary';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spaceM),
            TextFormField(
              controller: _detailsController,
              minLines: 5,
              maxLines: 9,
              decoration: AppTheme.tradingInputDecoration(label: 'Details'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Add a bit more detail';
                }
                return null;
              },
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
    );
  }

  Widget _buildFeedbackList({required bool adminMode, required String uid}) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('beta_feedback')
        .orderBy('createdAt', descending: true);

    if (!adminMode) {
      query = query.where('uid', isEqualTo: uid);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Container(
            padding: AppTheme.sectionCardPadding,
            decoration: AppTheme.tradingCardDecoration(
              borderColor: Colors.redAccent.withValues(alpha: 0.25),
            ),
            child: Text(
              'Could not load feedback: ${snapshot.error}',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        final docs =
            snapshot.data?.docs ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        if (docs.isEmpty) {
          return Container(
            padding: AppTheme.sectionCardPadding,
            decoration: AppTheme.tradingCardDecoration(),
            child: Text(
              adminMode
                  ? 'No feedback submitted yet.'
                  : 'You have not sent any feedback yet.',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        return Column(
          children: docs
              .map(
                (doc) => _FeedbackCard(
                  feedbackId: doc.id,
                  data: doc.data(),
                  adminMode: adminMode,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid == null) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: const Center(
          child: Text(
            'Sign in to use feedback.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() ?? <String, dynamic>{};
        final adminMode =
            userData['isAdmin'] == true || userData['isDev'] == true;

        return Scaffold(
          backgroundColor: AppTheme.darkBackground,
          appBar: UagAppBar(
            title: 'Beta Feedback',
            subtitle:
                'Send issues, review your submissions, and access the inbox if you are admin.',
          ),
          drawer: const AppDrawer(),
          body: Stack(
            children: [
              const Positioned.fill(child: StaticWatermark()),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: ListView(
                      padding: AppTheme.pagePadding,
                      children: [
                        if (adminMode) ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).pushNamed(
                                AdminConsoleScreen.routeName,
                              ),
                              icon: const Icon(Icons.admin_panel_settings_outlined),
                              label: const Text('Open Admin Console'),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceM),
                        ],
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _buildStandardChip('Send Feedback', 0),
                            _buildFeedbackChip(uid),
                            if (adminMode) _buildStandardChip('Inbox', 2),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spaceL),
                        if (_selectedTab == 0) _buildComposer(),
                        if (_selectedTab == 1)
                          _buildFeedbackList(adminMode: false, uid: uid),
                        if (_selectedTab == 2 && adminMode)
                          _buildFeedbackList(adminMode: true, uid: uid),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeedbackCard extends StatefulWidget {
  const _FeedbackCard({
    required this.feedbackId,
    required this.data,
    required this.adminMode,
  });

  final String feedbackId;
  final Map<String, dynamic> data;
  final bool adminMode;

  @override
  State<_FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<_FeedbackCard> {
  final TextEditingController _replyController = TextEditingController();
  bool _sendingReply = false;
  bool _updatingStatus = false;
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = (widget.data['status'] ?? 'new').toString();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _sendingReply = true);

    try {
      await FirebaseFirestore.instance
          .collection('beta_feedback')
          .doc(widget.feedbackId)
          .collection('replies')
          .add({
            'actorUid': user.uid,
            'actorLabel': _FeedbackScreenState._adminReplyLabel,
            'body': _replyController.text.trim(),
            'isAdminReply': true,
            'createdAt': FieldValue.serverTimestamp(),
          });

      final feedbackDoc = await FirebaseFirestore.instance
          .collection('beta_feedback')
          .doc(widget.feedbackId)
          .get();
      final feedbackData = feedbackDoc.data() ?? <String, dynamic>{};
      final targetUid = (feedbackData['uid'] ?? '').toString();
      final summary = (feedbackData['summary'] ?? 'Feedback update').toString();

      final notificationRef = FirebaseFirestore.instance
          .collection('trading_notifications')
          .doc();

      if (targetUid.isNotEmpty && targetUid != user.uid) {
        await notificationRef.set({
          'id': notificationRef.id,
          'targetUid': targetUid,
          'actorUid': user.uid,
          'title': 'UAG replied to your feedback',
          'body': summary,
          'type': 'feedbackReply',
          'listingId': '',
          'offerId': '',
          'sessionId': '',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await FirebaseFirestore.instance
          .collection('beta_feedback')
          .doc(widget.feedbackId)
          .update({
            'status': _status,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      _replyController.clear();
    } finally {
      if (mounted) {
        setState(() => _sendingReply = false);
      }
    }
  }

  Future<void> _updateStatus(String value) async {
    setState(() {
      _status = value;
      _updatingStatus = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('beta_feedback')
          .doc(widget.feedbackId)
          .update({'status': value, 'updatedAt': FieldValue.serverTimestamp()});
    } finally {
      if (mounted) {
        setState(() => _updatingStatus = false);
      }
    }
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: AppTheme.pillPadding,
      decoration: AppTheme.tradingPillDecoration(color: color),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    final value = timestamp?.toDate();
    if (value == null) return 'Pending timestamp';
    return value.toLocal().toString().substring(0, 16);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final createdAt = data['createdAt'] as Timestamp?;
    final category = (data['category'] ?? 'Other').toString();
    final summary = (data['summary'] ?? '').toString();
    final details = (data['details'] ?? '').toString();
    final email = (data['email'] ?? '').toString();
    final docUid = (data['uid'] ?? '').toString();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(category, AppTheme.neonCyan),
              _pill(_status.toUpperCase(), AppTheme.neonPink),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          Text(summary, style: AppTheme.tradingHeading(fontSize: 20)),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            details,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Text(
            widget.adminMode
                ? 'From: ${email.isNotEmpty ? email : docUid}'
                : 'Sent: ${_formatTimestamp(createdAt)}',
            style: TextStyle(color: AppTheme.tradingMutedText, fontSize: 12),
          ),
          if (widget.adminMode) ...[
            const SizedBox(height: AppTheme.spaceM),
            DropdownButtonFormField<String>(
              initialValue: _status,
              items: _FeedbackScreenState._statusOptions
                  .map(
                    (value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _updatingStatus
                  ? null
                  : (value) {
                      if (value != null) {
                        _updateStatus(value);
                      }
                    },
              decoration: AppTheme.tradingInputDecoration(label: 'Status'),
            ),
          ],
          const SizedBox(height: AppTheme.spaceM),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('beta_feedback')
                .doc(widget.feedbackId)
                .collection('replies')
                .orderBy('createdAt')
                .snapshots(),
            builder: (context, snapshot) {
              final docs =
                  snapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[];

              if (docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: AppTheme.tradingCardDecoration(
                    backgroundColor: AppTheme.cardBackgroundAlt,
                    radius: 14,
                  ),
                  child: Text(
                    'No replies yet.',
                    style: AppTheme.bodyTextStyle(
                      fontSize: 13,
                      color: AppTheme.tradingMutedText,
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reply Thread',
                    style: AppTheme.bodyTextStyle(
                      fontSize: 13,
                      color: AppTheme.tradingFaintText,
                      isBold: true,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceS),
                  ...docs.map((replyDoc) {
                    final reply = replyDoc.data();
                    final isAdminReply = reply['isAdminReply'] == true;
                    final actorLabel =
                        (reply['actorLabel'] ??
                                (isAdminReply
                                    ? _FeedbackScreenState._adminReplyLabel
                                    : 'You'))
                            .toString();
                    final body = (reply['body'] ?? '').toString();
                    final replyCreatedAt = reply['createdAt'] as Timestamp?;

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
                      padding: const EdgeInsets.all(12),
                      decoration: AppTheme.tradingCardDecoration(
                        backgroundColor: isAdminReply
                            ? AppTheme.neonPink.withValues(alpha: 0.08)
                            : AppTheme.cardBackgroundAlt,
                        borderColor: (isAdminReply
                                ? AppTheme.neonPink
                                : AppTheme.neonCyan)
                            .withValues(alpha: 0.28),
                        radius: 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  actorLabel,
                                  style: AppTheme.bodyTextStyle(
                                    fontSize: 13,
                                    color: isAdminReply
                                        ? AppTheme.neonPink
                                        : AppTheme.neonCyan,
                                    isBold: true,
                                  ),
                                ),
                              ),
                              if (isAdminReply)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: AppTheme.tradingPillDecoration(
                                    color: AppTheme.neonPink,
                                  ),
                                  child: Text(
                                    'UAG Reply',
                                    style: AppTheme.bodyTextStyle(
                                      fontSize: 10,
                                      color: AppTheme.neonPink,
                                      isBold: true,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            body,
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatTimestamp(replyCreatedAt),
                            style: TextStyle(
                              color: AppTheme.tradingMutedText,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
          if (widget.adminMode) ...[
            const SizedBox(height: AppTheme.spaceM),
            TextFormField(
              controller: _replyController,
              minLines: 2,
              maxLines: 4,
              decoration: AppTheme.tradingInputDecoration(
                label: 'Reply to tester',
              ),
            ),
            const SizedBox(height: AppTheme.spaceS),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _sendingReply ? null : _sendReply,
                icon: const Icon(Icons.reply_rounded),
                label: Text(_sendingReply ? 'Sending...' : 'Send Reply'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
