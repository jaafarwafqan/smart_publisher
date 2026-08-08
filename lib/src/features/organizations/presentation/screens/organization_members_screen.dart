import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/theme_tokens.dart';
import '../../application/current_organization_access.dart';
import '../../domain/entities/organization_member_entity.dart';

const _kAssignableRoles = <String>[
  'owner',
  'admin',
  'manager',
  'editor',
  'viewer',
];

String _roleLabel(String role, AppLocalizations l10n) {
  switch (role) {
    case 'owner':
      return l10n.orgSwitcherRoleOwner;
    case 'admin':
      return l10n.orgSwitcherRoleAdmin;
    case 'manager':
      return l10n.orgSwitcherRoleManager;
    case 'editor':
      return l10n.orgSwitcherRoleEditor;
    case 'viewer':
      return l10n.orgSwitcherRoleViewer;
    default:
      return role;
  }
}

/// Sprint 4 (Commercial SaaS): the UI counterpart to the backend's
/// already-existing `OrganizationMembershipController` — an owner/admin can
/// now add, re-role, and remove members of their CURRENT organization from
/// the app itself instead of needing direct API/database access. "Add
/// member" only attaches an EXISTING registered user by email; the
/// backend has no invite-by-email-to-a-new-account flow.
class OrganizationMembersScreen extends ConsumerStatefulWidget {
  const OrganizationMembersScreen({super.key});

  @override
  ConsumerState<OrganizationMembersScreen> createState() =>
      _OrganizationMembersScreenState();
}

class _OrganizationMembersScreenState
    extends ConsumerState<OrganizationMembersScreen> {
  List<OrganizationMemberEntity> _members = const <OrganizationMemberEntity>[];
  bool _loading = true;
  String? _error;
  String? _myUserId;
  final Set<int> _busyUserIds = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final session = await ref
        .read(authSessionControllerProvider)
        .currentSession();
    final result = await ref.read(organizationRepositoryProvider).getMembers();

    if (!mounted) {
      return;
    }

    setState(() {
      _myUserId = session?.user.id;
      _loading = false;
      if (result.isSuccess) {
        _members = result.data ?? const <OrganizationMemberEntity>[];
      } else {
        _error =
            result.message ??
            AppLocalizations.of(context)!.organizationMembersLoadError;
      }
    });
  }

  Future<void> _openAddMemberDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final access = ref.read(currentOrganizationAccessProvider).value;
    final canGrantOwner =
        access?.hasPermission(
          OrganizationPermissions.organizationTransferOwnership,
        ) ??
        false;
    final assignableRoles = canGrantOwner
        ? _kAssignableRoles
        : _kAssignableRoles.where((role) => role != 'owner').toList();

    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var selectedRole = assignableRoles.contains('viewer')
        ? 'viewer'
        : assignableRoles.first;
    String? dialogError;
    var submitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) {
                return;
              }
              setDialogState(() {
                submitting = true;
                dialogError = null;
              });
              final result = await ref
                  .read(organizationRepositoryProvider)
                  .addMember(
                    email: emailController.text.trim(),
                    role: selectedRole,
                  );
              if (result.isSuccess && result.data != null) {
                if (!mounted) {
                  return;
                }
                setState(() {
                  _members = <OrganizationMemberEntity>[
                    ..._members,
                    result.data!,
                  ];
                });
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.organizationMembersAddedSuccess)),
                );
              } else {
                setDialogState(() {
                  submitting = false;
                  dialogError =
                      result.message ?? l10n.organizationMembersLoadError;
                });
              }
            }

            return AlertDialog(
              title: Text(l10n.organizationMembersAddDialogTitle),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.organizationMembersAddDialogSubtitle,
                      style: Theme.of(dialogContext).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: l10n.organizationMembersEmailLabel,
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty || !text.contains('@')) {
                          return l10n.organizationMembersEmailValidationError;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: InputDecoration(
                        labelText: l10n.organizationMembersRoleLabel,
                      ),
                      items: assignableRoles
                          .map(
                            (role) => DropdownMenuItem<String>(
                              value: role,
                              child: Text(_roleLabel(role, l10n)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedRole = value);
                        }
                      },
                    ),
                    if (dialogError != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        dialogError!,
                        style: TextStyle(
                          color: Theme.of(dialogContext).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: submitting ? null : submit,
                  child: submitting
                      ? const SizedBox(
                          width: AppIconSize.sm,
                          height: AppIconSize.sm,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.organizationMembersAddSubmitButton),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateRole(OrganizationMemberEntity member, String role) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busyUserIds.add(member.userId));

    final result = await ref
        .read(organizationRepositoryProvider)
        .updateMemberRole(userId: member.userId, role: role);

    if (!mounted) {
      return;
    }

    setState(() {
      _busyUserIds.remove(member.userId);
      if (result.isSuccess) {
        _members = _members
            .map(
              (existing) => existing.userId == member.userId
                  ? OrganizationMemberEntity(
                      userId: existing.userId,
                      name: existing.name,
                      email: existing.email,
                      role: role,
                    )
                  : existing,
            )
            .toList(growable: false);
      }
    });

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? l10n.organizationMembersRoleUpdatedSuccess
              : result.message ?? l10n.organizationMembersLoadError,
        ),
      ),
    );
  }

  Future<void> _confirmRemove(OrganizationMemberEntity member) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.organizationMembersRemoveConfirmTitle),
        content: Text(
          l10n.organizationMembersRemoveConfirmMessage(member.name),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.organizationMembersRemoveButton),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _busyUserIds.add(member.userId));
    final result = await ref
        .read(organizationRepositoryProvider)
        .removeMember(userId: member.userId);

    if (!mounted) {
      return;
    }

    setState(() {
      _busyUserIds.remove(member.userId);
      if (result.isSuccess) {
        _members = _members
            .where((existing) => existing.userId != member.userId)
            .toList(growable: false);
      }
    });

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? l10n.organizationMembersRemovedSuccess
              : result.message ?? l10n.organizationMembersLoadError,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final access = ref.watch(currentOrganizationAccessProvider).value;
    final canInvite =
        access?.hasPermission(OrganizationPermissions.membersInvite) ?? false;
    final canChangeRole =
        access?.hasPermission(OrganizationPermissions.membersChangeRole) ??
        false;
    final canRemove =
        access?.hasPermission(OrganizationPermissions.membersRemove) ?? false;
    final canGrantOwner =
        access?.hasPermission(
          OrganizationPermissions.organizationTransferOwnership,
        ) ??
        false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.organizationMembersAppBarTitle)),
      floatingActionButton: canInvite
          ? FloatingActionButton.extended(
              onPressed: _openAddMemberDialog,
              icon: const Icon(Icons.person_add_outlined),
              label: Text(l10n.organizationMembersAddButton),
            )
          : null,
      body: _buildBody(l10n, canChangeRole, canRemove, canGrantOwner),
    );
  }

  Widget _buildBody(
    AppLocalizations l10n,
    bool canChangeRole,
    bool canRemove,
    bool canGrantOwner,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(_error!),
              const SizedBox(height: AppSpacing.md),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_members.isEmpty) {
      return Center(child: Text(l10n.organizationMembersEmptyMessage));
    }

    final assignableRoles = canGrantOwner
        ? _kAssignableRoles
        : _kAssignableRoles.where((role) => role != 'owner').toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.lg,
        ),
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];
          final isSelf = member.userId.toString() == _myUserId;
          final busy = _busyUserIds.contains(member.userId);

          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              title: Row(
                children: <Widget>[
                  Flexible(child: Text(member.name)),
                  if (isSelf) ...<Widget>[
                    const SizedBox(width: AppSpacing.xs),
                    Chip(
                      label: Text(l10n.organizationMembersYouLabel),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ],
              ),
              subtitle: Text(member.email),
              trailing: busy
                  ? const SizedBox(
                      width: AppIconSize.md,
                      height: AppIconSize.md,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (canChangeRole && !isSelf)
                          DropdownButton<String>(
                            value: assignableRoles.contains(member.role)
                                ? member.role
                                : null,
                            hint: Text(_roleLabel(member.role, l10n)),
                            underline: const SizedBox.shrink(),
                            items: assignableRoles
                                .map(
                                  (role) => DropdownMenuItem<String>(
                                    value: role,
                                    child: Text(_roleLabel(role, l10n)),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (role) {
                              if (role != null && role != member.role) {
                                _updateRole(member, role);
                              }
                            },
                          )
                        else
                          Text(_roleLabel(member.role, l10n)),
                        if (canRemove && !isSelf)
                          IconButton(
                            icon: const Icon(Icons.person_remove_outlined),
                            onPressed: () => _confirmRemove(member),
                          ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}
