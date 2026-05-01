import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../domain/models/book.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/review_provider.dart';
import '../../routes/app_router.dart';

class CreateEditBookScreen extends ConsumerStatefulWidget {
  final Book? book;

  const CreateEditBookScreen({this.book, super.key});

  @override
  ConsumerState<CreateEditBookScreen> createState() =>
      _CreateEditBookScreenState();
}

class _CreateEditBookScreenState extends ConsumerState<CreateEditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();

  Uint8List? _coverImageBytes;
  String? _coverFileName;
  bool _isSaving = false;
  List<String> _selectedQuestionIds = [];

  bool get _isEditMode => widget.book != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _titleController.text = widget.book!.title;
      _authorController.text = widget.book!.author;
      _descriptionController.text = widget.book!.description;
      _selectedQuestionIds = List<String>.from(widget.book!.reviewQuestionIds);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

    // In create mode, cover image is required
    if (!_isEditMode && _coverImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.bookCoverHint)),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final bookService = ref.read(bookServiceProvider);

      if (_isEditMode) {
        final changedFields = <String, dynamic>{};
        if (_titleController.text.trim() != widget.book!.title) {
          changedFields['title'] = _titleController.text.trim();
        }
        if (_authorController.text.trim() != widget.book!.author) {
          changedFields['author'] = _authorController.text.trim();
        }
        if (_descriptionController.text.trim() != widget.book!.description) {
          changedFields['description'] = _descriptionController.text.trim();
        }
        if (_coverImageBytes != null && _coverFileName != null) {
          final newCoverUrl = await bookService.uploadCover(
            widget.book!.id,
            _coverImageBytes!,
            _coverFileName!,
          );
          changedFields['coverUrl'] = newCoverUrl;
        }
        // Always update reviewQuestionIds (may have changed)
        changedFields['reviewQuestionIds'] = _selectedQuestionIds;
        if (changedFields.isNotEmpty) {
          await bookService.updateBook(widget.book!.id, changedFields);
        }        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.bookUpdatedSuccess)),
          );
          Navigator.of(context).pop();
        }
      } else {
        final currentUser = await ref.read(currentUserProvider.future);
        final book = Book(
          id: '',
          title: _titleController.text.trim(),
          author: _authorController.text.trim(),
          description: _descriptionController.text.trim(),
          coverUrl: '',
          status: 'reading',
          createdBy: currentUser?.uid ?? '',
          createdAt: DateTime.now(),
          reviewQuestionIds: _selectedQuestionIds,
        );
        await bookService.createBook(book, _coverImageBytes!, _coverFileName!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.bookCreatedSuccess)),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.bookSaveError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? l10n.editBook : l10n.createBook),
      ),
      body: _isSaving
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
                        labelText: l10n.bookTitle,
                        hintText: l10n.bookTitleHint,
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
                        labelText: l10n.bookAuthor,
                        hintText: l10n.bookAuthorHint,
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? l10n.fieldRequired
                              : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: l10n.bookDescription,
                        hintText: l10n.bookDescriptionHint,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Cover image
                    Text(
                      l10n.bookCover,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildCoverPicker(l10n),
                    const SizedBox(height: 24),

                    // Review questions selection (Requirement 9.2)
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
                      onPressed: () => Navigator.of(context).pop(),
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
    if (_isEditMode && widget.book!.coverUrl.isNotEmpty) {
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.book!.coverUrl,
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

// ---------------------------------------------------------------------------
// Review questions selector widget
// ---------------------------------------------------------------------------

/// Displays all available review questions as checkboxes.
/// Requirement 9.2
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
