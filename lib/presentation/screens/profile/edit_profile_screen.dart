import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/app_settings_service.dart';
import '../../../data/local/app_database.dart';
import '../../../presentation/widgets/app_bottom_sheet.dart';
import '../../../presentation/widgets/app_dialog.dart';
import '../../../presentation/widgets/leximon_widgets.dart';
import '../../../shared/providers/app_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({this.profile, super.key});

  final UserProfileRow? profile;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  static const _defaultName = 'Leximon';
  static const _defaultEmail = 'hello@leximon.app';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _imagePicker = ImagePicker();

  String? _avatarPath;
  bool _isSaving = false;
  bool _hasAppliedProfile = false;

  @override
  void initState() {
    super.initState();
    _applyProfile(widget.profile);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _applyProfile(UserProfileRow? profile) {
    if (_hasAppliedProfile || profile == null) {
      if (profile == null && _nameController.text.isEmpty) {
        _nameController.text = _defaultName;
        _emailController.text = _defaultEmail;
      }
      return;
    }
    _hasAppliedProfile = true;
    _nameController.text = profile.name;
    _emailController.text = profile.email;
    _avatarPath = profile.avatarPath;
  }

  Future<void> _chooseAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AppBottomSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 2),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Chọn ảnh đại diện',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),
            _ImageSourceTile(
              icon: Icons.photo_library_outlined,
              title: 'Chọn từ thư viện',
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            _ImageSourceTile(
              icon: Icons.photo_camera_outlined,
              title: 'Chụp ảnh mới',
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    if (!await _ensureImagePermission(source)) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (pickedFile == null || !mounted) return;

      final documentsDirectory = await getApplicationDocumentsDirectory();
      final profileDirectory = Directory('${documentsDirectory.path}/profile');
      await profileDirectory.create(recursive: true);

      final extension = _fileExtension(pickedFile.path);
      final destination = File(
        '${profileDirectory.path}/avatar_${DateTime.now().microsecondsSinceEpoch}$extension',
      );
      await File(pickedFile.path).copy(destination.path);

      if (!mounted) return;
      setState(() => _avatarPath = destination.path);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể lưu ảnh: $error')));
    }
  }

  Future<bool> _ensureImagePermission(ImageSource source) async {
    final permission = switch (source) {
      ImageSource.camera => Permission.camera,
      ImageSource.gallery when Platform.isIOS => Permission.photos,
      ImageSource.gallery => null,
    };
    if (permission == null) return true;

    final permissionKey = source == ImageSource.camera
        ? 'profile.image_permission.camera_requested'
        : 'profile.image_permission.photos_requested';
    final preferences = await SharedPreferences.getInstance();
    final requestedBefore = preferences.getBool(permissionKey) ?? false;
    var status = await permission.status;

    if (status.isGranted || status.isLimited) return true;
    if (status.isPermanentlyDenied || status.isRestricted) {
      await _showPermissionSettingsDialog(source);
      return false;
    }

    status = await permission.request();
    await preferences.setBool(permissionKey, true);
    if (status.isGranted || status.isLimited) return true;

    // The first denial has just shown the native prompt. On the next attempt
    // the platform may return denied without showing it again, so guide the
    // user to the app settings screen instead.
    if (requestedBefore || status.isPermanentlyDenied || status.isRestricted) {
      await _showPermissionSettingsDialog(source);
    }
    return false;
  }

  Future<void> _showPermissionSettingsDialog(ImageSource source) async {
    if (!mounted) return;
    final permissionName = source == ImageSource.camera
        ? 'camera'
        : 'thư viện ảnh';
    await showDialog<void>(
      context: context,
      builder: (context) => AppDialog(
        icon: Icons.lock_outline_rounded,
        title: 'Cần cấp quyền',
        message:
            'Leximon chưa được cấp quyền truy cập $permissionName. Bạn có thể bật quyền trong phần Cài đặt của ứng dụng.',
        secondaryLabel: 'Để sau',
        onSecondary: () => Navigator.of(context).pop(),
        primaryLabel: 'Mở Cài đặt',
        onPrimary: () async {
          Navigator.of(context).pop();
          await AppSettingsService.openAppSettings();
        },
      ),
    );
  }

  String _fileExtension(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == path.length - 1) return '.jpg';
    final extension = path.substring(dotIndex).toLowerCase();
    return extension.length <= 5 ? extension : '.jpg';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(appDatabaseProvider)
          .saveUserProfile(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            avatarPath: _avatarPath,
          );
      ref.invalidate(userProfileProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể lưu hồ sơ: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);
    if (!_hasAppliedProfile) {
      _applyProfile(profileState.valueOrNull);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _EditProfileBackdrop(),
            Column(
              children: [
                _EditProfileTopBar(onBack: () => Navigator.of(context).pop()),
                Expanded(
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            LeximonSurface(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                18,
                                16,
                                12,
                              ),
                              child: Column(
                                children: [
                                  const SectionHeader(
                                    kicker: 'Personalize',
                                    title: 'Ảnh đại diện',
                                  ),
                                  const SizedBox(height: 12),
                                  _AvatarPicker(
                                    avatarPath: _avatarPath,
                                    onTap: _chooseAvatar,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            LeximonSurface(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SectionHeader(
                                    kicker: 'Profile details',
                                    title: 'Thông tin cá nhân',
                                  ),
                                  const SizedBox(height: 18),
                                  _ProfileField(
                                    controller: _nameController,
                                    label: 'Tên của bạn',
                                    hintText: 'Nhập tên hiển thị',
                                    icon: Icons.person_outline_rounded,
                                    textInputAction: TextInputAction.next,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Vui lòng nhập tên của bạn';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  _ProfileField(
                                    controller: _emailController,
                                    label: 'Email',
                                    hintText: 'you@example.com',
                                    icon: Icons.alternate_email_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.done,
                                    validator: (value) {
                                      final email = value?.trim() ?? '';
                                      if (email.isEmpty) {
                                        return 'Vui lòng nhập email';
                                      }
                                      if (!RegExp(
                                        r'^\S+@\S+\.\S+$',
                                      ).hasMatch(email)) {
                                        return 'Email chưa đúng định dạng';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isSaving
                                        ? const [
                                            Color(0xFF78A2FF),
                                            Color(0xFF8DB4FF),
                                          ]
                                        : const [
                                            Color(0xFF0C4DE4),
                                            Color(0xFF147BFF),
                                          ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x40155CFF),
                                      blurRadius: 18,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(18),
                                  child: InkWell(
                                    onTap: _isSaving ? null : _save,
                                    borderRadius: BorderRadius.circular(18),
                                    child: Center(
                                      child: _isSaving
                                          ? const SizedBox.square(
                                              dimension: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check_rounded,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Lưu hồ sơ',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileBackdrop extends StatelessWidget {
  const _EditProfileBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.background),
        Align(
          alignment: Alignment.topCenter,
          child: FractionallySizedBox(
            widthFactor: 1,
            heightFactor: .5,
            child: Image.asset(
              'assets/images/banner_header.png',
              fit: BoxFit.fill,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
      ],
    );
  }
}

class _EditProfileTopBar extends StatelessWidget {
  const _EditProfileTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.paddingOf(context).top + 10,
        18,
        14,
      ),
      color: Colors.transparent,
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: .72),
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(15),
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PERSONAL HUB',
                  style: TextStyle(
                    color: Color(0xFF52739A),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Sửa hồ sơ',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.8,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceBlue,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFD9E7FF)),
            ),
            child: const Icon(
              Icons.edit_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.avatarPath, required this.onTap});

  final String? avatarPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            _AvatarImage(path: avatarPath, size: 118, radius: 37),
            Positioned(
              right: -4,
              bottom: -4,
              child: Material(
                color: AppColors.primary,
                shape: const CircleBorder(),
                elevation: 5,
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(11),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 19,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.edit_rounded, size: 16),
          label: const Text('Đổi ảnh đại diện'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({
    required this.path,
    required this.size,
    required this.radius,
  });

  final String? path;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final image = path == null
        ? Image.asset('assets/images/leximon-owl.png', fit: BoxFit.cover)
        : Image.file(
            File(path!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Image.asset('assets/images/leximon-owl.png', fit: BoxFit.cover),
          );

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          colors: [Color(0xFF1D75FF), Color(0xFF064EE0)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x361258FF),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 3),
        child: image,
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: .65),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Color(0xFFE3EAF4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Color(0xFFE3EAF4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}

class _ImageSourceTile extends StatelessWidget {
  const _ImageSourceTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 2),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surfaceBlue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
