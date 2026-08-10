import '../../organizations/application/current_organization_access.dart';
import '../domain/models/help_content_models.dart';

/// Filters guide content two independent ways: [visibleTo] hides
/// sections/articles the current member's role can never act on, and
/// [search] narrows by free-text query. Kept as plain functions (no
/// Riverpod provider, no repository) — this filters an in-memory static
/// content tree, not a network resource.
class HelpContentFilter {
  const HelpContentFilter._();

  /// `access == null` (still loading, or the account has no active
  /// organization) shows every section — the guide must stay readable
  /// (e.g. for a brand-new user with no organization yet reading "البدء
  /// باستخدام النظام"), just without the per-role badges resolved yet.
  static List<HelpSection> visibleTo(
    List<HelpSection> sections,
    OrganizationAccessState? access,
  ) {
    if (access == null) {
      return sections;
    }

    return sections
        .where((section) => _isVisible(section.requiredPermission, access))
        .map((section) {
          final articles = section.articles
              .where(
                (article) => _isVisible(article.requiredPermission, access),
              )
              .toList(growable: false);
          return HelpSection(
            id: section.id,
            title: section.title,
            icon: section.icon,
            requiredPermission: section.requiredPermission,
            articles: articles,
          );
        })
        .where((section) => section.articles.isNotEmpty)
        .toList(growable: false);
  }

  static bool _isVisible(
    RequiredPermission? required,
    OrganizationAccessState access,
  ) {
    if (required == null || !required.isRestricted) {
      return true;
    }
    return access.hasAnyPermission(required.anyOf!);
  }

  static List<HelpSection> search(List<HelpSection> sections, String query) {
    if (query.trim().isEmpty) {
      return sections;
    }
    return sections
        .where((section) => section.matches(query))
        .toList(growable: false);
  }
}
