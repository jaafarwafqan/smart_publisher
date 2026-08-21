import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/rich_content_codec.dart';

/// Visible, keyboard-accessible WYSIWYG editor. The built-in Quill toolbar
/// provides undo/redo, lists, alignment, RTL/LTR, links, formatting and safe
/// text paste without using a WebView.
class ComposerRichTextEditor extends StatelessWidget {
  const ComposerRichTextEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.enabled = true,
  });

  final quill.QuillController controller;
  final FocusNode focusNode;
  final VoidCallback onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final plainText = RichContentCodec.toPlainText(controller);
    final words = plainText.trim().isEmpty
        ? 0
        : plainText.trim().split(RegExp(r'\s+')).length;

    return Semantics(
      label: l10n.composerRichEditorSemanticsLabel,
      textField: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.composerFormattingToolsLabel,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Directionality(
            textDirection: TextDirection.rtl,
            child: quill.QuillSimpleToolbar(
              controller: controller,
              config: const quill.QuillSimpleToolbarConfig(
                showFontFamily: false,
                showFontSize: false,
                showSmallButton: false,
                showStrikeThrough: false,
                showInlineCode: false,
                showColorButton: false,
                showBackgroundColorButton: false,
                showHeaderStyle: false,
                showListCheck: false,
                showCodeBlock: false,
                showQuote: false,
                showIndent: false,
                showSearchButton: false,
                showSubscript: false,
                showSuperscript: false,
                showAlignmentButtons: true,
                showDirection: true,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: enabled ? () => _openEmojiPicker(context) : null,
              icon: const Icon(Icons.emoji_emotions_outlined),
              label: Text(l10n.composerAddEmojiButton),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 180, maxHeight: 440),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: quill.QuillEditor.basic(
                  key: const ValueKey<String>('composer-rich-editor'),
                  controller: controller,
                  focusNode: focusNode,
                  config: quill.QuillEditorConfig(
                    placeholder: l10n.composerContentHint,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    minHeight: 180,
                    maxHeight: 440,
                    scrollable: true,
                    onTapOutsideEnabled: true,
                    customStyles: quill.DefaultStyles(
                      paragraph: quill.DefaultTextBlockStyle(
                        theme.textTheme.bodyLarge ?? const TextStyle(),
                        const quill.HorizontalSpacing(0, 0),
                        const quill.VerticalSpacing(0, 8),
                        const quill.VerticalSpacing(0, 0),
                        null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            liveRegion: true,
            label: l10n.composerContentCounterSemanticsLabel,
            child: Text(
              l10n.composerWordCharCount(words, plainText.characters.length),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEmojiPicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    const emojis = <String>[
      '🙂',
      '✅',
      '📌',
      '📣',
      '✨',
      '🎉',
      '📢',
      '🤝',
      '💡',
      '🔗',
    ];
    final emoji = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: emojis
              .map(
                (item) => Semantics(
                  label: l10n.composerInsertEmojiLabel(item),
                  button: true,
                  child: IconButton(
                    tooltip: l10n.composerInsertEmojiLabel(item),
                    iconSize: 28,
                    onPressed: () => Navigator.pop(context, item),
                    icon: Text(item),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
    if (emoji == null) {
      return;
    }
    final selection = controller.selection;
    controller.replaceText(
      selection.start,
      selection.end - selection.start,
      emoji,
      TextSelection.collapsed(offset: selection.start + emoji.length),
    );
    onChanged();
  }
}
