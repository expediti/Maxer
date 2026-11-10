import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';

/// Production-ready URL & Document Link Launcher for Rexam
/// Handles external browsers, portal URLs, deep links, and PDF documents.
class UrlLauncherHelper {
  UrlLauncherHelper._();

  static Future<bool> openUrl(
    BuildContext context,
    String? rawUrl, {
    String? fallbackTitle,
  }) async {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'No official link provided for this action.');
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
        _showErrorSnackBar(context, 'Invalid web address: $rawUrl');
      }
      return false;
    }

    try {
      // First attempt: external application (browser or PDF reader)
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;

      // Second attempt: platform default
      final fallbackLaunched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
      if (fallbackLaunched) return true;

      // Third attempt: in-app browser view
      final inAppLaunched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );
      if (inAppLaunched) return true;

      if (context.mounted) {
        _showErrorSnackBar(
          context,
          'Could not open link in browser or viewer: $cleanedUrl',
        );
      }
      return false;
    } catch (e) {
      debugPrint('[REXAM] URL launch error for $cleanedUrl: $e');
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          'Unable to open ${fallbackTitle ?? "link"}. Please check your browser or network.',
        );
      }
      return false;
    }
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppColors.primaryText, fontSize: 13),
        ),
        backgroundColor: AppColors.cardBackground,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}

