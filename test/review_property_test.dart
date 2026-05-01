// Feature: book-club-app
// Property 15: Upsert de FinalReview garantiza exactamente un documento por autor
// Property 18: Preguntas de reseña configurables por libro

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_club_app/domain/models/final_review.dart';

// ---------------------------------------------------------------------------
// Firestore helpers (mirror ReviewService upsert logic)
// ---------------------------------------------------------------------------

/// Upserts a FinalReview using authorId as the document ID.
Future<void> _upsertFinalReview(
  FakeFirebaseFirestore fakeFirestore,
  String bookId,
  String authorId,
  List<String> favoritePhrases,
  Map<String, String> answers,
) async {
  await fakeFirestore
      .collection('books')
      .doc(bookId)
      .collection('reviews')
      .doc(authorId)
      .set({
    'authorId': authorId,
    'favoritePhrases': favoritePhrases,
    'answers': answers,
    'updatedAt': Timestamp.fromDate(DateTime.now()),
  });
}

/// Returns all review documents for a given book.
Future<List<Map<String, dynamic>>> _getReviews(
  FakeFirebaseFirestore fakeFirestore,
  String bookId,
) async {
  final snapshot = await fakeFirestore
      .collection('books')
      .doc(bookId)
      .collection('reviews')
      .get();
  return snapshot.docs
      .map((doc) => doc.data() as Map<String, dynamic>)
      .toList();
}

// ---------------------------------------------------------------------------
// Test data generators
// ---------------------------------------------------------------------------

List<String> _generateBookIds() =>
    List.generate(20, (i) => 'book_$i') + ['book_alpha', 'book_beta'];

List<String> _generateAuthorIds() =>
    List.generate(20, (i) => 'user_$i') + ['leader_1', 'member_abc'];

List<List<String>> _generatePhraseLists() => [
      [],
      ['phrase one'],
      ['phrase one', 'phrase two'],
      ['a', 'b', 'c', 'd', 'e'],
      ['The quick brown fox', 'jumps over the lazy dog'],
      List.generate(10, (i) => 'phrase_$i'),
    ];

/// Generates varied answer maps for given question IDs.
Map<String, String> _buildAnswers(List<String> questionIds, int seed) {
  final answers = <String, String>{};
  for (int i = 0; i < questionIds.length; i++) {
    answers[questionIds[i]] = 'answer_${seed}_$i';
  }
  return answers;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final bookIds = _generateBookIds();
  final authorIds = _generateAuthorIds();
  final phraseLists = _generatePhraseLists();

  // -------------------------------------------------------------------------
  // P15: Upsert de FinalReview garantiza exactamente un documento por autor
  // Validates: Requirements 9.3, 9.4
  // -------------------------------------------------------------------------
  group('P15 - Upsert FinalReview guarantees exactly one document per author',
      () {
    test(
      'for any bookId and authorId, multiple upserts result in exactly one document',
      () async {
        for (int i = 0; i < bookIds.length; i++) {
          for (int j = 0; j < authorIds.length; j++) {
            final fakeFirestore = FakeFirebaseFirestore();
            final bookId = bookIds[i];
            final authorId = authorIds[j];
            final questionIds = ['q1', 'q2', 'q3'];

            // Upsert three times with different data
            await _upsertFinalReview(
              fakeFirestore,
              bookId,
              authorId,
              ['first phrase'],
              _buildAnswers(questionIds, 1),
            );
            await _upsertFinalReview(
              fakeFirestore,
              bookId,
              authorId,
              ['second phrase', 'another phrase'],
              _buildAnswers(questionIds, 2),
            );
            await _upsertFinalReview(
              fakeFirestore,
              bookId,
              authorId,
              ['final phrase'],
              _buildAnswers(questionIds, 3),
            );

            final reviews = await _getReviews(fakeFirestore, bookId);

            expect(
              reviews.length,
              equals(1),
              reason:
                  'books/$bookId/reviews must have exactly 1 doc for author $authorId',
            );

            final data = reviews.first;
            expect(data['authorId'], equals(authorId),
                reason: 'authorId must be preserved for $authorId');

            // Must contain data from the last upsert
            final phrases = List<String>.from(data['favoritePhrases'] as List);
            expect(phrases, equals(['final phrase']),
                reason:
                    'favoritePhrases must be from the last upsert for $authorId');

            final answers = Map<String, String>.from(data['answers'] as Map);
            expect(answers, equals(_buildAnswers(questionIds, 3)),
                reason: 'answers must be from the last upsert for $authorId');
          }
        }
      },
    );

    test(
      'upsert overwrites all fields including favoritePhrases and answers',
      () async {
        for (int i = 0; i < bookIds.length; i++) {
          final fakeFirestore = FakeFirebaseFirestore();
          final bookId = bookIds[i];
          final authorId = authorIds[i % authorIds.length];
          final questionIds = ['qa', 'qb'];

          // Submit all phrase lists in sequence
          for (int k = 0; k < phraseLists.length; k++) {
            await _upsertFinalReview(
              fakeFirestore,
              bookId,
              authorId,
              phraseLists[k],
              _buildAnswers(questionIds, k),
            );
          }

          final reviews = await _getReviews(fakeFirestore, bookId);

          expect(
            reviews.length,
            equals(1),
            reason:
                'Exactly 1 document must exist after multiple upserts for $authorId in $bookId',
          );

          final data = reviews.first;
          final lastPhrases = phraseLists.last;
          final lastAnswers =
              _buildAnswers(questionIds, phraseLists.length - 1);

          expect(
            List<String>.from(data['favoritePhrases'] as List),
            equals(lastPhrases),
            reason:
                'favoritePhrases must be from the last upsert for $authorId',
          );
          expect(
            Map<String, String>.from(data['answers'] as Map),
            equals(lastAnswers),
            reason: 'answers must be from the last upsert for $authorId',
          );
        }
      },
    );

    test(
      'different authors each get their own document',
      () async {
        final fakeFirestore = FakeFirebaseFirestore();
        const bookId = 'book_multi_author_review';
        final fiveAuthors = authorIds.take(5).toList();
        final questionIds = ['q1', 'q2'];

        for (int i = 0; i < fiveAuthors.length; i++) {
          await _upsertFinalReview(
            fakeFirestore,
            bookId,
            fiveAuthors[i],
            ['phrase_$i'],
            _buildAnswers(questionIds, i),
          );
        }

        final reviews = await _getReviews(fakeFirestore, bookId);

        expect(
          reviews.length,
          equals(5),
          reason:
              'Subcollection must have exactly 5 documents (one per author)',
        );

        for (int i = 0; i < fiveAuthors.length; i++) {
          final authorId = fiveAuthors[i];
          final doc = reviews.firstWhere(
            (d) => d['authorId'] == authorId,
            orElse: () =>
                throw TestFailure('No document found for authorId=$authorId'),
          );
          expect(doc['authorId'], equals(authorId),
              reason: 'authorId must match for $authorId');
          expect(
            List<String>.from(doc['favoritePhrases'] as List),
            equals(['phrase_$i']),
            reason: 'favoritePhrases must match for $authorId',
          );
        }
      },
    );

    test(
      'upsert for one book does not affect another book',
      () async {
        for (int i = 0; i < bookIds.length; i++) {
          final fakeFirestore = FakeFirebaseFirestore();
          final bookId1 = bookIds[i];
          final bookId2 = bookIds[(i + 1) % bookIds.length];
          final authorId = authorIds[i % authorIds.length];
          final questionIds = ['q1'];

          await _upsertFinalReview(
            fakeFirestore,
            bookId1,
            authorId,
            ['phrase for book1'],
            _buildAnswers(questionIds, 1),
          );
          await _upsertFinalReview(
            fakeFirestore,
            bookId2,
            authorId,
            ['phrase for book2'],
            _buildAnswers(questionIds, 2),
          );

          final reviews1 = await _getReviews(fakeFirestore, bookId1);
          final reviews2 = await _getReviews(fakeFirestore, bookId2);

          expect(reviews1.length, equals(1),
              reason: 'books/$bookId1/reviews must have exactly 1 doc');
          expect(reviews2.length, equals(1),
              reason: 'books/$bookId2/reviews must have exactly 1 doc');

          expect(
            List<String>.from(reviews1.first['favoritePhrases'] as List),
            equals(['phrase for book1']),
            reason: 'book1 review must have its own phrases',
          );
          expect(
            List<String>.from(reviews2.first['favoritePhrases'] as List),
            equals(['phrase for book2']),
            reason: 'book2 review must have its own phrases',
          );
        }
      },
    );

    test(
      'FinalReview.fromMap/toMap round-trip preserves all fields',
      () {
        for (final authorId in authorIds) {
          for (final phrases in phraseLists) {
            final answers = {'q1': 'answer1', 'q2': 'answer2'};
            final updatedAt = DateTime(2024, 6, 15, 12, 0);

            final original = FinalReview(
              authorId: authorId,
              favoritePhrases: phrases,
              answers: answers,
              updatedAt: updatedAt,
            );

            final map = original.toMap();
            final restored = FinalReview.fromMap(map, authorId);

            expect(restored.authorId, equals(authorId),
                reason: 'authorId must survive round-trip for $authorId');
            expect(restored.favoritePhrases, equals(phrases),
                reason:
                    'favoritePhrases must survive round-trip for $authorId');
            expect(restored.answers, equals(answers),
                reason: 'answers must survive round-trip for $authorId');
          }
        }
      },
    );

    test(
      'updatedAt is set to the time of the last upsert',
      () async {
        final fakeFirestore = FakeFirebaseFirestore();
        const bookId = 'book_updated_at';
        const authorId = 'user_updated_at';
        final questionIds = ['q1'];

        final before = DateTime.now();
        await _upsertFinalReview(
          fakeFirestore,
          bookId,
          authorId,
          ['phrase'],
          _buildAnswers(questionIds, 1),
        );
        final after = DateTime.now();

        final reviews = await _getReviews(fakeFirestore, bookId);
        expect(reviews.length, equals(1));

        final updatedAt =
            (reviews.first['updatedAt'] as Timestamp).toDate();
        expect(
          updatedAt.isAfter(before.subtract(const Duration(seconds: 1))) &&
              updatedAt.isBefore(after.add(const Duration(seconds: 1))),
          isTrue,
          reason: 'updatedAt must be set to approximately now',
        );
      },
    );
  });

  // -------------------------------------------------------------------------
  // P18: Preguntas de reseña configurables por libro
  // Validates: Requirements 9.1, 9.2, 9.3
  // -------------------------------------------------------------------------
  group('P18 - Review questions configurable per book', () {
    test(
      'answers map contains exactly the keys from reviewQuestionIds',
      () async {
        // Test with varied sets of question IDs
        final questionIdSets = [
          ['q1'],
          ['q1', 'q2'],
          ['q1', 'q2', 'q3'],
          ['qa', 'qb', 'qc', 'qd'],
          List.generate(5, (i) => 'question_$i'),
          List.generate(10, (i) => 'q_${i * 3 + 1}'),
        ];

        for (int i = 0; i < bookIds.length; i++) {
          for (final questionIds in questionIdSets) {
            final fakeFirestore = FakeFirebaseFirestore();
            final bookId = bookIds[i];
            final authorId = authorIds[i % authorIds.length];

            // Build answers with exactly the book's question IDs
            final answers = <String, String>{};
            for (final qId in questionIds) {
              answers[qId] = 'non-empty answer for $qId';
            }

            await _upsertFinalReview(
              fakeFirestore,
              bookId,
              authorId,
              ['a phrase'],
              answers,
            );

            final reviews = await _getReviews(fakeFirestore, bookId);
            expect(reviews.length, equals(1));

            final storedAnswers =
                Map<String, String>.from(reviews.first['answers'] as Map);

            // The stored answers must have exactly the same keys as reviewQuestionIds
            expect(
              storedAnswers.keys.toSet(),
              equals(questionIds.toSet()),
              reason:
                  'answers keys must match reviewQuestionIds for book $bookId',
            );

            // Each answer must be a non-empty string
            for (final entry in storedAnswers.entries) {
              expect(
                entry.value.isNotEmpty,
                isTrue,
                reason:
                    'answer for question ${entry.key} must be non-empty in book $bookId',
              );
            }
          }
        }
      },
    );

    test(
      'answers map has no extra keys beyond reviewQuestionIds',
      () async {
        final fakeFirestore = FakeFirebaseFirestore();
        const bookId = 'book_exact_keys';
        const authorId = 'user_exact_keys';
        final questionIds = ['q1', 'q2', 'q3'];

        // Only provide answers for the book's question IDs (no extras)
        final answers = {
          'q1': 'answer to q1',
          'q2': 'answer to q2',
          'q3': 'answer to q3',
        };

        await _upsertFinalReview(
          fakeFirestore,
          bookId,
          authorId,
          [],
          answers,
        );

        final reviews = await _getReviews(fakeFirestore, bookId);
        final storedAnswers =
            Map<String, String>.from(reviews.first['answers'] as Map);

        expect(
          storedAnswers.keys.toSet(),
          equals(questionIds.toSet()),
          reason: 'answers must have exactly the book question IDs, no extras',
        );
        expect(
          storedAnswers.length,
          equals(questionIds.length),
          reason: 'answers count must equal reviewQuestionIds count',
        );
      },
    );

    test(
      'each answer must be a non-empty string for all question IDs',
      () async {
        // Test with many different author/book combinations
        for (int i = 0; i < bookIds.length; i++) {
          for (int j = 0; j < authorIds.length; j++) {
            final fakeFirestore = FakeFirebaseFirestore();
            final bookId = bookIds[i];
            final authorId = authorIds[j];
            final questionIds = ['q1', 'q2', 'q3'];

            final answers = <String, String>{};
            for (int k = 0; k < questionIds.length; k++) {
              answers[questionIds[k]] = 'answer_${i}_${j}_$k';
            }

            await _upsertFinalReview(
              fakeFirestore,
              bookId,
              authorId,
              [],
              answers,
            );

            final reviews = await _getReviews(fakeFirestore, bookId);
            final storedAnswers =
                Map<String, String>.from(reviews.first['answers'] as Map);

            for (final qId in questionIds) {
              expect(
                storedAnswers.containsKey(qId),
                isTrue,
                reason:
                    'answers must contain key $qId for author $authorId in book $bookId',
              );
              expect(
                storedAnswers[qId]!.isNotEmpty,
                isTrue,
                reason:
                    'answer for $qId must be non-empty for author $authorId in book $bookId',
              );
            }
          }
        }
      },
    );

    test(
      'different books can have different sets of review question IDs',
      () async {
        final fakeFirestore = FakeFirebaseFirestore();
        const authorId = 'user_multi_book';

        // Book A has questions [q1, q2]
        const bookA = 'book_A';
        final questionsA = ['q1', 'q2'];
        final answersA = {'q1': 'answer A1', 'q2': 'answer A2'};

        // Book B has questions [q3, q4, q5]
        const bookB = 'book_B';
        final questionsB = ['q3', 'q4', 'q5'];
        final answersB = {
          'q3': 'answer B3',
          'q4': 'answer B4',
          'q5': 'answer B5'
        };

        await _upsertFinalReview(
            fakeFirestore, bookA, authorId, [], answersA);
        await _upsertFinalReview(
            fakeFirestore, bookB, authorId, [], answersB);

        final reviewsA = await _getReviews(fakeFirestore, bookA);
        final reviewsB = await _getReviews(fakeFirestore, bookB);

        final storedAnswersA =
            Map<String, String>.from(reviewsA.first['answers'] as Map);
        final storedAnswersB =
            Map<String, String>.from(reviewsB.first['answers'] as Map);

        expect(storedAnswersA.keys.toSet(), equals(questionsA.toSet()),
            reason: 'Book A answers must match its question IDs');
        expect(storedAnswersB.keys.toSet(), equals(questionsB.toSet()),
            reason: 'Book B answers must match its question IDs');

        // Verify no cross-contamination
        for (final qId in questionsB) {
          expect(storedAnswersA.containsKey(qId), isFalse,
              reason: 'Book A answers must not contain Book B question $qId');
        }
        for (final qId in questionsA) {
          expect(storedAnswersB.containsKey(qId), isFalse,
              reason: 'Book B answers must not contain Book A question $qId');
        }
      },
    );

    test(
      'book with no review questions stores empty answers map',
      () async {
        for (int i = 0; i < bookIds.length; i++) {
          final fakeFirestore = FakeFirebaseFirestore();
          final bookId = bookIds[i];
          final authorId = authorIds[i % authorIds.length];

          // Book with no review questions → empty answers map
          await _upsertFinalReview(
            fakeFirestore,
            bookId,
            authorId,
            ['a phrase'],
            {},
          );

          final reviews = await _getReviews(fakeFirestore, bookId);
          expect(reviews.length, equals(1));

          final storedAnswers =
              Map<String, String>.from(reviews.first['answers'] as Map);
          expect(
            storedAnswers.isEmpty,
            isTrue,
            reason:
                'answers must be empty when book has no review questions for $bookId',
          );
        }
      },
    );

    test(
      'upsert with updated answers replaces previous answers map entirely',
      () async {
        final fakeFirestore = FakeFirebaseFirestore();
        const bookId = 'book_answers_update';
        const authorId = 'user_answers_update';
        final questionIds = ['q1', 'q2', 'q3'];

        // First submission
        final firstAnswers = {
          'q1': 'first answer 1',
          'q2': 'first answer 2',
          'q3': 'first answer 3',
        };
        await _upsertFinalReview(
            fakeFirestore, bookId, authorId, [], firstAnswers);

        // Second submission with updated answers
        final secondAnswers = {
          'q1': 'updated answer 1',
          'q2': 'updated answer 2',
          'q3': 'updated answer 3',
        };
        await _upsertFinalReview(
            fakeFirestore, bookId, authorId, [], secondAnswers);

        final reviews = await _getReviews(fakeFirestore, bookId);
        expect(reviews.length, equals(1),
            reason: 'Must still have exactly 1 document after re-submission');

        final storedAnswers =
            Map<String, String>.from(reviews.first['answers'] as Map);

        expect(storedAnswers.keys.toSet(), equals(questionIds.toSet()),
            reason: 'answers keys must match reviewQuestionIds');

        for (final qId in questionIds) {
          expect(storedAnswers[qId], equals(secondAnswers[qId]),
              reason:
                  'answer for $qId must be from the second (latest) submission');
        }
      },
    );
  });
}
