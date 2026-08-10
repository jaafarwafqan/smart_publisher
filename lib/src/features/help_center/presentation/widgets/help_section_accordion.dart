import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../domain/models/help_content_models.dart';

/// One accordion group per [HelpSection], each article rendered as its own
/// inner expansion tile with numbered steps, standalone notes, an optional
/// jump-to-screen button, and any article-level FAQs.
class HelpSectionAccordion extends StatelessWidget {
  const HelpSectionAccordion({
    super.key,
    required this.section,
    this.initiallyExpanded = false,
  });

  final HelpSection section;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey<String>(section.id),
        initiallyExpanded: initiallyExpanded,
        leading: Icon(section.icon),
        title: Text(
          section.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
        children: section.articles
            .map((article) => _HelpArticleTile(article: article))
            .toList(growable: false),
      ),
    );
  }
}

class _HelpArticleTile extends StatelessWidget {
  const _HelpArticleTile({required this.article});

  final HelpArticle article;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final roleHint = article.requiredPermission?.roleHint;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  article.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (roleHint != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.sm,
                  ),
                  child: StatusPill(
                    label: l10n.userGuideRequiredPermissionBadge(roleHint),
                    tone: PillTone.warning,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(article.summary, style: Theme.of(context).textTheme.bodyMedium),
          if (article.steps.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            ...article.steps.asMap().entries.map(
              (entry) => _NumberedStep(index: entry.key + 1, step: entry.value),
            ),
          ],
          if (article.notes.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            ...article.notes.map((note) => _NoteCallout(text: note)),
          ],
          if (article.faqs.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            ...article.faqs.map(
              (faq) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      faq.question,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Text(
                      faq.answer,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (article.actionLabel != null &&
              article.actionRoute != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: () => context.push(article.actionRoute!),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: Text(article.actionLabel!),
              ),
            ),
          ],
          const Divider(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _NumberedStep extends StatelessWidget {
  const _NumberedStep({required this.index, required this.step});

  final int index;
  final HelpStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 11,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(step.text, style: Theme.of(context).textTheme.bodyMedium),
                if (step.note != null)
                  Text(
                    step.note!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCallout extends StatelessWidget {
  const _NoteCallout({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: 16,
            color: colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
