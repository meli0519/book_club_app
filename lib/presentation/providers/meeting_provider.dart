import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/meeting_service.dart';
import '../../domain/models/meeting.dart';
import '../../domain/repositories/meeting_repository.dart';
import 'auth_provider.dart';

final meetingServiceProvider =
    Provider<MeetingRepository>((ref) => MeetingService());

/// Stream of meetings for a given book, ordered by date ascending.
/// Guards against opening the Firestore stream before membership is confirmed
/// active, preventing a permission-denied error during the brief window
/// between router redirect and membership check completing.
final meetingsStreamProvider =
    StreamProvider.family<List<Meeting>, String>((ref, bookId) {
  // Wait for active membership before opening the stream, mirroring the
  // same guard used in booksStreamProvider.
  final membershipAsync = ref.watch(membershipStatusProvider);
  final membershipState = membershipAsync.valueOrNull;

  if (membershipState == null ||
      membershipState.status != MembershipStatus.active) {
    return const Stream.empty();
  }

  final service = ref.watch(meetingServiceProvider);
  return service.watchMeetings(bookId);
});
