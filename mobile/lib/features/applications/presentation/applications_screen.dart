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
import '../providers/applications_provider.dart';

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
        return AppColors.pending;
      case ApplicationStatus.applied:
        return AppColors.info;
      case ApplicationStatus.admitCardDownloaded:
        return AppColors.primaryGreen;
      case ApplicationStatus.examAppeared:
        return AppColors.primaryGreen;
      case ApplicationStatus.resultAwaited:
        return AppColors.warning;
      case ApplicationStatus.qualified:
        return AppColors.primaryGreen;
      case ApplicationStatus.notQualified:
        return AppColors.error;
    }
  }

  void _showStatusDialog(BuildContext context, ApplicationTrackerItem item) {
    ApplicationStatus current = item.status;
    final appNumController = TextEditingController(text: item.applicationNumber ?? '');
    final notesController = TextEditingController(text: item.personalNotes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: ctx.themeCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
            side: BorderSide(color: ctx.themeBorder),
          ),
          title: Text(
            'Update Application Stage',
            style: AppTypography.screenTitle.copyWith(fontSize: 18, color: ctx.themeTextMain),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<ApplicationStatus>(
                  initialValue: current,
                  dropdownColor: ctx.themeSurfaceElevated,
                  decoration: const InputDecoration(
                    labelText: 'Status Stage',
                    prefixIcon: Icon(LucideIcons.clipboardCheck, size: 18, color: AppColors.primaryGreen),
                  ),
                  items: ApplicationStatus.values.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(
                        s.label,
                        style: TextStyle(fontSize: 13, color: ctx.themeTextMain),
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
                  style: TextStyle(color: ctx.themeTextMain, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Roll No / Registration ID',
                    prefixIcon: Icon(LucideIcons.hash, size: 18, color: ctx.themeTextMuted),
                  ),
                ),
                const SizedBox(height: AppDimensions.space12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  style: TextStyle(color: ctx.themeTextMain, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Personal Notes & Checklist',
                    prefixIcon: Icon(LucideIcons.fileText, size: 18, color: ctx.themeTextMuted),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _confirmDelete(context, item);
              },
              child: const Text('Remove', style: TextStyle(color: AppColors.error)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: TextStyle(color: ctx.themeTextMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(applicationsProvider.notifier).updateStatus(
                      examinationId: item.examinationId,
                      status: current,
                      applicationNumber: appNumController.text.trim().isEmpty ? null : appNumController.text.trim(),
                      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    );
                Navigator.of(ctx).pop();
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ApplicationTrackerItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.themeCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          side: BorderSide(color: ctx.themeBorder),
        ),
        title: Text('Remove from Tracker?', style: TextStyle(color: ctx.themeTextMain)),
        content: Text(
          'Stop tracking "${item.examination.title}"? Your notes and registration ID will be removed.',
          style: TextStyle(color: ctx.themeTextMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: ctx.themeTextMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(applicationsProvider.notifier).remove(item.examinationId);
              Navigator.of(ctx).pop();
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final applications = ref.watch(applicationsProvider);
    final filtered = _filterStatus == null
        ? applications
        : applications.where((a) => a.status == _filterStatus).toList();

    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        backgroundColor: context.themeBackground,
        elevation: 0,
        title: Text(
          'Application Tracker',
          style: AppTypography.screenTitle.copyWith(fontSize: 18, color: context.themeTextMain),
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
                    backgroundColor: context.themeCard,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      side: BorderSide(
                        color: _filterStatus == null ? AppColors.primaryGreen : context.themeBorder,
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: _filterStatus == null ? Colors.white : context.themeTextMain,
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
                        backgroundColor: context.themeCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          side: BorderSide(
                            color: isSelected ? AppColors.primaryGreen : context.themeBorder,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : context.themeTextMain,
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
            Divider(color: context.themeBorder, height: 1),

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
                            icon: LucideIcons.clipboardList,
                            title: 'No Applications Tracked',
                            description: _filterStatus != null
                                ? 'No applications in ${_filterStatus!.label} stage.'
                                : 'Track your applications, examination dates, and registration numbers in one private dashboard.',
                            actionLabel: 'Discover Opportunities',
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
                              color: context.themeCard,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                              border: Border.all(color: context.themeBorder),
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
                                    style: AppTypography.cardTitle.copyWith(fontSize: 15, color: context.themeTextMain),
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Organisation
                                Text(
                                  item.examination.organisation,
                                  style: AppTypography.caption.copyWith(color: context.themeTextMuted),
                                ),
                                const SizedBox(height: AppDimensions.space12),

                                // Application number or notes if present
                                if (item.applicationNumber != null && item.applicationNumber!.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: context.themeSurfaceElevated,
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                      border: Border.all(color: context.themeBorder),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.hash, size: 12, color: context.themeTextMuted),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Reg / Roll No: ${item.applicationNumber}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                            color: context.themeTextMain,
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
                                      color: context.themeTextMuted,
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
                                      style: AppTypography.caption.copyWith(fontSize: 10, color: context.themeTextSubtle),
                                    ),
                                    InkWell(
                                      onTap: () => context.push('/opportunities/${item.examinationId}'),
                                      child: const Row(
                                        children: [
                                          Text(
                                            'View Details',
                                            style: TextStyle(
                                              color: AppColors.primaryGreen,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 2),
                                          Icon(LucideIcons.arrowRight, size: 12, color: AppColors.primaryGreen),
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
