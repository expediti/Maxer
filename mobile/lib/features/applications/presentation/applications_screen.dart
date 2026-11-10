import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/application_tracker.dart';
import 'providers/applications_provider.dart';

class ApplicationsScreen extends ConsumerStatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  ConsumerState<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends ConsumerState<ApplicationsScreen> {
  ApplicationStatus? _filterStatus;

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.interested:
        return AppColors.textMuted;
      case ApplicationStatus.preparingDocuments:
      case ApplicationStatus.readyToApply:
        return AppColors.warning;
      case ApplicationStatus.applied:
        return AppColors.primaryGreen;
      case ApplicationStatus.admitCardReleased:
      case ApplicationStatus.examCompleted:
        return const Color(0xFF60A5FA); // Info blue
      case ApplicationStatus.resultDeclared:
      case ApplicationStatus.selected:
        return AppColors.primaryGreen;
      case ApplicationStatus.rejected:
      case ApplicationStatus.withdrawn:
        return AppColors.error;
    }
  }

  void _showStatusDialog(BuildContext context, ApplicationTrackerItem item) {
    ApplicationStatus current = item.status;
    final notesController = TextEditingController(text: item.personalNotes ?? '');
    final appNumController = TextEditingController(text: item.applicationNumber ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Text(
            'Update Application Stage',
            style: AppTypography.screenTitle.copyWith(fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<ApplicationStatus>(
                  initialValue: current,
                  dropdownColor: AppColors.secondarySurface,
                  decoration: const InputDecoration(
                    labelText: 'Status Stage',
                    prefixIcon: Icon(LucideIcons.clipboardCheck, size: 18, color: AppColors.primaryGreen),
                  ),
                  items: ApplicationStatus.values.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(
                        s.label,
                        style: const TextStyle(fontSize: 13, color: AppColors.textMain),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => current = val);
                  },
                ),
                const SizedBox(height: AppDimensions.space12),
                TextField(
                  controller: appNumController,
                  style: const TextStyle(color: AppColors.textMain, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Roll No / Registration ID',
                    prefixIcon: Icon(LucideIcons.hash, size: 18, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: AppDimensions.space12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.textMain, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Personal Notes & Checklist',
                    prefixIcon: Icon(LucideIcons.fileText, size: 18, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => _showConfirmDeleteDialog(context, item),
              child: const Text('Remove', style: TextStyle(color: AppColors.error)),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(applicationsProvider.notifier).addOrUpdate(
                      opportunity: item.examination,
                      status: current,
                      applicationNumber: appNumController.text.trim().isEmpty ? null : appNumController.text.trim(),
                      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    );
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Stage updated: ${current.label}'),
                    backgroundColor: AppColors.primaryGreen,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDeleteDialog(BuildContext context, ApplicationTrackerItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Remove from Tracker?'),
        content: Text(
          'Are you sure you want to stop tracking "${item.examination.title}"?',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(applicationsProvider.notifier).remove(item.id);
              Navigator.of(ctx).pop(); // Close confirm dialog
              Navigator.of(context).pop(); // Close status dialog
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTrackers = ref.watch(applicationsProvider);

    final filtered = allTrackers.where((item) {
      if (_filterStatus == null) return true;
      return item.status == _filterStatus;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Application Tracker',
          style: AppTypography.screenTitle.copyWith(fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stage Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space8,
              ),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All Stages'),
                    selected: _filterStatus == null,
                    showCheckmark: false,
                    selectedColor: AppColors.primaryGreen,
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      side: BorderSide(
                        color: _filterStatus == null ? AppColors.primaryGreen : AppColors.border,
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: _filterStatus == null ? AppColors.background : AppColors.textMain,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _filterStatus = null);
                    },
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  ...ApplicationStatus.values.map((status) {
                    final isSelected = _filterStatus == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppDimensions.space8),
                      child: FilterChip(
                        label: Text(status.label),
                        selected: isSelected,
                        showCheckmark: false,
                        selectedColor: AppColors.primaryGreen,
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          side: BorderSide(
                            color: isSelected ? AppColors.primaryGreen : AppColors.border,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.background : AppColors.textMain,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          setState(() => _filterStatus = selected ? status : null);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),

            // Content List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryGreen,
                onRefresh: () async {
                  await ref.read(applicationsProvider.notifier).loadApplications();
                },
                child: filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          EmptyStateView(
                            icon: LucideIcons.clipboardCheck,
                            title: 'No Tracked Applications',
                            description: _filterStatus != null
                                ? 'No applications currently in stage "${_filterStatus!.label}".'
                                : 'Track examinations you intend to sit for to log your registration ID, exam dates, and milestone preparation notes.',
                            actionLabel: 'Browse Examinations',
                            onAction: () => context.go('/explorer'),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppDimensions.space16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final statusColor = _getStatusColor(item.status);

                          return Container(
                            margin: const EdgeInsets.only(bottom: AppDimensions.space12),
                            padding: const EdgeInsets.all(AppDimensions.space16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Stage and Action Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        item.status.label,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _showStatusDialog(context, item),
                                      icon: const Icon(LucideIcons.edit3, size: 14, color: AppColors.primaryGreen),
                                      label: const Text(
                                        'Update Stage',
                                        style: TextStyle(color: AppColors.primaryGreen, fontSize: 12),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppDimensions.space8),

                                // Title
                                InkWell(
                                  onTap: () => context.push('/opportunities/${item.examinationId}'),
                                  child: Text(
                                    item.examination.title,
                                    style: AppTypography.cardTitle.copyWith(fontSize: 15),
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Organisation
                                Text(
                                  item.examination.organisation,
                                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                                ),
                                const SizedBox(height: AppDimensions.space12),

                                // Application number or notes if present
                                if (item.applicationNumber != null && item.applicationNumber!.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondarySurface,
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.hash, size: 12, color: AppColors.textMuted),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Reg / Roll No: ${item.applicationNumber}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                            color: AppColors.textMain,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppDimensions.space8),
                                ],

                                if (item.personalNotes != null && item.personalNotes!.isNotEmpty) ...[
                                  Text(
                                    item.personalNotes!,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textMuted,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: AppDimensions.space8),
                                ],

                                // Last Updated
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Updated ${DateFormat('d MMM yyyy').format(item.lastUpdated)}',
                                      style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textSubtle),
                                    ),
                                    InkWell(
                                      onTap: () => context.push('/opportunities/${item.examinationId}'),
                                      child: Row(
                                        children: [
                                          const Text(
                                            'View Details',
                                            style: TextStyle(
                                              color: AppColors.primaryGreen,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          const Icon(LucideIcons.arrowRight, size: 12, color: AppColors.primaryGreen),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
