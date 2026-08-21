part of 'platform_admin_screens.dart';

class _CreateOrganizationDialog extends ConsumerStatefulWidget {
  const _CreateOrganizationDialog();

  @override
  ConsumerState<_CreateOrganizationDialog> createState() =>
      _CreateOrganizationDialogState();
}

class _CreateOrganizationDialogState
    extends ConsumerState<_CreateOrganizationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _ownerName = TextEditingController();
  final _ownerEmail = TextEditingController();
  final _ownerPassword = TextEditingController();
  bool _useExistingOwner = false;
  bool _submitting = false;
  String? _error;
  PlatformUser? _selectedOwner;
  late Future<PlatformPage<PlatformUser>> _availableUsers;

  @override
  void initState() {
    super.initState();
    // Fetched eagerly regardless of _useExistingOwner (so switching to
    // "existing owner" later doesn't need to wait), but the FutureBuilder
    // that actually consumes this only builds once that toggle is flipped
    // — so a rejection before then would otherwise have zero listeners
    // attached at the moment it rejects, which Dart reports as an
    // "unhandled" async error even though it's genuinely handled once the
    // FutureBuilder builds. ignore() marks it handled for that reporting
    // purpose only — it does not consume or transform the result, so the
    // FutureBuilder still receives the real value/error normally.
    _availableUsers = ref.read(platformAdminRepositoryProvider).getUsers();
    _availableUsers.ignore();
  }

  @override
  void dispose() {
    _name.dispose();
    _ownerName.dispose();
    _ownerEmail.dispose();
    _ownerPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(platformAdminRepositoryProvider)
          .createOrganization(
            name: _name.text.trim(),
            ownerUserId: _useExistingOwner ? _selectedOwner?.id : null,
            newOwnerName: _useExistingOwner ? null : _ownerName.text.trim(),
            newOwnerEmail: _useExistingOwner ? null : _ownerEmail.text.trim(),
            newOwnerPassword: _useExistingOwner ? null : _ownerPassword.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on PlatformAdminException catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error.message;
        });
      }
    } catch (error, stackTrace) {
      // A live E2E test found this dialog getting permanently stuck showing
      // its loading spinner after the organization was genuinely created
      // server-side — root cause: this catch only handled
      // PlatformAdminException, so any other exception (a response-parsing
      // edge case, a client-side error unrelated to the HTTP call itself)
      // propagated uncaught, and _submitting never reset. Any exception
      // now surfaces as a real error and re-enables the form instead of
      // leaving it stuck forever. The raw error is logged for
      // diagnosis (the exact wiring point a real Sentry/Crashlytics
      // integration would hook into) but never shown to the user — an
      // unclassified exception's message could contain implementation
      // detail that isn't meant to be user-facing.
      AppLogger.e('Unexpected error creating organization', error, stackTrace);
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = AppLocalizations.of(context)!.platformAdminUnexpectedError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.platformAdminCreateOrgButton),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: l10n.platformAdminOrgNameLabel,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.platformAdminOrgNameRequiredError
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<bool>(
                  segments: <ButtonSegment<bool>>[
                    ButtonSegment(
                      value: false,
                      label: Text(l10n.platformAdminNewOwnerSegment),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text(l10n.platformAdminExistingOwnerSegment),
                    ),
                  ],
                  selected: <bool>{_useExistingOwner},
                  onSelectionChanged: (value) =>
                      setState(() => _useExistingOwner = value.first),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_useExistingOwner)
                  FutureBuilder<PlatformPage<PlatformUser>>(
                    future: _availableUsers,
                    builder: (context, snapshot) {
                      // A failed fetch (network error, backend error) must not
                      // spin forever — only snapshot.hasData was checked
                      // before, so an error here left this picker showing an
                      // infinite loading spinner with no way to notice
                      // anything had actually gone wrong or retry. The raw
                      // error is logged (never shown raw to the user — same
                      // reasoning as the _submit() catch-alls above) and the
                      // message/button are localized rather than hardcoded
                      // Arabic, which would render even under an English
                      // locale.
                      if (snapshot.hasError) {
                        AppLogger.e(
                          'Failed to load platform admin owner picker users',
                          snapshot.error,
                          snapshot.stackTrace,
                        );
                        return Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                l10n.platformAdminOwnerListLoadError,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              OutlinedButton(
                                onPressed: () => setState(() {
                                  _availableUsers = ref
                                      .read(platformAdminRepositoryProvider)
                                      .getUsers();
                                }),
                                child: Text(l10n.commonRetry),
                              ),
                            ],
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: CircularProgressIndicator(),
                        );
                      }
                      final users = snapshot.data!.items
                          .where((user) => user.isActive)
                          .toList(growable: false);
                      return DropdownButtonFormField<PlatformUser>(
                        initialValue: _selectedOwner,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.platformAdminOwnerFieldLabel,
                        ),
                        items: users
                            .map(
                              (user) => DropdownMenuItem(
                                value: user,
                                child: Text(
                                  '${user.name} — ${user.email}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) =>
                            setState(() => _selectedOwner = value),
                        validator: (value) => value == null
                            ? l10n.platformAdminSelectActiveOwnerError
                            : null,
                      );
                    },
                  )
                else ...<Widget>[
                  TextFormField(
                    controller: _ownerName,
                    decoration: InputDecoration(
                      labelText: l10n.platformAdminNewOwnerNameLabel,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.platformAdminNewOwnerNameRequiredError
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _ownerEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: l10n.platformAdminNewOwnerEmailLabel,
                    ),
                    validator: (value) => value == null || !value.contains('@')
                        ? l10n.platformAdminValidEmailRequiredError
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _ownerPassword,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l10n.platformAdminNewOwnerPasswordLabel,
                    ),
                    validator: (value) => value == null || value.length < 12
                        ? l10n.platformAdminPasswordMinLengthError
                        : null,
                  ),
                ],
                if (_error != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.platformAdminCreateOrgSubmitButton),
        ),
      ],
    );
  }
}

class _EditOrganizationDialog extends ConsumerStatefulWidget {
  const _EditOrganizationDialog({required this.organization});

  final PlatformOrganization organization;

  @override
  ConsumerState<_EditOrganizationDialog> createState() =>
      _EditOrganizationDialogState();
}

class _EditOrganizationDialogState
    extends ConsumerState<_EditOrganizationDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.organization.name,
  );
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      setState(
        () => _error = AppLocalizations.of(
          context,
        )!.platformAdminOrgNameRequiredError,
      );
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(platformAdminRepositoryProvider)
          .updateOrganization(
            id: widget.organization.id,
            name: _name.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on PlatformAdminException catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error.message;
        });
      }
    } catch (error, stackTrace) {
      // Same hardening as _CreateOrganizationDialog._submit() — see its
      // comment. Any exception must reset _submitting, not just the
      // specific HTTP-layer one, and the raw error is logged rather than
      // shown to the user.
      AppLogger.e('Unexpected error updating organization', error, stackTrace);
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = AppLocalizations.of(context)!.platformAdminUnexpectedError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.platformAdminEditOrgNameMenuItem),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.platformAdminOrgNameLabel,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

class _CreateUserDialog extends ConsumerStatefulWidget {
  const _CreateUserDialog();
  @override
  ConsumerState<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  String? _error;
  int _organizationId = -1;
  String _membershipRole = 'viewer';
  late final Future<PlatformPage<PlatformOrganization>> _organizations;

  @override
  void initState() {
    super.initState();
    _organizations = ref
        .read(platformAdminRepositoryProvider)
        .getOrganizations(perPage: 100);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(platformAdminRepositoryProvider)
          .createUser(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            organizationId: _organizationId == -1 ? null : _organizationId,
            membershipRole: _organizationId == -1 ? null : _membershipRole,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on PlatformAdminException catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error.message;
        });
      }
    } catch (error, stackTrace) {
      // Same hardening as _CreateOrganizationDialog._submit() — see its
      // comment. This dialog had the identical gap: any non-
      // PlatformAdminException left _submitting stuck at true forever.
      AppLogger.e('Unexpected error creating user', error, stackTrace);
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = AppLocalizations.of(context)!.platformAdminUnexpectedError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.platformAdminAddUserButton),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: l10n.platformAdminNameLabel,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l10n.platformAdminNameRequiredError
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.platformAdminEmailLabel,
                ),
                validator: (value) => value == null || !value.contains('@')
                    ? l10n.platformAdminValidEmailShortError
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.platformAdminPasswordLabel,
                ),
                validator: (value) => value == null || value.length < 12
                    ? l10n.platformAdminPasswordMinLengthError
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              FutureBuilder<PlatformPage<PlatformOrganization>>(
                future: _organizations,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      DropdownButton<int>(
                        value: _organizationId,
                        items: <DropdownMenuItem<int>>[
                          DropdownMenuItem(
                            value: -1,
                            child: Text(l10n.platformAdminNoOrgOption),
                          ),
                          ...snapshot.data!.items.map(
                            (organization) => DropdownMenuItem(
                              value: organization.id,
                              child: Text(organization.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => _organizationId = value);
                        },
                      ),
                      if (_organizationId != -1)
                        DropdownButton<String>(
                          value: _membershipRole,
                          items: _membershipRoles
                              .map(
                                (role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(_roleLabel(role, l10n)),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() => _membershipRole = value);
                          },
                        ),
                    ],
                  );
                },
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.platformAdminAddButtonShort),
        ),
      ],
    );
  }
}

class _EditUserDialog extends ConsumerStatefulWidget {
  const _EditUserDialog({required this.user});
  final PlatformUser user;
  @override
  ConsumerState<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends ConsumerState<_EditUserDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.user.name,
  );
  late final TextEditingController _email = TextEditingController(
    text: widget.user.email,
  );
  bool _submitting = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(platformAdminRepositoryProvider)
          .updateUser(
            id: widget.user.id,
            name: _name.text.trim(),
            email: _email.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on PlatformAdminException catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error.message;
        });
      }
    } catch (error, stackTrace) {
      // Same hardening as _CreateOrganizationDialog._submit() — see its
      // comment. This dialog had the identical gap: any non-
      // PlatformAdminException left _submitting stuck at true forever.
      AppLogger.e('Unexpected error updating user', error, stackTrace);
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = AppLocalizations.of(context)!.platformAdminUnexpectedError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.platformAdminEditUserDialogTitle),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: l10n.platformAdminNameLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.platformAdminEmailLabel,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

class _MembershipEditorDialog extends ConsumerStatefulWidget {
  const _MembershipEditorDialog({required this.user});
  final PlatformUser user;
  @override
  ConsumerState<_MembershipEditorDialog> createState() =>
      _MembershipEditorDialogState();
}

class _MembershipEditorDialogState
    extends ConsumerState<_MembershipEditorDialog> {
  late final List<PlatformMembership> _memberships;
  late Future<PlatformPage<PlatformOrganization>> _organizations;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _memberships = List<PlatformMembership>.from(widget.user.memberships);
    _organizations = ref
        .read(platformAdminRepositoryProvider)
        .getOrganizations();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(platformAdminRepositoryProvider)
          .syncMemberships(widget.user.id, _memberships);
      if (mounted) Navigator.of(context).pop(true);
    } on PlatformAdminException catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error.message;
        });
      }
    } catch (error, stackTrace) {
      // Same hardening as _CreateOrganizationDialog._submit() — see its
      // comment. This dialog had the identical gap: any non-
      // PlatformAdminException left _submitting stuck at true forever.
      AppLogger.e('Unexpected error syncing memberships', error, stackTrace);
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = AppLocalizations.of(context)!.platformAdminUnexpectedError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.platformAdminMembershipsDialogTitle(widget.user.name)),
      content: SizedBox(
        width: 600,
        child: FutureBuilder<PlatformPage<PlatformOrganization>>(
          future: _organizations,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final organizations = snapshot.data!.items;
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(l10n.platformAdminMembershipsHint),
                  const SizedBox(height: AppSpacing.md),
                  ..._memberships.asMap().entries.map((entry) {
                    final index = entry.key;
                    final membership = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Row(
                          children: <Widget>[
                            Expanded(child: Text(membership.organizationName)),
                            DropdownButton<String>(
                              value: membership.role,
                              items: _membershipRoles
                                  .map(
                                    (role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(_roleLabel(role, l10n)),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (role) => role == null
                                  ? null
                                  : setState(
                                      () => _memberships[index] =
                                          PlatformMembership(
                                            organizationId:
                                                membership.organizationId,
                                            organizationName:
                                                membership.organizationName,
                                            organizationStatus:
                                                membership.organizationStatus,
                                            role: role,
                                            status: membership.status,
                                          ),
                                    ),
                            ),
                            IconButton(
                              tooltip:
                                  l10n.platformAdminRemoveMembershipTooltip,
                              onPressed: () =>
                                  setState(() => _memberships.removeAt(index)),
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  DropdownButtonFormField<PlatformOrganization>(
                    // Bug reported 2026-08-11: DropdownButtonFormField keeps
                    // its selected value in its own internal FormFieldState,
                    // separate from this widget's `items:` list. Picking an
                    // organization here calls setState() to add it to
                    // _memberships, which immediately filters that same
                    // organization OUT of `items` below (already-added
                    // orgs are excluded) — but without a key forcing a fresh
                    // State, the field's retained value is now an object
                    // matching zero entries in the rebuilt items list,
                    // tripping Flutter's "exactly one item must match value"
                    // assertion on every subsequent add/remove. Keying on the
                    // current membership set forces Flutter to discard the
                    // old State (and its stale value) and mount a fresh one
                    // that starts unselected — which is also the correct UX,
                    // since the just-added organization can no longer be
                    // picked again anyway.
                    key: ValueKey<String>(
                      _memberships.map((m) => m.organizationId).join(','),
                    ),
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.platformAdminAddToOrgLabel,
                    ),
                    items: organizations
                        .where(
                          (organization) => !_memberships.any(
                            (membership) =>
                                membership.organizationId == organization.id,
                          ),
                        )
                        .map(
                          (organization) => DropdownMenuItem(
                            value: organization,
                            child: Text(
                              organization.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (organization) {
                      if (organization == null) return;
                      setState(
                        () => _memberships.add(
                          PlatformMembership(
                            organizationId: organization.id,
                            organizationName: organization.name,
                            organizationStatus: organization.status,
                            role: 'viewer',
                            status: 'active',
                          ),
                        ),
                      );
                    },
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.platformAdminSaveMembershipsButton),
        ),
      ],
    );
  }
}

Future<bool?> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required bool destructive,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: AppColors.error)
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              destructive
                  ? l10n.platformAdminConfirmActionButton
                  : l10n.commonConfirm,
            ),
          ),
        ],
      );
    },
  );
}

/// Prepaid-billing model (2026-08-21) — `POST /admin/organizations/{id}/subscription`:
/// assigns a plan and grants `months` of paid-for period. `reason` is
/// mandatory (a free grant with no documented reason is an audit gap).
class GrantSubscriptionDialog extends ConsumerStatefulWidget {
  const GrantSubscriptionDialog({super.key, required this.organizationId});

  final int organizationId;

  @override
  ConsumerState<GrantSubscriptionDialog> createState() =>
      _GrantSubscriptionDialogState();
}

class _GrantSubscriptionDialogState
    extends ConsumerState<GrantSubscriptionDialog> {
  final _months = TextEditingController(text: '1');
  final _reason = TextEditingController();
  int? _planId;
  bool _submitting = false;
  String? _error;
  late final Future<List<PlatformPlanOption>> _plans;

  @override
  void initState() {
    super.initState();
    _plans = ref.read(platformAdminRepositoryProvider).getPlans();
  }

  @override
  void dispose() {
    _months.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final months = int.tryParse(_months.text.trim());
    if (_planId == null) {
      setState(() => _error = l10n.platformAdminSubscriptionPlanRequiredError);
      return;
    }
    if (months == null || months < 1) {
      setState(() => _error = l10n.platformAdminSubscriptionMonthsInvalidError);
      return;
    }
    if (_reason.text.trim().isEmpty) {
      setState(
        () => _error = l10n.platformAdminSubscriptionReasonRequiredError,
      );
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(platformAdminRepositoryProvider)
          .grantSubscription(
            organizationId: widget.organizationId,
            planId: _planId!,
            months: months,
            reason: _reason.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on PlatformAdminException catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error.message;
        });
      }
    } catch (error, stackTrace) {
      AppLogger.e('Unexpected error granting subscription', error, stackTrace);
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = l10n.platformAdminUnexpectedError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.platformAdminGrantSubscriptionTitle),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FutureBuilder<List<PlatformPlanOption>>(
              future: _plans,
              builder: (context, snapshot) {
                final plans = snapshot.data ?? const <PlatformPlanOption>[];
                return DropdownButtonFormField<int>(
                  initialValue: _planId,
                  decoration: InputDecoration(
                    labelText: l10n.platformAdminSubscriptionPlanLabel,
                  ),
                  items: plans
                      .map(
                        (plan) => DropdownMenuItem<int>(
                          value: plan.id,
                          child: Text(plan.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _planId = value),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _months,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.platformAdminSubscriptionMonthsLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _reason,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.platformAdminSubscriptionReasonLabel,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

/// `POST /admin/organizations/{id}/subscription/extend` — extends the
/// CURRENT plan's period without changing which plan is assigned. Exactly
/// one of days/months is required; both may be supplied together.
class ExtendSubscriptionDialog extends ConsumerStatefulWidget {
  const ExtendSubscriptionDialog({super.key, required this.organizationId});

  final int organizationId;

  @override
  ConsumerState<ExtendSubscriptionDialog> createState() =>
      _ExtendSubscriptionDialogState();
}

class _ExtendSubscriptionDialogState
    extends ConsumerState<ExtendSubscriptionDialog> {
  final _days = TextEditingController();
  final _months = TextEditingController();
  final _reason = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _days.dispose();
    _months.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final days = int.tryParse(_days.text.trim());
    final months = int.tryParse(_months.text.trim());
    if ((days == null || days < 1) && (months == null || months < 1)) {
      setState(
        () => _error = l10n.platformAdminSubscriptionExtendRequiredError,
      );
      return;
    }
    if (_reason.text.trim().isEmpty) {
      setState(
        () => _error = l10n.platformAdminSubscriptionReasonRequiredError,
      );
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(platformAdminRepositoryProvider)
          .extendSubscription(
            organizationId: widget.organizationId,
            days: days,
            months: months,
            reason: _reason.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on PlatformAdminException catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error.message;
        });
      }
    } catch (error, stackTrace) {
      AppLogger.e('Unexpected error extending subscription', error, stackTrace);
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = l10n.platformAdminUnexpectedError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.platformAdminExtendSubscriptionTitle),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _days,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.platformAdminSubscriptionExtendDaysLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _months,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.platformAdminSubscriptionExtendMonthsLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _reason,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.platformAdminSubscriptionReasonLabel,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

/// `POST /admin/organizations/{id}/subscription/trial` — grants a trialing
/// period on whatever plan is already assigned. Deliberately takes no
/// plan_id.
class GrantSubscriptionTrialDialog extends ConsumerStatefulWidget {
  const GrantSubscriptionTrialDialog({super.key, required this.organizationId});

  final int organizationId;

  @override
  ConsumerState<GrantSubscriptionTrialDialog> createState() =>
      _GrantSubscriptionTrialDialogState();
}

class _GrantSubscriptionTrialDialogState
    extends ConsumerState<GrantSubscriptionTrialDialog> {
  final _days = TextEditingController(text: '14');
  final _reason = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _days.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final days = int.tryParse(_days.text.trim());
    if (days == null || days < 1) {
      setState(
        () => _error = l10n.platformAdminSubscriptionTrialDaysInvalidError,
      );
      return;
    }
    if (_reason.text.trim().isEmpty) {
      setState(
        () => _error = l10n.platformAdminSubscriptionReasonRequiredError,
      );
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(platformAdminRepositoryProvider)
          .grantSubscriptionTrial(
            organizationId: widget.organizationId,
            days: days,
            reason: _reason.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on PlatformAdminException catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error.message;
        });
      }
    } catch (error, stackTrace) {
      AppLogger.e('Unexpected error granting a trial', error, stackTrace);
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = l10n.platformAdminUnexpectedError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.platformAdminGrantTrialTitle),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _days,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.platformAdminSubscriptionTrialDaysLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _reason,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.platformAdminSubscriptionReasonLabel,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

/// `DELETE /admin/organizations/{id}/subscription` — reverts to the Free
/// plan, applying Free's limits immediately. reason is mandatory.
class RevertSubscriptionDialog extends ConsumerStatefulWidget {
  const RevertSubscriptionDialog({super.key, required this.organizationId});

  final int organizationId;

  @override
  ConsumerState<RevertSubscriptionDialog> createState() =>
      _RevertSubscriptionDialogState();
}

class _RevertSubscriptionDialogState
    extends ConsumerState<RevertSubscriptionDialog> {
  final _reason = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_reason.text.trim().isEmpty) {
      setState(
        () => _error = l10n.platformAdminSubscriptionReasonRequiredError,
      );
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(platformAdminRepositoryProvider)
          .revertSubscriptionToFree(
            organizationId: widget.organizationId,
            reason: _reason.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on PlatformAdminException catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error.message;
        });
      }
    } catch (error, stackTrace) {
      AppLogger.e(
        'Unexpected error reverting subscription to Free',
        error,
        stackTrace,
      );
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = l10n.platformAdminUnexpectedError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.platformAdminRevertSubscriptionTitle),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(l10n.platformAdminRevertSubscriptionWarning),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _reason,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.platformAdminSubscriptionReasonLabel,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: _submitting ? null : _submit,
          child: Text(l10n.platformAdminConfirmActionButton),
        ),
      ],
    );
  }
}
