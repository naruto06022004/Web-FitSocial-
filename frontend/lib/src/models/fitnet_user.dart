class FitnetUser {
  FitnetUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.permissions,
    this.roleLabel,
  });

  final int id;
  final String name;
  final String email;
  final String role; // admin | staff | user | custom key
  final Map<String, dynamic>? permissions;
  final String? roleLabel;

  /// `null` = always allowed (e.g. Dashboard shell tab).
  bool hasPermission(String? key) {
    if (key == null) return true;
    final p = permissions;
    if (p != null) {
      return p[key] == true;
    }
    if (role == 'admin') return true;
    if (role == 'staff') {
      return key == 'users_manage' || key == 'posts_manage';
    }
    return false;
  }

  bool get hasAdminAccess {
    final p = permissions;
    if (p != null) {
      return p['admin_access'] == true;
    }
    return role == 'admin' || role == 'staff';
  }

  factory FitnetUser.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? perms;
    final raw = json['permissions'];
    if (raw is Map<String, dynamic>) {
      perms = raw;
    } else if (raw is Map) {
      perms = Map<String, dynamic>.from(raw);
    }

    return FitnetUser(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      permissions: perms,
      roleLabel: json['role_label']?.toString(),
    );
  }
}
