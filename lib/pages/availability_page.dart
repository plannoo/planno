import 'package:flutter/material.dart';

class AvailabilityPage extends StatefulWidget {
  const AvailabilityPage({super.key});

  @override
  State<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  // Mock data structure for days
  final List<DaySettings> _days = [
    DaySettings(day: "Monday", isEnabled: true, slots: [TimeSlot(start: "08:00", end: "17:00")]),
    DaySettings(day: "Tuesday", isEnabled: true, isAllDay: true),
    DaySettings(day: "Wednesday", isEnabled: true, slots: [TimeSlot(start: "09:00", end: "13:00")]),
    DaySettings(day: "Thursday", isEnabled: false),
    DaySettings(day: "Friday", isEnabled: true, isAllDay: true),
  ];
   void _toggleAllDay(int index) {
    setState(() {
      _days[index].isAllDay = !_days[index].isAllDay;
      if (_days[index].isAllDay) {
        _days[index].slots.clear();
      } else {
        _days[index].slots.add(TimeSlot(start: '09:00', end: '17:00'));
      }
    });
  }

  void _addTimeSlot(int dayIndex) {
    setState(() {
      _days[dayIndex].slots.add(TimeSlot(start: '09:00', end: '17:00'));
    });
  }

  void _removeTimeSlot(int dayIndex, int slotIndex) {
    setState(() {
      _days[dayIndex].slots.removeAt(slotIndex);
    });
  }

  Future<void> _selectTime(BuildContext context, int dayIndex, int slotIndex, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isStart) {
          _days[dayIndex].slots[slotIndex].start = timeString;
        } else {
          _days[dayIndex].slots[slotIndex].end = timeString;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Weekly Availability",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "Set your standard weekly routine. This will be used as your default availability for scheduling.",
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 15, height: 1.4),
                  ),
                ),
                ..._days.map((day) => _buildDayCard(day)).toList(),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Save Routine", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDayCard(DaySettings settings) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                settings.day,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: settings.isEnabled ? Colors.black : Colors.black38,
                ),
              ),
              Switch(
                value: settings.isEnabled,
                activeColor: const Color(0xFF2563EB),
                onChanged: (val) => setState(() => settings.isEnabled = val),
              ),
            ],
          ),
          if (!settings.isEnabled)
            const Text("Unavailable", style: TextStyle(color: Colors.black38, fontStyle: FontStyle.italic)),
          if (settings.isEnabled) ...[
            const SizedBox(height: 12),
            if (settings.isAllDay) _buildAllDayBadge() else ...[
              ...settings.slots.map((slot) => _buildTimeSlotRow(slot, settings)),
              TextButton.icon(
                onPressed: () => setState(() => settings.slots.add(TimeSlot(start: "09:00", end: "17:00"))),
                icon: const Icon(Icons.add, size: 18, color: Color(0xFF2563EB)),
                label: const Text("Add slot", style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildAllDayBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("All Day", style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
          Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 20),
        ],
      ),
    );
  }

  Widget _buildTimeSlotRow(TimeSlot slot, DaySettings day) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          _timePickerBox(slot.start),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("—", style: TextStyle(color: Colors.black38))),
          _timePickerBox(slot.end),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => setState(() => day.slots.remove(slot)),
          ),
        ],
      ),
    );
  }

  Widget _timePickerBox(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(time, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: ""),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: ""),
        BottomNavigationBarItem(icon: Icon(Icons.access_time), label: ""),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: ""),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: ""),
        BottomNavigationBarItem(icon: Icon(Icons.menu), label: ""),
      ],
    );
  }
}

class DaySettings {
  String day;
  bool isEnabled;
  bool isAllDay;
  List<TimeSlot> slots;
  DaySettings({required this.day, this.isEnabled = true, this.isAllDay = false, List<TimeSlot>? slots})
      : slots = slots ?? [];
}

class TimeSlot {
  String start;
  String end;
  TimeSlot({required this.start, required this.end});
}