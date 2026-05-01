import '../models/meeting.dart';

abstract class MeetingRepository {
  Stream<List<Meeting>> watchMeetings(String bookId);
  Future<Meeting?> getMeeting(String meetingId);
  Future<String> createMeeting(Meeting meeting);
  Future<void> updateMeeting(String meetingId, Map<String, dynamic> fields);
  Future<void> deleteMeeting(String meetingId);
}
