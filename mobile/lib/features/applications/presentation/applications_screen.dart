import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
        return AppColors.info;
      case ApplicationStatus.preparingDocuments:
      case ApplicationStatus.readyToApply:
        return AppColors.warning;
      case ApplicationStatus.applied:
        return AppColors.primaryBlue;
      case ApplicationStatus.admitCardReleased:
      case ApplicationStatus.examCompleted:
        return Colors.indigo;
      case ApplicationStatus.resultDeclared:
      case ApplicationStatus.selected:
        return AppColors.success;
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
          title: Text('Update Application Stage', style: AppTypography.screenTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<ApplicationStatus>(
                  initialValue: current,
                  decoration: const InputDecoration(labelText: 'Status Stage'),
                  items: ApplicationStatus.values.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s.label, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => current = val);
                  },
                ),
                const SizedBox(height: AppDimensions.space12),
                TextField(
                  controller: appNumController,
                  decoration: const InputDecoration(labelText: 'Application / Registration Number'),
                ),
                const SizedBox(height: AppDimensions.space12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Personal Notes & Checklist'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _showConfirmDeleteDialog(context, item);
              },
              child: Text('Remove', style: TextStyle(color: AppColors.error)),
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
                  SnackBar(content: Text('Updated to ${current.label}')),
                );
              },
              child: const Text('Update'),
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
        title: const Text('Remove from Tracker?'),
        content: Text('Are you sure you want to stop tracking "${item.examination.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allTrackers = ref.watch(applicationsProvider);

    final filtered = allTrackers.where((item) {
      if (_filterStatus == null) return true;
      return item.status == _filterStatus;
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Application Tracker'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stage Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: AppDimensions.space8),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Stages'),
                    selected: _filterStatus == null,
                    onSelected: (selected) {
                      if (selected) setState(() => _filterStatus = null);
                    },
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  ...ApplicationStatus.values.map((status) {
                    final isSelected = _filterStatus == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppDimensions.space8),
                      child: ChoiceChip(
                        label: Text(status.label),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _filterStatus = selected ? status : null);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            Divider(color: theme.colorScheme.outline),

            // Content List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryBlue,
                onRefresh: () async {
                  await ref.read(applicationsProvider.notifier).loadApplications();
                },
                child: filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          EmptyStateView(
                            icon: Icons.assignment_outlined,
                            title: 'No Tracked Applications',
                            description: _filterStatus != null
                                ? 'No applications in stage "${_filterStatus!.label}".'
                                : 'Track examinations you intend to sit for to log your registration ID, exam dates, and preparation milestones.',
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
                              color: theme.cardColor,
                              borderRadius: AppDimensions.roundedDefault,
                              border: Border.all(color: theme.colorScheme.outline),
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
                                        borderRadius: AppDimensions.roundedSmall,
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
                                      icon: const Icon(Icons.edit_note, size: 16),
                                      label: const Text('Update'),
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
                                  onTap: () => context.go('/opportunities/${item.examinationId}'),
                                  child: Text(
                                    item.examination.title,
                                    style: AppTypography.cardTitle.copyWith(fontSize: 15),
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Organisation
                                Text(
                                  item.examination.organisation,
                                  style: AppTypography.caption.copyWith(
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.space12),

                                // Application number or dates if present
                                if (item.applicationNumber != null && item.applicationNumber!.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
                                      borderRadius: AppDimensions.roundedSmall,
                                    ),
                                    child: Text(
                                      'Reg / Roll No: ${item.applicationNumber}',
                                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                                    ),
                                  ),
                                  const SizedBox(height: AppDimensions.space8),
                                ],

                                if (item.personalNotes != null && item.personalNotes!.isNotEmpty) ...[
                                  Text(
                                    item.personalNotes!,
                                    style: AppTypography.caption.copyWith(
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
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
                                      'Last updated: ${DateFormat('d MMM yyyy').format(item.lastUpdated)}',
                                      style: AppTypography.caption.copyWith(fontSize: 10),
                                    ),
                                    InkWell(
                                      onTap: () => context.go('/opportunities/${item.examinationId}'),
                                      child: const Text(
                                        'View Exam →',
                                        style: TextStyle(color: AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold),
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
