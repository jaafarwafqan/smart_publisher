part of 'platform_admin_screens.dart';

class _AdminGuidePoint extends StatelessWidget {
  const _AdminGuidePoint({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value, this.icon, {this.danger = false});

  final String label;
  final int value;
  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    // Width now comes from the enclosing AdaptiveCardGrid, which sizes
    // every card in a row equally rather than this card carrying its own
    // fixed width (that fixed width was what produced "4 then 2" rows
    // with wasted trailing space — see the call site).
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: <Widget>[
            Icon(icon, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    value.toString(),
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: color),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.onViewAll});
  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      TextButton(
        onPressed: onViewAll,
        child: Text(AppLocalizations.of(context)!.platformAdminViewAllButton),
      ),
    ],
  );
}

class _OrganizationList extends StatelessWidget {
  const _OrganizationList({
    required this.page,
    required this.onStatus,
    required this.onEdit,
    required this.onDelete,
    required this.onFixPrimaryOwner,
    required this.onPage,
  });
  final PlatformPage<PlatformOrganization> page;
  final ValueChanged<PlatformOrganization> onStatus;
  final ValueChanged<PlatformOrganization> onEdit;
  final ValueChanged<PlatformOrganization> onDelete;
  final ValueChanged<PlatformOrganization> onFixPrimaryOwner;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: <Widget>[
        Text(
          l10n.platformAdminOrgCountLabel(page.total),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...page.items.map(
          (organization) => _OrganizationTile(
            organization: organization,
            onTap: () => context.push(
              RouteNames.platformOrganizationDetailPath.replaceFirst(
                ':id',
                organization.id.toString(),
              ),
            ),
            onFixPrimaryOwner: () => onFixPrimaryOwner(organization),
            actions: PopupMenuButton<String>(
              onSelected: (action) {
                switch (action) {
                  case 'edit':
                    onEdit(organization);
                    break;
                  case 'delete':
                    onDelete(organization);
                    break;
                  default:
                    onStatus(organization);
                }
              },
              itemBuilder: (_) => <PopupMenuEntry<String>>[
                PopupMenuItem(
                  value: 'edit',
                  child: Text(l10n.platformAdminEditOrgNameMenuItem),
                ),
                PopupMenuItem(
                  value: 'status',
                  child: Text(
                    organization.isActive
                        ? l10n.platformAdminDisableOrgTitle
                        : l10n.platformAdminReactivateMenuItem,
                  ),
                ),
                // Deletion is only offered once the organization is already
                // deactivated — mirrors the backend's own real precondition
                // (AdminOrganizationController::destroy()) instead of
                // showing an action that would just 422.
                if (!organization.isActive)
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(l10n.platformAdminDeleteOrgMenuItem),
                  ),
              ],
            ),
          ),
        ),
        _Pagination(page: page, onPage: onPage),
      ],
    );
  }
}

class _OrganizationTile extends StatelessWidget {
  const _OrganizationTile({
    required this.organization,
    required this.onTap,
    this.actions,
    this.onFixPrimaryOwner,
  });
  final PlatformOrganization organization;
  final VoidCallback onTap;
  final Widget? actions;
  // Null on the read-only dashboard summary tile — the warning still shows
  // there, just without an action button.
  final VoidCallback? onFixPrimaryOwner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusLabel = organization.isActive
        ? l10n.platformAdminOrgActiveStatus
        : l10n.platformAdminOrgInactiveStatus;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Icon(
            organization.isActive
                ? Icons.domain_outlined
                : Icons.domain_disabled_outlined,
          ),
        ),
        title: Text(organization.name),
        subtitle: organization.primaryOwnerMissing
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      '${l10n.platformAdminPrimaryOwnerMissingLabel} · '
                      '${l10n.platformAdminMembersCountLabel(organization.membersCount)}',
                      style: TextStyle(color: AppColors.warning),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onFixPrimaryOwner != null)
                    TextButton(
                      onPressed: onFixPrimaryOwner,
                      child: Text(l10n.platformAdminFixButton),
                    ),
                ],
              )
            : Text(
                l10n.platformAdminOrgSummaryLine(
                  organization.primaryOwner?.name ?? '—',
                  organization.membersCount,
                  _formatDate(organization.createdAt, l10n),
                ),
              ),
        trailing: actions == null
            ? StatusPill(
                label: statusLabel,
                tone: organization.isActive
                    ? PillTone.success
                    : PillTone.danger,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  StatusPill(
                    label: statusLabel,
                    tone: organization.isActive
                        ? PillTone.success
                        : PillTone.danger,
                  ),
                  actions!,
                ],
              ),
      ),
    );
  }
}

/// Replaces the vague "لا يوجد مالك فعّال" fallback text the 2026-08-12
/// audit flagged with an explicit, actionable alert: what's wrong, and a
/// button that calls the reconcile-primary-owner endpoint right from here.
class _PrimaryOwnerMissingBanner extends StatelessWidget {
  const _PrimaryOwnerMissingBanner({required this.onFix});
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.platformAdminPrimaryOwnerMissingLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.platformAdminPrimaryOwnerMissingBannerBody),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: onFix,
            child: Text(l10n.platformAdminFixButton),
          ),
        ],
      ),
    );
  }
}

class _OrganizationDetailsContent extends StatelessWidget {
  const _OrganizationDetailsContent({
    required this.details,
    required this.onFixPrimaryOwner,
    required this.onGrantSubscription,
    required this.onExtendSubscription,
    required this.onGrantSubscriptionTrial,
    required this.onRevertSubscription,
  });
  final PlatformOrganizationDetails details;
  final VoidCallback onFixPrimaryOwner;
  final VoidCallback onGrantSubscription;
  final VoidCallback onExtendSubscription;
  final VoidCallback onGrantSubscriptionTrial;
  final VoidCallback onRevertSubscription;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final organization = details.organization;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: <Widget>[
        Text(
          organization.name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (organization.primaryOwnerMissing) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          _PrimaryOwnerMissingBanner(onFix: onFixPrimaryOwner),
        ],
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            StatusPill(
              label: organization.isActive
                  ? l10n.platformAdminOrgActiveStatus
                  : l10n.platformAdminOrgInactiveStatus,
              tone: organization.isActive ? PillTone.success : PillTone.danger,
            ),
            StatusPill(
              label: l10n.platformAdminMembersCountLabel(
                organization.membersCount,
              ),
            ),
            StatusPill(
              label: l10n.platformAdminLastActivityLabel(
                _formatDate(organization.lastActivityAt, l10n),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _DetailSection(
          title: l10n.platformAdminMembersSectionTitle,
          child: details.members.isEmpty
              ? AppEmptyState(
                  compact: true,
                  title: l10n.platformAdminNoMembersTitle,
                  message: l10n.platformAdminNoMembersMessage,
                )
              : Column(
                  children: details.members
                      .map(
                        (member) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Text(
                              member.user.name.isEmpty
                                  ? '?'
                                  : member.user.name.substring(0, 1),
                            ),
                          ),
                          title: Text(member.user.name),
                          subtitle: Text(member.user.email),
                          trailing: StatusPill(
                            label: _roleLabel(member.role, l10n),
                            tone: member.status == 'active'
                                ? PillTone.neutral
                                : PillTone.warning,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SubscriptionSection(
          subscription: organization.subscription,
          onGrant: onGrantSubscription,
          onExtend: onExtendSubscription,
          onTrial: onGrantSubscriptionTrial,
          onRevert: onRevertSubscription,
        ),
        const SizedBox(height: AppSpacing.lg),
        _DetailSection(
          title: l10n.platformAdminSocialAccountsSectionTitle,
          child: details.socialAccounts.isEmpty
              ? AppEmptyState(
                  compact: true,
                  title: l10n.platformAdminNoSocialAccountsTitle,
                  message: l10n.platformAdminNoSocialAccountsMessage,
                )
              : Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: details.socialAccounts
                      .map(
                        (account) => StatusPill(
                          label:
                              '${account['provider'] ?? l10n.platformAdminUnnamedAccountFallback} · '
                              '${account['account_name'] ?? account['account_username'] ?? l10n.platformAdminUnnamedFallback}',
                          tone: account['is_active'] == true
                              ? PillTone.success
                              : PillTone.warning,
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _DetailSection(
          title: l10n.platformAdminPostsSummarySectionTitle,
          child: details.postsSummary.isEmpty
              ? AppEmptyState(
                  compact: true,
                  title: l10n.platformAdminNoPostsTitle,
                  message: l10n.platformAdminNoPostsMessage,
                )
              : Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: details.postsSummary.entries
                      .map(
                        (entry) =>
                            StatusPill(label: '${entry.key}: ${entry.value}'),
                      )
                      .toList(growable: false),
                ),
        ),
      ],
    );
  }
}

/// Prepaid-billing model (2026-08-21) — the manual side of
/// BillingPeriodGrantService: grant/extend/trial/revert-to-free. See
/// AdminSubscriptionController on the backend for the actual endpoints.
class _SubscriptionSection extends StatelessWidget {
  const _SubscriptionSection({
    required this.subscription,
    required this.onGrant,
    required this.onExtend,
    required this.onTrial,
    required this.onRevert,
  });

  final PlatformOrganizationSubscription? subscription;
  final VoidCallback onGrant;
  final VoidCallback onExtend;
  final VoidCallback onTrial;
  final VoidCallback onRevert;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subscription = this.subscription;
    return _DetailSection(
      title: l10n.platformAdminSubscriptionSectionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              StatusPill(
                label:
                    subscription?.planName ??
                    l10n.platformAdminSubscriptionNoPlanLabel,
              ),
              StatusPill(
                label: _statusLabel(subscription?.status, l10n),
                tone: _statusTone(subscription?.status),
              ),
              StatusPill(
                label: subscription?.isUnbounded ?? true
                    ? l10n.platformAdminSubscriptionNoExpiryLabel
                    : l10n.platformAdminSubscriptionPeriodEndLabel(
                        _formatDate(subscription?.currentPeriodEnd, l10n),
                      ),
              ),
              if (subscription?.isManuallyGranted ?? false)
                StatusPill(
                  label: l10n.platformAdminSubscriptionManuallyGrantedLabel,
                  tone: PillTone.warning,
                ),
            ],
          ),
          if (subscription?.grantedReason case final String reason
              when reason.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.platformAdminSubscriptionGrantedReasonLabel(reason),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              FilledButton.icon(
                onPressed: onGrant,
                icon: const Icon(Icons.card_membership_outlined),
                label: Text(l10n.platformAdminGrantSubscriptionButton),
              ),
              OutlinedButton.icon(
                onPressed: onExtend,
                icon: const Icon(Icons.more_time_outlined),
                label: Text(l10n.platformAdminExtendSubscriptionButton),
              ),
              OutlinedButton.icon(
                onPressed: onTrial,
                icon: const Icon(Icons.schedule_outlined),
                label: Text(l10n.platformAdminGrantTrialButton),
              ),
              TextButton.icon(
                onPressed: onRevert,
                icon: Icon(
                  Icons.restart_alt_outlined,
                  color: Theme.of(context).colorScheme.error,
                ),
                label: Text(
                  l10n.platformAdminRevertSubscriptionButton,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String? status, AppLocalizations l10n) {
    return switch (status) {
      'active' => l10n.platformAdminSubscriptionStatusActive,
      'trialing' => l10n.platformAdminSubscriptionStatusTrialing,
      'expired' => l10n.platformAdminSubscriptionStatusExpired,
      'canceled' => l10n.platformAdminSubscriptionStatusCanceled,
      'past_due' => l10n.platformAdminSubscriptionStatusPastDue,
      _ => l10n.platformAdminSubscriptionStatusUnknown,
    };
  }

  PillTone _statusTone(String? status) => switch (status) {
    'active' => PillTone.success,
    'trialing' => PillTone.neutral,
    'expired' || 'canceled' || 'past_due' => PillTone.danger,
    _ => PillTone.neutral,
  };
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    ),
  );
}

class _UserList extends StatelessWidget {
  const _UserList({
    required this.page,
    required this.onStatus,
    required this.onPlatformRole,
    required this.onEdit,
    required this.onMemberships,
    required this.onDelete,
    required this.onPage,
  });
  final PlatformPage<PlatformUser> page;
  final ValueChanged<PlatformUser> onStatus;
  final ValueChanged<PlatformUser> onPlatformRole;
  final ValueChanged<PlatformUser> onEdit;
  final ValueChanged<PlatformUser> onMemberships;
  final ValueChanged<PlatformUser> onDelete;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: <Widget>[
        Text(
          l10n.platformAdminUserCountLabel(page.total),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...page.items.map(
          (user) => _UserTile(
            user: user,
            actions: PopupMenuButton<String>(
              onSelected: (action) {
                switch (action) {
                  case 'edit':
                    onEdit(user);
                    break;
                  case 'memberships':
                    onMemberships(user);
                    break;
                  case 'status':
                    onStatus(user);
                    break;
                  case 'role':
                    onPlatformRole(user);
                    break;
                  case 'delete':
                    onDelete(user);
                    break;
                }
              },
              itemBuilder: (_) => <PopupMenuEntry<String>>[
                PopupMenuItem(
                  value: 'edit',
                  child: Text(l10n.platformAdminEditUserDataMenuItem),
                ),
                PopupMenuItem(
                  value: 'memberships',
                  child: Text(l10n.platformAdminManageMembershipsMenuItem),
                ),
                PopupMenuItem(
                  value: 'role',
                  child: Text(
                    user.isSuperAdmin
                        ? l10n.platformAdminRevokeSuperAdminTitle
                        : l10n.platformAdminGrantSuperAdminTitle,
                  ),
                ),
                PopupMenuItem(
                  value: 'status',
                  child: Text(
                    user.isActive
                        ? l10n.platformAdminDeactivateAccountTitle
                        : l10n.platformAdminActivateAccountTitle,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(l10n.platformAdminDeleteUserMenuItem),
                ),
              ],
            ),
          ),
        ),
        _Pagination(page: page, onPage: onPage),
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, this.actions});
  final PlatformUser user;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(user.name.isEmpty ? '?' : user.name.substring(0, 1)),
        ),
        title: Text(user.name),
        subtitle: Text(
          '${user.email}\n${user.memberships.isEmpty ? l10n.platformAdminNoOrgLabel : user.memberships.map((membership) => '${membership.organizationName} (${_roleLabel(membership.role, l10n)})').join(' · ')}',
        ),
        isThreeLine: user.memberships.isNotEmpty,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (user.isSuperAdmin)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                child: StatusPill(
                  label: l10n.platformAdminSuperAdminBadge,
                  tone: PillTone.warning,
                ),
              ),
            StatusPill(
              label: user.isActive
                  ? l10n.platformAdminActiveLabel
                  : l10n.platformAdminInactiveLabel,
              tone: user.isActive ? PillTone.success : PillTone.danger,
            ),
            if (actions case final Widget actions) actions,
          ],
        ),
      ),
    );
  }
}

class _Pagination<T> extends StatelessWidget {
  const _Pagination({required this.page, required this.onPage});
  final PlatformPage<T> page;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    if (page.lastPage <= 1) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    // Code-quality review (2026-08-17), item B4/3.2: same fix as
    // AuditLogPagination in organization_audit_log_screen.dart — was
    // hardcoded regardless of locale (correct for RTL, backward in LTR).
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final previousIcon = isRtl ? Icons.chevron_right : Icons.chevron_left;
    final nextIcon = isRtl ? Icons.chevron_left : Icons.chevron_right;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          OutlinedButton.icon(
            onPressed: page.currentPage > 1
                ? () => onPage(page.currentPage - 1)
                : null,
            icon: Icon(previousIcon),
            label: Text(l10n.platformAdminPreviousPageButton),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              l10n.platformAdminPageIndicator(page.currentPage, page.lastPage),
            ),
          ),
          OutlinedButton.icon(
            onPressed: page.currentPage < page.lastPage
                ? () => onPage(page.currentPage + 1)
                : null,
            icon: Icon(nextIcon),
            label: Text(l10n.commonNext),
          ),
        ],
      ),
    );
  }
}

class _PlatformErrorState extends StatelessWidget {
  const _PlatformErrorState({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isForbidden =
        error is PlatformAdminException &&
        (error as PlatformAdminException).isForbidden;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AppEmptyState(
          icon: isForbidden ? Icons.lock_outline : Icons.cloud_off_outlined,
          title: isForbidden
              ? l10n.platformAdminUnauthorizedTitle
              : l10n.platformAdminLoadErrorTitle,
          message: isForbidden
              ? l10n.platformAdminForbiddenMessage
              : l10n.platformAdminGenericLoadErrorMessage,
          actionLabel: isForbidden ? null : l10n.commonRetry,
          onAction: isForbidden ? null : onRetry,
        ),
      ),
    );
  }
}
