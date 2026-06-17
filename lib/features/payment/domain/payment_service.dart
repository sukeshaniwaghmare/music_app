import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  static Future<bool> checkVerified(String txnId) async {
    final client = Supabase.instance.client;
    final row = await client
        .from('payments')
        .select()
        .eq('transaction_id', txnId)
        .maybeSingle();
    return row != null && row['verified'] == true;
  }

  static Future<void> submitPayment(String txnId) async {
    final client = Supabase.instance.client;
    await client.from('payments').upsert({
      'transaction_id': txnId,
      'amount': 10,
      'verified': false,
    }, onConflict: 'transaction_id');
  }

  static Future<void> unlock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('payment_done', true);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('payment_done');
  }

  static Future<bool> isUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('payment_done') ?? false;
  }
}
