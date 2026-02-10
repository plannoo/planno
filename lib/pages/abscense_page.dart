import 'package:flutter/material.dart';

// Constants
const Color _primaryColor = Color(0xFF2563EB);
const Color _darkColor = Color(0xFF0F172A);
const Color _lightGrayColor = Color(0xFFE2E8F0);
const Color _bgColor = Color(0xFFF8FAFC);
const Color _successColor = Color(0xFF22C55E);
const Color _infoColor = Color(0xFFEFF6FF);
const Color _infoBgColor = Color(0xFFDBEAFE);

class NewAbsencePage extends StatefulWidget {
  const NewAbsencePage({super.key});

  @override
  State<NewAbsencePage> createState() => _NewAbsencePageState();
}

class _NewAbsencePageState extends State<NewAbsencePage> {
  String? _selectedType;
  DateTime _startDate = DateTime(2024, 6, 12);
  DateTime _endDate = DateTime(2024, 6, 15);
  final TextEditingController _reasonController = TextEditingController();

  final List<({String label, IconData icon})> _absenceTypes = [
    (label: 'Vacation', icon: Icons.beach_access),
    (label: 'Sick Leave', icon: Icons.local_hospital),
    (label: 'Personal Day', icon: Icons.person),
    (label: 'Other', icon: Icons.more_horiz),
  ];

  int get _totalDays => _endDate.difference(_startDate).inDays + 1;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _primaryColor,
            onPrimary: Colors.white,
            onSurface: _darkColor,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        } else {
          _endDate = picked.isBefore(_startDate) ? _startDate : picked;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showTypeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModalHandle(),
            const SizedBox(height: 20),
            _buildSectionLabel('Select Absence Type'),
            const SizedBox(height: 20),
            ..._absenceTypes.map((type) => _buildTypeOption(type.label, type.icon)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildModalHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: _lightGrayColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildTypeOption(String type, IconData icon) {
    return InkWell(
      onTap: () {
        setState(() => _selectedType = type);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedType == type ? _primaryColor : _lightGrayColor,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF64748B)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                type,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _darkColor,
                ),
              ),
            ),
            if (_selectedType == type)
              const Icon(Icons.check_circle, color: _primaryColor),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 24),
            _buildDateSelector(),
            const SizedBox(height: 24),
            _buildDurationCard(),
            const SizedBox(height: 24),
            _buildReasonSection(),
            const SizedBox(height: 24),
            _buildApprovalInfo(),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _buildSubmitButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text(
          'Cancel',
          style: TextStyle(
            color: _primaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      leadingWidth: 80,
      centerTitle: true,
      title: const Text(
        'New Absence',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _darkColor,
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Absence Type'),
        const SizedBox(height: 8),
        _buildSelectDropdown(
          label: _selectedType ?? 'Select type...',
          isPlaceholder: _selectedType == null,
          onTap: _showTypeSelector,
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildDateColumn('Start Date', _startDate, () => _selectDate(context, true)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDateColumn('End Date', _endDate, () => _selectDate(context, false)),
        ),
      ],
    );
  }

  Widget _buildDateColumn(String label, DateTime date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(label),
        const SizedBox(height: 8),
        _buildDatePickerField(date, onTap),
      ],
    );
  }

  Widget _buildSelectDropdown({
    required String label,
    required bool isPlaceholder,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _lightGrayColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: isPlaceholder ? const Color(0xFF94A3B8) : _darkColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerField(DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _lightGrayColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF64748B), size: 20),
            const SizedBox(width: 12),
            Text(
              _formatDate(date),
              style: const TextStyle(
                fontSize: 16,
                color: _darkColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _infoColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL DURATION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$_totalDays ',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: _darkColor,
                        ),
                      ),
                      const TextSpan(
                        text: 'days',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _infoBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.info_outline, color: _primaryColor, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionLabel('Reason'),
            const Spacer(),
            Text(
              'Optional',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildTextInputField(),
      ],
    );
  }

  Widget _buildTextInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lightGrayColor),
      ),
      child: TextField(
        controller: _reasonController,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'Add any extra notes for your manager...',
          hintStyle: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
        ),
        style: const TextStyle(fontSize: 15, color: _darkColor),
      ),
    );
  }

  Widget _buildApprovalInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _lightGrayColor),
      ),
      child: const Text(
        'Your request will be sent to your manager for approval. You will receive a notification once a decision is made.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton.icon(
          onPressed: _selectedType != null ? _handleSubmit : null,
          icon: const Icon(Icons.arrow_forward, size: 20),
          label: const Text(
            'Submit Request',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _lightGrayColor,
            disabledForegroundColor: const Color(0xFF94A3B8),
            elevation: 0,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Absence request submitted successfully'),
        backgroundColor: _successColor,
      ),
    );
    Navigator.pop(context);
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: _darkColor,
      ),
    );
  }
}