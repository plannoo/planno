import 'package:aplano/pages/myschedule.dart';
import 'package:flutter/material.dart';


class TeamSchedulePage extends StatelessWidget {
  const TeamSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          _buildHeader(),
          const TabBar(
            labelColor: Color(0xFF2563EB),
            unselectedLabelColor: Color(0xFF64748B),
            indicatorColor: Color(0xFF2563EB),
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            tabs: [
              Tab(text: "My Schedule"),
              Tab(text: "Team Schedule"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                const MySchedulePage(),
                _buildTeamListView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.groups_rounded, color: Color(0xFF2563EB), size: 24),
          ),
          const SizedBox(width: 16),
          const Text(
            'Team Schedule',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const Spacer(),
          IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list_rounded, color: Color(0xFF64748B))),
          IconButton(onPressed: () {}, icon: const Icon(Icons.search, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildTeamListView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildHorizontalDatePicker(),
          const SizedBox(height: 24),
          _buildListHeader(),
          const SizedBox(height: 16),
          _buildStaffCard(
            "Sarah Jenkins",
            "09:00 - 17:00",
            "Cashier / Lead",
            "ACTIVE",
            const Color(0xFFDBEAFE),
            const Color(0xFF2563EB),
            "https://i.pravatar.cc/150?img=1",
          ),
          _buildStaffCard(
            "Marcus Rivera",
            "08:00 - 16:00",
            "Warehouse",
            null,
            null,
            null,
            "https://i.pravatar.cc/150?img=3",
          ),
          _buildStaffCard(
            "Emma Watson",
            "14:00 - 22:00",
            "Inventory Management",
            "ON CALL",
            const Color(0xFFFEF3C7),
            const Color(0xFFB45309),
            "https://i.pravatar.cc/150?img=5",
          ),
          _buildStaffCard(
            "David Kim",
            "10:00 - 18:00",
            "Front Desk",
            null,
            null,
            null,
            "https://i.pravatar.cc/150?img=8",
          ),
          _buildStaffCard(
            "Alex Thompson",
            "12:00 - 20:00",
            "Security",
            null,
            null,
            null,
            "https://i.pravatar.cc/150?img=11",
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                "END OF AFTERNOON SHIFTS",
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          _buildStaffCard(
            "Linda Ortega",
            "18:00 - 02:00",
            "Night Manager",
            null,
            null,
            null,
            "https://i.pravatar.cc/150?img=16",
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tuesday, Oct 13",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              "12 Staff Members • 14 Shifts",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.ios_share, size: 16),
          label: const Text(
            "Export",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0F172A),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        )
      ],
    );
  }

  Widget _buildStaffCard(
    String name,
    String time,
    String role,
    String? status,
    Color? statusBg,
    Color? statusText,
    String img,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(img),
            onBackgroundImageError: (exception, stackTrace) {},
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE2E8F0),
              ),
              child: const Icon(Icons.person, color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (status != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusText,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    children: [
                      TextSpan(
                        text: "$time  •  ",
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      TextSpan(text: role),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Color(0xFFCBD5E1),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalDatePicker() {
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
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item['day'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white70 : const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  item['date'] as String,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}