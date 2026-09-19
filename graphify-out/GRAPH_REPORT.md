# Graph Report - alianza_chaclacayo_app  (2026-09-18)

## Corpus Check
- 56 files · ~1,565,041 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 605 nodes · 801 edges · 37 communities (30 shown, 7 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- academia_screen.dart
- Win32Window
- user_model.dart
- GeneratedPluginRegistrant.swift
- app_colors.dart
- diezmos_screen.dart
- asistencia_clase_screen.dart
- my_application.cc
- register_screen.dart
- oracion_screen.dart
- redes_screen.dart
- home_screen.dart
- authStateProvider
- main_scaffold.dart
- login_screen.dart
- package:flutter_riverpod/flutter_riverpod.dart
- wWinMain
- app_constants.dart
- package:flutter/material.dart
- ConsumerState
- manifest.json
- main.dart
- perfil_screen.dart
- build
- widget_test.dart
- MainActivity
- alianza_chaclacayo_app
- README.md
- _OracionScreenState
- flutter_export_environment.sh
- Package.swift
- String?

## God Nodes (most connected - your core abstractions)
1. `authStateProvider` - 34 edges
2. `Win32Window` - 22 edges
3. `MessageHandler` - 12 edges
4. `FlutterWindow` - 10 edges
5. `Create` - 10 edges
6. `WndProc` - 10 edges
7. `MessageHandler` - 9 edges
8. `_MyApplication` - 7 edges
9. `OnCreate` - 7 edges
10. `WindowClassRegistrar` - 7 edges

## Surprising Connections (you probably didn't know these)
- `_handleLogin` --references--> `authStateProvider`  [EXTRACTED]
  lib/features/auth/presentation/login_screen.dart → lib/features/auth/data/auth_provider.dart
- `build` --references--> `authStateProvider`  [EXTRACTED]
  lib/features/home/presentation/home_screen.dart → lib/features/auth/data/auth_provider.dart
- `build` --references--> `authStateProvider`  [EXTRACTED]
  lib/features/navigation/presentation/main_scaffold.dart → lib/features/auth/data/auth_provider.dart
- `build` --references--> `authStateProvider`  [EXTRACTED]
  lib/features/redes/presentation/redes_screen.dart → lib/features/auth/data/auth_provider.dart
- `_fetchMyCell` --references--> `authStateProvider`  [EXTRACTED]
  lib/features/redes/presentation/redes_screen.dart → lib/features/auth/data/auth_provider.dart

## Import Cycles
- None detected.

## Communities (37 total, 7 thin omitted)

### Community 0 - "academia_screen.dart"
Cohesion: 0.03
Nodes (63): asistencia_clase_screen.dart, DataRow, abcCurriculum, _activeCycle, _addCourseMaterial, _allCycles, _allReportsList, _approvedSubjects (+55 more)

### Community 1 - "Win32Window"
Cohesion: 0.06
Nodes (53): PluginRegistry, Point, RECT, Size, unique_ptr, RegisterPlugins(), DartProject, HWND (+45 more)

### Community 2 - "user_model.dart"
Cohesion: 0.04
Nodes (47): bool get, AuthNotifier, AuthState, authUser, build, checkDniExists, _client, copyWith (+39 more)

### Community 3 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (32): Any, app_links, Cocoa, file_selector_macos, Flutter, flutter_secure_storage_darwin, FlutterAppDelegate, FlutterImplicitEngineBridge (+24 more)

### Community 4 - "app_colors.dart"
Cohesion: 0.06
Nodes (34): AppColors, background, error, errorContainer, foreground, info, infoContainer, onPrimaryContainer (+26 more)

### Community 5 - "diezmos_screen.dart"
Cohesion: 0.06
Nodes (33): _amountController, build, _buildAccountsTab, _buildBankCard, _buildFormTab, _buildHistoryTab, _contributionTypes, _copyToClipboard (+25 more)

### Community 6 - "asistencia_clase_screen.dart"
Cohesion: 0.07
Nodes (29): DateTime, build, _buildStatusButton, _buildStudentCard, courseId, courseTitle, createState, dispose (+21 more)

### Community 7 - "my_application.cc"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 8 - "register_screen.dart"
Cohesion: 0.08
Nodes (25): _assignedNetwork, _birthDateController, build, _buildFieldLabel, _buildForm, _buildSuccessCard, createState, dispose (+17 more)

### Community 9 - "oracion_screen.dart"
Cohesion: 0.08
Nodes (25): bibleGatewayName, BookReading, _buildDailyReadingCard, _buildPrayerBoxCard, _buildZoomBanner, chapters, createState, dispose (+17 more)

### Community 10 - "redes_screen.dart"
Cohesion: 0.09
Nodes (23): Color, ageBracket, build, _buildDetailItem, _buildInfoRow, _buildMyCellCard, ChurchNetworkInfo, createState (+15 more)

### Community 11 - "home_screen.dart"
Cohesion: 0.12
Nodes (18): supabaseClientProvider, _announcements, build, _buildAccessCard, _buildAnnouncementsCarousel, _buildLiveStreamCard, _buildPlaceholderImage, _buildQuickAccessGrid (+10 more)

### Community 12 - "authStateProvider"
Cohesion: 0.13
Nodes (18): ConsumerWidget, build, _enrollInCourse, _loadData, _saveAttendance, authStateProvider, _handleSubmit, _fetchHistory (+10 more)

### Community 13 - "main_scaffold.dart"
Cohesion: 0.12
Nodes (16): ../../academia/presentation/academia_screen.dart, ../../diezmos/presentation/diezmos_screen.dart, ../../home/presentation/home_screen.dart, build, createState, _currentIndex, MainScaffold, _MainScaffoldState (+8 more)

### Community 14 - "login_screen.dart"
Cohesion: 0.13
Nodes (15): ../data/auth_provider.dart, FormState, createState, dispose, _emailController, _errorMessage, _formKey, _handleLogin (+7 more)

### Community 15 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.20
Nodes (10): ../../features/auth/data/auth_provider.dart, build, _buildDrawerItem, build, onNotificationTap, preferredSize, package:flutter_riverpod/flutter_riverpod.dart, package:flutter_svg/flutter_svg.dart (+2 more)

### Community 16 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 17 - "app_constants.dart"
Cohesion: 0.17
Nodes (11): AppConstants, bankAccounts, churchLocation, churchName, liveDefaultUrl, networkNames, supabaseAnonKey, supabaseUrl (+3 more)

### Community 18 - "package:flutter/material.dart"
Cohesion: 0.20
Nodes (9): app_colors.dart, ../../core/theme/app_colors.dart, AppTheme, build, _buildNotificationItem, NotificationsSheet, package:flutter/material.dart, package:google_fonts/google_fonts.dart (+1 more)

### Community 19 - "ConsumerState"
Cohesion: 0.25
Nodes (11): ConsumerState, ConsumerStatefulWidget, AcademiaScreen, _AcademiaScreenState, AsistenciaClaseScreen, _AsistenciaClaseScreenState, RegisterScreen, _RegisterScreenState (+3 more)

### Community 20 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 21 - "main.dart"
Cohesion: 0.25
Nodes (7): core/theme/app_theme.dart, features/auth/presentation/login_screen.dart, features/navigation/presentation/main_scaffold.dart, build, initialize, main, package:supabase_flutter/supabase_flutter.dart

### Community 22 - "perfil_screen.dart"
Cohesion: 0.29
Nodes (6): ../../auth/data/auth_provider.dart, ../../auth/presentation/login_screen.dart, core/constants/app_constants.dart, _buildInfoRow, _buildMembershipCard, package:qr_flutter/qr_flutter.dart

### Community 23 - "build"
Cohesion: 0.50
Nodes (4): _buildTeacherPanelTab, build, build, MaterialPageRoute

### Community 24 - "widget_test.dart"
Cohesion: 0.50
Nodes (3): package:alianza_chaclacayo_app/main.dart, package:flutter_test/flutter_test.dart, main

## Knowledge Gaps
- **326 isolated node(s):** `AppConstants`, `supabaseUrl`, `supabaseAnonKey`, `churchName`, `churchLocation` (+321 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `authStateProvider` connect `authStateProvider` to `user_model.dart`, `redes_screen.dart`, `home_screen.dart`, `main_scaffold.dart`, `login_screen.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `ConsumerState`, `main.dart`, `build`, `_OracionScreenState`?**
  _High betweenness centrality (0.030) - this node is a cross-community bridge._
- **Why does `FlutterWindow` connect `Win32Window` to `GeneratedPluginRegistrant.swift`?**
  _High betweenness centrality (0.021) - this node is a cross-community bridge._
- **What connects `AppConstants`, `supabaseUrl`, `supabaseAnonKey` to the rest of the system?**
  _326 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `academia_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03125 - nodes in this community are weakly interconnected._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.0597567424643046 - nodes in this community are weakly interconnected._
- **Should `user_model.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.04251700680272109 - nodes in this community are weakly interconnected._
- **Should `GeneratedPluginRegistrant.swift` be split into smaller, more focused modules?**
  _Cohesion score 0.05217391304347826 - nodes in this community are weakly interconnected._