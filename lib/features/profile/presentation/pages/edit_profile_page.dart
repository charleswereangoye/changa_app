// Owner: A - Person A (Foundation, Authentication, Profile)
// Screen: Edit Profile Screen: update name and phone with validation

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/member_avatar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/profile_cubit.dart';

/// Screen allowing the authenticated user to update their display name and phone number.
class EditProfilePage extends StatefulWidget {
  final ProfileCubit? cubit;
  final AppUser? initialUser;

  const EditProfilePage({super.key, this.cubit, this.initialUser});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final ProfileCubit _cubit;
  late final bool _ownsCubit;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.cubit != null) {
      _cubit = widget.cubit!;
      _ownsCubit = false;
    } else if (GetIt.instance.isRegistered<ProfileCubit>()) {
      _cubit = GetIt.instance<ProfileCubit>();
      _ownsCubit = false;
    } else {
      _cubit = ProfileCubit();
      _ownsCubit = true;
    }

    final user = widget.initialUser;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-populate if not supplied via constructor and fields are still empty
    if (_nameController.text.isEmpty && _emailController.text.isEmpty) {
      try {
        final authUser =
            widget.initialUser ?? context.read<AuthCubit>().state.user;
        if (authUser != null) {
          _nameController.text = authUser.fullName;
          _phoneController.text = authUser.phone;
          _emailController.text = authUser.email;
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    if (_ownsCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _isSaving) return;

    _isSaving = true;
    final success = await _cubit.editProfile(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (!mounted) return;
    _isSaving = false;

    if (success) {
      final updatedUser = (_cubit.state is ProfileStateLoaded)
          ? (_cubit.state as ProfileStateLoaded).user
          : null;
      if (updatedUser != null && mounted) {
        try {
          context.read<AuthCubit>().updateUser(updatedUser);
        } catch (_) {}
      }
      AppSnackbar.success(context, 'Profile updated successfully.');
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(updatedUser);
      }
    } else {
      final err = (_cubit.state is ProfileStateError)
          ? (_cubit.state as ProfileStateError).message
          : 'Failed to update profile. Please try again.';
      AppSnackbar.error(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF072B28) : AppColors.white;
    final cardBorder = isDark
        ? Border.all(color: const Color(0xFF0F3E3A))
        : null;

    return BlocProvider<ProfileCubit>.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: isDark ? AppColors.ginFizz : AppColors.sherwoodGreen,
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Edit Profile',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.ginFizz : AppColors.sherwoodGreen,
            ),
          ),
        ),
        body: SafeArea(
          child: BlocConsumer<ProfileCubit, ProfileState>(
            listener: (context, state) {
              if (state is ProfileStateError) {
                AppSnackbar.error(context, state.message);
              }
            },
            builder: (context, state) {
              final isLoading = state is ProfileStateLoading;
              final currentUid = context.read<AuthCubit>().state.user?.uid;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Avatar display
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.lightGreen
                                      : AppColors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: MemberAvatar(
                                uid: currentUid,
                                name: _nameController.text.isEmpty
                                    ? 'Changa Member'
                                    : _nameController.text,
                                radius: 42,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.sherwoodGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  color: AppColors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Card containing form fields
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: cardBorder,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Full Name Field
                            AppTextField(
                              key: const Key('edit-profile-name-input'),
                              label: 'Full Name',
                              hintText: 'e.g. Amara Okoye',
                              controller: _nameController,
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                                color: AppColors.edward,
                                size: 20,
                              ),
                              validator: Validators.name,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),

                            // Phone Number Field
                            AppTextField(
                              key: const Key('edit-profile-phone-input'),
                              label: 'Phone Number',
                              hintText: '+250 788 123 456',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              prefixIcon: const Icon(
                                Icons.phone_outlined,
                                color: AppColors.edward,
                                size: 20,
                              ),
                              validator: Validators.phone,
                              textInputAction: TextInputAction.done,
                            ),
                            const SizedBox(height: 16),

                            // Email Address (Read-only)
                            AppTextField(
                              key: const Key('edit-profile-email-input'),
                              label: 'Email Address',
                              hintText: 'email@example.com',
                              controller: _emailController,
                              enabled: false,
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: AppColors.edward,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Email cannot be changed directly.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: AppColors.edward,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Submit Button
                      PrimaryButton(
                        key: const Key('edit-profile-save-button'),
                        text: 'Save Changes',
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _handleSubmit,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
