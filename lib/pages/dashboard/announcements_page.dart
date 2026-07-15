import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/announcement_model.dart';
import '../../../providers/announcement_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/member_picker_sheet.dart';

// ── Announcements List Page ────────────────────────────────────────────────────

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<AnnouncementProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnnouncementProvider>();
    final cs       = Theme.of(context).colorScheme;
    // Only admins/managers may create announcements.
    final canCreate = context.select<AuthProvider, bool>((a) => a.isAdmin);

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Announcements',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17),
        ),
        actions: [
          if (canCreate)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 26),
              onPressed: () {
                final prov = context.read<AnnouncementProvider>();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewAnnouncementPage()),
                ).then((_) => prov.load());
              },
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<AnnouncementProvider>().load(),
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                // items (+ 1 footer "Create" row for admins only)
                itemCount: provider.items.length + (canCreate ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i < provider.items.length) {
                    final a = provider.items[i];
                    return _AnnouncementCard(
                      announcement: a,
                      onAccept: () =>
                          ctx.read<AnnouncementProvider>().markRead(a.id),
                    );
                  }
                  // Footer — create row (admins only)
                  return GestureDetector(
                    onTap: () {
                      final prov = ctx.read<AnnouncementProvider>();
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(builder: (_) => const NewAnnouncementPage()),
                      ).then((_) => prov.load());
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: cs.surfaceContainerHighest,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 28, height: 28,
                            decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Create an announcement',
                            style: TextStyle(
                              fontSize: 15,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement, required this.onAccept});
  final AnnouncementModel announcement;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        final prov = context.read<AnnouncementProvider>();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnnouncementDetailPage(announcement: announcement),
          ),
        ).then((_) => prov.load());
      },
      child: Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  announcement.author,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  announcement.createdAt,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  announcement.title,
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                ),
              ),
              if (!announcement.isRead)
                ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Accept', style: TextStyle(fontSize: 13)),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 16),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

// ── New Announcement Page ──────────────────────────────────────────────────────

class NewAnnouncementPage extends StatefulWidget {
  const NewAnnouncementPage({super.key});

  @override
  State<NewAnnouncementPage> createState() => _NewAnnouncementPageState();
}

class _NewAnnouncementPageState extends State<NewAnnouncementPage> {
  final _titleCtrl   = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _saving       = false;
  String? _fileName;
  final List<String> _selectedEmployeeIds = [];

  bool get _canSave => _messageCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && mounted) {
      setState(() => _fileName = result.files.single.name);
    }
  }

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);
    try {
      await ApiClient.instance.post(
        ApiConfig.announcements,
        data: {
          'title':   _titleCtrl.text.trim().isEmpty ? 'Untitled' : _titleCtrl.text.trim(),
          'message': _messageCtrl.text.trim(),
          if (_selectedEmployeeIds.isNotEmpty) 'targetUserIds': _selectedEmployeeIds,
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Announcement',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17),
        ),
        actions: [
          TextButton(
            onPressed: _canSave && !_saving ? _save : null,
            child: _saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    'Save',
                    style: TextStyle(
                      color: _canSave ? Colors.white : Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected employees row
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => MultiMemberPickerSheet(
                  initialSelectedIds: _selectedEmployeeIds.toSet(),
                  onDone: (picked) => setState(() {
                    _selectedEmployeeIds
                      ..clear()
                      ..addAll(picked.map((p) => p.id));
                  }),
                ),
              ),
              child: Container(
                color: cs.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.account_circle_outlined, size: 28, color: cs.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                          children: [
                            const TextSpan(text: 'Selected employees: '),
                            TextSpan(
                              text: '${_selectedEmployeeIds.length}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Title',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant)),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('(optional)',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            ),
            const SizedBox(height: 6),
            Container(
              color: cs.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _titleCtrl,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: 'Title',
                  hintStyle: TextStyle(color: cs.onSurfaceVariant),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Message label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Message',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant)),
            ),
            const SizedBox(height: 6),
            Container(
              color: cs.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _messageCtrl,
                onChanged: (_) => setState(() {}),
                minLines: 6,
                maxLines: 12,
                style: TextStyle(color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: 'Message',
                  hintStyle: TextStyle(color: cs.onSurfaceVariant),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Upload file
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                color: cs.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.upload_file_outlined,
                        size: 22, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _fileName ?? 'Upload file',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Announcement Detail / Edit Page ────────────────────────────────────────────

class AnnouncementDetailPage extends StatefulWidget {
  const AnnouncementDetailPage({super.key, required this.announcement});
  final AnnouncementModel announcement;

  @override
  State<AnnouncementDetailPage> createState() => _AnnouncementDetailPageState();
}

class _AnnouncementDetailPageState extends State<AnnouncementDetailPage> {
  late AnnouncementModel _announcement = widget.announcement;
  late final _titleCtrl   = TextEditingController(text: _announcement.title);
  late final _messageCtrl = TextEditingController(text: _announcement.message);
  bool _editing = false;
  bool _saving  = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_messageCtrl.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final updated = await context.read<AnnouncementProvider>().update(
        _announcement.id,
        title:   _titleCtrl.text.trim().isEmpty ? 'Untitled' : _titleCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _announcement = updated;
        _editing = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final canEdit = context.select<AuthProvider, bool>((a) => a.isAdmin);

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(_editing ? Icons.close : Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_editing) {
              setState(() {
                _editing = false;
                _titleCtrl.text   = _announcement.title;
                _messageCtrl.text = _announcement.message;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _editing ? 'Edit Announcement' : 'Announcement',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17),
        ),
        actions: [
          if (canEdit && !_editing)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: () => setState(() => _editing = true),
            ),
          if (_editing)
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _announcement.author,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
                  ),
                ),
                Text(
                  _announcement.createdAt,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_editing) ...[
              Text('Title',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant)),
              const SizedBox(height: 6),
              Container(
                color: cs.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _titleCtrl,
                  style: TextStyle(color: cs.onSurface),
                  decoration: const InputDecoration(hintText: 'Title', border: InputBorder.none),
                ),
              ),
              const SizedBox(height: 16),
              Text('Message',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant)),
              const SizedBox(height: 6),
              Container(
                color: cs.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _messageCtrl,
                  minLines: 6,
                  maxLines: 12,
                  style: TextStyle(color: cs.onSurface),
                  decoration: const InputDecoration(hintText: 'Message', border: InputBorder.none),
                ),
              ),
            ] else ...[
              Text(
                _announcement.title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
              ),
              const SizedBox(height: 12),
              Text(
                _announcement.message,
                style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant, height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
