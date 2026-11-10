import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:rexam/core/constants/app_colors.dart';
import 'package:rexam/core/constants/app_dimensions.dart';
import 'package:rexam/core/theme/app_typography.dart';
import 'package:rexam/core/widgets/empty_state.dart';
import 'package:rexam/features/alerts/domain/alert_item.dart';
import 'package:rexam/features/alerts/presentation/providers/alerts_provider.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  AlertType? _selectedType;

  IconData _getIconForType(AlertType type) {
    switch (type) {
      case AlertType.upcomingDeadline:
      case AlertType.deadlineChange:
        return LucideIcons.clock;
      case AlertType.corrigendum:
        return LucideIcons.alertTriangle;
      case AlertType.admitCard:
        return LucideIcons.fileCheck;
      case AlertType.result:
        return LucideIcons.award;
      default:
        return LucideIcons.bell;
    }
  }

  Color _getColorForType(AlertType type) {
    switch (type) {
      case AlertType.upcomingDeadline:
      case AlertType.deadlineChange:
        return AppColors.warning;
      case AlertType.corrigendum:
        return const Color(0xFFF97316); // Orange
      case AlertType.admitCard:
        return const Color(0xFF60A5FA); // Sky blue
      case AlertType.result:
        return AppColors.primaryGreen;
      default:
        return AppColors.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allAlerts = ref.watch(alertsProvider);

    final filtered = allAlerts.where((a) {
      if (_selectedType == null) return true;
      return a.type == _selectedType;
    }).toList();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/discover');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/discover');
              }
            },
          ),
          title: Text(
            'Notifications & Alerts',
            style: AppTypography.screenTitle.copyWith(fontSize: 18),
          ),
        actions: [
          if (allAlerts.any((a) => !a.isRead))
            TextButton.icon(
              onPressed: () => ref.read(alertsProvider.notifier).markAllAsRead(),
              icon: const Icon(LucideIcons.checkCheck, size: 14, color: AppColors.primaryGreen),
              label: const Text(
                'Mark All Read',
                style: TextStyle(color: AppColors.primaryGreen, fontSize: 12),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space8,
              ),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All Alerts'),
                    selected: _selectedType == null,
                    showCheckmark: false,
                    selectedColor: AppColors.primaryGreen,
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      side: BorderSide(
                        color: _selectedType == null ? AppColors.primaryGreen : AppColors.border,
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: _selectedType == null ? AppColors.background : AppColors.textMain,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _selectedType = null),
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  ...AlertType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppDimensions.space8),
                      child: FilterChip(
                        label: Text(type.label),
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
                          setState(() => _selectedType = selected ? type : null);
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
                  await ref.read(alertsProvider.notifier).loadAlerts();
                },
                child: filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          EmptyStateView(
                            icon: LucideIcons.bell,
                            title: 'No Notifications',
                            description: _selectedType != null
                                ? 'No alerts in category "${_selectedType!.label}".'
                                : 'You are completely caught up! New deadline reminders, admit card notifications, and official corrigenda will appear here.',
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppDimensions.space16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final alert = filtered[index];
                          final icon = _getIconForType(alert.type);
                          final color = _getColorForType(alert.type);

                          return InkWell(
                            onTap: () {
                              ref.read(alertsProvider.notifier).markAsRead(alert.id);
                              if (alert.opportunityId != null) {
                                context.push('/opportunities/${alert.opportunityId}');
                              }
                            },
                            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: AppDimensions.space12),
                              padding: const EdgeInsets.all(AppDimensions.space16),
                              decoration: BoxDecoration(
                                color: alert.isRead ? AppColors.surface : AppColors.secondarySurface,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                                border: Border.all(
                                  color: alert.isRead
                                      ? AppColors.border
                                      : AppColors.primaryGreen.withValues(alpha: 0.4),
                                  width: alert.isRead ? 1.0 : 1.5,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Alert Type Icon
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                    ),
                                    child: Icon(icon, size: 18, color: color),
                                  ),
                                  const SizedBox(width: AppDimensions.space12),

                                  // Text Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              alert.type.label,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: color,
                                              ),
                                            ),
                                            Text(
                                              DateFormat('d MMM, HH:mm').format(alert.timestamp),
                                              style: AppTypography.caption.copyWith(
                                                fontSize: 10,
                                                color: AppColors.textSubtle,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),

                                        // Title
                                        Text(
                                          alert.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: alert.isRead ? FontWeight.w600 : FontWeight.bold,
                                            color: AppColors.textMain,
                                          ),
                                        ),
                                        const SizedBox(height: 4),

                                        // Message Body
                                        Text(
                                          alert.message,
                                          style: AppTypography.caption.copyWith(
                                            height: 1.4,
                                            color: AppColors.textMuted,
                                          ),
                                        ),

                                        if (alert.opportunityId != null) ...[
                                          const SizedBox(height: 8),
                                          const Row(
                                            children: [
                                              Text(
                                                'View Examination',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.primaryGreen,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              Icon(LucideIcons.arrowRight, size: 12, color: AppColors.primaryGreen),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
