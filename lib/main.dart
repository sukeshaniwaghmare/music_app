import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/library/presentation/library_screen.dart';
import 'features/library/provider/library_bloc.dart';
import 'features/payment/presentation/payment_gate_screen.dart';
import 'core/services/supabase_service.dart';
import 'core/services/audio_player_service.dart';
import 'widgets/mini_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const MusicApp());
}

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LibraryBloc(),
      child: MaterialApp(
        title: 'WS Music',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF9C27B0),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF121212),
          useMaterial3: true,
        ),
        home: const RootScreen(),
      ),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});
  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool? _paid;

  @override
  void initState() {
    super.initState();
    _checkPayment();
  }

  Future<void> _checkPayment() async {
    print('DATABASE_LOG: _checkPayment started');
    try {
      final prefs = await SharedPreferences.getInstance();
      final paid = prefs.getBool('payment_done') ?? false;
      print('DATABASE_LOG: _checkPayment finished, paid: $paid');
      if (mounted) setState(() => _paid = paid);
    } catch (e) {
      print('DATABASE_LOG: _checkPayment error: $e');
      if (mounted) setState(() => _paid = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_paid == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0F),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFB44FE8))),
      );
    }
    // Bypassing payment screen for now as requested
    // if (!_paid!) {
    //   return PaymentGateScreen(
    //     onPaymentVerified: () => setState(() => _paid = true),
    //   );
    // }
    return const _MainApp();
  }
}

class _MainApp extends StatefulWidget {
  const _MainApp();
  @override
  State<_MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<_MainApp> {
  int _currentIndex = 0;
  String? _libraryCategory;

  void _goToLibrary(String? category) {
    setState(() {
      _libraryCategory = category;
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AudioPlayerService.instance,
      builder: (context, _) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              HomeScreen(onGoToLibrary: _goToLibrary),
              LibraryScreen(filterCategory: _libraryCategory),
            ],
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniPlayer(),
              NavigationBar(
                backgroundColor: const Color(0xFF0A0A0F),
                indicatorColor: const Color(0xFF2D0B5A),
                selectedIndex: _currentIndex,
                onDestinationSelected: (i) {
                  setState(() {
                    if (i == 1) _libraryCategory = null;
                    _currentIndex = i;
                  });
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined, color: Colors.white38),
                    selectedIcon: Icon(Icons.home_rounded, color: Color(0xFFB44FE8)),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.library_music_outlined, color: Colors.white38),
                    selectedIcon: Icon(Icons.library_music_rounded, color: Color(0xFFB44FE8)),
                    label: 'Library',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
