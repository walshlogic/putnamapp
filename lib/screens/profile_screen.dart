import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/route_names.dart';
import '../models/user_profile.dart';
import '../providers/auth_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditMode = false;
  final _displayNameController = TextEditingController();
  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  bool _isSavingComments = false;
  bool? _commentAnonymousOverride;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final updateProfile = ref.read(updateUserProfileProvider);
      await updateProfile(
        displayName: _displayNameController.text.trim().isEmpty
            ? null
            : _displayNameController.text.trim(),
      );

      setState(() {
        _isLoading = false;
        _isEditMode = false;
        _successMessage = 'Profile updated successfully';
      });

      // Clear success message after 3 seconds
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _successMessage = null;
          });
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handleUpdateCommentSettings(bool isAnonymous) async {
    if (_isSavingComments) return;
    setState(() {
      _isSavingComments = true;
      _commentAnonymousOverride = isAnonymous;
    });

    try {
      final updateProfile = ref.read(updateUserProfileProvider);
      await updateProfile(commentAnonymous: isAnonymous);
    } catch (e) {
      if (mounted) {
        setState(() {
          _commentAnonymousOverride = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update comment settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingComments = false;
        });
      }
    }
  }

  String _contentTypeForExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'heic':
        return 'image/heic';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _showAvatarOptions(UserProfile profile) async {
    if (_isUploadingAvatar) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadAvatar(profile);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove photo'),
                enabled: profile.avatarUrl != null,
                onTap: profile.avatarUrl == null
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        _removeAvatar();
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatar(UserProfile profile) async {
    if (_isUploadingAvatar) return;

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (picked == null) return;

    setState(() {
      _isUploadingAvatar = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final bytes = await picked.readAsBytes();
      final extension = picked.name.split('.').last;
      final filePath =
          '${profile.id}/${DateTime.now().millisecondsSinceEpoch}.$extension';

      final storage = Supabase.instance.client.storage.from('avatars');
      await storage.uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: _contentTypeForExtension(extension),
        ),
      );

      final publicUrl = storage.getPublicUrl(filePath);
      final updateProfile = ref.read(updateUserProfileProvider);
      await updateProfile(avatarUrl: publicUrl);

      if (mounted) {
        setState(() {
          _successMessage = 'Profile photo updated successfully';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _removeAvatar() async {
    setState(() {
      _isUploadingAvatar = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final updateProfile = ref.read(updateUserProfileProvider);
      await updateProfile(removeAvatar: true);
      if (mounted) {
        setState(() {
          _successMessage = 'Profile photo removed';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final signOut = ref.read(signOutProvider);
        await signOut();

        if (mounted) {
          context.goNamed(RouteNames.login);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILE'),
        actions: <Widget>[
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditMode = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditMode = false;
                  _errorMessage = null;
                });
              },
            ),
        ],
      ),
      body: profileAsync.when(
        data: (UserProfile? profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }

          // Initialize controller with current display name
          if (_displayNameController.text.isEmpty &&
              profile.displayName != null) {
            _displayNameController.text = profile.displayName!;
          }

          final bool commentAnonymous =
              _commentAnonymousOverride ?? profile.commentAnonymous;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Profile header
                Center(
                  child: Column(
                    children: <Widget>[
                      GestureDetector(
                        onTap: _isEditMode ? () => _showAvatarOptions(profile) : null,
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            CircleAvatar(
                              radius: 100,
                              backgroundColor: Colors.blue,
                              backgroundImage: profile.avatarUrl != null
                                  ? NetworkImage(profile.avatarUrl!)
                                  : const AssetImage(
                                      'assets/images/app_icon.png',
                                    ),
                            ),
                            if (_isUploadingAvatar)
                              Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            if (_isEditMode)
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!_isEditMode) ...<Widget>[
                        Text(
                          profile.displayName ?? 'No name set',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.email,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Edit mode
                if (_isEditMode) ...<Widget>[
                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),

                  TextField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      prefixIcon: Icon(Icons.person_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleUpdateProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Changes'),
                  ),
                  const SizedBox(height: 32),
                ],

                // Success message
                if (_successMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: TextStyle(color: Colors.green.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),

                // (Subscription / "Pro" section removed — this is a personal
                // test build, not a commercial app. RevenueCat plumbing still
                // exists in the codebase but no upgrade UI is shown.)

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'COMMENTS',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'User ID',
                          profile.appUserId ?? 'PENDING',
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Post comments anonymously'),
                          subtitle: const Text(
                            'When enabled, your name shows as ANON',
                          ),
                          value: commentAnonymous,
                          onChanged: _isSavingComments
                              ? null
                              : _handleUpdateCommentSettings,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Account info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Account Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Email', profile.email),
                        _buildInfoRow(
                          'Member Since',
                          profile.createdAt != null
                              ? _formatDate(profile.createdAt!)
                              : 'N/A',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Sign out button
                OutlinedButton.icon(
                  onPressed: _handleSignOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading profile: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(currentUserProfileProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
