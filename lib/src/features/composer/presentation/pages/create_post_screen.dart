import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../domain/publish_target.dart';
import '../../../auth/domain/entities/account_entity.dart';
import '../../../posts/domain/entities/media_entity.dart';
import '../../../posts/domain/entities/post_entity.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key, this.initialDraft});

  final PostEntity? initialDraft;

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _mediaController = TextEditingController();
  final Set<String> _selectedPlatforms = <String>{};
  final List<String> _mediaUrls = <String>[];

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
    _selectedPlatforms.addAll(draft.platforms);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _mediaController.dispose();
    super.dispose();
  }

  Future<List<AccountEntity>> _loadConnectedAccounts() async {
    final result = await ref.read(accountRepositoryProvider).getAccounts();
    final accounts = result.data ?? const <AccountEntity>[];
    return accounts
        .where((account) => account.isConnected)
        .toList(growable: false);
  }

  Future<void> _refreshConnectedAccounts() async {
    setState(() {
      _connectedAccountsFuture = _loadConnectedAccounts();
    });
    await _connectedAccountsFuture;
  }

  void _addMediaUrl() {
    final mediaUrl = _mediaController.text.trim();
    if (mediaUrl.isEmpty) {
      return;
    }
    if (_mediaUrls.contains(mediaUrl)) {
      _showFeedback('Media URL already added.', isError: true);
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
      _showFeedback('Title and content are required.', isError: true);
      return false;
    }

    return true;
  }

  bool _validatePublishFields() {
    if (!_validateDraftFields()) {
      return false;
    }

    if (_selectedPlatforms.isEmpty) {
      _showFeedback(
        'Select at least one platform for publishing.',
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

    if (_scheduledAt == null) {
      _showFeedback('Select a schedule time before scheduling.', isError: true);
      return false;
    }

    if (_scheduledAt!.isBefore(DateTime.now())) {
      _showFeedback('Schedule time must be in the future.', isError: true);
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
      platforms: _selectedPlatforms.toList(growable: false),
    );
  }

  Future<PostEntity> _saveOrUpdateDraftEntity() async {
    final draft = _buildPost(status: 'draft');

    if (_draftId == null) {
      final created = await ref.read(createPostUseCaseProvider)(draft);
      if (!created.isSuccess || created.data == null) {
        throw StateError(created.message ?? 'Failed to save draft.');
      }
      _draftId = created.data!.id;
      return created.data!;
    }

    final updated = await ref.read(postRepositoryProvider).updatePost(draft);
    if (!updated.isSuccess || updated.data == null) {
      throw StateError(updated.message ?? 'Failed to update draft.');
    }
    return updated.data!;
  }

  Future<void> _saveDraft() async {
    if (!_validateDraftFields()) {
      return;
    }

    await _runSubmission(() async {
      final isNewDraft = _draftId == null;
      await _saveOrUpdateDraftEntity();
      _showFeedback(
        isNewDraft
            ? 'Draft saved successfully.'
            : 'Draft updated successfully.',
      );
    });
  }

  Future<void> _schedulePost() async {
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
        platforms: _selectedPlatforms.toList(growable: false),
      );

      final scheduled = await ref.read(schedulePostUseCaseProvider)(
        scheduledPost,
      );
      if (!scheduled.isSuccess) {
        throw StateError(scheduled.message ?? 'Failed to schedule post.');
      }

      _showFeedback('Post scheduled successfully.');
    });
  }

  Future<void> _publishNow() async {
    if (!_validatePublishFields()) {
      return;
    }

    await _runSubmission(() async {
      final savedDraft = await _saveOrUpdateDraftEntity();

      final publishTargets = _selectedPlatforms
          .map(
            (platformId) => PublishTarget(
              category: _categoryForPlatform(platformId),
              destinationKey: platformId,
            ),
          )
          .toList(growable: false);

      await ref
          .read(publishEngineProvider)
          .publish(post: savedDraft, targets: publishTargets);

      _showFeedback('Post queued and published successfully.');
    });
  }

  Future<void> _pickAndUploadMediaFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    final path = file.path;
    if (path == null || path.trim().isEmpty) {
      _showFeedback('Selected file path is not available.', isError: true);
      return;
    }

    await _runSubmission(() async {
      final postId =
          _draftId ?? 'temp-post-${DateTime.now().microsecondsSinceEpoch}';
      final media = MediaEntity(
        id: 'media-${DateTime.now().microsecondsSinceEpoch}',
        postId: postId,
        url: path,
        mimeType: _guessMimeType(path),
        sizeInBytes: file.size,
      );

      final uploaded = await ref.read(uploadMediaUseCaseProvider)(media);
      if (!uploaded.isSuccess || uploaded.data == null) {
        throw StateError(uploaded.message ?? 'Failed to upload media file.');
      }

      final uploadedUrl = uploaded.data!.url;
      if (_mediaUrls.contains(uploadedUrl)) {
        _showFeedback('Media file already attached.');
        return;
      }

      setState(() {
        _mediaUrls.add(uploadedUrl);
      });
      _showFeedback('Media file uploaded and attached.');
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

  void _openPreviewSheet() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Post Preview', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(
                title.isEmpty ? 'Untitled post' : title,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(content.isEmpty ? 'No content yet.' : content),
              const SizedBox(height: 12),
              _PreviewRow(
                label: 'Media',
                value: _mediaUrls.isEmpty
                    ? 'None'
                    : '${_mediaUrls.length} item(s)',
              ),
              _PreviewRow(
                label: 'Platforms',
                value: _selectedPlatforms.isEmpty
                    ? 'None selected'
                    : _selectedPlatforms.map(_platformLabel).join(', '),
              ),
              _PreviewRow(
                label: 'Schedule',
                value: _scheduledAt == null
                    ? 'Publish now'
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

    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: RefreshIndicator(
        onRefresh: _refreshConnectedAccounts,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            Text('Build your post', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Title, content, media, platforms, schedule, preview, and publish in one flow.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            if (_draftId != null)
              Wrap(
                spacing: 8,
                children: <Widget>[
                  const Chip(
                    avatar: Icon(Icons.edit_note_outlined),
                    label: Text('Editing Existing Draft'),
                  ),
                  Chip(label: Text('ID: $_draftId')),
                ],
              ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Title', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Post title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Content', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _contentController,
                      minLines: 5,
                      maxLines: 9,
                      decoration: const InputDecoration(
                        hintText: 'Write your post content...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Media', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Attach media links or upload files from your device.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _mediaController,
                            decoration: const InputDecoration(
                              hintText: 'https://cdn.example.com/image.png',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: _submitting ? null : _addMediaUrl,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Add URL'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _submitting ? null : _pickAndUploadMediaFile,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('Upload File'),
                    ),
                    const SizedBox(height: 10),
                    if (_mediaUrls.isEmpty)
                      const Text('No media attached yet.')
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
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Platforms', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Select connected accounts as publish targets.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<AccountEntity>>(
                      future: _connectedAccountsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(10),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final accounts =
                            snapshot.data ?? const <AccountEntity>[];
                        if (accounts.isEmpty) {
                          return const Text(
                            'No connected accounts. Connect platforms from Dashboard > Accounts.',
                          );
                        }

                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: accounts
                              .map(
                                (account) => FilterChip(
                                  label: Text(_platformLabel(account.platform)),
                                  selected: _selectedPlatforms.contains(
                                    account.platform,
                                  ),
                                  onSelected: _submitting
                                      ? null
                                      : (selected) {
                                          setState(() {
                                            if (selected) {
                                              _selectedPlatforms.add(
                                                account.platform,
                                              );
                                            } else {
                                              _selectedPlatforms.remove(
                                                account.platform,
                                              );
                                            }
                                          });
                                        },
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
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Scheduling', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _scheduledAt == null
                                ? 'No schedule selected (publish immediately).'
                                : 'Scheduled for ${_formatDateTime(_scheduledAt!)}',
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _submitting ? null : _pickScheduleDateTime,
                          icon: const Icon(Icons.schedule),
                          label: const Text('Pick time'),
                        ),
                        IconButton(
                          tooltip: 'Clear schedule',
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
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Preview', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _PreviewRow(
                      label: 'Title',
                      value: _titleController.text.trim().isEmpty
                          ? 'Untitled post'
                          : _titleController.text.trim(),
                    ),
                    _PreviewRow(
                      label: 'Content',
                      value: _contentController.text.trim().isEmpty
                          ? 'No content yet.'
                          : _contentController.text.trim(),
                    ),
                    _PreviewRow(
                      label: 'Media',
                      value: _mediaUrls.isEmpty
                          ? 'None'
                          : '${_mediaUrls.length} item(s)',
                    ),
                    _PreviewRow(
                      label: 'Platforms',
                      value: _selectedPlatforms.isEmpty
                          ? 'None selected'
                          : _selectedPlatforms.map(_platformLabel).join(', '),
                    ),
                    _PreviewRow(
                      label: 'Schedule',
                      value: _scheduledAt == null
                          ? 'Publish now'
                          : _formatDateTime(_scheduledAt!),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _openPreviewSheet,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Open Preview'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_feedback != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: _submitting ? null : _saveDraft,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Draft'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _submitting ? null : _schedulePost,
                  icon: const Icon(Icons.event_available_outlined),
                  label: const Text('Schedule'),
                ),
                FilledButton.icon(
                  onPressed: _submitting ? null : _publishNow,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: const Text('Publish'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PublishTargetCategory _categoryForPlatform(String platformId) {
    switch (platformId) {
      case 'telegram':
      case 'whatsapp':
        return PublishTargetCategory.messaging;
      case 'linkedin':
        return PublishTargetCategory.professional;
      case 'facebook':
      case 'instagram':
      case 'twitter':
      default:
        return PublishTargetCategory.social;
    }
  }

  String _platformLabel(String platformId) {
    switch (platformId) {
      case 'facebook':
        return 'Facebook';
      case 'instagram':
        return 'Instagram';
      case 'telegram':
        return 'Telegram';
      case 'whatsapp':
        return 'WhatsApp';
      case 'linkedin':
        return 'LinkedIn';
      case 'twitter':
        return 'X';
      default:
        return platformId;
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
      padding: const EdgeInsets.only(bottom: 8),
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
