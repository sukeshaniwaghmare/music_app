import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../domain/payment_service.dart';

class PaymentGateScreen extends StatefulWidget {
  final VoidCallback onPaymentVerified;
  const PaymentGateScreen({super.key, required this.onPaymentVerified});

  @override
  State<PaymentGateScreen> createState() => _PaymentGateScreenState();
}

class _PaymentGateScreenState extends State<PaymentGateScreen> {
  static const _upiId = '9011064801@paytm';
  static const _phone = '9011064801';

  final _txnController = TextEditingController();
  bool _verifying = false;
  bool _success = false;
  String? _errorMsg;
  StreamSubscription? _subscription;

  @override
  void dispose() {
    _txnController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _launchUPI() async {
    final name = Uri.encodeComponent('Sukeshani Waghmare');
    final note = Uri.encodeComponent('WS Music Premium');
    // Simplified UPI URL for personal accounts to avoid security blocks
    final upiUrl = 'upi://pay?pa=$_upiId&pn=$name&tn=$note&cu=INR';
    
    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        final intent = AndroidIntent(
          action: 'action_view',
          data: upiUrl,
        );
        await intent.launch();
      } else {
        _showNoUPIError('UPI is only supported on Android. Please use manual payment.');
      }
    } catch (e) {
      _showNoUPIError('Could not launch UPI app: $e');
    }
  }

  void _showNoUPIError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
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

    setState(() {
      _verifying = true;
      _errorMsg = null;
    });
    try {
      final client = Supabase.instance.client;
      final existing = await client
          .from('payments')
          .select()
          .eq('transaction_id', txnId)
          .maybeSingle();

      if (existing != null && existing['verified'] == true) {
        await _onVerified();
        return;
      }

      await PaymentService.submitPayment(txnId);
      _listenForVerification(txnId);
    } catch (e) {
      if (mounted) {
        setState(() {
          _verifying = false;
          _errorMsg = 'Error: ${e.toString().replaceAll('Exception:', '').trim()}';
        });
      }
    }
  }

  void _listenForVerification(String txnId) {
    _subscription?.cancel();
    _subscription = Supabase.instance.client
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('transaction_id', txnId)
        .listen((data) async {
      if (data.isNotEmpty && data.first['verified'] == true) {
        await _onVerified();
      }
    });
  }

  Future<void> _onVerified() async {
    _subscription?.cancel();
    await PaymentService.unlock();
    if (mounted) {
      setState(() {
        _verifying = false;
        _success = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -50,
            child: _GlowCircle(color: const Color(0xFF7C3AED).withOpacity(0.2)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _GlowCircle(color: const Color(0xFFB44FE8).withOpacity(0.1)),
          ),

          SafeArea(
            child: _success ? _buildSuccessState() : _buildPaymentState(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentState() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Top Section
          _buildLogoHeader(),
          const SizedBox(height: 32),

          // Pricing Card
          _buildPricingCard(),
          const SizedBox(height: 32),

          if (_verifying)
            _buildVerifyingState()
          else ...[
            // Payment Options
            _buildSectionTitle('Choose Payment Method'),
            const SizedBox(height: 16),
            _buildPayNowButton(),
            const SizedBox(height: 20),
            _buildAppIcons(),
            const SizedBox(height: 32),

            // Alternative Payment
            _buildSectionTitle('Payment Instructions'),
            const SizedBox(height: 16),
            _buildPhonePaymentCard(),
            const SizedBox(height: 32),

            // Verification
            _buildSectionTitle('Confirm Payment'),
            const SizedBox(height: 16),
            _buildVerificationInput(),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  Widget _buildLogoHeader() {
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFB44FE8), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 44),
        ),
        const SizedBox(height: 16),
        const Text(
          'WS Music',
          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
          ),
          child: const Text(
            'PREMIUM ACCESS REQUIRED',
            style: TextStyle(color: Color(0xFFB44FE8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFFFFF).withOpacity(0.05),
                const Color(0xFFFFFFFF).withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              const Text('LIFETIME ACCESS', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('₹', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 24, fontWeight: FontWeight.w600, height: 1.5)),
                  const Text('10', style: TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w900, height: 1)),
                ],
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFFB44FE8), size: 16),
                  SizedBox(width: 8),
                  Text('No Subscriptions', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                  SizedBox(width: 16),
                  Icon(Icons.check_circle_rounded, color: Color(0xFFB44FE8), size: 16),
                  SizedBox(width: 8),
                  Text('One-time Pay', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayNowButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFB44FE8)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: _launchUPI,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('Pay Now', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _buildAppIcons() {
    return Column(
      children: [
        const Text(
          'PAY DIRECTLY TO PHONE NUMBER',
          style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAppTag('G-Pay'),
            const SizedBox(width: 8),
            _buildAppTag('PhonePe'),
            const SizedBox(width: 8),
            _buildAppTag('Paytm'),
          ],
        ),
      ],
    );
  }

  Widget _buildAppTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildPhonePaymentCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16161E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          const Icon(Icons.send_to_mobile_rounded, color: Color(0xFFB44FE8), size: 48),
          const SizedBox(height: 16),
          const Text(
            'Pay using Phone Number',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Open any UPI app and pay to the number below',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _infoRow('MOBILE NUMBER', _phone),
          const SizedBox(height: 16),
          _infoRow('UPI ID', _upiId),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFFB44FE8), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'After payment, copy the Transaction ID/UTR and paste it below.',
                    style: TextStyle(color: Color(0xFFB44FE8), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter Transaction ID (UTR)',
          style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _txnController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'e.g. 435678901234',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
            filled: true,
            fillColor: const Color(0xFF16161E),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF7C3AED))),
            contentPadding: const EdgeInsets.all(18),
          ),
        ),
        if (_errorMsg != null) ...[
          const SizedBox(height: 10),
          Text(_errorMsg!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _verify,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16161E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: const Color(0xFF7C3AED).withOpacity(0.5)),
              ),
              elevation: 0,
            ),
            child: const Text('Verify Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF16161E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              const Text(
                'LIVE VERIFICATION',
                style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const SizedBox(
            width: 50, height: 50,
            child: CircularProgressIndicator(color: Color(0xFF7C3AED), strokeWidth: 3),
          ),
          const SizedBox(height: 32),
          const Text(
            'Verifying your payment...',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Please wait while we verify your transaction. Do not close this screen.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => setState(() => _verifying = false),
            child: const Text('Cancel / Edit ID', style: TextStyle(color: Color(0xFFB44FE8), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.black, size: 60),
            ),
            const SizedBox(height: 32),
            const Text(
              'Premium Unlocked!',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            const Text(
              'Welcome to the elite club. Enjoy ad-free music and exclusive features forever.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: widget.onPaymentVerified,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Continue to App', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
          IconButton(
            icon: const Icon(Icons.copy_all_rounded, color: Color(0xFFB44FE8), size: 22),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('$label copied to clipboard'),
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

class _GlowCircle extends StatelessWidget {
  final Color color;
  const _GlowCircle({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300, height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)],
      ),
    );
  }
}
