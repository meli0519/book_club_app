import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/review_question.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../../widgets/common/app_drawer.dart';

/// Screen for leaders to manage (create, edit, delete) review questions.
/// Requirement 9.6
class ReviewQuestionsManagementScreen extends ConsumerWidget {
  const ReviewQuestionsManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final questionsAsync = ref.watch(allReviewQuestionsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reviewQuestionsManagementTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.signOut,
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.addReviewQuestion,
        onPressed: () => _showQuestionDialog(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.reviewQuestionSaveError)),
        data: (questions) {
          if (questions.isEmpty) {
            return Center(child: Text(l10n.noReviewQuestions));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              return _ReviewQuestionTile(
                question: question,
                onEdit: () => _showQuestionDialog(context, ref, question),
                onDelete: () => _confirmDelete(context, ref, question),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showQuestionDialog(
    BuildContext context,
    WidgetRef ref,
    ReviewQuestion? existing,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _ReviewQuestionDialog(
        existing: existing,
        onSave: (questionText, order) async {
          final service = ref.read(reviewQuestionServiceProvider);
          final l10n = AppLocalizations.of(context)!;
          try {
            if (existing == null) {
              final question = ReviewQuestion(
                id: '',
                question: questionText,
                order: order,
                createdAt: DateTime.now(),
              );
              await service.createReviewQuestion(question);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.reviewQuestionCreatedSuccess)),
                );
              }
            } else {
              await service.updateReviewQuestion(existing.id, {
                'question': questionText,
                'order': order,
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.reviewQuestionUpdatedSuccess)),
                );
              }
            }
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.reviewQuestionSaveError)),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ReviewQuestion question,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteReviewQuestionConfirm),
        content: Text(question.question),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final service = ref.read(reviewQuestionServiceProvider);
      await service.deleteReviewQuestion(question.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reviewQuestionDeletedSuccess)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reviewQuestionDeleteError)),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Tile widget
// ---------------------------------------------------------------------------

class _ReviewQuestionTile extends StatelessWidget {
  final ReviewQuestion question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReviewQuestionTile({
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text('${question.order}')),
        title: Text(question.question),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: AppLocalizations.of(context)!.editReviewQuestion,
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: AppLocalizations.of(context)!.deleteReviewQuestion,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog widget
// ---------------------------------------------------------------------------

class _ReviewQuestionDialog extends StatefulWidget {
  final ReviewQuestion? existing;
  final Future<void> Function(String question, int order) onSave;

  const _ReviewQuestionDialog({
    required this.existing,
    required this.onSave,
  });

  @override
  State<_ReviewQuestionDialog> createState() => _ReviewQuestionDialogState();
}

class _ReviewQuestionDialogState extends State<_ReviewQuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _questionController;
  late final TextEditingController _orderController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _questionController =
        TextEditingController(text: widget.existing?.question ?? '');
    _orderController =
        TextEditingController(text: widget.existing?.order.toString() ?? '');
  }

  @override
  void dispose() {
    _questionController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        _questionController.text.trim(),
        int.parse(_orderController.text.trim()),
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(isEdit ? l10n.editReviewQuestion : l10n.addReviewQuestion),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _questionController,
              decoration: InputDecoration(
                labelText: l10n.reviewQuestionLabel,
                hintText: l10n.reviewQuestionHint,
              ),
              maxLines: 3,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _orderController,
              decoration: InputDecoration(
                labelText: l10n.reviewQuestionOrderLabel,
                hintText: l10n.reviewQuestionOrderHint,
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.fieldRequired;
                if (int.tryParse(v.trim()) == null) {
                  return l10n.reviewQuestionOrderInvalid;
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}
