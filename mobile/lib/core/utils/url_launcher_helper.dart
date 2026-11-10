import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Production-grade Authoritative URL & Gazette Document Launcher for Rexam.
/// Preserves exact URL query parameters, full paths, and anchors.
/// Validates link status and provides seamless fallback when links are under review.
class UrlLauncherHelper {
  UrlLauncherHelper._();

  /// Launches any arbitrary official URL in the device's external browser.
  static Future<bool> openUrl(
    BuildContext context,
    String? rawUrl, {
    String? fallbackTitle,
  }) async {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      if (context.mounted) {
        _showReviewDialog(
          context,
          title: 'Official Link Unavailable',
          message: 'Official application link is currently unavailable. We are reviewing the link.',
        );
      }
      return false;
    }

    String cleanedUrl = rawUrl.trim();
    if (!cleanedUrl.startsWith('http://') && !cleanedUrl.startsWith('https://')) {
      cleanedUrl = 'https://$cleanedUrl';
    }

    final uri = Uri.tryParse(cleanedUrl);
    if (uri == null) {
      if (context.mounted) {
        _showReviewDialog(
          context,
          title: 'Invalid Link',
          message: 'Official application link is currently unavailable. We are reviewing the link.',
        );
      }
      return false;
    }

    try {
      // Rule: Launch in external browser preserving all parameters and session cookies
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;

      // Fallback to platform default
      final fallbackLaunched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
      if (fallbackLaunched) return true;

      if (context.mounted) {
        _showReviewDialog(
          context,
          title: 'Link Under Review',
          message: 'Official application link is currently unavailable. We are reviewing the link.',
        );
      }
      return false;
    } catch (e) {
      debugPrint('[REXAM] URL launch error for $cleanedUrl: $e');
      if (context.mounted) {
        _showReviewDialog(
          context,
          title: 'Connection Notice',
          message: 'Official application link is currently unavailable. We are reviewing the link.',
        );
      }
      return false;
    }
  }

  /// Specialized Official Portal Application Launcher with graceful fallback
  static Future<void> openApplicationPortal(
    BuildContext context, {
    required String? applicationUrl,
    String? notificationPdfUrl,
    String? sourcePortalUrl,
    bool isApplicationUrlVerified = true,
    String? applicationUrlStatus,
  }) async {
    final status = (applicationUrlStatus ?? '').toUpperCase();
    final isInvalidOrBlocked = status == 'INVALID_URL' ||
        status == 'INVALID_DNS' ||
        status == 'TEMPORARILY_UNAVAILABLE';

    if (applicationUrl == null ||
        applicationUrl.trim().isEmpty ||
        isInvalidOrBlocked ||
        (!isApplicationUrlVerified && status == 'NEEDS_REVIEW' && applicationUrl.trim().isEmpty)) {
      _showReviewDialog(
        context,
        title: 'Application Link Under Review',
        message: 'Official application link is currently unavailable. We are reviewing the link.',
        fallbackPdfUrl: notificationPdfUrl,
        fallbackHomeUrl: sourcePortalUrl,
      );
      return;
    }

    // Attempt external launch
    final ok = await openUrl(context, applicationUrl, fallbackTitle: 'Official Application Portal');
    if (!ok && context.mounted) {
      _showReviewDialog(
        context,
        title: 'Application Link Under Review',
        message: 'Official application link is currently unavailable. We are reviewing the link.',
        fallbackPdfUrl: notificationPdfUrl,
        fallbackHomeUrl: sourcePortalUrl,
      );
    }
  }

  static void _showReviewDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? fallbackPdfUrl,
    String? fallbackHomeUrl,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.themeCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          side: BorderSide(color: ctx.themeBorder),
        ),
        title: Row(
          children: [
            const Icon(LucideIcons.shieldAlert, size: 20, color: AppColors.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: ctx.themeTextMain,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: ctx.themeTextMuted,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            if (fallbackPdfUrl != null && fallbackPdfUrl.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.space12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  openUrl(context, fallbackPdfUrl, fallbackTitle: 'Official Notification Document');
                },
                icon: const Icon(LucideIcons.fileText, size: 15),
                label: const Text('Open Official Notification PDF'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  side: BorderSide(color: ctx.themeBorder),
                  foregroundColor: ctx.themeTextMain,
                ),
              ),
            ],
            if (fallbackHomeUrl != null && fallbackHomeUrl.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.space8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  openUrl(context, fallbackHomeUrl, fallbackTitle: 'Official Authority Portal');
                },
                icon: const Icon(LucideIcons.globe, size: 15),
                label: const Text('Visit Authority Official Website'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  side: BorderSide(color: ctx.themeBorder),
                  foregroundColor: ctx.themeTextMain,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: TextStyle(color: ctx.themeTextMuted)),
          ),
        ],
      ),
    );
  }
}
