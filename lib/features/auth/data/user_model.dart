class UserProfile {
  final String id;
  final String name;
  final String firstName;
  final String lastName;
  final String dni;
  final String email;
  final String phone;
  final String birthDate;
  final bool isBaptized;
  final String maritalStatus;
  final String assignedNetwork;
  final String role;
  final bool isApproved;

  UserProfile({
    required this.id,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.dni,
    required this.email,
    required this.phone,
    required this.birthDate,
    required this.isBaptized,
    required this.maritalStatus,
    required this.assignedNetwork,
    required this.role,
    required this.isApproved,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final firstName = map['first_name'] ?? '';
    final lastName = map['last_name'] ?? '';
    return UserProfile(
      id: map['id'] ?? '',
      name: '$firstName $lastName'.trim(),
      firstName: firstName,
      lastName: lastName,
      dni: map['dni'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      birthDate: map['birth_date'] ?? '',
      isBaptized: map['is_baptized'] ?? false,
      maritalStatus: map['marital_status'] ?? 'Soltero/a',
      assignedNetwork: map['assigned_network'] ?? 'dunamis',
      role: map['role'] ?? 'miembro',
      isApproved: map['is_approved'] ?? false,
    );
  }

  List<String> get rolesList =>
      role.split(',').map((r) => r.trim().toLowerCase()).where((r) => r.isNotEmpty).toList();

  bool get isAdmin => rolesList.contains('admin');
  bool get isPastor => isAdmin || rolesList.contains('pastor');
  bool get isTreasuryAdmin => isAdmin || isPastor || rolesList.contains('admin_tesoreria');
  bool get isTeacher =>
      isAdmin || isPastor || rolesList.contains('maestro') || rolesList.contains('instructor_temporal') || rolesList.contains('instructor_abc');
  bool get isGroupLeader =>
      isAdmin || isPastor || rolesList.contains('lider_grupo') || rolesList.contains('coordinador_red') || rolesList.contains('lider_red');
  bool get isNetworkCoordinator => isAdmin || isPastor || rolesList.contains('coordinador_red');
  bool get hasRedesAccess => isAdmin;
  bool get isCultoAdmin => isAdmin || isPastor || rolesList.contains('conteo_culto');
  bool get isAcademyCoordinator => isAdmin || isPastor || rolesList.contains('coordinador_academia');
  bool get isAnnouncementAdmin => isAdmin || isPastor || rolesList.contains('encargado_anuncios');
  bool get isPrayerAdmin => isAdmin || isPastor || rolesList.contains('encargado_oracion');

  bool get hasAdminAccess =>
      isAdmin ||
      isPastor ||
      isTreasuryAdmin ||
      isCultoAdmin ||
      isAcademyCoordinator ||
      isAnnouncementAdmin ||
      isPrayerAdmin ||
      isGroupLeader;

  String get roleTranslated {
    const translations = {
      'admin': 'Administrador (Soporte)',
      'pastor': 'Pastor Principal',
      'coordinador_red': 'Coordinador de Red',
      'lider_red': 'Líder de Red',
      'lider_grupo': 'Líder de Célula',
      'maestro': 'Maestro',
      'instructor_temporal': 'Maestro',
      'instructor_abc': 'Maestro',
      'coordinador_academia': 'Coordinador de Academia',
      'admin_tesoreria': 'Encargado de Tesorería',
      'encargado_anuncios': 'Encargado de Anuncios',
      'encargado_oracion': 'Encargado de Oración',
      'apoyo_abc': 'Apoyo de Academia',
      'conteo_culto': 'Encargado Conteo Culto',
      'miembro': 'Miembro',
    };

    if (role.isEmpty) return 'Miembro';
    final labels = rolesList.map((r) => translations[r] ?? r).toSet().toList();
    return labels.isEmpty ? 'Miembro' : labels.join(', ');
  }
}
