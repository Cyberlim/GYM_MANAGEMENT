import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';

import 'package:gym_owner_web/data/api/api_service.dart';
import 'package:gym_owner_web/features/attendance/attendance_page.dart';
import 'package:intl/intl.dart';

class AttendanceNotifier extends AsyncNotifier<List<AttendanceRecord>> {
  @override
  Future<List<AttendanceRecord>> build() async {
    final selectedDate = ref.watch(selectedDateProvider);
    return _fetchAttendance(selectedDate);
  }

  Future<List<AttendanceRecord>> _fetchAttendance(DateTime date) async {
    try {
      final api = ApiService();
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final response = await api.get('/attendance?date=$dateStr');
      if (response != null && response is List) {
        return response.map((data) => AttendanceRecord.fromJson(data)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching attendance: $e');
      return [];
    }
  }

  Future<void> markAttendance(String memberId, String role, DateTime date, String status) async {
    final previousState = state;
    
    // Optimistic update
    final currentDateRecords = state.value ?? [];
    final existingIndex = currentDateRecords.indexWhere((r) => r.memberId == memberId);
    List<AttendanceRecord> updatedRecords = List.from(currentDateRecords);

    if (existingIndex >= 0) {
      updatedRecords[existingIndex] = AttendanceRecord(
        id: updatedRecords[existingIndex].id,
        memberId: memberId,
        date: date,
        checkInTime: status == 'Present' ? (updatedRecords[existingIndex].checkInTime ?? DateTime.now()) : null,
        status: status,
      );
    } else {
      updatedRecords.add(AttendanceRecord(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        memberId: memberId,
        date: date,
        checkInTime: status == 'Present' ? DateTime.now() : null,
        status: status,
      ));
    }
    state = AsyncValue.data(updatedRecords);

    try {
      final api = ApiService();
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      await api.post('/attendance', {
        'personId': memberId,
        'role': role,
        'date': dateStr,
        'status': status,
      });
      
      // Optionally refetch to ensure consistency
      // ref.invalidateSelf();
    } catch (e) {
      print('Error marking attendance: $e');
      // Revert optimistic update
      state = previousState;
    }
  }

  AttendanceRecord? getRecordForMember(String memberId, DateTime date) {
    try {
      final records = state.value ?? [];
      return records.firstWhere((record) => 
        record.memberId == memberId && 
        record.date.year == date.year && 
        record.date.month == date.month && 
        record.date.day == date.day
      );
    } catch (e) {
      return null;
    }
  }
}

final attendanceProvider = AsyncNotifierProvider<AttendanceNotifier, List<AttendanceRecord>>(AttendanceNotifier.new);
