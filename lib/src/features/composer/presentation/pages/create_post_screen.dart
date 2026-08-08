import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../shared/widgets/adaptive_content_width.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../auth/domain/entities/account_entity.dart';
import '../../../auth/domain/entities/social_page_entity.dart';
import '../../../dashboard/presentation/utils/platform_label.dart';
import '../../../organizations/application/current_organization_access.dart';
import '../../../posts/domain/entities/media_entity.dart';
import '../../../posts/domain/entities/post_entity.dart';
import '../../domain/lite_markdown.dart';
import '../widgets/composer_formatting_toolbar.dart';
import '../widgets/composer_readiness.dart';
import '../widgets/highlighting_text_editing_controller.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key, this.initialDraft});

  final PostEntity? initialDraft;

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = HighlightingTextEditingController();
  final _mediaController = TextEditingController();
  final Set<String> _selectedPageIds = <String>{};
  final List<String> _mediaUrls = <String>[];

  /// Per-platform caption overrides ("different text for X than Facebook")
  /// — keyed by provider id, created lazily as platforms become selected.
  /// Empty text means "use the shared body" for that platform.
  final Map<String, TextEditingController> _platformContentControllers =
      <String, TextEditingController>{};

  late Future<List<AccountEntity>> _connectedAccountsFuture;
  String? _draftId;

  DateTime? _scheduledAt;
  bool _submitting = false;
  String? _feedback;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _hydrateFromInitialDraft();
    _connectedAccountsFuture = _loadConnectedAccounts();
  }

  void _hydrateFromInitialDraft() {
    final draft = widget.initialDraft;
    if (draft == null) {
      return;
    }

    _draftId = draft.id;
    _titleController.text = draft.title;
    _contentController.text = draft.body;
    _scheduledAt = draft.scheduledAt;
    _mediaUrls.addAll(draft.attachments);
    _selectedPageIds.addAll(draft.targetPageIds);
    for (final entry in draft.platformContent.entries) {
      _platformContentController(entry.key).text = entry.value;
    }
  }

  TextEditingController _platformContentController(String platform) {
    return _platformContentControllers.putIfAbsent(
      platform,
      () => TextEditingController(),
    );
  }

  Map<String, String> _resolvedPlatformContent() {
    final overrides = <String, String>{};
    final selectedPlatforms = _derivedPlatforms().toSet();
    for (final entry in _platformContentControllers.entries) {
      final text = entry.value.text.trim();
      if (text.isNotEmpty && selectedPlatforms.contains(entry.key)) {
        overrides[entry.key] = text;
      }
    }
    return overrides;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _mediaController.dispose();
    for (final controller in _platformContentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<AccountEntity> _lastLoadedAccounts = const <AccountEntity>[];

  Future<List<AccountEntity>> _loadConnectedAccounts() async {
    final session = await ref
        .read(authSessionControllerProvider)
        .currentSession();
    final userId = session?.user.id;
    if (userId == null) {
      return const <AccountEntity>[];
    }
    final result = await ref
        .read(accountRepositoryProvider)
        .getAccounts(userId: userId);
    if (result.isFailure) {
      // Thrown, not swallowed into an empty list — the FutureBuilder below
      // reads snapshot.hasError to tell "no connected accounts" apart from
      // "the request failed," rather than showing composerNoUsablePages
      // for both.
      throw StateError(result.message ?? 'Failed to load connected accounts.');
    }
    final accounts = result.data ?? const <AccountEntity>[];
    final connected = accounts
        // Keep an old non-beta connection visible in Accounts for support,
        // but never let it become a publishing target. The backend enforces
        // the same Facebook/Telegram release boundary.
        .where(
          (account) =>
              account.isConnected && isBetaLaunchPlatform(account.platform),
        )
        .toList(growable: false);
    _lastLoadedAccounts = connected;
    _selectedPageIds.removeWhere((pageId) => !_isSelectableTargetId(pageId));
    return connected;
  }

  bool _isLaunchTarget(AccountEntity account, SocialPageEntity page) {
    return isBetaLaunchPublishingTarget(
      platform: account.platform,
      pageKind: page.kind,
    );
  }

  bool _isSelectableTarget(AccountEntity account, SocialPageEntity page) {
    return page.isUsable && _isLaunchTarget(account, page);
  }

  bool _isSelectableTargetId(String pageId) {
    for (final account in _lastLoadedAccounts) {
      for (final page in account.pages) {
        if (page.id == pageId) {
          return _isSelectableTarget(account, page);
        }
      }
    }
    return false;
  }

  List<String> _selectedEligiblePageIds() {
    return _selectedPageIds
        .where(_isSelectableTargetId)
        .toList(growable: false);
  }

  AccountEntity? _accountForPage(String pageId) {
    for (final account in _lastLoadedAccounts) {
      for (final page in account.pages) {
        if (page.id == pageId && _isSelectableTarget(account, page)) {
          return account;
        }
      }
    }
    return null;
  }

  List<String> _derivedPlatforms() {
    final platforms = <String>{};
    for (final pageId in _selectedEligiblePageIds()) {
      final account = _accountForPage(pageId);
      if (account != null) {
        platforms.add(account.platform);
      }
    }
    return platforms.toList(growable: false);
  }

  String _pageLabel(String pageId) {
    for (final account in _lastLoadedAccounts) {
      final page = account.pages.where((p) => p.id == pageId).firstOrNull;
      if (page != null) {
        return page.name;
      }
    }
    return pageId;
  }

  Future<void> _refreshConnectedAccounts() async {
    setState(() {
      _connectedAccountsFuture = _loadConnectedAccounts();
    });
    try {
      await _connectedAccountsFuture;
    } catch (_) {
      // Swallowed here — the FutureBuilder watching _connectedAccountsFuture
      // independently picks up the rejection via snapshot.hasError and
      // renders the error/retry UI. This await only exists so
      // RefreshIndicator knows when loading finished.
    }
  }

  void _addMediaUrl() {
    final l10n = AppLocalizations.of(context)!;
    final mediaUrl = _mediaController.text.trim();
    if (mediaUrl.isEmpty) {
      return;
    }
    final uri = Uri.tryParse(mediaUrl);
    final isRealUrl =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    if (!isRealUrl) {
      _showFeedback(l10n.composerInvalidMediaUrl, isError: true);
      return;
    }
    if (_mediaUrls.contains(mediaUrl)) {
      _showFeedback(l10n.composerMediaUrlAlreadyAdded, isError: true);
      return;
    }

    setState(() {
      _mediaUrls.add(mediaUrl);
      _mediaController.clear();
    });
  }

  void _removeMediaUrl(String mediaUrl) {
    setState(() {
      _mediaUrls.remove(mediaUrl);
    });
  }

  bool _validateDraftFields() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      _showFeedback(
        AppLocalizations.of(context)!.composerTitleContentRequired,
        isError: true,
      );
      return false;
    }

    return true;
  }

  bool _validatePublishFields() {
    if (!_validateDraftFields()) {
      return false;
    }

    if (_selectedEligiblePageIds().isEmpty) {
      _showFeedback(
        AppLocalizations.of(context)!.composerSelectAtLeastOnePage,
        isError: true,
      );
      return false;
    }

    return true;
  }

  bool _validateScheduleFields() {
    if (!_validatePublishFields()) {
      return false;
    }

    final l10n = AppLocalizations.of(context)!;

    if (_scheduledAt == null) {
      _showFeedback(l10n.composerSelectScheduleTime, isError: true);
      return false;
    }

    if (_scheduledAt!.isBefore(DateTime.now())) {
      _showFeedback(l10n.composerScheduleTimeMustBeFuture, isError: true);
      return false;
    }

    return true;
  }

  PostEntity _buildPost({required String status}) {
    final now = DateTime.now();
    return PostEntity(
      id: _draftId ?? 'post-${now.microsecondsSinceEpoch}',
      title: _titleController.text.trim(),
      body: _contentController.text.trim(),
      status: status,
      createdAt: now,
      updatedAt: now,
      hasMedia: _mediaUrls.isNotEmpty,
      scheduledAt: _scheduledAt,
      attachments: List<String>.unmodifiable(_mediaUrls),
      platforms: _derivedPlatforms(),
      targetPageIds: _selectedEligiblePageIds(),
      platformContent: _resolvedPlatformContent(),
    );
  }

  Future<PostEntity> _saveOrUpdateDraftEntity() async {
    final l10n = AppLocalizations.of(context)!;
    final draft = _buildPost(status: 'draft');

    if (_draftId == null) {
      final created = await ref.read(createPostUseCaseProvider)(draft);
      if (!created.isSuccess || created.data == null) {
        throw StateError(created.message ?? l10n.composerFailedSaveDraft);
      }
      _draftId = created.data!.id;
      return created.data!;
    }

    final updated = await ref.read(postRepositoryProvider).updatePost(draft);
    if (!updated.isSuccess || updated.data == null) {
      throw StateError(updated.message ?? l10n.composerFailedUpdateDraft);
    }
    return updated.data!;
  }

  Future<void> _saveDraft() async {
    if (!_validateDraftFields()) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    await _runSubmission(() async {
      final isNewDraft = _draftId == null;
      await _saveOrUpdateDraftEntity();
      _showFeedback(
        isNewDraft
            ? l10n.composerDraftSavedSuccess
            : l10n.composerDraftUpdatedSuccess,
      );
    });
  }

  Future<void> _schedulePost() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_canSubmitPostAction()) {
      _showFeedback(l10n.composerPostActionNotAllowed, isError: true);
      return;
    }

    if (!_validateScheduleFields()) {
      return;
    }

    await _runSubmission(() async {
      final savedDraft = await _saveOrUpdateDraftEntity();

      final scheduledPost = savedDraft.copyWith(
        status: 'scheduled',
        scheduledAt: _scheduledAt,
        updatedAt: DateTime.now(),
        attachments: List<String>.unmodifiable(_mediaUrls),
        platforms: _derivedPlatforms(),
        targetPageIds: _selectedEligiblePageIds(),
      );

      final scheduled = await ref.read(schedulePostUseCaseProvider)(
        scheduledPost,
      );
      if (!scheduled.isSuccess) {
        throw StateError(scheduled.message ?? l10n.composerFailedSchedulePost);
      }

      // See publishNow — the backend distinguishes "scheduled" from
      // "submitted for approval" via this same message field.
      _showFeedback(scheduled.message ?? l10n.composerPostScheduledSuccess);
    });
  }

  Future<void> _publishNow() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_canSubmitPostAction()) {
      _showFeedback(l10n.composerPostActionNotAllowed, isError: true);
      return;
    }

    if (!_validatePublishFields()) {
      return;
    }

    await _runSubmission(() async {
      final savedDraft = await _saveOrUpdateDraftEntity();

      // Real delivery (e.g. an actual Telegram sendMessage) happens
      // server-side via PublishPostJob against the selected pages — the
      // backend is the only place with real provider credentials.
      final published = await ref
          .read(postRepositoryProvider)
          .publishNow(savedDraft.id, socialPageIds: _selectedEligiblePageIds());
      if (!published.isSuccess) {
        throw StateError(published.message ?? l10n.composerFailedPublishPost);
      }

      // The backend's own message distinguishes "queued for publishing"
      // from "submitted for approval" (an editor-role request pending
      // manager/admin/owner review) — surface it verbatim rather than a
      // fixed string that would say "queued for publishing" even when it
      // wasn't.
      _showFeedback(published.message ?? l10n.composerPostQueuedSuccess);
    });
  }

  Future<void> _pickAndUploadMediaFile() async {
    // Flutter Web has no filesystem — file_picker can only hand back bytes
    // there, and reading `.path` on web throws instead of returning null, so
    // it must never be touched unless we're actually on a platform with one.
    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      withData: kIsWeb,
    );

    if (result == null || result.files.isEmpty || !mounted) {
      return;
    }

    final file = result.files.single;
    final bytes = kIsWeb ? file.bytes : null;
    final path = kIsWeb ? null : file.path;
    final l10n = AppLocalizations.of(context)!;

    if (kIsWeb && bytes == null) {
      _showFeedback(l10n.composerFileDataUnavailable, isError: true);
      return;
    }
    if (!kIsWeb && (path == null || path.trim().isEmpty)) {
      _showFeedback(l10n.composerFilePathUnavailable, isError: true);
      return;
    }

    final referenceName = path ?? file.name;

    await _runSubmission(() async {
      final postId =
          _draftId ?? 'temp-post-${DateTime.now().microsecondsSinceEpoch}';
      final media = MediaEntity(
        id: 'media-${DateTime.now().microsecondsSinceEpoch}',
        postId: postId,
        url: referenceName,
        mimeType: _guessMimeType(referenceName),
        sizeInBytes: file.size,
        bytes: bytes,
      );

      final uploaded = await ref.read(uploadMediaUseCaseProvider)(media);
      if (!uploaded.isSuccess || uploaded.data == null) {
        throw StateError(uploaded.message ?? l10n.composerFailedUploadMedia);
      }

      final uploadedUrl = uploaded.data!.url;
      if (_mediaUrls.contains(uploadedUrl)) {
        _showFeedback(l10n.composerMediaAlreadyAttached);
        return;
      }

      setState(() {
        _mediaUrls.add(uploadedUrl);
      });
      _showFeedback(l10n.composerMediaUploadedSuccess);
    });
  }

  Future<void> _pickScheduleDateTime() async {
    final now = DateTime.now();
    final initial = _scheduledAt ?? now.add(const Duration(hours: 1));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (selectedTime == null) {
      return;
    }

    setState(() {
      _scheduledAt = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  Future<void> _runSubmission(Future<void> Function() action) async {
    setState(() {
      _submitting = true;
      _feedback = null;
    });

    try {
      await action();
    } catch (error) {
      _showFeedback(
        error.toString().replaceFirst('Bad state: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  void _showFeedback(String message, {bool isError = false}) {
    setState(() {
      _feedback = message;
      _isError = isError;
    });
  }

  bool _canSubmitPostAction() {
    return ref
            .read(currentOrganizationAccessProvider)
            .valueOrNull
            ?.canPublishOrRequestApproval ??
        false;
  }

  void _openPreviewSheet() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final l10n = AppLocalizations.of(context)!;
    final requiresApproval =
        ref
            .read(currentOrganizationAccessProvider)
            .valueOrNull
            ?.canRequestPostApproval ??
        false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.composerPreviewSheetTitle,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title.isEmpty ? l10n.postUntitled : title,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(content.isEmpty ? l10n.composerNoContentYet : content),
              const SizedBox(height: AppSpacing.md),
              _PreviewRow(
                label: l10n.composerPreviewMediaLabel,
                value: _mediaUrls.isEmpty
                    ? l10n.composerMediaNone
                    : l10n.composerMediaItemCount(_mediaUrls.length),
              ),
              _PreviewRow(
                label: l10n.composerPreviewTargetsLabel,
                value: _selectedEligiblePageIds().isEmpty
                    ? l10n.composerNoneSelected
                    : _selectedEligiblePageIds().map(_pageLabel).join(', '),
              ),
              _PreviewRow(
                label: l10n.composerPreviewScheduleLabel,
                value: _scheduledAt == null
                    ? requiresApproval
                          ? l10n.composerSubmitPublishForApprovalButton
                          : l10n.composerPublishNow
                    : _formatDateTime(_scheduledAt!),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final organizationAccess = ref.watch(currentOrganizationAccessProvider);
    final access = organizationAccess.valueOrNull;
    final canSaveDraft =
        access?.hasPermission(OrganizationPermissions.postsCreate) ?? false;
    final canSubmitPostAction = access?.canPublishOrRequestApproval ?? false;
    final requiresApproval = access?.canRequestPostApproval ?? false;
    final accessUnavailable =
        organizationAccess.hasError ||
        (access != null && !access.hasActiveOrganization);
    final readiness =
        <bool>[
          _titleController.text.trim().isNotEmpty,
          _contentController.text.trim().isNotEmpty,
          _selectedEligiblePageIds().isNotEmpty,
        ].where((isReady) => isReady).length /
        3;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.composerAppBarTitle)),
      body: AdaptiveContentWidth(
        maxWidth: 960,
        child: RefreshIndicator(
          onRefresh: _refreshConnectedAccounts,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: <Widget>[
              Text(l10n.composerHeading, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.composerSubheading, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              ComposerReadiness(progress: readiness),
              const SizedBox(height: AppSpacing.lg),
              if (_draftId != null)
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    Chip(
                      avatar: const Icon(Icons.edit_note_outlined),
                      label: Text(l10n.composerEditingDraftChip),
                    ),
                    Chip(label: Text(l10n.composerDraftIdChip(_draftId!))),
                  ],
                ),
              const SizedBox(height: AppSpacing.xl),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.composerTitleLabel,
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _titleController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: l10n.composerTitleHint,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            l10n.composerContentLabel,
                            style: theme.textTheme.labelLarge,
                          ),
                          ComposerFormattingToolbar(
                            controller: _contentController,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _contentController,
                        minLines: 5,
                        maxLines: 9,
                        decoration: InputDecoration(
                          hintText: l10n.composerContentHint,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.composerMediaTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.composerMediaSubtitle,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: _mediaController,
                              decoration: InputDecoration(
                                hintText: l10n.composerMediaUrlHint,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          FilledButton.icon(
                            onPressed: _submitting ? null : _addMediaUrl,
                            icon: const Icon(
                              Icons.add_photo_alternate_outlined,
                            ),
                            label: Text(l10n.composerAddUrl),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: _submitting ? null : _pickAndUploadMediaFile,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: Text(l10n.composerUploadFile),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_mediaUrls.isEmpty)
                        AppEmptyState(
                          message: l10n.composerNoMediaYet,
                          icon: Icons.perm_media_outlined,
                          compact: true,
                          showCard: false,
                          alignment: CrossAxisAlignment.start,
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _mediaUrls
                              .map(
                                (url) => InputChip(
                                  label: SizedBox(
                                    width: 220,
                                    child: Text(
                                      url,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  onDeleted: _submitting
                                      ? null
                                      : () => _removeMediaUrl(url),
                                ),
                              )
                              .toList(growable: false),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.composerPagesTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.composerPagesSubtitle,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FutureBuilder<List<AccountEntity>>(
                        future: _connectedAccountsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(l10n.composerFailedToLoadAccounts),
                                  const SizedBox(height: AppSpacing.sm),
                                  OutlinedButton.icon(
                                    onPressed: () => setState(() {
                                      _connectedAccountsFuture =
                                          _loadConnectedAccounts();
                                    }),
                                    icon: const Icon(Icons.refresh),
                                    label: Text(l10n.commonRetry),
                                  ),
                                ],
                              ),
                            );
                          }

                          final accounts =
                              snapshot.data ?? const <AccountEntity>[];
                          final accountsWithPages = accounts
                              .where(
                                (account) =>
                                    account.pages.any((page) => page.isUsable),
                              )
                              .toList(growable: false);

                          if (accountsWithPages.isEmpty) {
                            return AppEmptyState(
                              message: l10n.composerNoUsablePages,
                              icon: Icons.account_tree_outlined,
                              compact: true,
                              showCard: false,
                              alignment: CrossAxisAlignment.start,
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: accountsWithPages
                                .map(
                                  (account) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.md,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          platformLabel(account.platform),
                                          style: theme.textTheme.labelLarge,
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: account.pages
                                              .where((page) => page.isUsable)
                                              .map((page) {
                                                final isSelectable =
                                                    _isSelectableTarget(
                                                      account,
                                                      page,
                                                    );
                                                final kindLabel =
                                                    _pageKindLabel(
                                                      page.kind,
                                                      l10n,
                                                    );

                                                return FilterChip(
                                                  key: ValueKey<String>(
                                                    'publish-target-${page.id}',
                                                  ),
                                                  avatar: isSelectable
                                                      ? null
                                                      : const Icon(
                                                          Icons.hourglass_top,
                                                          size: 16,
                                                        ),
                                                  label: Text(
                                                    isSelectable
                                                        ? page.name
                                                        : <String>[
                                                            page.name,
                                                            l10n.comingSoonSuffix(
                                                              kindLabel,
                                                            ),
                                                          ].join(' — '),
                                                  ),
                                                  selected:
                                                      isSelectable &&
                                                      _selectedPageIds.contains(
                                                        page.id,
                                                      ),
                                                  onSelected:
                                                      _submitting ||
                                                          !isSelectable
                                                      ? null
                                                      : (selected) {
                                                          setState(() {
                                                            if (selected) {
                                                              _selectedPageIds
                                                                  .add(page.id);
                                                            } else {
                                                              _selectedPageIds
                                                                  .remove(
                                                                    page.id,
                                                                  );
                                                            }
                                                          });
                                                        },
                                                );
                                              })
                                              .toList(growable: false),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_derivedPlatforms().isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          l10n.composerPerPlatformContentTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.composerPerPlatformContentSubtitle,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ..._derivedPlatforms().map(
                          (platform) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: TextField(
                              controller: _platformContentController(platform),
                              minLines: 1,
                              maxLines: 4,
                              decoration: InputDecoration(
                                labelText: l10n.composerPlatformOverrideLabel(
                                  platformLabel(platform),
                                ),
                                hintText: l10n.composerPlatformOverrideHint,
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_derivedPlatforms().isNotEmpty)
                const SizedBox(height: AppSpacing.lg),
              if (_derivedPlatforms().isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          l10n.composerPerPlatformPreviewTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.composerPerPlatformPreviewSubtitle,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ..._derivedPlatforms().map(
                          (platform) => _PlatformPreviewCard(
                            platform: platform,
                            label: platformLabel(platform),
                            text:
                                _platformContentController(
                                  platform,
                                ).text.trim().isNotEmpty
                                ? _platformContentController(
                                    platform,
                                  ).text.trim()
                                : _contentController.text.trim(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.composerSchedulingTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              _scheduledAt == null
                                  ? l10n.composerNoScheduleSelected
                                  : l10n.composerScheduledFor(
                                      _formatDateTime(_scheduledAt!),
                                    ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _submitting
                                ? null
                                : _pickScheduleDateTime,
                            icon: const Icon(Icons.schedule),
                            label: Text(l10n.composerPickTime),
                          ),
                          IconButton(
                            tooltip: l10n.composerClearScheduleTooltip,
                            onPressed: _submitting || _scheduledAt == null
                                ? null
                                : () {
                                    setState(() {
                                      _scheduledAt = null;
                                    });
                                  },
                            icon: const Icon(Icons.clear),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.composerPreviewTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _PreviewRow(
                        label: l10n.composerTitleLabel,
                        value: _titleController.text.trim().isEmpty
                            ? l10n.postUntitled
                            : _titleController.text.trim(),
                      ),
                      _PreviewRow(
                        label: l10n.composerContentLabel,
                        value: _contentController.text.trim().isEmpty
                            ? l10n.composerNoContentYet
                            : _contentController.text.trim(),
                      ),
                      _PreviewRow(
                        label: l10n.composerPreviewMediaLabel,
                        value: _mediaUrls.isEmpty
                            ? l10n.composerMediaNone
                            : l10n.composerMediaItemCount(_mediaUrls.length),
                      ),
                      _PreviewRow(
                        label: l10n.composerPreviewTargetsLabel,
                        value: _selectedEligiblePageIds().isEmpty
                            ? l10n.composerNoneSelected
                            : _selectedEligiblePageIds()
                                  .map(_pageLabel)
                                  .join(', '),
                      ),
                      _PreviewRow(
                        label: l10n.composerPreviewScheduleLabel,
                        value: _scheduledAt == null
                            ? requiresApproval
                                  ? l10n.composerSubmitPublishForApprovalButton
                                  : l10n.composerPublishNow
                            : _formatDateTime(_scheduledAt!),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: _openPreviewSheet,
                        icon: const Icon(Icons.visibility_outlined),
                        label: Text(l10n.composerOpenPreview),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_feedback != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    _feedback!,
                    style: TextStyle(
                      color: _isError
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (organizationAccess.isLoading && access == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    children: <Widget>[
                      const SizedBox(
                        width: AppSizes.iconMd,
                        height: AppSizes.iconMd,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(l10n.composerOrganizationAccessLoading),
                    ],
                  ),
                )
              else if (accessUnavailable)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Card(
                    color: theme.colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        l10n.composerOrganizationAccessUnavailable,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                )
              else if (requiresApproval)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Card(
                    color: theme.colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(l10n.composerApprovalRequiredNotice),
                    ),
                  ),
                ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: _submitting || !canSaveDraft ? null : _saveDraft,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(l10n.composerSaveDraftButton),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _submitting || !canSubmitPostAction
                        ? null
                        : _schedulePost,
                    icon: const Icon(Icons.event_available_outlined),
                    label: Text(
                      requiresApproval
                          ? l10n.composerSubmitScheduleForApprovalButton
                          : l10n.composerScheduleButton,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _submitting || !canSubmitPostAction
                        ? null
                        : _publishNow,
                    icon: _submitting
                        ? const SizedBox(
                            width: AppSizes.iconSm,
                            height: AppSizes.iconSm,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(
                      requiresApproval
                          ? l10n.composerSubmitPublishForApprovalButton
                          : l10n.composerPublishButton,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _pageKindLabel(String kind, AppLocalizations l10n) {
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

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }

  String _guessMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.mp4')) {
      return 'video/mp4';
    }
    if (lower.endsWith('.mov')) {
      return 'video/quicktime';
    }
    if (lower.endsWith('.pdf')) {
      return 'application/pdf';
    }
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (lower.endsWith('.xls')) {
      return 'application/vnd.ms-excel';
    }
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.doc')) {
      return 'application/msword';
    }
    if (lower.endsWith('.csv')) {
      return 'text/csv';
    }
    if (lower.endsWith('.zip')) {
      return 'application/zip';
    }
    return 'application/octet-stream';
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 92, child: Text(label)),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders exactly what a platform will really display: Telegram (the only
/// provider with real `**bold**`/`_italic_` support) shows the formatting
/// rendered; every other platform shows the plain, marker-stripped text —
/// matching `LiteMarkdown`'s server-side transform at actual publish time.
class _PlatformPreviewCard extends StatelessWidget {
  const _PlatformPreviewCard({
    required this.platform,
    required this.label,
    required this.text,
  });

  final String platform;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayText = text.isEmpty
        ? AppLocalizations.of(context)!.composerNoContentYet
        : text;
    final supportsFormatting = platform == 'telegram';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.circle, size: 10, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: theme.textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (supportsFormatting)
            Text.rich(
              key: ValueKey<String>('platform-preview-text-$platform'),
              TextSpan(
                children: LiteMarkdown.toRuns(displayText)
                    .map(
                      (run) => TextSpan(
                        text: run.text,
                        style: switch (run.style) {
                          LiteMarkdownStyle.bold => const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          LiteMarkdownStyle.italic => const TextStyle(
                            fontStyle: FontStyle.italic,
                          ),
                          LiteMarkdownStyle.plain => null,
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
            )
          else
            Text(
              LiteMarkdown.toPlainText(displayText),
              key: ValueKey<String>('platform-preview-text-$platform'),
            ),
        ],
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
