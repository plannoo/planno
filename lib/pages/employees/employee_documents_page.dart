import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/file_saver.dart';


class EmployeeDocumentsPage extends StatefulWidget {
  const EmployeeDocumentsPage({
    super.key, required this.userId, required this.name,
    this.titleOverride, this.self = false,
  });
  final String userId;
  final String name;
  final String? titleOverride;
  /// When true, uses the `/api/documents/me*` endpoints (own documents).
  final bool self;

  @override
  State<EmployeeDocumentsPage> createState() => _EmployeeDocumentsPageState();
}

class _EmployeeDocumentsPageState extends State<EmployeeDocumentsPage> {
  List<Map<String, dynamic>> _docs = [];
  bool _loading = true;
  String? _error;

  // Endpoint bases differ for self vs admin.
  String get _listPath => widget.self ? '/api/documents/me' : '/api/documents/${widget.userId}';
  String _itemPath(String id) =>
      widget.self ? '/api/documents/me/$id' : '/api/documents/${widget.userId}/$id';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await ApiClient.instance.get(_listPath);
      final wrap = (data is Map<String, dynamic>) ? data : <String, dynamic>{};
      // Backend returns { documents: [...], owner, nextCursor? }
      final raw = (wrap['documents'] ?? wrap['data'] ?? []) as List? ?? [];
      if (mounted) {
        setState(() {
          _docs    = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      // An empty list here is indistinguishable from "no documents" — and the
      // org can now disable document viewing outright, so say why.
      if (mounted) {
        setState(() {
          _docs = [];
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  /// Every mutation on this page reports failures the same way; renaming and
  /// deleting used to swallow them, so the row simply never changed.
  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _upload(bool image) async {
    final r = await FilePicker.platform.pickFiles(
      type: image ? FileType.image : FileType.any,
      withData: true,
    );
    if (r == null || !mounted) return;
    final picked = r.files.single;
    try {
      final multipart = picked.path != null
          ? await MultipartFile.fromFile(picked.path!, filename: picked.name)
          : MultipartFile.fromBytes(picked.bytes ?? [], filename: picked.name);
      final form = FormData.fromMap({ 'file': multipart });
      await ApiClient.instance.post(_listPath, data: form);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _showUploadTypeSheet() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Welchen Datei-Typ möchten Sie hochladen?'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () { Navigator.pop(ctx); _upload(true); },
            child: const Text('Bild'),
          ),
          CupertinoActionSheetAction(
            onPressed: () { Navigator.pop(ctx); _upload(false); },
            child: const Text('Dokument'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Abbrechen'),
        ),
      ),
    );
  }

  /// Fetches the document's bytes (authenticated) and triggers a download.
  Future<void> _downloadDoc(Map<String, dynamic> doc) async {
    final id = doc['id'] as String?;
    if (id == null) return;
    try {
      final res = await ApiClient.instance.get(
        _itemPath(id),
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = (res as List).cast<int>();
      final name  = doc['fileName'] as String? ?? 'document';
      final mime  = doc['mimeType'] as String? ?? 'application/octet-stream';
      await saveFile(bytes, name, mime);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showDocActions(Map<String, dynamic> doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DocActionsSheet(
        filename: doc['fileName'] as String? ?? '',
        onDownload: () async {
          Navigator.pop(context);
          await _downloadDoc(doc);
        },
        onRename:   () async { Navigator.pop(context); _promptRename(doc); },
        onDelete:   () async { Navigator.pop(context); _confirmDelete(doc); },
      ),
    );
  }

  Future<void> _promptRename(Map<String, dynamic> doc) async {
    final result = await showModalBottomSheet<({String name, String comment})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RenameDocumentSheet(
        initialName:    doc['fileName']    as String? ?? '',
        initialComment: doc['description'] as String? ?? '',
      ),
    );
    if (result == null || !mounted) return;
    try {
      // Backend stores a free-text `description`; the immutable file name stays.
      await ApiClient.instance.patch(
          _itemPath(doc['id'] as String), data: {'description': result.comment});
      _load();
    } catch (e) { _showError(e); }
  }

  Future<void> _confirmDelete(Map<String, dynamic> doc) async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete document?'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ApiClient.instance.delete(_itemPath(doc['id'] as String));
      _load();
    } catch (e) { _showError(e); }
  }

  String _fmtSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }

  String _fmtUploaded(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso);
      final locale = Intl.defaultLocale ?? 'en';
      final isDE = locale.startsWith('de');
      final datePart = DateFormat(isDE ? 'd. MMMM yyyy' : 'MMMM d, yyyy', locale).format(d);
      final time = '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
      return 'Uploaded on $datePart, $time';
    } catch (_) { return iso; }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 14),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                          widget.titleOverride ?? 'Documents: ${widget.name}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.upload_outlined, color: Colors.white),
                      onPressed: _showUploadTypeSheet,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_docs.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 42),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.insert_drive_file_outlined,
                                    size: 56, color: cs.onSurfaceVariant),
                                const SizedBox(height: 12),
                                Text(
                                    _error ??
                                        'No documents have been uploaded yet',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 15, color: cs.onSurface)),
                              ],
                            ),
                          )
                        else Container(
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            children: [
                              for (int i = 0; i < _docs.length; i++) ...[
                                if (i > 0)
                                  Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                                _DocCard(
                                  doc: _docs[i],
                                  sizeLabel:     _fmtSize((_docs[i]['sizeBytes'] as num?)?.toInt()),
                                  uploadedLabel: _fmtUploaded(_docs[i]['createdAt'] as String?),
                                  onTap: () => _showDocActions(_docs[i]),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showUploadTypeSheet,
                          icon: const Icon(Icons.upload_outlined,
                              color: Colors.white, size: 20),
                          label: const Text('Upload document',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  const _DocCard({
    required this.doc, required this.sizeLabel,
    required this.uploadedLabel, required this.onTap,
  });
  final Map<String, dynamic> doc;
  final String sizeLabel, uploadedLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs   = Theme.of(context).colorScheme;
    final name = doc['fileName']    as String? ?? '';
    final tag  = doc['description'] as String? ?? '';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.insert_drive_file_outlined,
                color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                  const SizedBox(height: 4),
                  if (uploadedLabel.isNotEmpty)
                    Text(uploadedLabel,
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  if (sizeLabel.isNotEmpty)
                    Text(sizeLabel,
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  if (tag.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5C100),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(tag,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text('Visible for employees',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500)),
                    ],
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

// ── Document actions sheet ────────────────────────────────────────────────────

class _DocActionsSheet extends StatelessWidget {
  const _DocActionsSheet({
    required this.filename, required this.onDownload,
    required this.onRename, required this.onDelete,
  });
  final String       filename;
  final VoidCallback onDownload, onRename, onDelete;

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
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: 22, color: cs.onSurfaceVariant),
                  ),
                  Expanded(
                    child: Text(filename,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 22),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
            _action(cs, Icons.download_outlined, 'Download',
                AppColors.success, onDownload),
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
            _action(cs, Icons.edit_outlined, 'Rename',
                AppColors.primary, onRename),
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
            _action(cs, Icons.delete_outline, 'Delete',
                AppColors.error, onDelete, textColor: AppColors.error),
          ],
        ),
      ),
    );
  }

  Widget _action(ColorScheme cs, IconData icon, String label, Color iconColor,
      VoidCallback onTap, {Color? textColor}) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 16),
          Text(label,
              style: TextStyle(
                  fontSize: 17,
                  color: textColor ?? cs.onSurface,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    ),
  );
}

// ── Rename document sheet ─────────────────────────────────────────────────────

class _RenameDocumentSheet extends StatefulWidget {
  const _RenameDocumentSheet({required this.initialName, required this.initialComment});
  final String initialName, initialComment;

  @override
  State<_RenameDocumentSheet> createState() => _RenameDocumentSheetState();
}

class _RenameDocumentSheetState extends State<_RenameDocumentSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _commentCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl    = TextEditingController(text: widget.initialName);
    _commentCtrl = TextEditingController(text: widget.initialComment);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 22, color: cs.onSurfaceVariant),
                ),
                const Expanded(
                  child: Text('Rename Document',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 22),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name',
                    style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: cs.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Comment',
                    style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
                const SizedBox(height: 6),
                TextField(
                  controller: _commentCtrl,
                  decoration: InputDecoration(
                    hintText: 'Comment',
                    filled: true,
                    fillColor: cs.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, (
                        name:    _nameCtrl.text.trim(),
                        comment: _commentCtrl.text.trim(),
                      )),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                      child: const Text('Save',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
