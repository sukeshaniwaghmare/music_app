import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentGateScreen extends StatefulWidget {
  final VoidCallback onPaymentVerified;
  const PaymentGateScreen({super.key, required this.onPaymentVerified});

  @override
  State<PaymentGateScreen> createState() => _PaymentGateScreenState();
}

class _PaymentGateScreenState extends State<PaymentGateScreen> {
  static const _upiId = '9011064801@paytm';
  static const _upiLink =
      'upi://pay?pa=9011064801@paytm&pn=WS%20Music&am=10&cu=INR&tn=WS%20Music%20App%20Access';
  static const _phone = '9011064801';

  final _txnController = TextEditingController();
  bool _verifying = false;
  String? _errorMsg;

  @override
  void dispose() {
    _txnController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final txnId = _txnController.text.trim();
    if (txnId.isEmpty) {
      setState(() => _errorMsg = 'Please enter your Transaction ID / UTR');
      return;
    }
    if (txnId.length < 6) {
      setState(() => _errorMsg = 'Transaction ID too short');
      return;
    }

    setState(() { _verifying = true; _errorMsg = null; });

    try {
      final client = Supabase.instance.client;

      // Check if this txn ID already verified
      final existing = await client
          .from('payments')
          .select()
          .eq('transaction_id', txnId)
          .maybeSingle();

      if (existing != null && existing['verified'] == true) {
        // Already verified — unlock
        await _unlock();
        return;
      }

      // Insert new payment record (unverified — admin will verify)
      await client.from('payments').upsert({
        'transaction_id': txnId,
        'amount': 10,
        'verified': false,
      });

      // Show pending message
      if (mounted) {
        setState(() { _verifying = false; _errorMsg = null; });
        _showPendingDialog(txnId);
      }
    } catch (e) {
      if (mounted) setState(() {
        _verifying = false;
        _errorMsg = 'Error: ${e.toString().replaceAll('Exception:', '').trim()}';
      });
    }
  }

  Future<void> _unlock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('payment_done', true);
    if (mounted) widget.onPaymentVerified();
  }

  void _showPendingDialog(String txnId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Text('⏳', style: TextStyle(fontSize: 22)),
          SizedBox(width: 8),
          Text('Verification Pending', style: TextStyle(color: Colors.white, fontSize: 16)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
            'Your Transaction ID has been submitted.\n\nAdmin will verify your payment shortly.\n\nOnce verified, tap "Check Again" to unlock.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0F),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('TXN: $txnId',
                style: const TextStyle(color: Color(0xFFB44FE8), fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              await _checkVerified(txnId);
            },
            child: const Text('Check Again'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkVerified(String txnId) async {
    setState(() { _verifying = true; _errorMsg = null; });
    try {
      final client = Supabase.instance.client;
      final row = await client
          .from('payments')
          .select()
          .eq('transaction_id', txnId)
          .maybeSingle();

      if (row != null && row['verified'] == true) {
        await _unlock();
      } else {
        if (mounted) setState(() {
          _verifying = false;
          _errorMsg = 'Payment not verified yet. Please wait for admin approval.';
        });
      }
    } catch (e) {
      if (mounted) setState(() { _verifying = false; _errorMsg = 'Check failed. Try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFB44FE8), Color(0xFF7C3AED)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 38),
              ),
              const SizedBox(height: 12),
              const Text('WS Music',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text('Premium Access Required',
                  style: TextStyle(color: Color(0xFFB44FE8), fontSize: 13, fontWeight: FontWeight.w600)),

              const SizedBox(height: 24),

              // Price card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A0533), Color(0xFF2D0B5A)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF7C3AED), width: 1),
                ),
                child: const Column(children: [
                  Text('One-time Payment', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  SizedBox(height: 4),
                  Text('₹10', style: TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900)),
                  Text('Lifetime Access • No Subscription',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                ]),
              ),

              const SizedBox(height: 20),

              // QR
              const Text('Scan & Pay ₹10',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: QrImageView(data: _upiLink, version: QrVersions.auto, size: 170, backgroundColor: Colors.white),
              ),

              const SizedBox(height: 14),

              // UPI ID row
              _infoRow('UPI ID', _upiId),
              const SizedBox(height: 8),
              _infoRow('Phone / Paytm / GPay', _phone),

              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),

              // Transaction ID input
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Enter Transaction ID / UTR after payment',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _txnController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. 4356789012345',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: const Color(0xFF1C1C28),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white10)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),

              if (_errorMsg != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_errorMsg!,
                      style: const TextStyle(color: Colors.red, fontSize: 12))),
                ]),
              ],

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _verifying ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _verifying
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Verify & Unlock App',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),

              const SizedBox(height: 16),
              const Text('Pay ₹10 → Enter Transaction ID → Verify',
                  style: TextStyle(color: Colors.white24, fontSize: 11),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: Color(0xFFB44FE8), size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('$label copied!'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFF7C3AED),
              ));
            },
          ),
        ],
      ),
    );
  }
}
