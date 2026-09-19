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
      role.split(',').map((r) => r.trim().toLowerCase()).toList();

  bool get isPastor => rolesList.contains('pastor');
  bool get isTreasuryAdmin => isPastor || rolesList.contains('admin_tesoreria');
  bool get isTeacher => isPastor || rolesList.contains('maestro') || rolesList.contains('instructor_temporal');
  bool get isGroupLeader =>
      isPastor || rolesList.contains('lider_grupo') || rolesList.contains('coordinador_red') || rolesList.contains('lider_red');
  bool get isCultoAdmin => isPastor || rolesList.contains('conteo_culto');
  bool get isAcademyCoordinator => isPastor || rolesList.contains('coordinador_academia');
  bool get isAnnouncementAdmin => isPastor || rolesList.contains('encargado_anuncios');
  bool get isPrayerAdmin => isPastor || rolesList.contains('encargado_oracion');

  bool get hasAdminAccess =>
      isPastor || isTreasuryAdmin || isCultoAdmin || isAcademyCoordinator || isAnnouncementAdmin || isPrayerAdmin;

  String get roleTranslated {
    const translations = {
      'miembro': 'Miembro',
      'lider_grupo': 'Líder de Grupo',
      'coordinador_red': 'Coordinador de Red',
      'lider_red': 'Líder de Red',
      'coordinador_academia': 'Coordinador de Academia',
      'maestro': 'Maestro',
      'instructor_temporal': 'Instructor Temporal',
      'admin_tesoreria': 'Encargado de Tesorería',
      'encargado_anuncios': 'Encargado de Anuncios',
      'encargado_oracion': 'Encargado de Oración',
      'apoyo_abc': 'Apoyo de Academia',
      'conteo_culto': 'Encargado de Conteo de Culto',
      'pastor': 'Pastor Principal',
    };

    if (role.isEmpty) return 'Miembro';
    return rolesList
        .map((r) => translations[r] ?? r)
        .join(', ');
  }
}
