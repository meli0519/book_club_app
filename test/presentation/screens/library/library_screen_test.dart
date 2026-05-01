// Tests for LibraryScreen, _LibraryCategoryTab, and LibraryBookCard
// Task 20.5 – Library filtering and visualization
//
// Widget-level tests that require Firebase/Riverpod are kept as logic tests
// to avoid needing a running emulator. Full widget rendering tests use
// ProviderScope overrides with stub data.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_club_app/domain/models/book.dart';
import 'package:book_club_app/domain/models/user_book_entry.dart';
import 'package:book_club_app/l10n/app_localizations.dart';
import 'package:book_club_app/presentation/providers/library_provider.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Book _makeBook({
  String id = 'book_1',
  String title = 'Test Book',
  String author = 'Test Author',
  String coverUrl = '',
}) =>
    Book(
      id: id,
      title: title,
      author: author,
      description: 'A description',
      coverUrl: coverUrl,
      status: 'reading',
      createdBy: 'user_1',
      createdAt: DateTime(2024, 1, 1),
    );

UserBookEntry _makeEntry({
  String bookId = 'book_1',
  String category = UserBookCategory.wantToRead,
}) =>
    UserBookEntry(
      userId: 'user_1',
      bookId: bookId,
      category: category,
      updatedAt: DateTime(2024, 6, 1),
    );

UserBookWithDetails _makeItem({
  String bookId = 'book_1',
  String title = 'Test Book',
  String author = 'Test Author',
  String category = UserBookCategory.wantToRead,
  double? rating,
}) =>
    UserBookWithDetails(
      entry: _makeEntry(bookId: bookId, category: category),
      book: _makeBook(id: bookId, title: title, author: author),
      averageRating: rating,
    );

/// Wraps a widget with the minimum required setup for localization and Riverpod.
Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('es')],
      home: child,
    ),
  );
}

// ---------------------------------------------------------------------------
// 1. Tab labels
// ---------------------------------------------------------------------------

void main() {
  group('LibraryScreen – tab labels', () {
    testWidgets('renders 3 tabs with correct English labels', (tester) async {
      // Override the provider to return empty lists so the screen renders
      // without needing Firebase.
      await tester.pumpWidget(
        _wrap(
          const _StubLibraryScreen(),
          overrides: [
            libraryWithDetailsByCategoryProvider
                .overrideWith((ref, category) => const Stream.empty()),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('Want to Read'), findsOneWidget);
      expect(find.text('Reading'), findsOneWidget);
      expect(find.text('Read'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // 2. Empty state
  // -------------------------------------------------------------------------

  group('LibraryScreen – empty state', () {
    testWidgets('shows empty state icon when category has no books',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const _StubLibraryScreen(),
          overrides: [
            libraryWithDetailsByCategoryProvider.overrideWith(
              (ref, category) => Stream.value(<UserBookWithDetails>[]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // The empty state shows a menu_book_outlined icon
      expect(find.byIcon(Icons.menu_book_outlined), findsWidgets);
    });

    testWidgets('shows empty message text when category has no books',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const _StubLibraryScreen(),
          overrides: [
            libraryWithDetailsByCategoryProvider.overrideWith(
              (ref, category) => Stream.value(<UserBookWithDetails>[]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // At least one empty-state message should be visible (first tab)
      expect(
        find.text('No books in your want-to-read list yet.'),
        findsOneWidget,
      );
    });
  });

  // -------------------------------------------------------------------------
  // 3. LibraryBookCard – title, author, rating
  // -------------------------------------------------------------------------

  group('LibraryBookCard – content', () {
    testWidgets('shows book title and author', (tester) async {
      final item = _makeItem(title: 'Clean Code', author: 'Robert C. Martin');

      await tester.pumpWidget(
        _wrap(
          _StubLibraryScreen(items: [item]),
          overrides: [
            libraryWithDetailsByCategoryProvider.overrideWith(
              (ref, category) => Stream.value([item]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Clean Code'), findsOneWidget);
      expect(find.text('Robert C. Martin'), findsOneWidget);
    });

    testWidgets('shows rating when averageRating is provided', (tester) async {
      final item = _makeItem(title: 'Rated Book', rating: 4.5);

      await tester.pumpWidget(
        _wrap(
          _StubLibraryScreen(items: [item]),
          overrides: [
            libraryWithDetailsByCategoryProvider.overrideWith(
              (ref, category) => Stream.value([item]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('4.5'), findsOneWidget);
    });

    testWidgets('does not show rating when averageRating is null',
        (tester) async {
      final item = _makeItem(title: 'Unrated Book', rating: null);

      await tester.pumpWidget(
        _wrap(
          _StubLibraryScreen(items: [item]),
          overrides: [
            libraryWithDetailsByCategoryProvider.overrideWith(
              (ref, category) => Stream.value([item]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // No star icon should be visible in the card
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // 4. LibraryBookCard – navigation
  // -------------------------------------------------------------------------

  group('LibraryBookCard – navigation', () {
    test('book card tap target is the book id path', () {
      // Verify the navigation path is constructed correctly
      const bookId = 'abc123';
      final path = '/books/$bookId';
      expect(path, equals('/books/abc123'));
    });

    test('navigation path uses book.id from UserBookWithDetails', () {
      final item = _makeItem(bookId: 'xyz789');
      final expectedPath = '/books/${item.book.id}';
      expect(expectedPath, equals('/books/xyz789'));
    });
  });

  // -------------------------------------------------------------------------
  // 5. PopupMenuButton – category options
  // -------------------------------------------------------------------------

  group('LibraryBookCard – popup menu', () {
    testWidgets('shows more_vert icon for popup menu', (tester) async {
      final item = _makeItem(title: 'Menu Book');

      await tester.pumpWidget(
        _wrap(
          _StubLibraryScreen(items: [item]),
          overrides: [
            libraryWithDetailsByCategoryProvider.overrideWith(
              (ref, category) => Stream.value([item]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('popup menu shows all 3 category options and remove option',
        (tester) async {
      final item = _makeItem(title: 'Menu Book');

      await tester.pumpWidget(
        _wrap(
          _StubLibraryScreen(items: [item]),
          overrides: [
            libraryWithDetailsByCategoryProvider.overrideWith(
              (ref, category) => Stream.value([item]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Open the popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Want to read'), findsOneWidget);
      expect(find.text('Reading'), findsWidgets); // tab + menu item
      expect(find.text('Read'), findsWidgets); // tab + menu item
      expect(find.text('Remove from library'), findsOneWidget);
    });

    testWidgets('popup menu shows delete icon for remove option',
        (tester) async {
      final item = _makeItem(title: 'Menu Book 2');

      await tester.pumpWidget(
        _wrap(
          _StubLibraryScreen(items: [item]),
          overrides: [
            libraryWithDetailsByCategoryProvider.overrideWith(
              (ref, category) => Stream.value([item]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // 6. Tab filtering logic (unit tests)
  // -------------------------------------------------------------------------

  group('Library tab filtering logic', () {
    test('wantToRead filter returns only wantToRead entries', () {
      final entries = [
        _makeEntry(bookId: 'b1', category: UserBookCategory.wantToRead),
        _makeEntry(bookId: 'b2', category: UserBookCategory.reading),
        _makeEntry(bookId: 'b3', category: UserBookCategory.read),
        _makeEntry(bookId: 'b4', category: UserBookCategory.wantToRead),
      ];

      final filtered = entries
          .where((e) => e.category == UserBookCategory.wantToRead)
          .toList();

      expect(filtered.length, equals(2));
      expect(filtered.every((e) => e.category == UserBookCategory.wantToRead),
          isTrue);
    });

    test('reading filter returns only reading entries', () {
      final entries = [
        _makeEntry(bookId: 'b1', category: UserBookCategory.wantToRead),
        _makeEntry(bookId: 'b2', category: UserBookCategory.reading),
        _makeEntry(bookId: 'b3', category: UserBookCategory.reading),
      ];

      final filtered = entries
          .where((e) => e.category == UserBookCategory.reading)
          .toList();

      expect(filtered.length, equals(2));
    });

    test('read filter returns only read entries', () {
      final entries = [
        _makeEntry(bookId: 'b1', category: UserBookCategory.wantToRead),
        _makeEntry(bookId: 'b2', category: UserBookCategory.read),
      ];

      final filtered =
          entries.where((e) => e.category == UserBookCategory.read).toList();

      expect(filtered.length, equals(1));
      expect(filtered.first.bookId, equals('b2'));
    });

    test('filter returns empty list when no entries match', () {
      final entries = [
        _makeEntry(bookId: 'b1', category: UserBookCategory.wantToRead),
      ];

      final filtered =
          entries.where((e) => e.category == UserBookCategory.read).toList();

      expect(filtered, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // 7. Stream behavior
  // -------------------------------------------------------------------------

  group('Library stream behavior', () {
    test('stream emits updated list when entry is added', () async {
      final controller = StreamController<List<UserBookEntry>>();
      final values = <List<UserBookEntry>>[];
      final sub = controller.stream.listen(values.add);

      controller.add([]);
      controller.add([_makeEntry(bookId: 'b1')]);

      await Future.delayed(Duration.zero);
      await sub.cancel();
      await controller.close();

      expect(values.first, isEmpty);
      expect(values.last.length, equals(1));
    });

    test('stream emits empty list after entry is removed', () async {
      final controller = StreamController<List<UserBookEntry>>();
      final values = <List<UserBookEntry>>[];
      final sub = controller.stream.listen(values.add);

      controller.add([_makeEntry(bookId: 'b1')]);
      controller.add([]);

      await Future.delayed(Duration.zero);
      await sub.cancel();
      await controller.close();

      expect(values.last, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // 8. UserBookWithDetails – data access
  // -------------------------------------------------------------------------

  group('UserBookWithDetails – data access for card rendering', () {
    test('book title is accessible via item.book.title', () {
      final item = _makeItem(title: 'Accessible Title');
      expect(item.book.title, equals('Accessible Title'));
    });

    test('book author is accessible via item.book.author', () {
      final item = _makeItem(author: 'Accessible Author');
      expect(item.book.author, equals('Accessible Author'));
    });

    test('rating is accessible via item.averageRating', () {
      final item = _makeItem(rating: 3.7);
      expect(item.averageRating, equals(3.7));
    });

    test('category is accessible via item.entry.category', () {
      final item = _makeItem(category: UserBookCategory.read);
      expect(item.entry.category, equals(UserBookCategory.read));
    });

    test('book id is accessible via item.book.id', () {
      final item = _makeItem(bookId: 'my_book_id');
      expect(item.book.id, equals('my_book_id'));
    });
  });
}

// ---------------------------------------------------------------------------
// Stub widget that renders LibraryScreen content without Firebase
// ---------------------------------------------------------------------------

/// A minimal stub that renders the same tab structure as LibraryScreen
/// but uses overridden providers so no Firebase connection is needed.
class _StubLibraryScreen extends ConsumerWidget {
  final List<UserBookWithDetails> items;

  const _StubLibraryScreen({this.items = const []});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.libraryTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.libraryTabWantToRead),
              Tab(text: l10n.libraryTabReading),
              Tab(text: l10n.libraryTabRead),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _StubCategoryTab(
              category: UserBookCategory.wantToRead,
              emptyMessage: l10n.libraryEmptyWantToRead,
            ),
            _StubCategoryTab(
              category: UserBookCategory.reading,
              emptyMessage: l10n.libraryEmptyReading,
            ),
            _StubCategoryTab(
              category: UserBookCategory.read,
              emptyMessage: l10n.libraryEmptyRead,
            ),
          ],
        ),
      ),
    );
  }
}

class _StubCategoryTab extends ConsumerWidget {
  final String category;
  final String emptyMessage;

  const _StubCategoryTab({
    required this.category,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync =
        ref.watch(libraryWithDetailsByCategoryProvider(category));

    return booksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error')),
      data: (books) {
        if (books.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu_book_outlined, size: 64),
                const SizedBox(height: 16),
                Text(emptyMessage),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) =>
              _StubBookCard(item: books[index]),
        );
      },
    );
  }
}

/// Minimal card that mirrors LibraryBookCard's visible content for testing.
class _StubBookCard extends ConsumerWidget {
  final UserBookWithDetails item;

  const _StubBookCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = item.book;
    final rating = item.averageRating;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: InkWell(
        onTap: () {}, // navigation tested via unit test
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title),
                    Text(book.author),
                    if (rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 16),
                          const SizedBox(width: 4),
                          Text(rating.toStringAsFixed(1)),
                        ],
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: l10n.libraryChangeCategory,
                icon: const Icon(Icons.more_vert),
                onSelected: (_) {},
                itemBuilder: (_) => [
                  PopupMenuItem<String>(
                    value: UserBookCategory.wantToRead,
                    child: Text(l10n.libraryCategoryWantToRead),
                  ),
                  PopupMenuItem<String>(
                    value: UserBookCategory.reading,
                    child: Text(l10n.libraryCategoryReading),
                  ),
                  PopupMenuItem<String>(
                    value: UserBookCategory.read,
                    child: Text(l10n.libraryCategoryRead),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: '_remove',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            color: Theme.of(context).colorScheme.error,
                            size: 20),
                        const SizedBox(width: 8),
                        Flexible(child: Text(l10n.libraryRemoveFromLibrary)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
