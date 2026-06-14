import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Role selection state (false = Candidate, true = Recruiter/Company)
  bool _isCompany = false;
  
  // Candidate onboarding fields
  String _currentStatus = 'Student';
  final _interestedFieldController = TextEditingController();
  
  // Company onboarding fields
  final _organizationController = TextEditingController();
  final _hiringFocusController = TextEditingController();

  final List<String> _statusOptions = ['Student', 'Job Seeker', 'Working Professional', 'Other'];

  void _signup() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      await auth.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        isCompany: _isCompany,
        currentStatus: _isCompany ? null : _currentStatus,
        interestedField: _isCompany ? null : _interestedFieldController.text.trim(),
        organization: _isCompany ? _organizationController.text.trim() : null,
        hiringFocus: _isCompany ? _hiringFocusController.text.trim() : null,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppTheme.primary, size: 28),
                SizedBox(width: 12),
                Text(
                  'Account Created',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ],
            ),
            content: const Text(
              'Registration successful! Your account is active — you can now log in and start using Aptitude GO.',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'GOT IT',
                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CREATE ACCOUNT'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.background, AppTheme.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Icon(Icons.rocket_launch_outlined, size: 60, color: AppTheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Join Aptitude GO',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Compete, practice, and get hired!',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 28),
                    
                    // --- ROLE SELECTION CARDS ---
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isCompany = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: !_isCompany ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: !_isCompany ? AppTheme.primary : AppTheme.surfaceLight,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.school,
                                    color: !_isCompany ? AppTheme.primary : AppTheme.textSecondary,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Candidate',
                                    style: TextStyle(
                                      color: !_isCompany ? AppTheme.textPrimary : AppTheme.textSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isCompany = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _isCompany ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _isCompany ? AppTheme.primary : AppTheme.surfaceLight,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.business,
                                    color: _isCompany ? AppTheme.primary : AppTheme.textSecondary,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Recruiter',
                                    style: TextStyle(
                                      color: _isCompany ? AppTheme.textPrimary : AppTheme.textSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // --- SIGNUP FORM FIELDS CONTAINER ---
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Username Field
                              TextFormField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  hintText: 'Username',
                                  helperText: 'Must be unique across both candidate and recruiter accounts.',
                                  prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primary),
                                  filled: true,
                                  fillColor: AppTheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Username is required';
                                  if (val.trim().length < 3) return 'Username is too short';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: 'Email Address',
                                  prefixIcon: const Icon(Icons.mail_outline, color: AppTheme.primary),
                                  filled: true,
                                  fillColor: AppTheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Email is required';
                                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                                  if (!emailRegex.hasMatch(val.trim())) return 'Enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
                                  filled: true,
                                  fillColor: AppTheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Password is required';
                                  if (val.length < 6) return 'Password must be at least 6 characters';
                                  return null;
                                },
                              ),
                              
                              // --- DYNAMIC ONBOARDING FIELDS ---
                              if (!_isCompany) ...[
                                const SizedBox(height: 24),
                                const Divider(color: AppTheme.surfaceLight),
                                const SizedBox(height: 12),
                                const Text(
                                  'Candidate Profile Information',
                                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 16),
                                
                                // Current Status Dropdown
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  // ignore: deprecated_member_use
                                  value: _currentStatus,
                                  dropdownColor: AppTheme.surface,
                                  decoration: InputDecoration(
                                    labelText: 'Current Status',
                                    prefixIcon: const Icon(Icons.psychology, color: AppTheme.primary),
                                    filled: true,
                                    fillColor: AppTheme.surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  items: _statusOptions.map((String opt) {
                                    return DropdownMenuItem<String>(
                                      value: opt,
                                      child: Text(opt),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _currentStatus = val);
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                // Interested Field
                                TextFormField(
                                  controller: _interestedFieldController,
                                  decoration: InputDecoration(
                                    hintText: 'Interested Field (e.g. Software, Finance)',
                                    prefixIcon: const Icon(Icons.star_border, color: AppTheme.primary),
                                    filled: true,
                                    fillColor: AppTheme.surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (val) {
                                    if (!_isCompany && (val == null || val.trim().isEmpty)) {
                                      return 'Please enter your field of interest';
                                    }
                                    return null;
                                  },
                                ),
                              ] else ...[
                                const SizedBox(height: 24),
                                const Divider(color: AppTheme.surfaceLight),
                                const SizedBox(height: 12),
                                const Text(
                                  'Recruiter / Company Details',
                                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 16),
                                
                                // Organization / Company Name
                                TextFormField(
                                  controller: _organizationController,
                                  decoration: InputDecoration(
                                    hintText: 'Company or Organization Name',
                                    helperText: 'If this account already exists as a candidate, it will be upgraded to recruiter.',
                                    prefixIcon: const Icon(Icons.corporate_fare_outlined, color: AppTheme.primary),
                                    filled: true,
                                    fillColor: AppTheme.surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (val) {
                                    if (_isCompany && (val == null || val.trim().isEmpty)) {
                                      return 'Organization name is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                // Hiring Focus
                                TextFormField(
                                  controller: _hiringFocusController,
                                  decoration: InputDecoration(
                                    hintText: 'Hiring Focus (e.g. React Developers, Java)',
                                    prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                                    filled: true,
                                    fillColor: AppTheme.surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (val) {
                                    if (_isCompany && (val == null || val.trim().isEmpty)) {
                                      return 'Hiring focus is required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                              
                              const SizedBox(height: 32),
                              
                              // JOIN ARENA Button
                              SizedBox(
                                width: double.infinity,
                                child: auth.isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(color: AppTheme.primary),
                                      )
                                    : ElevatedButton(
                                        onPressed: _signup,
                                        child: const Text(
                                          'JOIN ARENA',
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
