import 'package:flutter/widgets.dart';

/// A single numbered step inside a [HelpArticle] — e.g. step 3 of "ربط حساب
/// Facebook". [note] is an optional inline caveat shown under the step
/// (e.g. a warning that a token must never be pasted into a chat).
class HelpStep {
  const HelpStep(this.text, {this.note});

  final String text;
  final String? note;
}

/// One FAQ entry, either in the guide's global FAQ section or attached to a
/// specific article.
class HelpFaq {
  const HelpFaq({required this.question, required this.answer});

  final String question;
  final String answer;
}

/// One troubleshooting entry: a symptom the user recognizes and a plain,
/// non-technical fix — never a stack trace or internal error code beyond
/// the HTTP status the backend already returns to the client.
class HelpTroubleshootingItem {
  const HelpTroubleshootingItem({required this.symptom, required this.fix});

  final String symptom;
  final String fix;
}

/// Gates an [HelpArticle]/[HelpSection] to whoever holds this permission —
/// matches `OrganizationPermissions` string constants 1:1 so the guide never
/// invents a capability the backend doesn't actually enforce. `null` means
/// visible to every authenticated member regardless of role.
class RequiredPermission {
  const RequiredPermission({this.anyOf, this.roleHint});

  /// Any one of these `OrganizationPermissions.*` values is sufficient.
  final List<String>? anyOf;

  /// A short role label used only for the visual badge (e.g. "Owner"),
  /// never for the actual gating decision — [anyOf] is the source of truth.
  final String? roleHint;

  bool get isRestricted => anyOf != null && anyOf!.isNotEmpty;
}

/// One collapsible article inside a [HelpSection] — a self-contained how-to
/// with optional steps, notes, and a jump-to-screen action.
class HelpArticle {
  const HelpArticle({
    required this.id,
    required this.title,
    required this.summary,
    this.steps = const <HelpStep>[],
    this.notes = const <String>[],
    this.faqs = const <HelpFaq>[],
    this.requiredPermission,
    this.actionLabel,
    this.actionRoute,
  });

  final String id;
  final String title;
  final String summary;
  final List<HelpStep> steps;

  /// Standalone callouts (important warnings, "لا يظهر الحساب المطلوب؟"
  /// style notes) rendered without a step number.
  final List<String> notes;
  final List<HelpFaq> faqs;
  final RequiredPermission? requiredPermission;

  /// "انتقل إلى الحسابات الاجتماعية"-style jump button. Both must be set
  /// together or both omitted.
  final String? actionLabel;
  final String? actionRoute;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return true;
    }
    if (title.toLowerCase().contains(q) || summary.toLowerCase().contains(q)) {
      return true;
    }
    return steps.any((step) => step.text.toLowerCase().contains(q));
  }
}

/// One row of the role → capability table in the "الأدوار والصلاحيات"
/// section. `grantedTo` lists the exact `OrganizationRole` values (owner /
/// admin / manager / editor / viewer) the backend's
/// `OrganizationRole::permissions()` actually grants this action to — kept
/// as a role-name list here purely for a compact ✓/— table rendering, not
/// as a second authorization source (the app never branches UI logic on
/// these strings; see [RequiredPermission] for that).
class RolePermissionRow {
  const RolePermissionRow({required this.action, required this.grantedTo});

  final String action;
  final List<String> grantedTo;

  bool grants(String role) => grantedTo.contains(role);
}

/// A top-level section of the guide (e.g. "ربط حساب Facebook"), rendered as
/// one entry in the table of contents and one accordion group.
class HelpSection {
  const HelpSection({
    required this.id,
    required this.title,
    required this.icon,
    this.articles = const <HelpArticle>[],
    this.requiredPermission,
  });

  final String id;
  final String title;
  final IconData icon;
  final List<HelpArticle> articles;

  /// Hides the whole section for anyone lacking this — used sparingly (e.g.
  /// "إدارة أعضاء المؤسسة" for Admin/Owner only). Most sections stay visible
  /// to everyone and instead gate individual articles/action buttons.
  final RequiredPermission? requiredPermission;

  bool matches(String query) {
    if (query.trim().isEmpty) {
      return true;
    }
    return title.toLowerCase().contains(query.trim().toLowerCase()) ||
        articles.any((article) => article.matches(query));
  }
}
