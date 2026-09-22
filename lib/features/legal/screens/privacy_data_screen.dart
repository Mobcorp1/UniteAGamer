import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/legal/data/uag_account_deletion_service.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/privacy_policy_screen.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/support_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_account_support_workspace_bar.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/screens/build/auth/auth_landing_screen.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

class UagPrivacyDataScreen extends StatefulWidget {
  const UagPrivacyDataScreen({super.key});

  static const routeName = '/privacy-data';

  @override
  State<UagPrivacyDataScreen> createState() => _UagPrivacyDataScreenState();
}

class _UagPrivacyDataScreenState extends State<UagPrivacyDataScreen> {
  final UagAccountDeletionService _deletionService =
      UagAccountDeletionService();

  Future<void> _openAccountDeletion() async {
    final receipt = await showDialog<UagAccountDeletionReceipt>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          _DeleteAccountDialog(deletionService: _deletionService),
    );

    if (!mounted || receipt == null) return;

    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      AuthLandingScreen.routeName,
      (route) => false,
      arguments: <String, String>{
        'accountDeleted': 'true',
        'receiptId': receipt.receiptId,
      },
    );
  }

  void _open(BuildContext context, Widget child) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => child));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const UagAppBar(
        title: 'Privacy & Data',
        subtitle: 'Account data, privacy controls and deletion.',
        showLogout: false,
      ),
      drawer: const AppDrawer(),
      body: ArcTacticalPageList(
        width: ArcPageWidth.standard,
        maxWidth: 980,
        padding: ArcLayoutTokens.pagePadding(context),
        children: [
          const ArcAccountSupportWorkspaceBar(
            current: ArcAccountSupportWorkspace.privacy,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: ArcUiTokens.gapM),
          const ArcTacticalPanel(
            icon: Icons.shield_outlined,
            title: 'Your data controls',
            subtitle:
                'Review UAG privacy information, use public support routes, or permanently delete your account.',
            accent: ArcUiTokens.primaryAccent,
            child: SizedBox.shrink(),
          ),
          _ActionTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle:
                'See what UAG stores, why it is used, retention boundaries and your data-protection rights.',
            onTap: () => _open(context, const PrivacyPolicyScreen()),
          ),
          _ActionTile(
            icon: Icons.support_agent_outlined,
            title: 'Privacy & account support',
            subtitle:
                'Use the public deletion route or contact MobCorp if the in-app process cannot be completed.',
            onTap: () => _open(context, const UagSupportScreen()),
          ),
          ArcTacticalPanel(
            icon: Icons.delete_forever_outlined,
            title: 'Delete My Account',
            subtitle:
                'Permanent account erasure with a narrow retention boundary for safety, disputes and legal obligations.',
            accent: ArcUiTokens.danger,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deletion removes your UAG sign-in, profile, onboarding and personalisation data, progression, Match Raider availability, actionable trading data, notification preferences and account uploads where they belong to your account.',
                  style: ArcUiTokens.body(fontSize: 13),
                ),
                const SizedBox(height: ArcUiTokens.gapS),
                Text(
                  'Some shared records may be retained in a de-identified form where they are needed for verified trust and safety cases, fraud prevention, disputes, legal acceptance evidence, billing, tax or payout obligations. Deleting your account does not erase another Raider’s legitimate dispute history.',
                  style: ArcUiTokens.body(
                    fontSize: 13,
                    color: ArcUiTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: ArcUiTokens.gapS),
                Text(
                  'Deleting UAG does not cancel a Google Play or Stripe subscription. Cancel billing separately through the provider or your UAG plan controls.',
                  style: ArcUiTokens.body(
                    fontSize: 13,
                    color: ArcUiTokens.warning,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: ArcUiTokens.gapM),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: ArcUiTokens.danger,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _openAccountDeletion,
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: const Text('Delete My Account'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusL),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(ArcUiTokens.gapL),
          decoration: ArcUiTokens.surfaceDecoration(
            role: ArcSurfaceRole.interactive,
            accent: ArcUiTokens.primaryAccent,
            borderOpacity: 0.18,
          ),
          child: Row(
            children: [
              Icon(icon, color: ArcUiTokens.primaryAccent),
              const SizedBox(width: ArcUiTokens.gapM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: ArcUiTokens.cardTitle(fontSize: 16)),
                    const SizedBox(height: ArcUiTokens.gapXS),
                    Text(subtitle, style: ArcUiTokens.bodySmall()),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: ArcUiTokens.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.deletionService});

  final UagAccountDeletionService deletionService;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmationController = TextEditingController();

  bool _understands = false;
  bool _busy = false;
  bool _obscurePassword = true;
  String? _error;

  bool get _ready =>
      !_busy &&
      _understands &&
      _passwordController.text.isNotEmpty &&
      _confirmationController.text.trim() == 'DELETE';

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (!_ready) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final receipt = await widget.deletionService.deleteCurrentAccount(
        password: _passwordController.text,
        typedConfirmation: _confirmationController.text,
      );
      _passwordController.clear();
      if (!mounted) return;
      Navigator.of(context).pop(receipt);
    } on UagAccountDeletionException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error =
            'Account deletion could not be completed. Retry, or use Support if the problem continues.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        backgroundColor: ArcUiTokens.surfaceOverlay,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Permanently delete account?',
          style: ArcUiTokens.sectionTitle(
            fontSize: 19,
            color: ArcUiTokens.danger,
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This cannot be undone. Confirm your current password, tick the acknowledgement, then type DELETE.',
                  style: ArcUiTokens.body(fontSize: 13),
                ),
                const SizedBox(height: ArcUiTokens.gapM),
                TextField(
                  controller: _passwordController,
                  enabled: !_busy,
                  obscureText: _obscurePassword,
                  autofillHints: const <String>[AutofillHints.password],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Current password',
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: _busy
                          ? null
                          : () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: ArcUiTokens.gapM),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _understands,
                  onChanged: _busy
                      ? null
                      : (value) =>
                            setState(() => _understands = value ?? false),
                  title: Text(
                    'I understand account deletion is permanent and subscription cancellation is separate.',
                    style: ArcUiTokens.body(fontSize: 13),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: ArcUiTokens.gapS),
                TextField(
                  controller: _confirmationController,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Type DELETE to confirm',
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: ArcUiTokens.gapM),
                  Text(
                    _error!,
                    style: ArcUiTokens.body(
                      fontSize: 13,
                      color: ArcUiTokens.danger,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
                if (_busy) ...[
                  const SizedBox(height: ArcUiTokens.gapM),
                  const LinearProgressIndicator(),
                  const SizedBox(height: ArcUiTokens.gapS),
                  Text(
                    'Deleting account data. Do not close UAG until this completes.',
                    style: ArcUiTokens.bodySmall(),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: ArcUiTokens.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: _ready ? _delete : null,
            icon: const Icon(Icons.delete_forever_outlined),
            label: Text(_busy ? 'Deleting…' : 'Delete permanently'),
          ),
        ],
      ),
    );
  }
}
