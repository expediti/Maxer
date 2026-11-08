import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rexam/core/supabase_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Verify Supabase initialization with publishable key and config', () async {
    SharedPreferences.setMockInitialValues({});

    await SupabaseConfig.initialize();

    expect(SupabaseConfig.isInitialized, isTrue);
    expect(SupabaseConfig.client, isNotNull);
    expect(SupabaseConfig.supabaseUrl, 'https://bryatogngcaissitkgvv.supabase.co');
    expect(SupabaseConfig.supabasePublishableKey, 'sb_publishable_beeGHXpm0_UYo41OyoLPDg_jPGR_GfV');
  });
}
