import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_drawer.dart';
import '../widgets/settings_drawer.dart';
import '../repositories/contact_repository.dart';
import '../services/supabase_service.dart';
import '../extensions/build_context_extensions.dart';

// Provider for contact repository
final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return SupabaseContactRepository(SupabaseService.client);
});

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageTitleController = TextEditingController();
  final _messageBodyController = TextEditingController();
  
  String _selectedDepartment = 'GENERAL';
  bool _pleaseContactMe = false;
  bool _isSubmitting = false;
  bool _messageSentSuccessfully = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageTitleController.dispose();
    _messageBodyController.dispose();
    super.dispose();
  }

  Future<void> _copyEmailToClipboard() async {
    const email = 'info@putnam.app';
    await Clipboard.setData(const ClipboardData(text: email));
    if (mounted) {
      context.showSnackBar('Email copied to clipboard');
    }
  }

  Future<void> _submitMessage() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate that at least email or phone is provided
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    
    if (email.isEmpty && phone.isEmpty) {
      if (mounted) {
        context.showErrorSnackBar('Please provide either an email or phone number');
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = ref.read(contactRepositoryProvider);
      await repository.submitMessage(
        name: _nameController.text.trim(),
        email: email.isEmpty ? null : email,
        phone: phone.isEmpty ? null : phone,
        department: _selectedDepartment,
        messageTitle: _messageTitleController.text.trim(),
        messageBody: _messageBodyController.text.trim(),
        pleaseContactMe: _pleaseContactMe,
      );

      if (mounted) {
        // Clear form
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _messageTitleController.clear();
        _messageBodyController.clear();
        setState(() {
          _selectedDepartment = 'GENERAL';
          _pleaseContactMe = false;
          _messageSentSuccessfully = true;
        });
        
        // Show success snackbar
        context.showSuccessSnackBar('Message sent successfully!');
        
        // Navigate to home screen after a short delay to show the snackbar
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            // Pop all routes until we reach home, or push home if needed
            context.go('/');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to send message: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _cancelForm() {
    // Close the contact screen
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    
    return Scaffold(
      appBar: const PutnamAppBar(showBackButton: true),
      drawer: const AppDrawer(),
      endDrawer: const SettingsDrawer(),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                // Header
                Text(
                  'CONTACT US',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: appColors.primaryPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'GET IN TOUCH WITH US',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: appColors.textMedium,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Email Card with Copy Button
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: appColors.lightPurple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.email_outlined,
                            color: appColors.primaryPurple,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'EMAIL',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: appColors.textLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'info@putnam.app',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.copy_outlined,
                            color: appColors.primaryPurple,
                          ),
                          onPressed: _copyEmailToClipboard,
                          tooltip: 'Copy email address',
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Contact Form
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'SEND US A MESSAGE',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: appColors.primaryPurple,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Name *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Email or Phone Field
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                final emailRegex = RegExp(
                                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                );
                                if (!emailRegex.hasMatch(value.trim())) {
                                  return 'Please enter a valid email address';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Phone Field
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone (for text message contact)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          
                          // Message Title Field
                          TextFormField(
                            controller: _messageTitleController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Message Title *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a message title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Message Body Field
                          TextFormField(
                            controller: _messageBodyController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Message Body *',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 5,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your message';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          // Department Selection
                          Text(
                            'Department *',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: [
                              RadioListTile<String>(
                                title: const Text('GENERAL'),
                                value: 'GENERAL',
                                groupValue: _selectedDepartment,
                                onChanged: (String? value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedDepartment = value;
                                    });
                                  }
                                },
                              ),
                              RadioListTile<String>(
                                title: const Text('SUPPORT'),
                                value: 'SUPPORT',
                                groupValue: _selectedDepartment,
                                onChanged: (String? value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedDepartment = value;
                                    });
                                  }
                                },
                              ),
                              RadioListTile<String>(
                                title: const Text('SALES'),
                                value: 'SALES',
                                groupValue: _selectedDepartment,
                                onChanged: (String? value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedDepartment = value;
                                    });
                                  }
                                },
                              ),
                              RadioListTile<String>(
                                title: const Text('REQUEST'),
                                value: 'REQUEST',
                                groupValue: _selectedDepartment,
                                onChanged: (String? value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedDepartment = value;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Please Contact Me Checkbox
                          CheckboxListTile(
                            title: const Text('PLEASE CONTACT ME'),
                            value: _pleaseContactMe,
                            onChanged: (value) {
                              setState(() {
                                _pleaseContactMe = value ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          const SizedBox(height: 24),
                          
                          // Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              TextButton(
                                onPressed: _isSubmitting ? null : _cancelForm,
                                child: Text(_messageSentSuccessfully ? 'CLOSE' : 'CANCEL'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _isSubmitting ? null : _submitMessage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: appColors.primaryPurple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Text('SEND'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }
}
