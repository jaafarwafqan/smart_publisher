import 'package:dio/dio.dart';

import '../../../core/network/backend_error_message.dart';
import '../../../core/network/laravel_api.dart';
import '../../../core/network/network_client.dart';

enum AiOperation {
  spellCheck,
  improve,
  rewrite,
  shorten,
  expand,
  simplify,
  officialNews,
  advertisement,
  academicFormat,
  mediaFormat,
  suggestTitles,
  suggestClosing,
  suggestCallToAction,
  suggestHashtags,
  addEmojis,
  translate,
  adaptPlatforms,
}

enum AiTone {
  formal,
  academic,
  media,
  marketing,
  friendly,
  concise,
  enthusiastic,
}

extension AiOperationEndpoint on AiOperation {
  String get endpoint => switch (this) {
    AiOperation.spellCheck => LaravelEndpoints.aiSpellCheck,
    AiOperation.improve => LaravelEndpoints.aiImprove,
    AiOperation.rewrite => LaravelEndpoints.aiRewrite,
    AiOperation.shorten => LaravelEndpoints.aiShorten,
    AiOperation.expand => LaravelEndpoints.aiExpand,
    AiOperation.simplify => LaravelEndpoints.aiSimplify,
    AiOperation.officialNews => LaravelEndpoints.aiOfficialNews,
    AiOperation.advertisement => LaravelEndpoints.aiAdvertisement,
    AiOperation.academicFormat => LaravelEndpoints.aiAcademicFormat,
    AiOperation.mediaFormat => LaravelEndpoints.aiMediaFormat,
    AiOperation.suggestTitles => LaravelEndpoints.aiSuggestTitles,
    AiOperation.suggestClosing => LaravelEndpoints.aiSuggestClosing,
    AiOperation.suggestCallToAction => LaravelEndpoints.aiSuggestCallToAction,
    AiOperation.suggestHashtags => LaravelEndpoints.aiSuggestHashtags,
    AiOperation.addEmojis => LaravelEndpoints.aiAddEmojis,
    AiOperation.translate => LaravelEndpoints.aiTranslate,
    AiOperation.adaptPlatforms => LaravelEndpoints.aiAdaptPlatforms,
  };

  String get label => switch (this) {
    AiOperation.spellCheck => 'تدقيق النص',
    AiOperation.improve => 'تحسين الصياغة',
    AiOperation.rewrite => 'إعادة الصياغة',
    AiOperation.shorten => 'اختصار النص',
    AiOperation.expand => 'توسيع النص',
    AiOperation.simplify => 'تبسيط النص',
    AiOperation.officialNews => 'خبر رسمي',
    AiOperation.advertisement => 'صياغة إعلان',
    AiOperation.academicFormat => 'صياغة أكاديمية',
    AiOperation.mediaFormat => 'صياغة إعلامية',
    AiOperation.suggestTitles => 'اقتراح عنوان',
    AiOperation.suggestClosing => 'اقتراح خاتمة',
    AiOperation.suggestCallToAction => 'اقتراح دعوة',
    AiOperation.suggestHashtags => 'اقتراح وسوم',
    AiOperation.addEmojis => 'إضافة رموز باعتدال',
    AiOperation.translate => 'ترجمة',
    AiOperation.adaptPlatforms => 'تكييف للمنصات',
  };
}

class AiSuggestion {
  const AiSuggestion({
    required this.operation,
    required this.originalText,
    required this.proposedText,
    required this.suggestions,
    required this.appliesToSelection,
  });

  final AiOperation operation;
  final String originalText;
  final String proposedText;
  final List<String> suggestions;
  final bool appliesToSelection;
}

class PrePublishReport {
  const PrePublishReport({
    required this.errors,
    required this.warnings,
    required this.notices,
  });

  final List<String> errors;
  final List<String> warnings;
  final List<String> notices;

  bool get hasBlockingErrors => errors.isNotEmpty;
}

/// Real API client. It never contains a provider credential and intentionally
/// returns a proposal only; the composer owns applying any result.
class AiRepository {
  const AiRepository(this._networkClient);

  final NetworkClient _networkClient;

  Future<AiSuggestion> request({
    required AiOperation operation,
    required String text,
    required AiTone tone,
    required bool appliesToSelection,
    String? postId,
    String? targetLanguage,
    List<String> platforms = const <String>[],
  }) async {
    final numericPostId = int.tryParse(postId ?? '');
    final requestData = <String, dynamic>{'text': text, 'tone': tone.name};
    if (numericPostId != null) {
      requestData['post_id'] = numericPostId;
    }
    if (targetLanguage != null) {
      requestData['target_language'] = targetLanguage;
    }
    if (platforms.isNotEmpty) {
      requestData['platforms'] = platforms;
    }
    try {
      final response = await _networkClient.post(
        operation.endpoint,
        timeoutInSeconds: 30,
        data: requestData,
      );
      final payload = _payload(response.data);
      return AiSuggestion(
        operation: operation,
        originalText: payload['original_text']?.toString() ?? text,
        proposedText: payload['proposed_text']?.toString() ?? '',
        suggestions:
            (payload['suggestions'] as List<dynamic>? ?? const <dynamic>[])
                .map((item) => item.toString())
                .where((item) => item.isNotEmpty)
                .toList(growable: false),
        appliesToSelection: appliesToSelection,
      );
    } on DioException catch (error) {
      throw StateError(
        extractBackendErrorMessage(
              error.response?.data,
              error.response?.statusCode,
            ) ??
            'تعذر تنفيذ المساعدة الذكية. حاول مرة أخرى.',
      );
    }
  }

  Future<PrePublishReport> prePublishCheck(String postId) async {
    try {
      final response = await _networkClient.post(
        LaravelEndpoints.postPrePublishCheck(postId),
        timeoutInSeconds: 20,
      );
      final payload = _payload(response.data);
      return PrePublishReport(
        errors: _messages(payload['errors']),
        warnings: _messages(payload['warnings']),
        notices: _messages(payload['notices']),
      );
    } on DioException catch (error) {
      throw StateError(
        extractBackendErrorMessage(
              error.response?.data,
              error.response?.statusCode,
            ) ??
            'تعذر إجراء فحوصات ما قبل النشر.',
      );
    }
  }

  Map<String, dynamic> _payload(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    throw const FormatException('Invalid AI response payload.');
  }

  List<String> _messages(Object? raw) {
    if (raw is! List<dynamic>) {
      return const <String>[];
    }
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map((item) => item['message']?.toString() ?? '')
        .where((message) => message.isNotEmpty)
        .toList(growable: false);
  }
}
