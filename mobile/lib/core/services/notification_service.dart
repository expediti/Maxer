import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:rexam/models/examination.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String channelDeadlines = 'rexam_deadlines';
  static const String channelExamDates = 'rexam_exam_dates';
  static const String channelUpdates = 'rexam_updates';

  /// Initialize local notification channels and timezone data
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone database
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (_) {
        // Fallback to UTC if Asia/Kolkata lookup fails
      }

      // Android Initialization settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Linux / macOS initialization settings
      const LinuxInitializationSettings linuxSettings =
          LinuxInitializationSettings(defaultActionName: 'Open Rexam');

      final InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        linux: linuxSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[REXAM Notifications] Notification tapped: ${response.payload}');
        },
      );

      // Create distinct Android notification channels
      if (!kIsWeb && Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          // Channel 1: Deadlines
          await androidImplementation.createNotificationChannel(
            const AndroidNotificationChannel(
              channelDeadlines,
              'Application Deadlines',
              description: 'Urgent reminders before registration closes (7d, 3d, 2d, 24h)',
              importance: Importance.high,
              enableVibration: true,
            ),
          );

          // Channel 2: Examination Dates
          await androidImplementation.createNotificationChannel(
            const AndroidNotificationChannel(
              channelExamDates,
              'Examination Dates & Admit Cards',
              description: 'Admit card dispatches and stage examination schedules',
              importance: Importance.high,
              enableVibration: true,
            ),
          );

          // Channel 3: Official Updates
          await androidImplementation.createNotificationChannel(
            const AndroidNotificationChannel(
              channelUpdates,
              'Official Updates & Corrigenda',
              description: 'Government gazettes, syllabus revisions, and corrigenda notices',
              importance: Importance.defaultImportance,
            ),
          );

          // Request permission on Android 13+
          await androidImplementation.requestNotificationsPermission();
        }
      }

      _isInitialized = true;
      debugPrint('[REXAM Notifications] Initialized with Asia/Kolkata timezone support.');
    } catch (e) {
      debugPrint('[REXAM Notifications] Initialization error: $e');
    }
  }

  /// Generate a deterministic 32-bit positive integer ID for notification scheduling
  int _generateId(String examId, int slot) {
    final bytes = utf8.encode('$examId:$slot');
    final digest = md5.convert(bytes);
    final value = digest.bytes[0] |
        (digest.bytes[1] << 8) |
        (digest.bytes[2] << 16) |
        (digest.bytes[3] << 24);
    return (value & 0x7FFFFFFF);
  }

  /// Safe resolution of examination date from importantDates map
  DateTime? _resolveExamDate(Examination exam) {
    for (final entry in exam.importantDates.entries) {
      final keyLower = entry.key.toLowerCase();
      if (keyLower.contains('exam') ||
          keyLower.contains('tier') ||
          keyLower.contains('prelim') ||
          keyLower.contains('cbt') ||
          keyLower.contains('stage 1') ||
          keyLower.contains('written')) {
        if (entry.value != null) {
          return entry.value;
        }
      }
    }
    return null;
  }

  /// Schedule all verified date alerts for an examination in Asia/Kolkata timezone
  Future<void> scheduleRemindersForExamination(Examination exam) async {
    await initialize();

    final now = DateTime.now();
    final kolkata = tz.getLocation('Asia/Kolkata');

    final String title = exam.title.isNotEmpty ? exam.title : 'Examination';
    final String orgName = exam.organisation.isNotEmpty
        ? exam.organisation
        : (exam.issuingAuthority.isNotEmpty ? exam.issuingAuthority : 'Authority');

    // 1. Application Deadline Milestones (7 days, 3 days, 2 days, 24 hours)
    final deadline = exam.applicationDeadline;
    if (deadline != null && deadline.isAfter(now)) {
      final tzDeadline = tz.TZDateTime.from(deadline, kolkata);
      final deadlineStr =
          '${deadline.day.toString().padLeft(2, '0')}/${deadline.month.toString().padLeft(2, '0')}/${deadline.year}';

      // Milestone: 7 Days Before
      final sevenDaysBefore = tzDeadline.subtract(const Duration(days: 7));
      if (sevenDaysBefore.isAfter(tz.TZDateTime.now(kolkata))) {
        await _scheduleSingle(
          id: _generateId(exam.id, 7),
          title: '7 Days Left: $title',
          body: 'Registration for $orgName closes on $deadlineStr. Complete your submission early.',
          scheduledDate: sevenDaysBefore,
          channel: channelDeadlines,
          payload: exam.id,
        );
      }

      // Milestone: 3 Days Before
      final threeDaysBefore = tzDeadline.subtract(const Duration(days: 3));
      if (threeDaysBefore.isAfter(tz.TZDateTime.now(kolkata))) {
        await _scheduleSingle(
          id: _generateId(exam.id, 3),
          title: '3 Days Left: $title',
          body: 'Only 3 days remaining before $orgName deadline closes. Ensure fee payment is reconciled.',
          scheduledDate: threeDaysBefore,
          channel: channelDeadlines,
          payload: exam.id,
        );
      }

      // Milestone: 2 Days Before
      final twoDaysBefore = tzDeadline.subtract(const Duration(days: 2));
      if (twoDaysBefore.isAfter(tz.TZDateTime.now(kolkata))) {
        await _scheduleSingle(
          id: _generateId(exam.id, 2),
          title: '48 Hours Left: $title',
          body: 'Final 48 hours for $orgName application window. Server load increases near closing.',
          scheduledDate: twoDaysBefore,
          channel: channelDeadlines,
          payload: exam.id,
        );
      }

      // Milestone: 24 Hours Before (Urgent)
      final oneDayBefore = tzDeadline.subtract(const Duration(hours: 24));
      if (oneDayBefore.isAfter(tz.TZDateTime.now(kolkata))) {
        await _scheduleSingle(
          id: _generateId(exam.id, 1),
          title: 'URGENT: 24 Hours Remaining for $title',
          body: 'Application window closes tomorrow! Submit your application and download confirmation slip.',
          scheduledDate: oneDayBefore,
          channel: channelDeadlines,
          payload: exam.id,
        );
      }
    }

    // 2. Application Start / Opening Reminder
    final opening = exam.applicationStartDate;
    if (opening != null && opening.isAfter(now)) {
      final tzOpening = tz.TZDateTime.from(opening, kolkata);
      await _scheduleSingle(
        id: _generateId(exam.id, 100),
        title: 'Applications Open: $title',
        body: 'Official registration portal for $orgName is now open.',
        scheduledDate: tzOpening,
        channel: channelDeadlines,
        payload: exam.id,
      );
    }

    // 3. Examination Date Reminder
    final examDate = _resolveExamDate(exam);
    if (examDate != null && examDate.isAfter(now)) {
      final tzExamDate = tz.TZDateTime.from(examDate, kolkata);
      final examMorning = tz.TZDateTime(kolkata, tzExamDate.year, tzExamDate.month, tzExamDate.day, 7, 0);

      if (examMorning.isAfter(tz.TZDateTime.now(kolkata))) {
        await _scheduleSingle(
          id: _generateId(exam.id, 200),
          title: 'Examination Today: $title',
          body: 'Carry your printed admit card, original photo ID, and arrive before gate closure.',
          scheduledDate: examMorning,
          channel: channelExamDates,
          payload: exam.id,
        );
      }
    }
  }

  /// Alias for backward compatibility
  Future<void> scheduleRemindersForOpportunity(Examination exam) =>
      scheduleRemindersForExamination(exam);

  Future<void> _scheduleSingle({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String channel,
    String? payload,
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel,
            channel == channelDeadlines
                ? 'Application Deadlines'
                : channel == channelExamDates
                    ? 'Examination Dates & Admit Cards'
                    : 'Official Updates',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      debugPrint('[REXAM Notifications] Scheduled "$title" for $scheduledDate (IST)');
    } catch (e) {
      debugPrint('[REXAM Notifications] Schedule error: $e');
    }
  }

  /// Cancel all scheduled local reminders for a given examination
  Future<void> cancelRemindersForExamination(String examId) async {
    await initialize();
    final slots = [7, 3, 2, 1, 100, 200];
    for (final slot in slots) {
      final id = _generateId(examId, slot);
      try {
        await _notificationsPlugin.cancel(id);
      } catch (_) {}
    }
    debugPrint('[REXAM Notifications] Cancelled scheduled reminders for $examId');
  }

  /// Alias for backward compatibility
  Future<void> cancelRemindersForOpportunity(String oppId) =>
      cancelRemindersForExamination(oppId);

  /// Send an immediate on-device notification (for test or immediate alerts)
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String channel = channelUpdates,
    String? payload,
  }) async {
    await initialize();
    try {
      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel,
            channel,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('[REXAM Notifications] Instant notification error: $e');
    }
  }
}
