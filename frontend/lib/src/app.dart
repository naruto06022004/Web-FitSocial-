import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'auth/auth_repository.dart';
import 'screens/login_screen.dart';
import 'screens/admin_mode_select_screen.dart';
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
        return MaterialApp(
          title: 'Fitnet',
          theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green), useMaterial3: true),
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
  FitnetAdminMode? _adminMode;

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
        _adminMode = null;
        _ready = true;
      });
    } catch (_) {
      await widget.deps.tokenStorage.deleteToken();
      setState(() {
        _me = null;
        _adminMode = null;
        _ready = true;
      });
    }
  }

  void _logout() => setState(() {
        _me = null;
        _adminMode = null;
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
          _adminMode = null;
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

    if (_adminMode == null) {
      return AdminModeSelectScreen(
        user: _me!,
        onOpenAdminDashboard: () => setState(() => _adminMode = FitnetAdminMode.adminPanel),
        onOpenUserMode: () => setState(() => _adminMode = FitnetAdminMode.userMode),
      );
    }

    if (_adminMode == FitnetAdminMode.adminPanel) {
      return AdminDashboardScreen(
        api: widget.deps.api,
        authRepository: widget.deps.authRepository,
        onLoggedOut: _logout,
      );
    }

    return UserAppShell(
      api: widget.deps.api,
      me: _me!,
      authRepository: widget.deps.authRepository,
      onLoggedOut: _logout,
    );
  }
}

enum FitnetAdminMode {
  adminPanel,
  userMode,
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

