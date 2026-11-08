import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
        return Icons.timer_outlined;
      case AlertType.corrigendum:
        return Icons.edit_notifications_outlined;
      case AlertType.admitCard:
        return Icons.badge_outlined;
      case AlertType.result:
        return Icons.emoji_events_outlined;
      default:
        return Icons.campaign_outlined;
    }
  }

  Color _getColorForType(AlertType type) {
    switch (type) {
      case AlertType.upcomingDeadline:
      case AlertType.deadlineChange:
        return AppColors.warning;
      case AlertType.corrigendum:
        return Colors.orange;
      case AlertType.admitCard:
        return AppColors.primaryBlue;
      case AlertType.result:
        return AppColors.success;
      default:
        return AppColors.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allAlerts = ref.watch(alertsProvider);

    final filtered = allAlerts.where((a) {
      if (_selectedType == null) return true;
      return a.type == _selectedType;
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications & Alerts'),
        actions: [
          if (allAlerts.any((a) => !a.isRead))
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
                    onSelected: (_) => setState(() => _selectedType = null),
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  ...AlertType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppDimensions.space8),
                      child: ChoiceChip(
                        label: Text(type.label),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedType = selected ? type : null);
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
                  await ref.read(alertsProvider.notifier).loadAlerts();
                },
                child: filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          EmptyStateView(
                            icon: Icons.notifications_none_rounded,
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
                                context.go('/opportunities/${alert.opportunityId}');
                              }
                            },
                            borderRadius: AppDimensions.roundedDefault,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: AppDimensions.space12),
                              padding: const EdgeInsets.all(AppDimensions.space16),
                              decoration: BoxDecoration(
                                color: alert.isRead
                                    ? theme.cardColor
                                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF)),
                                borderRadius: AppDimensions.roundedDefault,
                                border: Border.all(
                                  color: alert.isRead
                                      ? theme.colorScheme.outline
                                      : AppColors.primaryBlue.withValues(alpha: 0.4),
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
                                      color: color.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(icon, size: 20, color: color),
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
                                              style: AppTypography.caption.copyWith(fontSize: 10),
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
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),

                                        // Message Body
                                        Text(
                                          alert.message,
                                          style: AppTypography.caption.copyWith(
                                            height: 1.4,
                                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                          ),
                                        ),

                                        if (alert.opportunityId != null) ...[
                                          const SizedBox(height: 8),
                                          const Text(
                                            'View Details →',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.bold,
                                            ),
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
    );
  }
}
