import 'package:flutter/material.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../auth/domain/entities/social_page_entity.dart';
import '../utils/platform_label.dart';

/// Shows the Pages/Channels/Business Accounts under a connected account,
/// lets the user pick which ones to actually publish to, and exposes the
/// right discovery action ("Sync Pages" for auto-discovery providers like
/// Facebook, "Add Channel" for manual ones like Telegram).
class AccountPagesPanel extends StatefulWidget {
  const AccountPagesPanel({
    super.key,
    required this.pages,
    required this.discoveryMode,
    required this.onSync,
    required this.onAddChannel,
    required this.onSaveSelection,
    required this.onDeletePage,
    required this.canManagePages,
  });

  final List<SocialPageEntity> pages;
  final String discoveryMode;
  final Future<void> Function() onSync;
  final Future<void> Function() onAddChannel;
  final Future<void> Function(List<String> pageIds) onSaveSelection;
  final Future<void> Function(String pageId) onDeletePage;
  final bool canManagePages;

  @override
  State<AccountPagesPanel> createState() => _AccountPagesPanelState();
}

class _AccountPagesPanelState extends State<AccountPagesPanel> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = _savedEligiblePageIds();
  }

  @override
  void didUpdateWidget(covariant AccountPagesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pages != widget.pages ||
        oldWidget.discoveryMode != widget.discoveryMode) {
      _selected = _savedEligiblePageIds();
    }
  }

  bool _isLaunchTarget(SocialPageEntity page) {
    return isBetaLaunchPublishingTargetForDiscoveryMode(
      discoveryMode: widget.discoveryMode,
      pageKind: page.kind,
    );
  }

  bool _canSelect(SocialPageEntity page) {
    return page.isUsable && _isLaunchTarget(page);
  }

  Set<String> _savedEligiblePageIds() {
    return widget.pages
        .where((page) => page.isSelected && _canSelect(page))
        .map((page) => page.id)
        .toSet();
  }

  List<String> _selectedEligiblePageIds() {
    return widget.pages
        .where((page) => _selected.contains(page.id) && _canSelect(page))
        .map((page) => page.id)
        .toList(growable: false);
  }

  bool get _isDirty {
    final current = _savedEligiblePageIds();
    return !(_selected.length == current.length &&
        _selected.containsAll(current));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isAuto = widget.discoveryMode == 'auto';

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        widget.pages.isEmpty
            ? l10n.pagesPanelNoneYet
            : l10n.pagesPanelCount(widget.pages.length),
        style: theme.textTheme.labelLarge,
      ),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: <Widget>[
        if (widget.canManagePages)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: isAuto ? widget.onSync : widget.onAddChannel,
              icon: Icon(isAuto ? Icons.sync : Icons.add, size: 18),
              label: Text(
                isAuto ? l10n.pagesPanelSyncPages : l10n.pagesPanelAddChannel,
              ),
            ),
          ),
        if (widget.pages.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(l10n.pagesPanelNothingAdded),
          )
        else
          ...widget.pages.map((page) {
            final canSelect = _canSelect(page);
            final kindLabel = _kindLabel(page.kind, l10n);

            return CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: canSelect && _selected.contains(page.id),
              onChanged: widget.canManagePages && canSelect
                  ? (checked) {
                      setState(() {
                        if (checked ?? false) {
                          _selected.add(page.id);
                        } else {
                          _selected.remove(page.id);
                        }
                      });
                    }
                  : null,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(_kindIcon(page.kind), size: 16),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      canSelect
                          ? page.name
                          : <String>[
                              page.name,
                              l10n.comingSoonSuffix(kindLabel),
                            ].join(' — '),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                <String>[
                  _kindLabel(page.kind, l10n),
                  if (page.username != null) page.username!,
                  if (page.memberCount != null)
                    l10n.pagesPanelMembersCount(page.memberCount!),
                  _statusLabel(page.status, l10n),
                ].join(' • '),
              ),
              secondary: widget.canManagePages
                  ? IconButton(
                      tooltip: l10n.pagesPanelRemove,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => widget.onDeletePage(page.id),
                    )
                  : null,
            );
          }),
        if (widget.pages.isNotEmpty && widget.canManagePages)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton(
              onPressed: _isDirty
                  ? () => widget.onSaveSelection(_selectedEligiblePageIds())
                  : null,
              child: Text(l10n.pagesPanelSaveSelection),
            ),
          ),
      ],
    );
  }

  IconData _kindIcon(String kind) {
    switch (kind) {
      case 'instagram_business':
        return Icons.camera_alt_outlined;
      case 'whatsapp_number':
        return Icons.chat_outlined;
      case 'channel':
        return Icons.campaign_outlined;
      default:
        return Icons.flag_outlined;
    }
  }

  String _kindLabel(String kind, AppLocalizations l10n) {
    switch (kind) {
      case 'instagram_business':
        return l10n.pageKindInstagram;
      case 'whatsapp_number':
        return l10n.pageKindWhatsapp;
      case 'channel':
        return l10n.pageKindChannel;
      default:
        return l10n.pageKindPage;
    }
  }

  String _statusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case SocialPageStatus.valid:
        return l10n.pageStatusValid;
      case SocialPageStatus.needsReauth:
        return l10n.pageStatusNeedsReauth;
      case SocialPageStatus.invalid:
        return l10n.pageStatusInvalid;
      default:
        return status;
    }
  }
}
