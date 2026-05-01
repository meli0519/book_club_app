import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/book.dart';
import '../../../domain/models/meeting.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/meeting_provider.dart';
import '../../widgets/rating/star_rating_selector.dart';

/// Form screen for creating or editing a [Meeting].
///
/// When [bookId] is provided the book selector is hidden (the meeting is
/// created for that specific book). When [bookId] is null a dropdown is shown
/// so the leader can pick any available book.
///
/// Requirements 6.1, 6.2, 6.3
class CreateEditMeetingScreen extends ConsumerStatefulWidget {
  /// Pre-selected book. If null, a book selector dropdown is shown.
  final String? bookId;

  /// When non-null the form is in edit mode.
  final Meeting? meeting;

  const CreateEditMeetingScreen({
    this.bookId,
    this.meeting,
    super.key,
  });

  @override
  ConsumerState<CreateEditMeetingScreen> createState() =>
      _CreateEditMeetingScreenState();
}

class _CreateEditMeetingScreenState
    extends ConsumerState<CreateEditMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  int _partialRating = 0; // 0 = not selected
  String? _selectedBookId;
  bool _isSaving = false;
  bool _showDateError = false;
  bool _showRatingError = false;

  bool get _isEditMode => widget.meeting != null;

  @override
  void initState() {
    super.initState();
    _selectedBookId = widget.bookId ?? widget.meeting?.bookId;
    if (_isEditMode) {
      _selectedDate = widget.meeting!.date;
      _notesController.text = widget.meeting!.notes;
      _partialRating = widget.meeting!.partialRating;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _showDateError = false;
      });
    }
  }

  Future<void> _submit() async {
    // Validate date and rating before form validation
    setState(() {
      _showDateError = _selectedDate == null;
      _showRatingError = _partialRating < 1 || _partialRating > 5;
    });

    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _partialRating < 1 || _partialRating > 5) {
      return;
    }
    if (_selectedBookId == null || _selectedBookId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.fieldRequired)),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final service = ref.read(meetingServiceProvider);

      if (_isEditMode) {
        final changedFields = <String, dynamic>{};
        if (_selectedDate != widget.meeting!.date) {
          changedFields['date'] = Timestamp.fromDate(_selectedDate!);
        }
        if (_notesController.text.trim() != widget.meeting!.notes) {
          changedFields['notes'] = _notesController.text.trim();
        }
        if (_partialRating != widget.meeting!.partialRating) {
          changedFields['partialRating'] = _partialRating;
        }
        if (changedFields.isNotEmpty) {
          await service.updateMeeting(widget.meeting!.id, changedFields);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    AppLocalizations.of(context)!.meetingUpdatedSuccess)),
          );
          Navigator.of(context).pop();
        }
      } else {
        final currentUser = await ref.read(currentUserProvider.future);
        final meeting = Meeting(
          id: '',
          bookId: _selectedBookId!,
          date: _selectedDate!,
          notes: _notesController.text.trim(),
          partialRating: _partialRating,
          createdBy: currentUser?.uid ?? '',
          createdAt: DateTime.now(),
        );
        await service.createMeeting(meeting);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    AppLocalizations.of(context)!.meetingCreatedSuccess)),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.meetingSaveError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? l10n.editMeeting : l10n.createMeeting),
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
                    // Book selector (only when bookId is not pre-set)
                    if (widget.bookId == null && !_isEditMode) ...[
                      _BookSelectorField(
                        selectedBookId: _selectedBookId,
                        onChanged: (id) =>
                            setState(() => _selectedBookId = id),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Date picker
                    Text(
                      l10n.meetingDate,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _pickDate(context),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDate != null
                            ? dateFormat.format(_selectedDate!)
                            : l10n.selectDate,
                      ),
                    ),
                    if (_showDateError && _selectedDate == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 12),
                        child: Text(
                          l10n.fieldRequired,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: l10n.meetingNotes,
                        hintText: l10n.meetingNotesHint,
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      maxLength: 1000,
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            value.trim().isEmpty) {
                          return l10n.fieldRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Partial rating (star selector 1-5)
                    Text(
                      l10n.meetingPartialRating,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    StarRatingSelectorWidget(
                      currentRating: _partialRating,
                      onRatingSelected: (value) => setState(() {
                        _partialRating = value;
                        _showRatingError = false;
                      }),
                    ),
                    if (_showRatingError &&
                        (_partialRating < 1 || _partialRating > 5))
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 12),
                        child: Text(
                          l10n.meetingRatingInvalid,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),

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
}

// ---------------------------------------------------------------------------
// Book selector dropdown
// ---------------------------------------------------------------------------

/// Dropdown that loads all books from Firestore and lets the user pick one.
/// Requirement 22.2
class _BookSelectorField extends ConsumerWidget {
  final String? selectedBookId;
  final ValueChanged<String?> onChanged;

  const _BookSelectorField({
    required this.selectedBookId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final booksAsync = ref.watch(booksStreamProvider);

    return booksAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => Text(
        l10n.bookListError,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      data: (books) {
        return DropdownButtonFormField<String>(
          value: selectedBookId,
          decoration: InputDecoration(
            labelText: l10n.bookTitle,
            border: const OutlineInputBorder(),
          ),
          items: books
              .map(
                (Book b) => DropdownMenuItem<String>(
                  value: b.id,
                  child: Text(
                    b.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: (value) =>
              (value == null || value.isEmpty) ? l10n.fieldRequired : null,
        );
      },
    );
  }
}
