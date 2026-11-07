import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexam/core/constants/app_colors.dart';
import 'package:rexam/core/constants/app_dimensions.dart';
import 'package:rexam/core/theme/app_typography.dart';
import 'package:rexam/core/utils/date_formatter.dart';
import 'package:rexam/features/alerts/domain/alert_item.dart';
import 'package:rexam/features/alerts/presentation/providers/alerts_provider.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  AlertType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final allAlerts = ref.watch(alertsProvider);

    final filtered = allAlerts.where((a) {
      if (_selectedType == null) return true;
      return a.type == _selectedType;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications & Alerts'),
        actions: [
          TextButton(
            onPressed: () => ref.read(alertsProvider.notifier).markAllAsRead(),
            child: const Text('Mark All Read'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: AppDimensions.space8),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Alerts'),
                    selected: _selectedType == null,
                    selectedColor: AppColors.secondaryGreen,
                    backgroundColor: AppColors.surface,
                    labelStyle: AppTypography.caption.copyWith(
                      color: _selectedType == null ? AppColors.textMain : AppColors.textMuted,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppDimensions.roundedSmall,
                      side: BorderSide(color: _selectedType == null ? AppColors.primaryGreen : AppColors.border),
                    ),
                    onSelected: (_) => setState(() => _selectedType = null),
                  ),
                  ...AlertType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return Padding(
                      padding: const EdgeInsets.only(left: AppDimensions.space8),
                      child: ChoiceChip(
                        label: Text(type.label),
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
                          setState(() => _selectedType = selected ? type : null);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Divider(color: AppColors.border),

            // Alerts List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications_off_outlined, size: 40, color: AppColors.textMuted),
                          const SizedBox(height: AppDimensions.space12),
                          Text('No alerts in this category', style: AppTypography.sectionHeader),
                          const SizedBox(height: AppDimensions.space4),
                          Text('You will receive updates when official corrigenda or deadlines arrive.', style: AppTypography.bodyMuted),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppDimensions.space16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final alert = filtered[index];
                        return _buildAlertCard(context, alert);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, AlertItem alert) {
    Color typeColor;
    switch (alert.type) {
      case AlertType.upcomingDeadline:
      case AlertType.deadlineChange:
        typeColor = AppColors.warning;
        break;
      case AlertType.officialNotification:
      case AlertType.corrigendum:
        typeColor = AppColors.info;
        break;
      case AlertType.result:
      case AlertType.admitCard:
      case AlertType.matchingOpportunity:
      case AlertType.examDateChange:
        typeColor = AppColors.primaryGreen;
        break;
    }

    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimensions.space16),
        color: AppColors.errorLight,
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      onDismissed: (_) {
        ref.read(alertsProvider.notifier).removeAlert(alert.id);
      },
      child: InkWell(
        onTap: () {
          ref.read(alertsProvider.notifier).markAsRead(alert.id);
          if (alert.opportunityId != null) {
            context.go('/opportunities/${alert.opportunityId}');
          }
        },
        borderRadius: AppDimensions.roundedDefault,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.space12),
          padding: const EdgeInsets.all(AppDimensions.space16),
          decoration: BoxDecoration(
            color: alert.isRead ? AppColors.surface : AppColors.surfaceElevated,
            borderRadius: AppDimensions.roundedDefault,
            border: Border.all(
              color: alert.isRead ? AppColors.border : AppColors.primaryGreen.withOpacity(0.4),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space8, vertical: AppDimensions.space2),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.12),
                      borderRadius: AppDimensions.roundedSmall,
                      border: Border.all(color: typeColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      alert.type.label,
                      style: AppTypography.caption.copyWith(color: typeColor, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    DateFormatter.formatDateTime(alert.timestamp),
                    style: AppTypography.caption.copyWith(color: AppColors.textSubtle, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space8),
              Text(
                alert.title,
                style: AppTypography.cardTitle.copyWith(
                  fontWeight: alert.isRead ? FontWeight.w500 : FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppDimensions.space4),
              Text(
                alert.message,
                style: AppTypography.bodyMuted.copyWith(fontSize: 13),
              ),
              if (alert.opportunityId != null) ...[
                const SizedBox(height: AppDimensions.space8),
                Row(
                  children: [
                    Text('View Opportunity Details', style: AppTypography.caption.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
                    const SizedBox(width: AppDimensions.space4),
                    const Icon(Icons.arrow_forward, size: 12, color: AppColors.primaryGreen),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
