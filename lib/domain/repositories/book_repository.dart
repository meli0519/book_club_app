import 'dart:typed_data';
import '../models/book.dart';

abstract class BookRepository {
  Stream<List<Book>> watchBooks();
  Stream<Book?> watchBook(String bookId);
  Future<Book?> getBook(String bookId);
  Future<String> createBook(
    Book book,
    Uint8List coverImageBytes,
    String coverFileName,
  );
  Future<void> updateBook(String bookId, Map<String, dynamic> fields);
  Future<void> deleteBook(String bookId);
  Future<void> markAsRead(String bookId);
  Future<String> uploadCover(
    String bookId,
    Uint8List bytes,
    String fileName,
  );
}
