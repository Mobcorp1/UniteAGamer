import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_profile_social_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcSocialLinksEditor extends StatefulWidget {
  const ArcSocialLinksEditor({
    super.key,
    required this.initialLinks,
    required this.onChanged,
  });

  final List<ArcProfileSocialLink> initialLinks;
  final ValueChanged<List<ArcProfileSocialLink>> onChanged;

  @override
  State<ArcSocialLinksEditor> createState() => _ArcSocialLinksEditorState();
}

class _ArcSocialLinksEditorState extends State<ArcSocialLinksEditor> {
  late final Map<ArcSocialPlatform, TextEditingController> _controllers;
  late Map<ArcSocialPlatform, bool> _hidden;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final platform in ArcSocialPlatform.values)
        platform: TextEditingController(),
    };
    _applyInitialLinks(widget.initialLinks);
  }

  @override
  void didUpdateWidget(covariant ArcSocialLinksEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLinks != widget.initialLinks) {
      _applyInitialLinks(widget.initialLinks);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _applyInitialLinks(List<ArcProfileSocialLink> links) {
    final merged = {
      for (final link in ArcProfileSocialLinks.merge(links))
        link.platform: link,
    };
    _hidden = <ArcSocialPlatform, bool>{};
    for (final platform in ArcSocialPlatform.values) {
      final link = merged[platform];
      _controllers[platform]!.text = link?.value ?? '';
      _hidden[platform] = link?.hidden ?? false;
    }
  }

  ArcProfileSocialLink _linkFor(ArcSocialPlatform platform) {
    return ArcProfileSocialLink(
      platform: platform,
      value: _controllers[platform]!.text,
      hidden: _hidden[platform] ?? false,
    );
  }

  void _emitChanged() {
    widget.onChanged(
      ArcProfileSocialLinks.merge(ArcSocialPlatform.values.map(_linkFor)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Add only links you want associated with your public UAG identity. Hidden links are saved for later but excluded from public profile output.',
          style: ArcUiTokens.body(),
        ),
        const SizedBox(height: AppTheme.spaceM),
        ...ArcSocialPlatform.values.map(_platformField),
      ],
    );
  }

  Widget _platformField(ArcSocialPlatform platform) {
    final link = _linkFor(platform);
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
      padding: const EdgeInsets.all(AppTheme.spaceS),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.interactive,
        accent: ArcUiTokens.primaryAccent,
        borderOpacity: 0.12,
        radius: ArcUiTokens.radiusM,
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _controllers[platform],
            style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
            validator: (_) => _linkFor(platform).validationError,
            decoration:
                ArcUiTokens.inputDecoration(
                  labelText: '${platform.label} username or URL',
                ).copyWith(
                  helperText: link.destinationUrl.isEmpty
                      ? 'Optional'
                      : link.destinationUrl,
                  helperMaxLines: 2,
                  helperStyle: ArcUiTokens.bodySmall(),
                ),
            onChanged: (_) {
              setState(() {});
              _emitChanged();
            },
          ),
          SwitchListTile.adaptive(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: _hidden[platform] ?? false,
            activeThumbColor: ArcUiTokens.secondaryAccent,
            onChanged: (value) {
              setState(() => _hidden[platform] = value);
              _emitChanged();
            },
            title: Text(
              'Hide ${platform.label} from public profile',
              style: ArcUiTokens.body(
                color: ArcUiTokens.textPrimary,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
