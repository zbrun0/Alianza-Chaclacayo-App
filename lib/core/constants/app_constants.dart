class AppConstants {
  // Supabase Configuration
  static const String supabaseUrl = 'https://nnsqxguuefqixscmrrwd.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_g2EEJ25ATVGLcG4dbPH63Q_7eGXSd0Q';

  // Church Information
  static const String churchName = 'Iglesia Alianza Cristiana y Misionera';
  static const String churchLocation = 'Chaclacayo, Lima - Perú';
  static const String liveDefaultUrl = 'https://www.youtube.com';

  // Network Names Mapping
  static const Map<String, String> networkNames = {
    'dunamis': 'Dunamis (Jóvenes Adultos)',
    'next': 'NEXT (Adolescentes)',
    'free': 'Free (Universitarios)',
    'legado': 'Legado (Jóvenes)',
    'kids': 'Generación Kids',
    'maravillosos': 'Años Maravillosos',
    'mujeres': 'Mujeres de Fe',
    'varones': 'Varones Valientes',
    'matrimonios': 'Matrimonios Unidos',
  };

  // Official Church Bank Accounts
  static const List<Map<String, String>> bankAccounts = [
    {
      'bank': 'BCP Soles',
      'accountNumber': '191-23456789-0-12',
      'cci': '002-191-002345678901-23',
      'holder': 'Iglesia Alianza Cristiana y Misionera Chaclacayo',
      'icon': 'account_balance',
    },
    {
      'bank': 'Interbank Soles',
      'accountNumber': '200-3001234567',
      'cci': '003-200-003001234567-89',
      'holder': 'Iglesia Alianza Cristiana y Misionera Chaclacayo',
      'icon': 'account_balance',
    },
    {
      'bank': 'Yape / Plin',
      'accountNumber': '987 654 321',
      'cci': '',
      'holder': 'IACM Chaclacayo - Tesorería',
      'icon': 'phone_android',
    },
  ];
}
