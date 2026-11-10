import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/notification_service.dart';
import 'core/supabase_client.dart';
import 'app/app.dart';

export 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  await NotificationService().initialize();
  runApp(
    const ProviderScope(
      child: RexamApp(),
    ),
  );
}
