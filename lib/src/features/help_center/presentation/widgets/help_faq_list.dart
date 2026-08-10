import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/help_content_models.dart';

class HelpFaqList extends StatelessWidget {
  const HelpFaqList({super.key, required this.faqs});

  final List<HelpFaq> faqs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: faqs
          .map(
            (faq) => Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ExpansionTile(
                title: Text(
                  faq.question,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[Text(faq.answer)],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
