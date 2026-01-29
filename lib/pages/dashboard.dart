import 'package:flutter/material.dart';

class AplanoDashboard extends StatelessWidget {
  const AplanoDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const CircleAvatar(radius: 20, backgroundColor: Color(0xFFE2E8F0)),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monday, Oct 24', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text('Good morning, Alex', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.notifications_none, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Clock In Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
                ),
                child: Column(
                  children: [
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)]),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Center(child: Text('APLANO', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white.withOpacity(0.2), letterSpacing: 4))),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Not Clocked In', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  Text("Today's Shift: 08:30 - 17:00", style: TextStyle(color: Color(0xFF64748B))),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                                child: const Text('00:00:00', style: TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.access_time),
                            label: const Text('Clock In Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Announcements
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Announcements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('View all', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildAnnounceCard("Team meeting on Friday", "Conference Room B • 10:00 AM", Colors.grey[300]!),
                    _buildAnnounceCard("New safety protocols", "Please review before shift", Colors.amber[100]!),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Quick Actions
              const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildAction("Open Shifts", "4 available", Icons.calendar_today, const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
                  _buildAction("Requests", "1 pending", Icons.swap_horiz, const Color(0xFFFFF7ED), const Color(0xFFF97316)),
                  _buildAction("Handover", "Start report", Icons.assignment_return, const Color(0xFFF5F3FF), const Color(0xFF8B5CF6)),
                ],
              ),
              const SizedBox(height: 32),

              // Weekly Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    const CircleAvatar(backgroundColor: Color(0xFF2563EB), child: Icon(Icons.bar_chart, color: Colors.white)),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Weekly Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('32.5 / 40 hours logged', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnounceCard(String title, String sub, Color color) => Container(
    width: 260, margin: const EdgeInsets.only(right: 16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 110, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(20)))),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(sub, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        )
      ],
    ),
  );

  Widget _buildAction(String label, String sub, IconData icon, Color bg, Color iconColor) => Container(
    width: 105, padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Column(
      children: [
        CircleAvatar(backgroundColor: bg, child: Icon(icon, color: iconColor)),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
      ],
    ),
  );
}