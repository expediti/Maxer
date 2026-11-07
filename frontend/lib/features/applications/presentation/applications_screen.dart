import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../domain/application_tracker.dart';
import 'providers/applications_provider.dart';

class ApplicationsScreen extends ConsumerStatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  ConsumerState<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends ConsumerState<ApplicationsScreen> {
  ApplicationStatus? _filterStatus;

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
            borderRadius: AppDimensions.roundedDefault,
            side: const BorderSide(color: AppColors.border),
          ),
          title: Text('Update Application Stage', style: AppTypography.screenTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<ApplicationStatus>(
                  value: current,
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
                ref.read(applicationsProvider.notifier).remove(item.id);
                Navigator.of(ctx).pop();
              },
              child: Text('Remove from Tracker', style: AppTypography.caption.copyWith(color: AppColors.error)),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(applicationsProvider.notifier).addOrUpdate(
                      opportunity: item.opportunity,
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
        title: const Text('My Applications Tracker'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Disclaimer Banner
            Container(
              margin: const EdgeInsets.all(AppDimensions.space16),
              padding: const EdgeInsets.all(AppDimensions.space12),
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: AppDimensions.roundedDefault,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.primaryGreen),
                  const SizedBox(width: AppDimensions.space8),
                  Expanded(
                    child: Text(
                      'Rexam provides opportunity intelligence and tracks your application roadmap. Applications are submitted directly by you on the official conducting authority portals.',
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Stages'),
                    selected: _filterStatus == null,
                    selectedColor: AppColors.secondaryGreen,
                    backgroundColor: AppColors.surface,
                    labelStyle: AppTypography.caption.copyWith(
                      color: _filterStatus == null ? AppColors.textMain : AppColors.textMuted,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppDimensions.roundedSmall,
                      side: BorderSide(color: _filterStatus == null ? AppColors.primaryGreen : AppColors.border),
                    ),
                    onSelected: (_) => setState(() => _filterStatus = null),
                  ),
                  ...ApplicationStatus.values.map((status) {
                    final isSelected = _filterStatus == status;
                    return Padding(
                      padding: const EdgeInsets.only(left: AppDimensions.space8),
                      child: ChoiceChip(
                        label: Text(status.label),
                        selected: isSelected,
                        selectedColor: AppColors.secondaryGreen,
                        backgroundColor: AppColors.surface,
                        labelStyle: AppTypography.caption.copyWith(
                          color: isSelected ? AppColors.textMain : AppColors.textMuted,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppDimensions.roundedSmall,
                          side: BorderSide(color: isSelected ? AppColors.primaryGreen : AppColors.border),
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
            const SizedBox(height: AppDimensions.space12),
            const Divider(color: AppColors.border),

            // Tracker List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.assignment_outlined, size: 40, color: AppColors.textMuted),
                          const SizedBox(height: AppDimensions.space12),
                          Text('No applications in this stage', style: AppTypography.sectionHeader),
                          const SizedBox(height: AppDimensions.space4),
                          Text('Select an opportunity from Discover and mark "Track Status".', style: AppTypography.bodyMuted),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppDimensions.space16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _buildTrackerCard(context, item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackerCard(BuildContext context, ApplicationTrackerItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space12),
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.roundedDefault,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Status badge & Edit action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space8, vertical: AppDimensions.space4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryGreen,
                  borderRadius: AppDimensions.roundedSmall,
                  border: Border.all(color: AppColors.primaryGreen.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryGreen)),
                    const SizedBox(width: AppDimensions.space6),
                    Text(
                      item.status.label,
                      style: AppTypography.caption.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.w600, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.edit_note, size: 20, color: AppColors.textMuted),
                onPressed: () => _showStatusDialog(context, item),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space8),

          // Title
          InkWell(
            onTap: () => context.go('/opportunities/${item.opportunity.id}'),
            child: Text(
              item.opportunity.title,
              style: AppTypography.cardTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppDimensions.space4),
          Text(item.opportunity.organisation, style: AppTypography.cardSubtitle),
          const SizedBox(height: AppDimensions.space12),

          // Details row
          Container(
            padding: const EdgeInsets.all(AppDimensions.space8),
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: AppDimensions.roundedSmall,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.applicationNumber != null) ...[
                  Row(
                    children: [
                      Text('Reg / Roll No: ', style: AppTypography.caption.copyWith(color: AppColors.textSubtle)),
                      Text(item.applicationNumber!, style: AppTypography.caption.copyWith(color: AppColors.textMain, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space4),
                ],
                if (item.examDate != null) ...[
                  Row(
                    children: [
                      Text('Scheduled Exam: ', style: AppTypography.caption.copyWith(color: AppColors.textSubtle)),
                      Text(DateFormatter.formatDate(item.examDate), style: AppTypography.caption.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space4),
                ],
                if (item.personalNotes != null && item.personalNotes!.isNotEmpty) ...[
                  Text(
                    'Notes: ${item.personalNotes}',
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: AppDimensions.space4),
                ],
                Text(
                  'Updated on ${DateFormatter.formatDate(item.lastUpdated)}',
                  style: AppTypography.caption.copyWith(color: AppColors.textSubtle, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
