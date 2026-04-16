import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/api_client.dart';
import 'auth/auth_repository.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/user_app_shell.dart';
import 'storage/token_storage.dart';
import 'models/fitnet_user.dart';

class FitnetApp extends StatefulWidget {
  const FitnetApp({super.key});

  @override
  State<FitnetApp> createState() => _FitnetAppState();
}

class _FitnetAppState extends State<FitnetApp> {
  late final Future<_Deps> _depsFuture = _Deps.create();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Deps>(
      future: _depsFuture,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
        }
        final deps = snap.data!;

        const seed = Color(0xFF2563EB); // modern blue accent
        final cs = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light).copyWith(
          surface: Colors.white,
        );
        final base = ThemeData(colorScheme: cs, useMaterial3: true);
        final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
          bodyColor: const Color(0xFF0F172A),
          displayColor: const Color(0xFF0F172A),
        );
        final theme = base.copyWith(
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          textTheme: textTheme,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            shadowColor: Colors.transparent,
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
            ),
          ),
          dividerTheme: DividerThemeData(color: Colors.black.withValues(alpha: 0.06)),
        );

        return MaterialApp(
          title: 'Fitnet',
          theme: theme,
          home: _Root(deps: deps),
        );
      },
    );
  }
}

class _Root extends StatefulWidget {
  const _Root({required this.deps});

  final _Deps deps;

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _ready = false;
  FitnetUser? _me;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await widget.deps.tokenStorage.readToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      setState(() => _ready = true);
      return;
    }

    try {
      final user = await widget.deps.authRepository.me();
      setState(() {
        _me = user;
        _ready = true;
      });
    } catch (_) {
      await widget.deps.tokenStorage.deleteToken();
      setState(() {
        _me = null;
        _ready = true;
      });
    }
  }

  void _logout() => setState(() {
        _me = null;
      });

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_me == null) {
      return LoginScreen(
        authRepository: widget.deps.authRepository,
        onLoggedIn: (user) => setState(() {
          _me = user;
        }),
      );
    }

    final isAdmin = _me!.role == 'admin' || _me!.role == 'staff';

    if (!isAdmin) {
      return UserAppShell(
        api: widget.deps.api,
        me: _me!,
        authRepository: widget.deps.authRepository,
        onLoggedOut: _logout,
      );
    }

    return AdminDashboardScreen(
      api: widget.deps.api,
      authRepository: widget.deps.authRepository,
      onLoggedOut: _logout,
      onOpenUserMode: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => UserAppShell(
              api: widget.deps.api,
              me: _me!,
              authRepository: widget.deps.authRepository,
              onLoggedOut: _logout,
              onOpenAdminDashboard: () {
                Navigator.of(context).maybePop();
              },
            ),
          ),
        );
      },
    );
  }
}

class _Deps {
  _Deps._(this.tokenStorage, this.api, this.authRepository);

  final TokenStorage tokenStorage;
  final ApiClient api;
  final AuthRepository authRepository;

  static Future<_Deps> create() async {
    final tokenStorage = await TokenStorage.create();
    final api = ApiClient(tokenStorage: tokenStorage);
    final authRepository = AuthRepository(api: api, tokenStorage: tokenStorage);
    return _Deps._(tokenStorage, api, authRepository);
  }
}

