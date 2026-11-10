import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:rexam/core/constants/app_colors.dart';
import 'package:rexam/core/constants/app_dimensions.dart';
import 'package:rexam/features/profile/presentation/providers/profile_provider.dart';

class AvatarPickerWidget extends ConsumerStatefulWidget {
  final double radius;
  final bool editable;

  const AvatarPickerWidget({
    super.key,
    this.radius = 32,
    this.editable = true,
  });

  @override
  ConsumerState<AvatarPickerWidget> createState() => _AvatarPickerWidgetState();
}

class _AvatarPickerWidgetState extends ConsumerState<AvatarPickerWidget> {
  bool _isUploading = false;

  Future<void> _pickAndUploadImage(ImageSource source) async {
    Navigator.of(context).pop(); // Close bottom sheet
    final picker = ImagePicker();

    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85, // compressed web-safe quality
      );

      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      final bytes = await pickedFile.readAsBytes();
      final success = await ref.read(profileProvider.notifier).uploadAvatar(bytes);

      if (mounted) {
        setState(() => _isUploading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully.'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload photo. Please check network connection.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selection error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImageSourcePicker() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusCard)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.space16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Update Profile Photo',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppDimensions.space12),
              ListTile(
                leading: Icon(LucideIcons.camera, color: theme.colorScheme.onSurface),
                title: Text('Take Photo', style: TextStyle(color: theme.colorScheme.onSurface)),
                onTap: () => _pickAndUploadImage(ImageSource.camera),
              ),
              ListTile(
                leading: Icon(LucideIcons.image, color: theme.colorScheme.onSurface),
                title: Text('Choose from Gallery', style: TextStyle(color: theme.colorScheme.onSurface)),
                onTap: () => _pickAndUploadImage(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final theme = Theme.of(context);
    final avatarUrl = profileAsync.valueOrNull?.avatarUrl;
    final fullName = profileAsync.valueOrNull?.fullName ?? '';
    final initials = fullName.trim().isNotEmpty
        ? fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'C';

    return GestureDetector(
      onTap: widget.editable && !_isUploading ? _showImageSourcePicker : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: widget.radius,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? NetworkImage(avatarUrl) as ImageProvider
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Text(
                    initials,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontSize: widget.radius * 0.65,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          if (_isUploading)
            Container(
              width: widget.radius * 2,
              height: widget.radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black54,
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            ),
          if (widget.editable && !_isUploading)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                ),
                child: const Icon(
                  LucideIcons.camera,
                  size: 12,
                  color: Colors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

