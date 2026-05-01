import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

/// Screen that allows the current user to edit their display name and
/// profile photo. Satisfies subtasks 19.1–19.4.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  File? _pickedPhoto;
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Pre-fills the name field once the user data is available.
  void _initFromUser(String displayName) {
    if (!_initialized) {
      _nameController.text = displayName;
      _initialized = true;
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _pickedPhoto = File(picked.path));
    }
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final firebaseUser = ref.read(authStateProvider).valueOrNull;
    if (firebaseUser == null) return;

    setState(() => _isLoading = true);
    try {
      final userService = ref.read(userServiceProvider);
      await userService.updateProfile(
        firebaseUser.uid,
        _nameController.text.trim(),
        _pickedPhoto,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileUpdatedSuccess)),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileUpdateError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userAsync = ref.watch(currentUserStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfileTitle),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.bookDetailError)),
        data: (user) {
          if (user != null) _initFromUser(user.displayName);

          final currentPhotoUrl = user?.photoUrl ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  // Photo preview
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 56,
                          backgroundImage: _pickedPhoto != null
                              ? FileImage(_pickedPhoto!) as ImageProvider
                              : (currentPhotoUrl.isNotEmpty
                                  ? NetworkImage(currentPhotoUrl)
                                  : null),
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: (_pickedPhoto == null &&
                                  currentPhotoUrl.isEmpty)
                              ? Icon(
                                  Icons.person,
                                  size: 48,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                )
                              : null,
                        ),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: Icon(
                            Icons.camera_alt,
                            size: 16,
                            color:
                                Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      currentPhotoUrl.isNotEmpty || _pickedPhoto != null
                          ? l10n.changePhoto
                          : l10n.selectPhoto,
                    ),
                    onPressed: _pickPhoto,
                  ),
                  const SizedBox(height: 24),
                  // Name field (19.2)
                  TextFormField(
                    key: const Key('nameField'),
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.displayNameLabel,
                      hintText: l10n.displayNameHint,
                      border: const OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.displayNameRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      key: const Key('saveButton'),
                      onPressed: _isLoading ? null : () => _save(context),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : Text(l10n.save),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
