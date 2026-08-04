import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

/// Bold/Italic wrap the current selection in `**`/`_` markers — real markup
/// only Telegram can render; every other platform gets the markers stripped
/// at publish time. Emoji inserts a real Unicode character at the cursor.
class ComposerFormattingToolbar extends StatelessWidget {
  const ComposerFormattingToolbar({super.key, required this.controller});

  final TextEditingController controller;

  void _wrapSelection(String marker) {
    final selection = controller.selection;
    final text = controller.text;

    if (!selection.isValid || selection.isCollapsed) {
      final insertAt = selection.isValid ? selection.start : text.length;
      final newText = text.replaceRange(insertAt, insertAt, '$marker$marker');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: insertAt + marker.length),
      );
      return;
    }

    final selectedText = text.substring(selection.start, selection.end);
    final wrapped = '$marker$selectedText$marker';
    final newText = text.replaceRange(selection.start, selection.end, wrapped);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + wrapped.length,
      ),
    );
  }

  Future<void> _openEmojiPicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: 320,
        child: EmojiPicker(textEditingController: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: <Widget>[
        IconButton(
          tooltip: l10n.composerFormatBoldTooltip,
          onPressed: () => _wrapSelection('**'),
          icon: const Icon(Icons.format_bold),
        ),
        IconButton(
          tooltip: l10n.composerFormatItalicTooltip,
          onPressed: () => _wrapSelection('_'),
          icon: const Icon(Icons.format_italic),
        ),
        IconButton(
          tooltip: l10n.composerInsertEmojiTooltip,
          onPressed: () => _openEmojiPicker(context),
          icon: const Icon(Icons.emoji_emotions_outlined),
        ),
      ],
    );
  }
}
