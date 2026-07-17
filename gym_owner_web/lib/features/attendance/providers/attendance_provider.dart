import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_web/data/models/gym_owner_models.dart';

import 'package:uuid/uuid.dart';

class AttendanceNotifier extends Notifier<List<AttendanceRecord>> {
  @override
  List<AttendanceRecord> build() {
    return [];
  }

  void markAttendance(String memberId, DateTime date, String status) {
    // Check if record already exists for this member on this date
    final existingIndex = state.indexWhere((record) => 
      record.memberId == memberId && 
      record.date.year == date.year && 
      record.date.month == date.month && 
      record.date.day == date.day
    );

    if (existingIndex >= 0) {
      // Update existing
      final existing = state[existingIndex];
      final updated = AttendanceRecord(
        id: existing.id,
        memberId: existing.memberId,
        date: existing.date,
        checkInTime: status == 'Present' ? (existing.checkInTime ?? DateTime.now()) : null,
        status: status,
      );
      
      state = [
        ...state.sublist(0, existingIndex),
        updated,
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      // Create new
      final newRecord = AttendanceRecord(
        id: const Uuid().v4(),
        memberId: memberId,
        date: DateTime(date.year, date.month, date.day),
        checkInTime: status == 'Present' ? DateTime.now() : null,
        status: status,
      );
      state = [...state, newRecord];
    }
  }

  AttendanceRecord? getRecordForMember(String memberId, DateTime date) {
    try {
      return state.firstWhere((record) => 
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

final attendanceProvider = NotifierProvider<AttendanceNotifier, List<AttendanceRecord>>(AttendanceNotifier.new);
