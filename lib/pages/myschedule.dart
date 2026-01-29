import 'package:flutter/material.dart';

class MySchedulePage extends StatelessWidget {
  const MySchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopAppBar(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildHorizontalDatePicker(),
                const SizedBox(height: 32),
                _buildSectionHeader("Today, Oct 13", "2 Shifts"),
                const SizedBox(height: 16),
                _buildPrimaryShiftCard(),
                const SizedBox(height: 16),
                _buildBackupShiftCard(),
                const SizedBox(height: 32),
                _buildWeeklyProgressCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_month, color: Color(0xFF2563EB), size: 24),
          ),
          const SizedBox(width: 16),
          const Text(
            'My Schedule',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const Spacer(),
          IconButton(onPressed: () {}, icon: const Icon(Icons.search, color: Color(0xFF64748B))),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildHorizontalDatePicker() {
    // Mock data for the horizontal calendar
    final days = [
      {'day': 'MON', 'date': '12', 'selected': false},
      {'day': 'TUE', 'date': '13', 'selected': true},
      {'day': 'WED', 'date': '14', 'selected': false},
      {'day': 'THU', 'date': '15', 'selected': false},
      {'day': 'FRI', 'date': '16', 'selected': false},
      {'day': 'SAT', 'date': '17', 'selected': false},
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = days[index];
          bool isSelected = item['selected'] as bool;
          return Container(
            width: 65,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2563EB) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isSelected ? null : Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: isSelected 
                ? [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] 
                : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item['day'] as String, 
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.w700, 
                    color: isSelected ? Colors.white.withOpacity(0.8) : const Color(0xFF94A3B8)
                  )
                ),
                const SizedBox(height: 4),
                Text(item['date'] as String, 
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.w800, 
                    color: isSelected ? Colors.white : const Color(0xFF1E293B)
                  )
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, String badge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(8)),
          child: Text(badge, style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildPrimaryShiftCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('MORNING SHIFT', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
              Icon(Icons.more_vert, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 4),
          const Text('09:00 - 17:00', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.work_outline, 'Cashier • Floor Manager'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.location_on_outlined, 'Downtown Branch - Main Entrance'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.access_time, size: 18),
                  label: const Text('Clock In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFF1F5F9)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(0, 48),
                    backgroundColor: const Color(0xFFF8FAFC),
                  ),
                  child: const Text('Details', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBackupShiftCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('EVENING BACKUP', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                child: const Text('ON CALL', style: TextStyle(color: Color(0xFFB45309), fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('18:30 - 22:00', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.inventory_2_outlined, 'Inventory • North Warehouse'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.map_outlined, 'Logistics Center A2'),
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('View Details', style: TextStyle(fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF475569),
                backgroundColor: const Color(0xFFF8FAFC),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Progress', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(text: '32.5 ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    TextSpan(text: '/ 40h', style: TextStyle(fontSize: 16, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Text('81% Complete', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.81,
              minHeight: 10,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 14)),
      ],
    );
  }
}