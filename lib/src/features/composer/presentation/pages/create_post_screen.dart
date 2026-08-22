import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../shared/widgets/adaptive_content_width.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../auth/domain/entities/account_entity.dart';
import '../../../auth/domain/entities/social_page_entity.dart';
import '../../../dashboard/presentation/utils/platform_label.dart';
import '../../../organizations/application/current_organization_access.dart';
import '../../../posts/domain/entities/media_entity.dart';
import '../../../posts/domain/entities/post_entity.dart';
import '../../../ai/data/ai_repository.dart';
import '../../domain/lite_markdown.dart';
import '../../domain/rich_content_codec.dart';
import '../widgets/composer_readiness.dart';
import '../widgets/composer_rich_text_editor.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key, this.initialDraft});

  final PostEntity? initialDraft;

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _titleController = TextEditingController();
  late final quill.QuillController _contentController;
  final _contentFocusNode = FocusNode();
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
  bool _aiLoading = false;
  String? _feedback;
  bool _isError = false;
  AiTone _aiTone = AiTone.formal;
  String _translationLanguage = 'en';
  AiSuggestion? _aiSuggestion;
  final Map<String, AiSuggestion> _platformAiSuggestions =
      <String, AiSuggestion>{};
  List<Map<String, dynamic>>? _contentBeforeAiApply;

  @override
  void initState() {
    super.initState();
    final draft = widget.initialDraft;
    _contentController = RichContentCodec.controllerFromStorage(
      body: draft?.body ?? '',
      richContent: draft?.richContent ?? const <Map<String, dynamic>>[],
    );
    _contentController.addListener(_onContentChanged);
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
    _contentFocusNode.dispose();
    _mediaController.dispose();
    for (final controller in _platformContentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onContentChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String get _contentText => RichContentCodec.toPlainText(_contentController);

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
    // Discovery-mode-aware, not account.platform-keyed: an
    // instagram_business page's parent AccountEntity still has
    // platform: 'facebook' (Instagram has no OAuth of its own — it's
    // discovered in the same sync call as the Facebook Page, see
    // FacebookOAuthProvider::listPages() on the backend), so checking
    // account.platform directly would never recognize it as eligible.
    // Mirrors AccountPagesPanel's own eligibility check exactly, so the
    // dashboard and composer never disagree about which embedded pages are
    // real publishing targets.
    return isBetaLaunchPublishingTargetForDiscoveryMode(
      discoveryMode: account.discoveryMode,
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
    final content = _contentText.trim();

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
      body: RichContentCodec.toPublishText(_contentController),
      status: status,
      createdAt: now,
      updatedAt: now,
      hasMedia: _mediaUrls.isNotEmpty,
      scheduledAt: _scheduledAt,
      attachments: List<String>.unmodifiable(_mediaUrls),
      platforms: _derivedPlatforms(),
      targetPageIds: _selectedEligiblePageIds(),
      platformContent: _resolvedPlatformContent(),
      richContent: RichContentCodec.toDelta(_contentController),
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
      if (!await _confirmPrePublishCheck(savedDraft)) {
        return;
      }

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
      _leaveComposerAfterSuccess(
        scheduled.message ?? l10n.composerPostScheduledSuccess,
      );
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
      if (!await _confirmPrePublishCheck(savedDraft)) {
        return;
      }

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
      _leaveComposerAfterSuccess(
        published.message ?? l10n.composerPostQueuedSuccess,
      );
    });
  }

  /// A completed publish/schedule is a terminal action, unlike a draft save
  /// — was previously reported live: the inline `_feedback` banner (still
  /// used for every in-progress/failure case) is easy to miss since nothing
  /// actually happens after it appears, leaving the account staring at the
  /// same form wondering whether anything worked. A SnackBar survives the
  /// navigation below (unlike `_feedback`, which lives in this screen's
  /// own State and would just be discarded), so the confirmation is still
  /// visible on the screen the account lands on.
  void _leaveComposerAfterSuccess(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    context.go(RouteNames.dashboardPath);
  }

  Future<void> _pickAndUploadMediaFile() async {
    final l10n = AppLocalizations.of(context)!;

    // The backend validates the upload's post_id as nullable|integer|
    // exists:posts,id — was previously sent as a client-generated
    // 'temp-post-<timestamp>' string whenever a file was picked before the
    // first draft save, which always failed that check with a 422.
    // Reproduced live: a brand-new post + an image attached from the
    // composer before ever saving could never actually upload. Backend
    // title is 'required' (content is nullable) for a draft, so a title is
    // needed before a draft can be auto-created here — ask for it rather
    // than inventing a placeholder.
    if (_draftId == null && _titleController.text.trim().isEmpty) {
      _showFeedback(l10n.composerTitleRequiredForMedia, isError: true);
      return;
    }

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
      // A real, persisted post id — auto-creates the draft first (silently,
      // same as the explicit "Save draft" action) if this is the very first
      // thing attached to a brand-new post.
      final postId = _draftId ?? (await _saveOrUpdateDraftEntity()).id;
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

  Future<bool> _confirmPrePublishCheck(PostEntity post) async {
    // Local/offline drafts have no server id. Existing client validations keep
    // the composer usable offline; the authoritative endpoint runs once the
    // draft has a real Laravel id.
    if (int.tryParse(post.id) == null) {
      return true;
    }
    final report = await ref
        .read(aiRepositoryProvider)
        .prePublishCheck(post.id);
    if (report.hasBlockingErrors) {
      _showFeedback(report.errors.join('\n'), isError: true);
      return false;
    }
    if (report.warnings.isEmpty || !mounted) {
      return true;
    }
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.composerPrePublishWarningsTitle),
            content: Text(report.warnings.join('\n')),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.composerPrePublishBackToReview),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.composerPrePublishProceedAnyway),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _runAi(AiOperation operation, {String? targetPlatform}) async {
    if (_aiLoading) {
      return;
    }
    if (operation == AiOperation.adaptPlatforms && targetPlatform == null) {
      await _adaptAllPlatforms();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final selectedText = RichContentCodec.selectedText(_contentController);
    final sourceText = selectedText.isNotEmpty ? selectedText : _contentText;
    if (sourceText.trim().isEmpty) {
      _showFeedback(l10n.composerAiNoTextSelected, isError: true);
      return;
    }

    setState(() {
      _aiLoading = true;
      _feedback = null;
    });
    try {
      final result = await ref
          .read(aiRepositoryProvider)
          .request(
            operation: operation,
            text: sourceText,
            tone: _aiTone,
            appliesToSelection: selectedText.isNotEmpty,
            postId: _draftId,
            targetLanguage: operation == AiOperation.translate
                ? _translationLanguage
                : null,
            platforms: operation == AiOperation.adaptPlatforms
                ? <String>[targetPlatform!]
                : const <String>[],
          );
      if (!mounted) {
        return;
      }
      setState(() {
        if (targetPlatform == null) {
          _aiSuggestion = result;
        } else {
          _platformAiSuggestions[targetPlatform] = result;
        }
      });
    } catch (error) {
      _showFeedback(
        error.toString().replaceFirst('Bad state: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _aiLoading = false);
      }
    }
  }

  Future<void> _adaptAllPlatforms() async {
    final platforms = _derivedPlatforms();
    final l10n = AppLocalizations.of(context)!;
    if (platforms.isEmpty) {
      _showFeedback(l10n.composerAiSelectPlatformFirst, isError: true);
      return;
    }
    final sourceText = _contentText;
    if (sourceText.trim().isEmpty) {
      _showFeedback(l10n.composerAiWriteContentFirst, isError: true);
      return;
    }
    setState(() => _aiLoading = true);
    final suggestions = <String, AiSuggestion>{};
    var failed = 0;
    for (final platform in platforms) {
      try {
        suggestions[platform] = await ref
            .read(aiRepositoryProvider)
            .request(
              operation: AiOperation.adaptPlatforms,
              text: sourceText,
              tone: _aiTone,
              appliesToSelection: false,
              postId: _draftId,
              platforms: <String>[platform],
            );
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _platformAiSuggestions.addAll(suggestions);
      _aiLoading = false;
    });
    if (failed > 0 && mounted) {
      _showFeedback(
        AppLocalizations.of(context)!.composerAiSomePlatformsFailed,
        isError: true,
      );
    }
  }

  void _applyPlatformSuggestion(String platform) {
    final suggestion = _platformAiSuggestions[platform];
    if (suggestion == null) {
      return;
    }
    _platformContentController(platform).text = suggestion.proposedText;
    setState(() => _platformAiSuggestions.remove(platform));
  }

  void _applyAiSuggestion({
    bool forceSelection = false,
    bool insertBelow = false,
    String? resultText,
  }) {
    final suggestion = _aiSuggestion;
    if (suggestion == null) {
      return;
    }
    _contentBeforeAiApply = RichContentCodec.toDelta(_contentController);
    final proposedText = resultText ?? suggestion.proposedText;
    final addsSuggestion = <AiOperation>{
      AiOperation.suggestClosing,
      AiOperation.suggestCallToAction,
      AiOperation.suggestHashtags,
    }.contains(suggestion.operation);

    if (suggestion.operation == AiOperation.suggestTitles) {
      _titleController.text =
          resultText ??
          (suggestion.suggestions.isNotEmpty
              ? suggestion.suggestions.first
              : proposedText);
    } else if (insertBelow || addsSuggestion) {
      final end = _contentController.document.length - 1;
      final leadingBreak = _contentText.trim().isEmpty ? '' : '\n';
      _contentController.replaceText(
        end,
        0,
        '$leadingBreak$proposedText',
        TextSelection.collapsed(
          offset: end + leadingBreak.length + proposedText.length,
        ),
      );
    } else if ((forceSelection || suggestion.appliesToSelection) &&
        _contentController.selection.isValid &&
        !_contentController.selection.isCollapsed) {
      final selection = _contentController.selection;
      _contentController.replaceText(
        selection.start,
        selection.end - selection.start,
        proposedText,
        TextSelection.collapsed(offset: selection.start + proposedText.length),
      );
    } else {
      _contentController.document = RichContentCodec.documentFromPlainText(
        proposedText,
      );
      _contentController.updateSelection(
        TextSelection.collapsed(offset: proposedText.length),
        quill.ChangeSource.local,
      );
    }
    setState(() => _aiSuggestion = null);
  }

  void _restoreContentBeforeAi() {
    final previous = _contentBeforeAiApply;
    if (previous == null) {
      return;
    }
    _contentController.document = quill.Document.fromJson(previous);
    _contentBeforeAiApply = null;
    setState(() {});
  }

  bool _canSubmitPostAction() {
    return ref
            .read(currentOrganizationAccessProvider)
            .valueOrNull
            ?.canPublishOrRequestApproval ??
        false;
  }

  Widget _buildAiAssistant(ThemeData theme, AppLocalizations l10n) {
    const operations = <AiOperation>[
      AiOperation.spellCheck,
      AiOperation.improve,
      AiOperation.rewrite,
      AiOperation.shorten,
      AiOperation.expand,
      AiOperation.simplify,
      AiOperation.officialNews,
      AiOperation.advertisement,
      AiOperation.academicFormat,
      AiOperation.mediaFormat,
      AiOperation.suggestTitles,
      AiOperation.suggestClosing,
      AiOperation.suggestCallToAction,
      AiOperation.suggestHashtags,
      AiOperation.addEmojis,
      AiOperation.translate,
      AiOperation.adaptPlatforms,
    ];
    return Card(
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.auto_awesome_outlined),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.composerAiAssistantTitle,
                  style: theme.textTheme.titleSmall,
                ),
                if (_aiLoading) ...<Widget>[
                  const SizedBox(width: AppSpacing.sm),
                  const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              RichContentCodec.selectedText(_contentController).isEmpty
                  ? l10n.composerAiWholeTextNotice
                  : l10n.composerAiSelectionOnlyNotice,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                DropdownButton<AiTone>(
                  value: _aiTone,
                  hint: Text(l10n.composerAiToneHint),
                  onChanged: _aiLoading
                      ? null
                      : (tone) => setState(() => _aiTone = tone ?? _aiTone),
                  items: AiTone.values
                      .map(
                        (tone) => DropdownMenuItem<AiTone>(
                          value: tone,
                          child: Text(_aiToneLabel(tone, l10n)),
                        ),
                      )
                      .toList(growable: false),
                ),
                if (_translationLanguage == 'en')
                  TextButton(
                    onPressed: _aiLoading
                        ? null
                        : () => setState(() => _translationLanguage = 'ar'),
                    child: Text(l10n.composerAiTranslateToArabic),
                  )
                else
                  TextButton(
                    onPressed: _aiLoading
                        ? null
                        : () => setState(() => _translationLanguage = 'en'),
                    child: Text(l10n.composerAiTranslateToEnglish),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (MediaQuery.sizeOf(context).width < 600)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  onPressed: _aiLoading
                      ? null
                      : () => _openAiActionsSheet(operations),
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: Text(l10n.composerAiChooseOperation),
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: operations
                    .map(
                      (operation) => Tooltip(
                        message: _aiOperationLabel(operation, l10n),
                        child: OutlinedButton(
                          onPressed: _aiLoading
                              ? null
                              : () => _runAi(operation),
                          child: Text(_aiOperationLabel(operation, l10n)),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
          ],
        ),
      ),
    );
  }

  String _aiToneLabel(AiTone tone, AppLocalizations l10n) {
    return switch (tone) {
      AiTone.formal => l10n.composerAiToneFormal,
      AiTone.academic => l10n.composerAiToneAcademic,
      AiTone.media => l10n.composerAiToneMedia,
      AiTone.marketing => l10n.composerAiToneMarketing,
      AiTone.friendly => l10n.composerAiToneFriendly,
      AiTone.concise => l10n.composerAiToneConcise,
      AiTone.enthusiastic => l10n.composerAiToneEnthusiastic,
    };
  }

  Future<void> _openAiActionsSheet(List<AiOperation> operations) async {
    final l10n = AppLocalizations.of(context)!;
    final operation = await showModalBottomSheet<AiOperation>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: operations
              .map(
                (item) => ListTile(
                  leading: const Icon(Icons.auto_awesome_outlined),
                  title: Text(_aiOperationLabel(item, l10n)),
                  onTap: () => Navigator.pop(context, item),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
    if (operation != null && mounted) {
      await _runAi(operation);
    }
  }

  int? _platformCharacterLimit(String platform) {
    // Keep this tied to active, implemented integrations only. Telegram's
    // sendMessage limit is enforced in Laravel; Facebook has no hard caption
    // limit modeled by the live provider implementation, so show a count
    // rather than inventing one.
    return switch (platform) {
      'telegram' => 4096,
      _ => null,
    };
  }

  void _openPreviewSheet() {
    final title = _titleController.text.trim();
    final content = _contentText.trim();
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
          _contentText.trim().isNotEmpty,
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
                      Text(
                        l10n.composerContentLabel,
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ComposerRichTextEditor(
                        controller: _contentController,
                        focusNode: _contentFocusNode,
                        enabled: !_submitting,
                        onChanged: _onContentChanged,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildAiAssistant(theme, l10n),
                      if (_aiSuggestion != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        _AiSuggestionReview(
                          suggestion: _aiSuggestion!,
                          onApply: () => _applyAiSuggestion(),
                          onReplaceSelection: () =>
                              _applyAiSuggestion(forceSelection: true),
                          onInsertBelow: () =>
                              _applyAiSuggestion(insertBelow: true),
                          onUseSuggestion: (text) =>
                              _applyAiSuggestion(resultText: text),
                          onCopy: () => Clipboard.setData(
                            ClipboardData(text: _aiSuggestion!.proposedText),
                          ),
                          onRetry: () => _runAi(_aiSuggestion!.operation),
                          onDismiss: () => setState(() => _aiSuggestion = null),
                        ),
                      ],
                      if (_contentBeforeAiApply != null)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            onPressed: _restoreContentBeforeAi,
                            icon: const Icon(Icons.undo),
                            label: Text(l10n.composerAiRestorePreviousText),
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
                        ..._derivedPlatforms().map((platform) {
                          final controller = _platformContentController(
                            platform,
                          );
                          final limit = _platformCharacterLimit(platform);
                          final count = controller.text.characters.length;
                          final suggestion = _platformAiSuggestions[platform];
                          final overLimit = limit != null && count > limit;
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                TextField(
                                  controller: controller,
                                  minLines: 1,
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    labelText: l10n
                                        .composerPlatformOverrideLabel(
                                          platformLabel(platform),
                                        ),
                                    hintText: l10n.composerPlatformOverrideHint,
                                    border: const OutlineInputBorder(),
                                    helperText: limit == null
                                        ? l10n.composerPlatformCharCountNoLimit(
                                            count,
                                          )
                                        : l10n.composerPlatformCharCountWithLimit(
                                            count,
                                            limit,
                                          ),
                                    helperStyle: TextStyle(
                                      color: overLimit
                                          ? theme.colorScheme.error
                                          : null,
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  children: <Widget>[
                                    TextButton.icon(
                                      onPressed: _aiLoading
                                          ? null
                                          : () => _runAi(
                                              AiOperation.adaptPlatforms,
                                              targetPlatform: platform,
                                            ),
                                      icon: const Icon(Icons.auto_awesome),
                                      label: Text(
                                        l10n.composerAiAdaptForPlatform(
                                          platformLabel(platform),
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: controller.text.isEmpty
                                          ? null
                                          : () => setState(controller.clear),
                                      icon: const Icon(Icons.restart_alt),
                                      label: Text(
                                        l10n.composerUseBaseTextButton,
                                      ),
                                    ),
                                  ],
                                ),
                                if (suggestion != null)
                                  Card(
                                    margin: const EdgeInsets.only(
                                      top: AppSpacing.sm,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.sm,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            l10n.composerSuggestedVersionForReview,
                                          ),
                                          SelectableText(
                                            suggestion.proposedText,
                                          ),
                                          Wrap(
                                            spacing: AppSpacing.sm,
                                            children: <Widget>[
                                              TextButton(
                                                onPressed: () =>
                                                    _applyPlatformSuggestion(
                                                      platform,
                                                    ),
                                                child: Text(l10n.commonApply),
                                              ),
                                              TextButton(
                                                onPressed: () => setState(
                                                  () => _platformAiSuggestions
                                                      .remove(platform),
                                                ),
                                                child: Text(l10n.commonReject),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
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
                                : RichContentCodec.toPublishText(
                                    _contentController,
                                  ),
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
                        value: _contentText.trim().isEmpty
                            ? l10n.composerNoContentYet
                            : _contentText.trim(),
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

/// A conservative comparison view: the provider returns a complete proposal,
/// not unreliable character positions, so this intentionally never invents
/// per-word corrections. The user always chooses whether and where to apply.
class _AiSuggestionReview extends StatelessWidget {
  const _AiSuggestionReview({
    required this.suggestion,
    required this.onApply,
    required this.onReplaceSelection,
    required this.onInsertBelow,
    required this.onUseSuggestion,
    required this.onCopy,
    required this.onRetry,
    required this.onDismiss,
  });

  final AiSuggestion suggestion;
  final VoidCallback onApply;
  final VoidCallback onReplaceSelection;
  final VoidCallback onInsertBelow;
  final ValueChanged<String> onUseSuggestion;
  final VoidCallback onCopy;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final proposed = suggestion.suggestions.isNotEmpty
        ? suggestion.suggestions.join('\n')
        : suggestion.proposedText;
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.composerAiSuggestionReviewTitle(
                _aiOperationLabel(suggestion.operation, l10n),
              ),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.composerAiOriginalTextLabel,
              style: theme.textTheme.labelLarge,
            ),
            SelectableText(suggestion.originalText),
            const Divider(),
            Text(
              l10n.composerAiProposedTextLabel,
              style: theme.textTheme.labelLarge,
            ),
            SelectableText(proposed),
            if (suggestion.suggestions.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.composerAiChooseSuggestionLabel,
                style: theme.textTheme.labelLarge,
              ),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: suggestion.suggestions
                    .map(
                      (item) => OutlinedButton(
                        onPressed: () => onUseSuggestion(item),
                        child: Text(item),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.composerAiSafeComparisonNotice,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                FilledButton(
                  onPressed: onApply,
                  child: Text(l10n.composerAiApplyResultButton),
                ),
                OutlinedButton(
                  onPressed: onReplaceSelection,
                  child: Text(l10n.composerAiReplaceSelectionButton),
                ),
                OutlinedButton(
                  onPressed: onInsertBelow,
                  child: Text(l10n.composerAiInsertBelowButton),
                ),
                TextButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_outlined),
                  label: Text(l10n.commonCopy),
                ),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.commonRetry),
                ),
                TextButton(
                  onPressed: onDismiss,
                  child: Text(l10n.composerAiDismissSuggestionButton),
                ),
              ],
            ),
          ],
        ),
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

String _aiOperationLabel(AiOperation operation, AppLocalizations l10n) {
  return switch (operation) {
    AiOperation.spellCheck => l10n.aiOperationSpellCheck,
    AiOperation.improve => l10n.aiOperationImprove,
    AiOperation.rewrite => l10n.aiOperationRewrite,
    AiOperation.shorten => l10n.aiOperationShorten,
    AiOperation.expand => l10n.aiOperationExpand,
    AiOperation.simplify => l10n.aiOperationSimplify,
    AiOperation.officialNews => l10n.aiOperationOfficialNews,
    AiOperation.advertisement => l10n.aiOperationAdvertisement,
    AiOperation.academicFormat => l10n.aiOperationAcademicFormat,
    AiOperation.mediaFormat => l10n.aiOperationMediaFormat,
    AiOperation.suggestTitles => l10n.aiOperationSuggestTitles,
    AiOperation.suggestClosing => l10n.aiOperationSuggestClosing,
    AiOperation.suggestCallToAction => l10n.aiOperationSuggestCallToAction,
    AiOperation.suggestHashtags => l10n.aiOperationSuggestHashtags,
    AiOperation.addEmojis => l10n.aiOperationAddEmojis,
    AiOperation.translate => l10n.aiOperationTranslate,
    AiOperation.adaptPlatforms => l10n.aiOperationAdaptPlatforms,
  };
}
