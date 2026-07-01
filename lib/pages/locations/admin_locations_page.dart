import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';

/// Admin screen to manage work locations employees clock in at.
/// Backed by /api/locations (CRUD, requires `locations:manage`).
class AdminLocationsPage extends StatefulWidget {
  const AdminLocationsPage({super.key});

  @override
  State<AdminLocationsPage> createState() => _AdminLocationsPageState();
}

class _AdminLocationsPageState extends State<AdminLocationsPage> {
  List<_Location> _locations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res  = await ApiClient.instance.get('/api/locations?limit=100');
      final data = res is Map<String, dynamic>
          ? (res['data'] as List<dynamic>? ?? [])
          : (res as List<dynamic>? ?? []);
      final locs = data
          .map((e) => _Location.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() { _locations = locs; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _openEditor([_Location? existing]) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationEditorSheet(existing: existing),
    );
    if (changed == true) _load();
  }

  Future<void> _confirmDelete(_Location loc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text('Delete location'),
        content: Text('Delete "${loc.name}"? Shifts referencing it may be affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.instance.delete('/api/locations/${loc.id}');
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      appBar: AppBar(
        title: const Text('Locations'),
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add location'),
      ),
      body: _buildBody(cs),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_locations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined,
                size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('No locations yet',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15)),
            const SizedBox(height: 4),
            Text('Add one so employees can clock in.',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _locations.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final loc = _locations[i];
          return _LocationCard(
            loc: loc,
            onEdit: () => _openEditor(loc),
            onDelete: () => _confirmDelete(loc),
          );
        },
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.loc, required this.onEdit, required this.onDelete});
  final _Location loc;
  final VoidCallback onEdit, onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.place_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.name,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700,
                            color: cs.onSurface)),
                    if (loc.address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(loc.address,
                          style: TextStyle(
                              fontSize: 13, color: cs.onSurfaceVariant)),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${loc.latitude.toStringAsFixed(4)}, '
                      '${loc.longitude.toStringAsFixed(4)}  Â·  ${loc.radius.toStringAsFixed(0)} m',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Add / edit sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _LocationEditorSheet extends StatefulWidget {
  const _LocationEditorSheet({this.existing});
  final _Location? existing;

  @override
  State<_LocationEditorSheet> createState() => _LocationEditorSheetState();
}

class _LocationEditorSheetState extends State<_LocationEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late final TextEditingController _radius;
  bool _saving = false;
  bool _locating = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name    = TextEditingController(text: e?.name ?? '');
    _address = TextEditingController(text: e?.address ?? '');
    _lat     = TextEditingController(text: e != null ? e.latitude.toString() : '');
    _lng     = TextEditingController(text: e != null ? e.longitude.toString() : '');
    _radius  = TextEditingController(text: e != null ? e.radius.toStringAsFixed(0) : '150');
  }

  @override
  void dispose() {
    _name.dispose(); _address.dispose();
    _lat.dispose(); _lng.dispose(); _radius.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _lat.text = pos.latitude.toStringAsFixed(6);
        _lng.text = pos.longitude.toStringAsFixed(6);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Name is required'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final body = {
        'name':      name,
        'address':   _address.text.trim(),
        'latitude':  double.tryParse(_lat.text.trim()) ?? 0,
        'longitude': double.tryParse(_lng.text.trim()) ?? 0,
        'radius':    double.tryParse(_radius.text.trim()) ?? 150,
      };
      if (_isEdit) {
        await ApiClient.instance.put('/api/locations/${widget.existing!.id}', data: body);
      } else {
        await ApiClient.instance.post('/api/locations', data: body);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: cs.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(_isEdit ? 'Edit location' : 'New location',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
                const SizedBox(height: 18),
                _field(cs, 'Name', _name, hint: 'e.g. Hauptstandort'),
                const SizedBox(height: 14),
                _field(cs, 'Address', _address, hint: 'Street, city'),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _field(cs, 'Latitude', _lat,
                        keyboard: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                    const SizedBox(width: 12),
                    Expanded(child: _field(cs, 'Longitude', _lng,
                        keyboard: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _locating ? null : _useMyLocation,
                    icon: _locating
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location, size: 18),
                    label: const Text('Use my current location'),
                  ),
                ),
                const SizedBox(height: 4),
                _field(cs, 'Geofence radius (meters)', _radius,
                    keyboard: TextInputType.number),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Text(_isEdit ? 'Save changes' : 'Create location',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(ColorScheme cs, String label, TextEditingController c,
      {String? hint, TextInputType? keyboard}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: cs.onSurface)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          keyboardType: keyboard,
          style: TextStyle(color: cs.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
            ),
          ),
        ),
      ],
    );
  }
}

// â”€â”€ Model â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _Location {
  final String id, name, address;
  final double latitude, longitude, radius;

  const _Location({
    required this.id, required this.name, required this.address,
    required this.latitude, required this.longitude, required this.radius,
  });

  factory _Location.fromJson(Map<String, dynamic> j) => _Location(
        id:        j['id']?.toString() ?? '',
        name:      j['name'] as String? ?? '',
        address:   j['address'] as String? ?? '',
        latitude:  (j['latitude']  as num?)?.toDouble() ?? 0,
        longitude: (j['longitude'] as num?)?.toDouble() ?? 0,
        radius:    (j['radius'] as num?)?.toDouble()
                 ?? (j['geofenceRadiusMeters'] as num?)?.toDouble() ?? 150,
      );
}
