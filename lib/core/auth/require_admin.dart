import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Called from an admin page's `initState`. If the current user isn't an
/// admin/manager, it shows a snackbar and pops the route on the next frame.
/// Returns `true` when the caller should proceed with its own setup.
bool requireAdmin(BuildContext context) {
  final auth = context.read<AuthProvider>();
  if (auth.isAdmin) return true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Admin access required'),
          backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
    );
    Navigator.of(context).maybePop();
  });
  return false;
}
