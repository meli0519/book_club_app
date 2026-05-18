import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/services/personal_book_service.dart';
import '../../../domain/models/personal_book.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/personal_book_provider.dart';
import '../../providers/review_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/personal_book/personal_book_status_chip.dart';

/// Form screen for creating or editing a personal book.
///
/// In create mode (when [bookId] is null), creates a new personal book.
/// In edit mode (when [bookId] is provided), loads existing book data and
/// updates only the modified fields.
///
/// Validates that title and author are not empty before submission.
/// Shows inline error messages for validation failures.
///
/// When status changes to 'reading', records [startedAt] if it didn't exist before.
/// When status changes to 'read', records [finishedAt].
///
/// Displays a loading indicator during save operations and shows error SnackBars
/// on failure. Navigates back to [PersonalBooksScreen] on successful save.
///
/// Validates: Requirements 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4, 9.2, 9.3, 9.4
class PersonalBookFormScreen extends ConsumerStatefulWidget {
  /// The ID of the book to edit. If null, the screen is in create mode.
  final String? bookId;

  const PersonalBookFormScreen({this.bookId, super.key});

  @override
  ConsumerState<PersonalBookFormScreen> createState() =>
      _PersonalBookFormScreenState();
}

class _PersonalBookFormScreenState extends ConsumerState<PersonalBookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();

  Uint8List? _coverImageBytes;
  String? _coverFileName;
  String _status = PersonalBookStatus.wantToRead;
  List<String> _selectedQuestionIds = [];
  bool _isSaving = false;
  bool _isLoading = true;
  PersonalBook? _existingBook;

  bool get _isEditMode => widget.bookId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadExistingBook();
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingBook() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.networkError)),
        );
        context.pop();
      }
      return;
    }

    try {
      final book = await ref
          .read(personalBookServiceProvider)
          .getPersonalBook(user.uid, widget.bookId!);

      if (book != null) {
        setState(() {
          _existingBook = book;
          _titleController.text = book.title;
          _authorController.text = book.author;
          _descriptionController.text = book.description ?? '';
          _status = book.status;
          _selectedQuestionIds = List<String>.from(book.reviewQuestionIds);
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.bookNotFound),
            ),
          );
          context.pop();
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.personalBookSaveError),
          ),
        );
        context.pop();
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile == null) return;
    final bytes = await xFile.readAsBytes();
    setState(() {
      _coverImageBytes = bytes;
      _coverFileName = xFile.name.isNotEmpty
          ? xFile.name
          : 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final user = ref.read(authStateProvider).valueOrNull;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.networkError)),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final service = ref.read(personalBookServiceProvider);

      if (_isEditMode) {
        await _updateBook(service, user.uid);
      } else {
        await _createBook(service, user.uid);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? l10n.personalBookUpdatedSuccess
                  : l10n.personalBookCreatedSuccess,
            ),
          ),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.personalBookSaveError),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _createBook(PersonalBookService service, String uid) async {
    final now = DateTime.now();

    final book = PersonalBook(
      id: '',
      userId: uid,
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      coverUrl: null,
      status: _status,
      notes: const [],
      rating: null,
      reviewQuestionIds: _selectedQuestionIds,
      createdAt: now,
      updatedAt: now,
      startedAt: _status == PersonalBookStatus.reading ? now : null,
      finishedAt: _status == PersonalBookStatus.read ? now : null,
    );

    await service.createPersonalBook(
      uid,
      book,
      _coverImageBytes,
      _coverFileName,
    );
  }

  Future<void> _updateBook(PersonalBookService service, String uid) async {
    final changedFields = <String, dynamic>{};

    final newTitle = _titleController.text.trim();
    if (newTitle != _existingBook!.title) {
      changedFields['title'] = newTitle;
    }

    final newAuthor = _authorController.text.trim();
    if (newAuthor != _existingBook!.author) {
      changedFields['author'] = newAuthor;
    }

    final newDescription = _descriptionController.text.trim();
    final oldDescription = _existingBook!.description ?? '';
    if (newDescription != oldDescription) {
      changedFields['description'] = newDescription.isEmpty ? null : newDescription;
    }

    if (_status != _existingBook!.status) {
      changedFields['status'] = _status;
    }

    // Always update reviewQuestionIds (may have changed)
    if (_selectedQuestionIds != _existingBook!.reviewQuestionIds) {
      changedFields['reviewQuestionIds'] = _selectedQuestionIds;
    }

    if (changedFields.isNotEmpty) {
      await service.updatePersonalBook(uid, widget.bookId!, changedFields);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? l10n.editBook : l10n.addPersonalBook,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isSaving
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: l10n.personalBookTitleLabel,
                            hintText: l10n.personalBookTitleHint,
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? l10n.fieldRequired
                                  : null,
                        ),
                        const SizedBox(height: 16),

                        // Author
                        TextFormField(
                          controller: _authorController,
                          decoration: InputDecoration(
                            labelText: l10n.personalBookAuthorLabel,
                            hintText: l10n.personalBookAuthorHint,
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? l10n.fieldRequired
                                  : null,
                        ),
                        const SizedBox(height: 16),

                        // Description (optional)
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: l10n.personalBookDescriptionLabel,
                            hintText: l10n.personalBookDescriptionHint,
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),

                        // Status selector
                        _StatusSelector(
                          currentStatus: _status,
                          onChanged: (status) =>
                              setState(() => _status = status),
                        ),
                        const SizedBox(height: 24),

                        // Cover image (optional)
                        Text(
                          l10n.personalBookCoverLabel,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        _buildCoverPicker(l10n),
                        const SizedBox(height: 24),

                        // Review questions selection
                        Text(
                          l10n.reviewQuestionsForBook,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        _ReviewQuestionsSelector(
                          selectedIds: _selectedQuestionIds,
                          onChanged: (ids) =>
                              setState(() => _selectedQuestionIds = ids),
                        ),
                        const SizedBox(height: 32),

                        // Save button
                        ElevatedButton(
                          onPressed: _submit,
                          child: Text(l10n.save),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: Text(l10n.cancel),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildCoverPicker(AppLocalizations l10n) {
    // New image selected
    if (_coverImageBytes != null) {
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _coverImageBytes!,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image),
            label: Text(l10n.changeImage),
          ),
        ],
      );
    }

    // Edit mode with existing cover
    if (_isEditMode &&
        _existingBook != null &&
        _existingBook!.coverUrl != null &&
        _existingBook!.coverUrl!.isNotEmpty) {
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _existingBook!.coverUrl!,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, size: 80),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image),
            label: Text(l10n.changeImage),
          ),
        ],
      );
    }

    // No image yet
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(l10n.selectImage,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

/// Status selector dropdown for personal book status.
class _StatusSelector extends StatelessWidget {
  final String currentStatus;
  final ValueChanged<String> onChanged;

  const _StatusSelector({
    required this.currentStatus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.personalBookStatusLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: currentStatus,
          items: PersonalBookStatus.all.map((status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Row(
                children: [
                  PersonalBookStatusChip(status: status),
                  const SizedBox(width: 8),
                  Text(_getStatusLabel(status, l10n)),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  String _getStatusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case PersonalBookStatus.read:
        return l10n.personalBookStatusRead;
      case PersonalBookStatus.reading:
        return l10n.personalBookStatusReading;
      case PersonalBookStatus.wantToRead:
      default:
        return l10n.personalBookStatusWantToRead;
    }
  }
}

// ---------------------------------------------------------------------------
// Review questions selector widget
// ---------------------------------------------------------------------------

/// Displays all available review questions as checkboxes.
/// Same as in club books (Requirement 9.2)
class _ReviewQuestionsSelector extends ConsumerWidget {
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;

  const _ReviewQuestionsSelector({
    required this.selectedIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(allReviewQuestionsStreamProvider);

    return questionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (questions) {
        if (questions.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.noReviewQuestions,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                    AppLocalizations.of(context)!.reviewQuestionsManagementTitle),
                onPressed: () =>
                    context.push(AppRoutes.reviewQuestionsManagement),
              ),
            ],
          );
        }
        return Column(
          children: questions.map((q) {
            final isSelected = selectedIds.contains(q.id);
            return CheckboxListTile(
              value: isSelected,
              title: Text(q.question),
              subtitle: Text('Order: ${q.order}'),
              onChanged: (checked) {
                final updated = List<String>.from(selectedIds);
                if (checked == true) {
                  updated.add(q.id);
                } else {
                  updated.remove(q.id);
                }
                onChanged(updated);
              },
            );
          }).toList(),
        );
      },
    );
  }
}