import 'package:file_picker/file_picker.dart';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:provider/provider.dart';

import '../../../repositories/document_repository.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/master_data_labels.dart';
import '../../pages/absence/absence_page.dart';
import '../../pages/absence/admin_absences_page.dart';
import '../../pages/absence/admin_entitlement_page.dart';
import '../../pages/employees/employees_page.dart';
import '../../pages/locations/admin_locations_page.dart';
import '../../pages/schedule/swap_requests_page.dart';
import '../../pages/profile/admin_availabilities_page.dart';
import '../../pages/time_tracking/admin_time_account_page.dart';
import '../../pages/time_tracking/time_clock_terminal_page.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../repositories/user_repository.dart';
import '../profile/availability_page.dart';
import '../time_tracking/time_account_page.dart';

// â”€â”€ Supported languages â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

typedef _Lang = ({String name, String flag, String code});

const List<_Lang> _kLanguages = [
  // Flags use Unicode regional-indicator escapes so the source encoding can't
  // corrupt them (previously stored as mojibake).
  (name: 'English',      flag: '\u{1F1EC}\u{1F1E7}', code: 'en'),    // 🇬🇧
  (name: 'Deutsch',      flag: '\u{1F1E9}\u{1F1EA}', code: 'de'),    // 🇩🇪
  (name: 'English (US)', flag: '\u{1F1FA}\u{1F1F8}', code: 'en_US'), // 🇺🇸
];

// â”€â”€ Page â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: _ProfileAppBar(onLogout: () => _confirmLogout(context, l10n)),
      body: SingleChildScrollView(
        physics: Theme.of(context).platform == TargetPlatform.iOS
            ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
            : const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: Column(
          children: [
            // â”€â”€ 1. Profile header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Selector<AuthProvider,
                ({String id, String initials, String firstName, String lastName, String fullName, String role, String email, String? phone, String? avatarUrl})>(
              selector: (_, auth) => (
                id:        auth.user?.id        ?? '',
                initials:  auth.user?.initials  ?? 'A',
                firstName: auth.user?.firstName ?? '',
                lastName:  auth.user?.lastName  ?? '',
                fullName:  auth.user?.fullName  ?? 'Wrenta User',
                role:      auth.user?.role      ?? 'employee',
                email:     auth.user?.email     ?? '',
                phone:     auth.user?.phone,
                avatarUrl: auth.user?.avatarUrl,
              ),
              builder: (ctx, u, _) => _ProfileHeader(
                initials:   u.initials,
                firstName:  u.firstName,
                lastName:   u.lastName,
                fullName:   u.fullName,
                role:       u.role,
                email:      u.email,
                phone:      u.phone ?? '',
                employeeId: u.id,
                avatarUrl:  u.avatarUrl,
              ),
            ),
            const SizedBox(height: 28),

            _SectionHeader(l10n.profileSectionWorkDetails),
            const SizedBox(height: 12),
            const _WorkDetailsGrid(),
            const SizedBox(height: 28),

            _SectionHeader(l10n.profileSectionEmployment),
            const SizedBox(height: 12),
            const _EmploymentSection(),
            const SizedBox(height: 28),

            _SectionHeader(l10n.profileSectionDocuments),
            const SizedBox(height: 12),
            const _DocumentSection(),
            const SizedBox(height: 28),

            _SectionHeader('Professional Info'),
            const SizedBox(height: 12),
            const _ProfessionalInfoSection(),
            const SizedBox(height: 28),

            // Master data is admin-only.
            Selector<AuthProvider, bool>(
              selector: (_, auth) => auth.isAdmin,
              builder: (_, isAdmin, _) {
                if (!isAdmin) return const SizedBox.shrink();
                return const Column(
                  children: [
                    _MasterDataSection(),
                    SizedBox(height: 28),
                  ],
                );
              },
            ),

            _SectionHeader(l10n.profileSectionSettings),
            const SizedBox(height: 12),
            const _AppSettingsSection(),
            const SizedBox(height: 28),

            // â”€â”€ Admin section (gated by role) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Selector<AuthProvider, bool>(
              selector: (_, auth) => auth.isAdmin,
              builder: (_, isAdmin, _) {
                if (!isAdmin) return const SizedBox.shrink();
                return Column(
                  children: [
                    const _SectionHeader('Administration'),
                    const SizedBox(height: 12),
                    const _AdminSection(),
                    const SizedBox(height: 28),
                  ],
                );
              },
            ),

            _SectionHeader(l10n.profileSectionActions),
            const SizedBox(height: 12),
            Builder(
              builder: (ctx) => _AccountActionsSection(
                onLogout: () =>
                    _confirmLogout(ctx, AppLocalizations.of(ctx)),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:   Text(l10n.profileSignOutConfirmTitle),
        content: Text(l10n.profileSignOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().signOut();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.profileSignOut),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ App bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ProfileAppBar({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppBar(
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: true,
      title: Text(l10n.profileTitle, style: AppTextStyles.h5),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, size: 22),
          onPressed: onLogout,
          tooltip: l10n.profileSignOut,
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// â”€â”€ Profile header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.initials,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.role,
    required this.email,
    required this.phone,
    required this.employeeId,
    this.avatarUrl,
  });

  final String  initials;
  final String  firstName;
  final String  lastName;
  final String  fullName;
  final String  role;
  final String  email;
  final String  phone;
  final String  employeeId;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showEditSheet(context),
            child: Stack(
              children: [
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.slate200, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl!) : null,
                    child: avatarUrl == null
                        ? Text(initials,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 30,
                            ))
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 2, right: 2,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_outlined,
                        size: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(fullName, style: AppTextStyles.h4.copyWith(fontSize: 24)),
          const SizedBox(height: 5),
          Text(
            _cap(role),
            style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Employee ID: #$employeeId',
            style: AppTextStyles.caption.copyWith(color: AppColors.slate400),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _showEditSheet(context),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: Text(l10n.profileEditProfile),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primaryLight),
              backgroundColor: AppColors.primaryLighter,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99)),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        firstName: firstName,
        lastName:  lastName,
        phone:     phone,
        avatarUrl: avatarUrl,
      ),
    );
  }
}

// â”€â”€ Edit profile sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.avatarUrl,
  });
  final String  firstName, lastName, phone;
  final String? avatarUrl;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _firstNameCtrl, _lastNameCtrl, _phoneCtrl,
      _departmentCtrl, _contractCtrl;
  bool _isSaving  = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl  = TextEditingController(text: widget.firstName);
    _lastNameCtrl   = TextEditingController(text: widget.lastName);
    _phoneCtrl      = TextEditingController(text: widget.phone);
    _departmentCtrl = TextEditingController();
    _contractCtrl   = TextEditingController();
    _loadExtra();
  }

  Future<void> _loadExtra() async {
    try {
      final res  = await ApiClient.instance.get(ApiConfig.me);
      final wrap = res is Map<String, dynamic> ? res : <String, dynamic>{};
      final body = (wrap['data'] ?? wrap) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _departmentCtrl.text = body['department'] as String?
                              ?? body['departmentName'] as String? ?? '';
          _contractCtrl.text   = body['contractType'] as String?
                              ?? body['contract'] as String? ?? '';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _departmentCtrl.dispose();
    _contractCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final auth      = context.read<AuthProvider>();
    final l10nLocal = AppLocalizations.of(context);
    try {
      await ApiClient.instance.patch(ApiConfig.updateProfile, data: {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName':  _lastNameCtrl.text.trim(),
        if (_phoneCtrl.text.trim().isNotEmpty)
          'phone': _phoneCtrl.text.trim(),
        if (_departmentCtrl.text.trim().isNotEmpty)
          'department': _departmentCtrl.text.trim(),
        if (_contractCtrl.text.trim().isNotEmpty)
          'contractType': _contractCtrl.text.trim(),
      });
      await auth.refreshUser();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(_snackBar(
        context, l10nLocal.profileUpdated, AppColors.success,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_snackBar(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetHandle(),
          Text(l10n.profileEditProfile, style: AppTextStyles.h5),
          const SizedBox(height: 20),
          _SheetField(label: l10n.profileFirstName, controller: _firstNameCtrl, keyboard: TextInputType.name),
          const SizedBox(height: 14),
          _SheetField(label: l10n.profileLastName,  controller: _lastNameCtrl,  keyboard: TextInputType.name),
          const SizedBox(height: 14),
          _SheetField(label: l10n.profilePhone, controller: _phoneCtrl, keyboard: TextInputType.phone),
          const SizedBox(height: 14),
          if (_isLoading) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ]
          else ...[
            _SheetField(label: l10n.profileDepartmentLabel,   controller: _departmentCtrl, keyboard: TextInputType.text),
            const SizedBox(height: 14),
            _SheetField(label: l10n.profileContractTypeLabel, controller: _contractCtrl,   keyboard: TextInputType.text),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeightLg,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving ? _spinner() : Text(l10n.save),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({required this.label, required this.controller, required this.keyboard});
  final String label;
  final TextEditingController controller;
  final TextInputType keyboard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 6),
        TextField(controller: controller, keyboardType: keyboard,
            decoration: InputDecoration(hintText: label)),
      ],
    );
  }
}

// â”€â”€ Change password sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();
  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _cur = TextEditingController();
  final _new = TextEditingController();
  final _con = TextEditingController();
  bool _oCur = true, _oNew = true, _oCon = true, _saving = false;
  String? _error;

  @override
  void dispose() { _cur.dispose(); _new.dispose(); _con.dispose(); super.dispose(); }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _error = null);

    if (_new.text.length < 8) {
      setState(() => _error = l10n.validatorPasswordLength);
      return;
    }
    if (_new.text != _con.text) {
      setState(() => _error = l10n.profilePasswordMismatch);
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<UserRepository>().changePassword(
        currentPassword: _cur.text,
        newPassword:     _new.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(_snackBar(
        context, l10n.profilePasswordChanged, AppColors.success,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetHandle(),
          Text(l10n.profileChangePassword, style: AppTextStyles.h5),
          const SizedBox(height: 20),
          _PasswordField(label: l10n.profilePasswordCurrent,
              controller: _cur, obscure: _oCur,
              onToggle: () => setState(() => _oCur = !_oCur)),
          const SizedBox(height: 14),
          _PasswordField(label: l10n.profilePasswordNew,
              controller: _new, obscure: _oNew,
              onToggle: () => setState(() => _oNew = !_oNew)),
          const SizedBox(height: 14),
          _PasswordField(label: l10n.profilePasswordConfirm,
              controller: _con, obscure: _oCon,
              onToggle: () => setState(() => _oCon = !_oCon)),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))),
              ]),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeightLg,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving ? _spinner() : Text(l10n.profileChangePassword),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label, required this.controller,
    required this.obscure, required this.onToggle,
  });
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 6),
        TextField(
          controller: controller, obscureText: obscure,
          decoration: InputDecoration(
            hintText: 'â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢',
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 18, color: AppColors.slate400,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }
}

// â”€â”€ Work details grid â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _WorkDetailsGrid extends StatefulWidget {
  const _WorkDetailsGrid();
  @override
  State<_WorkDetailsGrid> createState() => _WorkDetailsGridState();
}

class _WorkDetailsGridState extends State<_WorkDetailsGrid> {
  bool   _loading    = true;
  String _department = '';
  String _location   = '';
  String _startDate  = '';
  String _contract   = '';


  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res  = await ApiClient.instance.get(ApiConfig.me);
      final wrap = res is Map<String, dynamic> ? res : <String, dynamic>{};
      final body = (wrap['data'] ?? wrap) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _department = body['department']    as String?
                   ?? body['departmentName'] as String? ?? '';
        // The API returns a `locations` array of objects; use the first one's
        // name. Fall back to legacy flat fields if present.
        final locs = body['locations'] as List<dynamic>?;
        if (locs != null && locs.isNotEmpty && locs.first is Map) {
          _location = (locs.first as Map)['name'] as String? ?? '';
        } else {
          _location = body['workLocation'] as String?
                   ?? body['locationName'] as String? ?? '';
        }
        // No explicit employment start date is exposed; createdAt is the
        // closest server-synced value.
        final raw = body['startDate']  as String?
                 ?? body['start_date'] as String?
                 ?? body['createdAt']  as String?;
        if (raw != null) {
          try {
            final d = DateTime.parse(raw).toLocal();
            _startDate =
                DateFormatter.formatShortDateWithYear(d);
          } catch (_) {
            _startDate = raw;
          }
        }
        _contract = body['contractType'] as String?
                 ?? body['contract']     as String? ?? '';
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: _WorkDetailCell(
              icon: Icons.work_outline_rounded,
              iconColor: AppColors.primary, iconBg: AppColors.primaryLighter,
              label: l10n.profileDepartment,
              value: _department.isEmpty ? 'â€”' : _department,
            )),
            const SizedBox(width: 12),
            Expanded(child: _WorkDetailCell(
              icon: Icons.location_on_outlined,
              iconColor: AppColors.success, iconBg: AppColors.successLight,
              label: l10n.profileLocation,
              value: _location.isEmpty ? 'â€”' : _location,
            )),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _WorkDetailCell(
              icon: Icons.calendar_today_outlined,
              iconColor: AppColors.purple, iconBg: AppColors.purpleLight,
              label: l10n.profileStartDate,
              value: _startDate.isEmpty ? 'â€”' : _startDate,
            )),
            const SizedBox(width: 12),
            Expanded(child: _WorkDetailCell(
              icon: Icons.schedule_outlined,
              iconColor: AppColors.warning, iconBg: AppColors.amberLight,
              label: l10n.profileContract,
              value: _contract.isEmpty ? l10n.profileContractFullTime : _contract,
            )),
          ]),
        ],
      ),
    );
  }
}

class _WorkDetailCell extends StatelessWidget {
  const _WorkDetailCell({
    required this.icon, required this.iconColor, required this.iconBg,
    required this.label, required this.value,
  });
  final IconData icon;
  final Color iconColor, iconBg;
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11)),
            const SizedBox(height: 2),
            Text(value,
                style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ],
        )),
      ]),
    );
  }
}

// â”€â”€ Employment overview â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EmploymentSection extends StatefulWidget {
  const _EmploymentSection();
  @override
  State<_EmploymentSection> createState() => _EmploymentSectionState();
}

class _EmploymentSectionState extends State<_EmploymentSection> {
  String? _vacationRemaining;
  String? _timeBalance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ApiClient.instance.get(ApiConfig.absenceEntitlement),
        ApiClient.instance.get('/api/overtime-balances/me'),
      ]);

      // â”€â”€ Vacation entitlement â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      final entRaw  = results[0] is Map<String, dynamic>
          ? results[0] as Map<String, dynamic>
          : <String, dynamic>{};
      final entBody = (entRaw['data'] ?? entRaw) as Map<String, dynamic>;
      final remaining = (entBody['remainingDays']
          ?? entBody['remaining']
          ?? entBody['remainingVacationDays']) as num?;

      // â”€â”€ Time balance â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      final timeRaw  = results[1] is Map<String, dynamic>
          ? results[1] as Map<String, dynamic>
          : <String, dynamic>{};
      final timeBody = (timeRaw['data'] ?? timeRaw) as Map<String, dynamic>;
      final balMin   = (timeBody['balanceMinutes'] ?? timeBody['balance']) as num?;
      String balance;
      if (balMin != null) {
        final sign = balMin >= 0 ? '+' : '-';
        final abs  = balMin.abs().toInt();
        balance =
            '$sign${(abs ~/ 60).toString().padLeft(2, '0')}:${(abs % 60).toString().padLeft(2, '0')}h';
      } else {
        balance = timeBody['balanceLabel'] as String? ?? '';
      }

      if (!mounted) return;
      setState(() {
        _vacationRemaining = remaining != null ? '${remaining.toInt()}' : null;
        _timeBalance       = balance.isEmpty ? null : balance;
      });
    } catch (_) {
      // keep null â€” tiles render without trailing widget
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _CardGroup(
      children: [
        _EmploymentTile(
          icon: Icons.event_busy_outlined,
          iconColor: AppColors.primary, iconBg: AppColors.primaryLighter,
          title:    l10n.absencesTitle,
          subtitle: l10n.profileAbsenceSubtitle,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AbsencePage())),
        ),
        _EmploymentTile(
          icon: Icons.beach_access_outlined,
          iconColor: AppColors.success, iconBg: AppColors.successLight,
          title:    l10n.profileVacationAccount,
          subtitle: l10n.profileVacationSubtitle,
          trailing: _vacationRemaining == null ? null : _CountBadge(
            count: _vacationRemaining!,
            label: l10n.absenceRemaining,
            color: AppColors.success,
            bg:    AppColors.successLight,
          ),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AbsencePage())),
        ),
        _EmploymentTile(
          icon: Icons.access_time_outlined,
          iconColor: AppColors.warning, iconBg: AppColors.amberLight,
          title:    l10n.profileTimeAccount,
          subtitle: l10n.profileTimeAccountSubtitle,
          trailing: _timeBalance == null ? null : Text(
            _timeBalance!,
            style: AppTextStyles.bodyBold
                .copyWith(color: AppColors.primary, fontSize: 16),
          ),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TimeAccountPage())),
        ),
        _EmploymentTile(
          icon: Icons.event_available_outlined,
          iconColor: AppColors.purple, iconBg: AppColors.purpleLight,
          title:    l10n.profileAvailability,
          subtitle: l10n.profileAvailabilitySubtitle,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AvailabilityPage())),
          isLast: true,
        ),
      ],
    );
  }
}

class _EmploymentTile extends StatelessWidget {
  const _EmploymentTile({
    required this.icon, required this.iconColor, required this.iconBg,
    required this.title, required this.subtitle, required this.onTap,
    this.trailing, this.isLast = false,
  });
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      InkWell(
        onTap: onTap,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(16))
            : BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.bodyBold.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.slate500, fontSize: 12)),
              ],
            )),
            trailing ??
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.slate300),
          ]),
        ),
      ),
      if (!isLast)
        const Divider(height: 1, indent: 74, color: AppColors.slate100),
    ]);
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count, required this.label,
    required this.color, required this.bg,
  });
  final String count, label;
  final Color color, bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(count, style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w800, color: color, height: 1.1)),
        Text(label, style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

// â”€â”€ Document management â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DocumentSection extends StatefulWidget {
  const _DocumentSection();
  @override
  State<_DocumentSection> createState() => _DocumentSectionState();
}

class _DocumentSectionState extends State<_DocumentSection> {
  final _repo = ApiDocumentRepository();
  bool _isUploading = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _docs = [];

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    try {
      final docs = await _repo.listMyDocuments();
      if (mounted) setState(() { _docs = docs; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFile() async {
    if (_isUploading) return;
    setState(() => _isUploading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        withData: true, // load bytes so web (no file path) can upload too
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        // Prefer bytes (works on web + mobile); fall back to a file path.
        if (file.bytes != null) {
          await _repo.uploadMyDocumentBytes(file.bytes!, file.name);
        } else if (file.path != null) {
          await _repo.uploadMyDocument(file.path!);
        } else {
          return;
        }
        await _loadDocs();
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(_snackBar(
          context, '${file.name} ${l10n.profileUploadSuccess}', AppColors.success,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(_snackBar(
        context, '${l10n.profileUploadFailed}: $e', AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _delete(String id) async {
    try {
      await _repo.deleteMyDocument(id);
      setState(() => _docs.removeWhere((d) => d['id'] == id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar(context, 'Delete failed: $e', AppColors.error));
    }
  }

  _DocItem _toDocItem(Map<String, dynamic> doc) {
    final name = doc['fileName'] as String? ?? doc['name'] as String? ?? 'Document';
    final mimeType = doc['mimeType'] as String? ?? '';
    final size = doc['size'] as int? ?? 0;
    final sizeStr = size < 1024 * 1024
        ? '${(size / 1024).toStringAsFixed(0)} KB'
        : '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    final isImage = mimeType.startsWith('image/');
    final isPdf   = mimeType == 'application/pdf';
    return _DocItem(
      icon: isImage ? Icons.image_outlined : isPdf ? Icons.picture_as_pdf_outlined : Icons.insert_drive_file_outlined,
      iconColor: isImage ? AppColors.success : isPdf ? AppColors.error : AppColors.purple,
      iconBg: isImage ? AppColors.successLight : isPdf ? AppColors.errorLight : AppColors.purpleLight,
      title: name,
      subtitle: sizeStr,
      id: doc['id'] as String?,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _CardGroup(children: [
        Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
      ]);
    }
    return _CardGroup(
      children: [
        ..._docs.map((d) => _DocumentTile(doc: _toDocItem(d), onDelete: d['id'] != null ? () => _delete(d['id'] as String) : null)),
        _UploadTile(isUploading: _isUploading, onTap: _pickFile),
      ],
    );
  }
}

class _DocItem {
  const _DocItem({
    required this.icon, required this.iconColor, required this.iconBg,
    required this.title, required this.subtitle, this.id,
  });
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle;
  final String? id;
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.doc, this.onDelete});
  final _DocItem doc;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: doc.iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(doc.icon, color: doc.iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(doc.title,
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 14),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(doc.subtitle,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.slate400, fontSize: 12)),
            ],
          )),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.slate300),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          else
            const Icon(Icons.download_outlined, size: 18, color: AppColors.slate300),
        ]),
      ),
      const Divider(height: 1, indent: 70, color: AppColors.slate100),
    ]);
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({required this.isUploading, required this.onTap});
  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: AppColors.purpleLight,
                borderRadius: BorderRadius.circular(10)),
            child: isUploading
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.purple))
                : const Icon(Icons.upload_file_outlined,
                    color: AppColors.purple, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUploading ? l10n.profileUploading : l10n.profileUploadDocument,
                style: AppTextStyles.bodyBold
                    .copyWith(fontSize: 14, color: AppColors.primary),
              ),
              const SizedBox(height: 2),
              const Text('PDF, DOC, JPG, PNG',
                  style: TextStyle(color: AppColors.slate400, fontSize: 12)),
            ],
          )),
          Icon(
            isUploading ? Icons.hourglass_top_rounded : Icons.add_circle_outline,
            size: 18,
            color: isUploading ? AppColors.slate300 : AppColors.primary,
          ),
        ]),
      ),
    );
  }
}

// â”€â”€ App settings â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AppSettingsSection extends StatefulWidget {
  const _AppSettingsSection();
  @override
  State<_AppSettingsSection> createState() => _AppSettingsSectionState();
}

class _AppSettingsSectionState extends State<_AppSettingsSection> {
  late _Lang _language;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final code = context.watch<LocaleProvider>().locale.languageCode;
    _language  = _kLanguages.firstWhere(
        (l) => l.code == code, orElse: () => _kLanguages.first);
  }

  void _showLanguagePicker() {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title:   const Text('Change language'),
        content: const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('Please choose a language'),
        ),
        actions: [
          for (final lang in _kLanguages)
            CupertinoDialogAction(
              isDefaultAction: lang.code == _language.code,
              onPressed: () {
                Navigator.pop(ctx);
                final code = lang.code.contains('_') ? lang.code.split('_').first : lang.code;
                context.read<LocaleProvider>().setLanguageCode(code);
              },
              child: Text(_displayName(lang)),
            ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _displayName(_Lang l) {
    switch (l.code) {
      case 'de':    return 'German';
      case 'en':    return 'English';
      case 'en_US': return 'English (US)';
      default:      return l.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n      = AppLocalizations.of(context);
    final themeMode = context.watch<ThemeProvider>().themeMode;
    // Reflect the *effective* brightness so the switch is correct even in system mode.
    final isDark    = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    return _CardGroup(children: [
      _AppSettingsTile(
        icon: Icons.language_outlined,
        iconColor: AppColors.success, iconBg: AppColors.successLight,
        title: l10n.settingsLanguage,
        onTap: _showLanguagePicker,
        trailing: GestureDetector(
          onTap: _showLanguagePicker,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(_language.flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(_language.name,
                style: AppTextStyles.bodySmall.copyWith(fontSize: 13)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16),
          ]),
        ),
      ),
      _AppSettingsTile(
        icon: Icons.dark_mode_outlined,
        iconColor: AppColors.slate600, iconBg: AppColors.slate100,
        title: l10n.profileDarkMode,
        isLast: true,
        trailing: Switch.adaptive(
          value: isDark,
          onChanged: (on) => context.read<ThemeProvider>()
              .setThemeMode(on ? ThemeMode.dark : ThemeMode.light),
          activeThumbColor: AppColors.primary,
        ),
      ),
    ]);
  }
}

class _AppSettingsTile extends StatelessWidget {
  const _AppSettingsTile({
    required this.icon, required this.iconColor, required this.iconBg,
    required this.title, this.trailing, this.isLast = false, this.onTap,
  });
  final IconData icon;
  final Color iconColor, iconBg;
  final String title;
  final Widget? trailing;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      InkWell(
        onTap: onTap,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(16))
            : BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(title,
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 14))),
            if (trailing != null) trailing!,
          ]),
        ),
      ),
      if (!isLast)
        const Divider(height: 1, indent: 66, color: AppColors.slate100),
    ]);
  }
}

// â”€â”€ Account actions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AccountActionsSection extends StatelessWidget {
  const _AccountActionsSection({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        _ActionButton(
          icon: Icons.lock_outline_rounded,
          label: l10n.profileChangePassword,
          iconColor: AppColors.primary, iconBg: AppColors.primaryLighter,
          onTap: () => showModalBottomSheet(
            context: context, isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const _ChangePasswordSheet(),
          ),
        ),
        const SizedBox(height: 10),
        const _TimeClockPinButton(),
        const SizedBox(height: 10),
        _ActionButton(
          icon: Icons.privacy_tip_outlined,
          label: l10n.profilePrivacyPolicy,
          iconColor: AppColors.primary, iconBg: AppColors.primaryLighter,
          onTap: () => Navigator.pushNamed(context, '/privacy-policy'),
        ),
        const SizedBox(height: 10),
        _ActionButton(
          icon: Icons.description_outlined,
          label: l10n.profileTermsOfService,
          iconColor: AppColors.primary, iconBg: AppColors.primaryLighter,
          onTap: () => Navigator.pushNamed(context, '/terms-of-service'),
        ),
        const SizedBox(height: 10),
        const _ExportMyDataButton(),
        const SizedBox(height: 10),
        _ActionButton(
          icon: Icons.logout_rounded,
          label: l10n.profileSignOut,
          iconColor: AppColors.error, iconBg: AppColors.errorLight,
          labelColor: AppColors.error, onTap: onLogout,
        ),
        const SizedBox(height: 10),
        _ActionButton(
          icon: Icons.delete_forever_outlined,
          label: l10n.profileDeleteAccount,
          iconColor: AppColors.error, iconBg: AppColors.errorLight,
          labelColor: AppColors.error,
          onTap: () => showModalBottomSheet(
            context: context, isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const _DeleteAccountSheet(),
          ),
        ),
      ]),
    );
  }
}

// ── Export my data ─────────────────────────────────────────────────────────

class _ExportMyDataButton extends StatefulWidget {
  const _ExportMyDataButton();

  @override
  State<_ExportMyDataButton> createState() => _ExportMyDataButtonState();
}

class _ExportMyDataButtonState extends State<_ExportMyDataButton> {
  bool _loading = false;

  Future<void> _export() async {
    setState(() => _loading = true);
    try {
      final data = await context.read<UserRepository>().exportMyData();
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => _DataExportViewerPage(data: data),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_snackBar(
        context, e.toString().replaceFirst('Exception: ', ''), AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: _loading ? null : _export,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: AppColors.successLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.download_outlined, size: 18, color: AppColors.success),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(l10n.profileExportMyData,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ))),
          if (_loading)
            const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(Icons.chevron_right, size: 18, color: AppColors.slate300),
        ]),
      ),
    );
  }
}

class _DataExportViewerPage extends StatelessWidget {
  const _DataExportViewerPage({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pretty = const JsonEncoder.withIndent('  ').convert(data);
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.slate700),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.profileExportMyData, style: AppTextStyles.h5),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
              child: SelectableText(pretty, style: AppTextStyles.monospace.copyWith(fontSize: 12)),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeightLg,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.copy_all_outlined, size: 18),
                  label: const Text('Copy to clipboard'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: pretty));
                    ScaffoldMessenger.of(context).showSnackBar(_snackBar(
                      context, 'Copied to clipboard', AppColors.success,
                    ));
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Delete account ───────────────────────────────────────────────────────────

class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet();

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  final _password = TextEditingController();
  bool _obscure = true, _deleting = false;
  String? _error;

  @override
  void dispose() { _password.dispose(); super.dispose(); }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    if (_password.text.isEmpty) {
      setState(() => _error = l10n.profilePasswordCurrent);
      return;
    }
    setState(() { _deleting = true; _error = null; });
    try {
      await context.read<UserRepository>().deleteAccount(_password.text);
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      Navigator.pop(context);
      await auth.signOut();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetHandle(),
          Text(l10n.profileDeleteConfirmTitle, style: AppTextStyles.h5),
          const SizedBox(height: 8),
          Text(l10n.profileDeleteConfirmBody,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.slate500)),
          const SizedBox(height: 20),
          _PasswordField(
            label: l10n.profilePasswordCurrent,
            controller: _password,
            obscure: _obscure,
            onToggle: () => setState(() => _obscure = !_obscure),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))),
              ]),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeightLg,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: _deleting ? null : _confirmDelete,
              child: _deleting ? _spinner() : Text(l10n.profileDelete),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Time Clock PIN button ─────────────────────────────────────────────────────

class _TimeClockPinButton extends StatefulWidget {
  const _TimeClockPinButton();

  @override
  State<_TimeClockPinButton> createState() => _TimeClockPinButtonState();
}

class _TimeClockPinButtonState extends State<_TimeClockPinButton> {
  String? _pin;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    try {
      final pin = await context.read<UserRepository>().getClockPin();
      if (mounted) setState(() { _pin = pin; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _pin = '????'; _loading = false; });
    }
  }

  Future<void> _regenerate() async {
    setState(() => _loading = true);
    try {
      final pin = await context.read<UserRepository>().regenerateClockPin();
      if (mounted) setState(() { _pin = pin; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _regenerate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.pin_outlined, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _loading
                ? const SizedBox(
                    height: 16,
                    child: LinearProgressIndicator(
                      backgroundColor: AppColors.primaryLighter,
                      color: AppColors.primary,
                    ),
                  )
                : Text(
                    'Time clock PIN $_pin',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
          ),
          const Icon(Icons.refresh_rounded, size: 18, color: AppColors.slate300),
        ]),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon, required this.label,
    required this.iconColor, required this.iconBg, required this.onTap,
    this.labelColor,
  });
  final IconData icon;
  final String label;
  final Color iconColor, iconBg;
  final Color? labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: labelColor ?? Theme.of(context).colorScheme.onSurface,
              ))),
          Icon(Icons.chevron_right,
              size: 18,
              color: AppColors.slate300),
        ]),
      ),
    );
  }
}

// â”€â”€ Shared helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(title,
            style: AppTextStyles.overline.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11, letterSpacing: 0.8)),
      );
}

class _CardGroup extends StatelessWidget {
  const _CardGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(children: children),
      );
}

// â”€â”€ Private widget helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Standard drag handle for bottom sheets.
Widget _sheetHandle() => Center(
      child: Container(
        width: 40, height: 4,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            color: AppColors.slate200,
            borderRadius: BorderRadius.circular(2)),
      ),
    );

/// Compact loading spinner for buttons.
Widget _spinner() => const SizedBox(
      width: 20, height: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );

/// Consistent floating snack bar.
SnackBar _snackBar(BuildContext context, String message, Color color) =>
    SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    );

// â”€â”€ Professional info section (roles / skills / calendar sync) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ProfessionalInfoSection extends StatefulWidget {
  const _ProfessionalInfoSection();
  @override
  State<_ProfessionalInfoSection> createState() => _ProfessionalInfoSectionState();
}

class _ProfessionalInfoSectionState extends State<_ProfessionalInfoSection> {
  String _calendarUrl = '';
  bool _calActive = false;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await ApiClient.instance.get('/api/users/me');
      final wrap = (res is Map<String, dynamic>) ? res : <String, dynamic>{};
      final body = (wrap['data'] ?? wrap) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _calendarUrl = body['calendarUrl'] as String? ?? '';
          _calActive = body['calendarSyncActive'] == true;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _CardGroup(children: [
        const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
      ]);
    }
    return _CardGroup(children: [
      _AppSettingsTile(
        icon: Icons.calendar_today_outlined,
        iconColor: AppColors.success, iconBg: AppColors.successLight,
        title: 'Calendar Sync',
        isLast: true,
        trailing: Text(_calActive ? 'Active' : 'Inactive',
            style: TextStyle(
                color: _calActive ? AppColors.success : AppColors.slate400,
                fontSize: 13, fontWeight: FontWeight.w600)),
        onTap: () => showModalBottomSheet(
          context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
          builder: (_) => _CalendarSyncSheet(
            url: _calendarUrl.isEmpty
                ? 'webcal://storage.googleapis.com/wrenta-production.appspot.com/calendar.ics'
                : _calendarUrl,
          ),
        ),
      ),
    ]);
  }
}

// â”€â”€ Master data section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MasterDataSection extends StatefulWidget {
  const _MasterDataSection();
  @override
  State<_MasterDataSection> createState() => _MasterDataSectionState();
}

class _MasterDataSectionState extends State<_MasterDataSection> {
  List<Map<String, dynamic>> _masterData = [];
  bool _loading = true;
  bool _editing = false;
  bool _saving  = false;
  final Map<String, TextEditingController> _ctrls = {};

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() {
    for (final c in _ctrls.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.instance.get('/api/master-data/me');
      final wrap = (res is Map<String, dynamic>) ? res : <String, dynamic>{};
      final md = (wrap['data'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
      if (mounted) setState(() { _masterData = md; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _masterData = []; _loading = false; });
    }
  }

  void _enterEdit() {
    for (final f in _masterData) {
      if (f['isLocked'] == true) continue;
      _ctrls[f['fieldId'] as String] =
          TextEditingController(text: f['value'] as String? ?? '');
    }
    setState(() => _editing = true);
  }

  Future<void> _exitEdit({bool save = false}) async {
    if (!save) {
      for (final c in _ctrls.values) { c.dispose(); }
      _ctrls.clear();
      setState(() => _editing = false);
      return;
    }
    setState(() => _saving = true);
    try {
      final values = _ctrls.entries
          .map((e) => {'fieldId': e.key, 'value': e.value.text.trim()})
          .toList();
      final res = await ApiClient.instance
          .put('/api/master-data/me', data: {'values': values});
      final wrap = (res is Map<String, dynamic>) ? res : <String, dynamic>{};
      final updated = (wrap['data'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      for (final c in _ctrls.values) { c.dispose(); }
      _ctrls.clear();
      if (mounted) {
        setState(() {
          if (updated != null) _masterData = updated;
          _editing = false; _saving = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Text('MASTER DATA',
                style: AppTextStyles.overline.copyWith(
                    color: cs.onSurfaceVariant, fontSize: 11, letterSpacing: 0.8)),
            const Spacer(),
            if (_loading)
              const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else if (_editing) ...[
              ElevatedButton.icon(
                onPressed: _saving ? null : () => _exitEdit(save: true),
                icon: _saving
                    ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_outlined, size: 16, color: Colors.white),
                label: const Text('Save', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _saving ? null : () => _exitEdit(),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: AppColors.error, borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ] else
              OutlinedButton.icon(
                onPressed: _masterData.isEmpty ? null : _enterEdit,
                icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                label: const Text('Edit', style: TextStyle(color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                ),
              ),
          ]),
          const SizedBox(height: 12),
          if (!_loading && _masterData.isEmpty)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
              ),
              padding: const EdgeInsets.all(16),
              child: Text('No master data available.',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            )
          else if (!_loading)
            for (int i = 0; i < _masterData.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _masterField(cs, _masterData[i]),
            ],
        ],
      ),
    );
  }

  Widget _masterField(ColorScheme cs, Map<String, dynamic> f) {
    final id       = f['fieldId'] as String;
    final label    = localizedMasterDataLabel(context, f['label'] as String? ?? '');
    final value    = f['value']   as String?;
    final editable = _editing && f['isLocked'] != true && _ctrls.containsKey(id);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          if (editable)
            TextField(
              controller: _ctrls[id],
              autofocus: false,
              style: TextStyle(fontSize: 15, color: cs.onSurface),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            )
          else
            Text((value == null || value.isEmpty) ? '-' : value,
                style: TextStyle(fontSize: 15, color: cs.onSurface)),
        ],
      ),
    );
  }
}

// â”€â”€ Calendar sync sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CalendarSyncSheet extends StatelessWidget {
  const _CalendarSyncSheet({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 22, color: cs.onSurfaceVariant),
                ),
                const Expanded(
                  child: Text('Calendar Sync',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 22),
              ]),
            ),
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Subscribe to your Wrenta calendar in any calendar app. New shifts may take a moment to appear — you can adjust the update interval in your calendar app settings.',
                    style: TextStyle(fontSize: 14, color: cs.onSurface, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Text(url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: cs.onSurface)),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                    child: const Text('Open with Calendar App',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Admin section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AdminSection extends StatefulWidget {
  const _AdminSection();

  @override
  State<_AdminSection> createState() => _AdminSectionState();
}

class _AdminSectionState extends State<_AdminSection> {
  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = context.select<AuthProvider, bool>((a) => a.isSuperAdmin);

    final tiles = <(IconData, String, Widget)>[
      (Icons.people_outline,           'Employees',           const EmployeesPage()),
      (Icons.place_outlined,           'Locations',           const AdminLocationsPage()),
      (Icons.swap_horiz,               'Swap requests',       const SwapRequestsPage()),
      (Icons.event_busy_outlined,      'Absences',            const AdminAbsencesPage()),
      if (isSuperAdmin)
        (Icons.beach_access_outlined,  'Entitlement',         const AdminEntitlementPage()),
      (Icons.access_time_outlined,     'Time account',        const AdminTimeAccountPage()),
      (Icons.event_available_outlined, 'Availabilities',      const AdminAvailabilitiesPage()),
      if (isSuperAdmin)
        (Icons.dialpad_outlined,       'Time Clock Terminal', const TimeClockTerminalSetupPage()),
    ];

    return _CardGroup(children: [
      for (int i = 0; i < tiles.length; i++)
        _AppSettingsTile(
          icon: tiles[i].$1,
          iconColor: AppColors.primary, iconBg: AppColors.primaryLight,
          title: tiles[i].$2,
          isLast: i == tiles.length - 1,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => tiles[i].$3)),
        ),
    ]);
  }
}
