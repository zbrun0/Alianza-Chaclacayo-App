# Graph Report - alianza_chaclacayo_app  (2026-09-29)

## Corpus Check
- 156 files · ~886,263 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1894 nodes · 2249 edges · 131 communities (124 shown, 7 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `ae9afe78`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

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
- admin_dashboard_screen.dart
- main_scaffold.dart
- login_screen.dart
- package:flutter_riverpod/flutter_riverpod.dart
- wWinMain
- app_constants.dart
- admin_treasury_screen.dart
- admin_members_screen.dart
- manifest.json
- main.dart
- perfil_screen.dart
- main_scaffold.dart
- widget_test.dart
- MainActivity
- alianza_chaclacayo_app
- README.md
- admin_culto_screen.dart
- flutter_export_environment.sh
- Package.swift
- String?
- package:flutter/material.dart
- login_screen.dart
- App Hosting CLI Commands
- _OracionScreenState
- package:flutter_riverpod/flutter_riverpod.dart
- Mutations
- Firebase Remote Config iOS Setup Guide
- Key Attributes
- Configuration Reference
- Security Reference
- Firebase Crashlytics iOS Setup Guide
- redes_screen.dart
- Native SQL Examples
- Schema Reference
- SKILL.md
- 1. Vector Similarity Search (Semantic)
- Firestore Web SDK Usage Guide
- Advanced Validation for Business Logic
- ConsumerState
- Firebase Authentication Web SDK
- ⛔️ CRITICAL RULE: NO INLINE INITIALIZATION ⛔️
- Firestore Indexes Reference
- ⛔️ CRITICAL RULES & ENVIRONMENT CHECKS
- Step-by-Step Migration Execution
- Web SDK
- Firebase SQL Connect
- Writing Data
- Cloud Functions Integration Reference
- 1. Local Prototyping: Data Seeding
- Templates
- Flutter & Firebase Setup Guide
- Realtime Reference
- Flutter SDK
- iOS SDK
- Firebase AI Logic Basics
- 🛠️ Firebase Android Setup Guide
- Android SDK Usage (Enterprise Native Mode)
- ⛔️ CRITICAL RULE: NO INLINE INITIALIZATION ⛔️
- Admin Node SDK
- Android SDK
- Cloud Firestore on Android (Kotlin)
- main.swift
- auth_provider.dart
- Firebase Functions V1 vs V2 Signature Mapping
- SKILL.md
- Firebase Authentication on Android (Kotlin)
- ⛔️ CRITICAL RULE: NO INLINE INITIALIZATION ⛔️
- ios_setup.md
- Native SQL Operations
- Document Data Model
- Firestore Indexes Reference
- Web SDK Usage (Enterprise Native Mode)
- Firebase AI Logic iOS Setup Guide
- Firebase AI Logic on Android (Kotlin)
- Basic Checks
- Alternative: Manual MCP Configuration (Project Scope)
- Manual Initialization
- AppDelegate
- RunnerTests.swift
- Flutter Setup for Firebase AI Logic
- Firebase AI Logic Basics
- Core Capabilities
- Firebase Auth & Google Sign-In for Flutter
- Cloud Firestore in Flutter
- Cloud Firestore in Flutter
- Manual Initialization
- 1. Instance Selection and Edition Detection
- Assessment: Security Validator (Red Team Edition)
- FlutterMacOS
- App Check Debug Tokens for Local Development & CI/CD
- Workflow
- Firebase Local Environment Setup
- Recommended: Global Setup
- Recommended: Global Setup
- Firebase Web Setup Guide
- AppDelegate
- Antigravity Setup
- Recommended Method: Using Plugins
- Cursor Setup
- RunnerTests
- Android Studio Setup
- RegisterGeneratedPlugins
- app_constants.dart
- package:intl/intl.dart
- _HomeScreenState
- app_constants.dart
- supabaseClientProvider
- Movie Review App
- Plantillas Oficiales de Correo Electrónico — Alianza Chaclacayo
- supabaseClientProvider
- app_constants.dart

## God Nodes (most connected - your core abstractions)
1. `authStateProvider` - 54 edges
2. `Win32Window` - 22 edges
3. `Firebase Authentication Web SDK` - 15 edges
4. `supabaseClientProvider` - 12 edges
5. `MessageHandler` - 12 edges
6. `FlutterWindow` - 10 edges
7. `Create` - 10 edges
8. `WndProc` - 10 edges
9. `Flutter SDK` - 10 edges
10. `Web SDK` - 10 edges

## Surprising Connections (you probably didn't know these)
- `_saveAttendance` --references--> `authStateProvider`  [EXTRACTED]
  lib/features/academia/presentation/asistencia_clase_screen.dart → lib/features/auth/data/auth_provider.dart
- `build` --references--> `authStateProvider`  [EXTRACTED]
  lib/features/academia/presentation/asistencia_clase_screen.dart → lib/features/auth/data/auth_provider.dart
- `_handleSubmit` --references--> `authStateProvider`  [EXTRACTED]
  lib/features/admin/presentation/admin_culto_screen.dart → lib/features/auth/data/auth_provider.dart
- `_handleLogin` --references--> `authStateProvider`  [EXTRACTED]
  lib/features/auth/presentation/login_screen.dart → lib/features/auth/data/auth_provider.dart
- `_handleSubmit` --references--> `authStateProvider`  [EXTRACTED]
  lib/features/auth/presentation/register_screen.dart → lib/features/auth/data/auth_provider.dart

## Import Cycles
- None detected.

## Communities (131 total, 7 thin omitted)

### Community 0 - "academia_screen.dart"
Cohesion: 0.01
Nodes (139): asistencia_clase_screen.dart, ../data/certificate_generator.dart, DataRow, abcCurriculum, _academiaChannel, _activeCourseTotalSessions, _activeCycle, _allCycles (+131 more)

### Community 1 - "Win32Window"
Cohesion: 0.06
Nodes (53): PluginRegistry, Point, RECT, Size, unique_ptr, RegisterPlugins(), DartProject, HWND (+45 more)

### Community 2 - "user_model.dart"
Cohesion: 0.07
Nodes (27): assignedNetwork, birthDate, dni, email, firstName, fromMap, hasAdminAccess, hasRedesAccess (+19 more)

### Community 3 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.20
Nodes (9): app_links, file_picker_darwin, file_selector_macos, flutter_secure_storage_darwin, Foundation, printing, shared_preferences_foundation, sqflite_darwin (+1 more)

### Community 4 - "app_colors.dart"
Cohesion: 0.06
Nodes (34): AppColors, background, error, errorContainer, foreground, info, infoContainer, onPrimaryContainer (+26 more)

### Community 5 - "diezmos_screen.dart"
Cohesion: 0.06
Nodes (33): _amountController, build, _buildAccountsTab, _buildBankCard, _buildFormTab, _buildHistoryTab, _contributionTypes, _copyToClipboard (+25 more)

### Community 6 - "asistencia_clase_screen.dart"
Cohesion: 0.06
Nodes (36): AsistenciaClaseScreen, _AsistenciaClaseScreenState, _attendanceOpen, build, _buildStatusButton, _buildStudentCard, courseId, courseTitle (+28 more)

### Community 7 - "my_application.cc"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 8 - "register_screen.dart"
Cohesion: 0.06
Nodes (30): _assignedNetwork, _birthDateController, build, _buildBaptismAndCoursesSection, _buildFieldLabel, _buildForm, _buildLevelCourseGroup, _buildPastCoursesForm (+22 more)

### Community 9 - "oracion_screen.dart"
Cohesion: 0.06
Nodes (31): ../../../core/services/resend_email_service.dart, bibleGatewayName, BookReading, build, _buildDailyReadingCard, _buildPrayerBoxCard, _buildZoomBanner, chapters (+23 more)

### Community 10 - "redes_screen.dart"
Cohesion: 0.09
Nodes (27): ConsumerWidget, build, _buildCoordCourses, _buildTeacherPanelTab, _enrollInCourse, _getEnrollableCourses, _markMyAttendance, _showStudentAttendanceHistoryDialog (+19 more)

### Community 11 - "home_screen.dart"
Cohesion: 0.07
Nodes (26): ../../admin/presentation/admin_announcements_screen.dart, _announcements, _announcementsChannel, _buildAccessCard, _buildAndroidInstallTab, _buildAnnouncementFullImage, _buildAnnouncementImage, _buildAnnouncementsCarousel (+18 more)

### Community 12 - "admin_dashboard_screen.dart"
Cohesion: 0.08
Nodes (25): admin_attendance_screen.dart, admin_culto_screen.dart, admin_members_screen.dart, admin_treasury_screen.dart, _academyStudents, AdminDashboardScreen, _AdminDashboardScreenState, _baptizedCount (+17 more)

### Community 13 - "main_scaffold.dart"
Cohesion: 0.12
Nodes (16): AdminAnnouncementsScreen, _AdminAnnouncementsScreenState, announcementCategories, _announcements, build, _buildImageWidget, _buildRawImage, createState (+8 more)

### Community 14 - "login_screen.dart"
Cohesion: 0.14
Nodes (13): core/constants/app_constants.dart, core/theme/app_theme.dart, features/auth/presentation/login_screen.dart, features/auth/presentation/reset_password_screen.dart, features/navigation/presentation/main_scaffold.dart, build, initialize, initializeDateFormatting (+5 more)

### Community 15 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.08
Nodes (26): AsistenciaCelulaScreen, _AsistenciaCelulaScreenState, AttendanceStatus, build, _buildStatusBtn, cellId, _cellInfo, CellMemberAttendance (+18 more)

### Community 16 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 17 - "app_constants.dart"
Cohesion: 0.11
Nodes (18): _attendanceList, build, _buildSessionFilterTab, _cellsList, createState, _fetchAttendanceData, _formatSessionDate, _groupedReports (+10 more)

### Community 18 - "admin_treasury_screen.dart"
Cohesion: 0.12
Nodes (17): AdminTreasuryScreen, _AdminTreasuryScreenState, build, _buildFilterChip, createState, _fetchReceipts, fundLabels, initState (+9 more)

### Community 19 - "admin_members_screen.dart"
Cohesion: 0.10
Nodes (20): build, _buildFilterChip, createState, _fetchMembers, formatMemberRoles, initialFilter, initState, _loading (+12 more)

### Community 20 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 22 - "perfil_screen.dart"
Cohesion: 0.07
Nodes (28): ../../auth/presentation/login_screen.dart, age, birthDate, _buildEmailRow, _buildInfoRow, _buildMembershipCard, _buildPhoneRow, _children (+20 more)

### Community 23 - "main_scaffold.dart"
Cohesion: 0.07
Nodes (26): ../../academia/presentation/academia_screen.dart, ../../diezmos/presentation/diezmos_screen.dart, ../../home/presentation/home_screen.dart, IconData, build, _checkPasswordRecovery, createState, _currentIndex (+18 more)

### Community 24 - "widget_test.dart"
Cohesion: 0.50
Nodes (3): package:alianza_chaclacayo_app/main.dart, package:flutter_test/flutter_test.dart, main

### Community 28 - "admin_culto_screen.dart"
Cohesion: 0.08
Nodes (24): DateTime, AdminCultoScreen, _AdminCultoScreenState, build, _countHistory, createState, dispose, _fetchSettingsAndHistory (+16 more)

### Community 37 - "package:flutter/material.dart"
Cohesion: 0.18
Nodes (10): 1. Visión General del Flujo, 2. Estructura de Datos Requerida en el Excel, 3. Estrategia de Autenticación y Cuentas (DNI / Contraseña), 4. Experiencia de Usuario en la Aplicación, 5. Script de Importación Masiva (Node.js / Supabase Admin SDK), 6. Lista de Pasos para Cuando Tengas el Excel Listo, A. Solicitud de Correo Electrónico Real (Sin alias ficticios), B. Cambio de Contraseña desde la App (+2 more)

### Community 38 - "login_screen.dart"
Cohesion: 0.20
Nodes (9): dart:typed_data, CertificateGenerator, generatePdfBytes, printPreviewCertificate, shareOrPrintCertificate, package:intl/intl.dart, package:pdf/pdf.dart, package:pdf/widgets.dart (+1 more)

### Community 39 - "App Hosting CLI Commands"
Cohesion: 0.06
Nodes (30): App Hosting CLI Commands, Automated deployment via GitHub (CI/CD), Backend Management, Initialization, `npx -y firebase-tools@latest apphosting:backends:create`, `npx -y firebase-tools@latest apphosting:backends:delete <backend-id>`, `npx -y firebase-tools@latest apphosting:backends:get <backend-id>`, `npx -y firebase-tools@latest apphosting:backends:list` (+22 more)

### Community 40 - "_OracionScreenState"
Cohesion: 0.11
Nodes (18): app_colors.dart, ../../core/theme/app_colors.dart, ../../features/admin/presentation/admin_announcements_screen.dart, ../../features/admin/presentation/admin_attendance_screen.dart, ../../features/admin/presentation/admin_culto_screen.dart, ../../features/admin/presentation/admin_dashboard_screen.dart, ../../features/admin/presentation/admin_members_screen.dart, ../../features/admin/presentation/admin_treasury_screen.dart (+10 more)

### Community 41 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.07
Nodes (27): 1. Per-Function Configuration, 2. Global Configuration (`setGlobalOptions`), 3. Migrating Environment Configurations (`functions.config()`), Advanced Interpolation & Logic, Built-ins, Common Property Translations, Deterministic Rules for Migration, Initialization & Scope (+19 more)

### Community 42 - "Mutations"
Cohesion: 0.07
Nodes (26): Aliases, Basic Query, Contents, Create, Create with Server Values, Delete, Embedded Queries, Expression Operators (Compare with Server Values) (+18 more)

### Community 43 - "Firebase Remote Config iOS Setup Guide"
Cohesion: 0.07
Nodes (24): Add Dependencies to Gradle Build, App-level `build.gradle.kts` (`<project>/<app-module>/build.gradle.kts`), Fetch and Activate Values, Firebase Remote Config Android Setup Guide, Follow up Steps, Project and App Setup, Project-level `build.gradle.kts` (`<project>/build.gradle.kts`), Set In-App Defaults (+16 more)

### Community 44 - "Key Attributes"
Cohesion: 0.08
Nodes (23): `cleanUrls` (Optional), Full Example, `headers` (Optional), Hosting Configuration (`firebase.json`), `ignore` (Optional), Key Attributes, `public` (Required), `redirects` (Optional) (+15 more)

### Community 45 - "Configuration Reference"
Cohesion: 0.08
Nodes (24): Breaking Changes, CI/CD Integration, Cloud SQL Configuration, Configuration Reference, Connect from SDK, connector.yaml, Contents, dataconnect.yaml (+16 more)

### Community 46 - "Security Reference"
Cohesion: 0.08
Nodes (24): Access Levels, Anti-Patterns, @auth Directive, auth.token Fields, Authorization Data Lookup, Authorization Patterns, Available Bindings, CEL Expressions (+16 more)

### Community 47 - "Firebase Crashlytics iOS Setup Guide"
Cohesion: 0.08
Nodes (21): Add Dependencies to Gradle Build, App-level `build.gradle.kts` (`<project>/<app-module>/build.gradle.kts`), Firebase Crashlytics Android Setup Guide, Follow up Steps, Optional: Add custom debugging information, Optional: Install the NDK SDK to capture native crashes, Project and App Setup, Project-level `build.gradle.kts` (`<project>/build.gradle.kts`) (+13 more)

### Community 48 - "redes_screen.dart"
Cohesion: 0.10
Nodes (21): asistencia_celula_screen.dart, ../../auth/data/auth_provider.dart, Color, ageBracket, _buildDetailItem, _buildInfoRow, ChurchNetworkInfo, createState (+13 more)

### Community 49 - "Native SQL Examples"
Cohesion: 0.10
Nodes (20): Advanced aggregation with RANK, Advanced CTE with upserts (atomic get-or-create), Basic SELECT with field aliasing, Basic UPDATE, Blog with Permissions, E-Commerce Store, Examples, Movie Review App (+12 more)

### Community 50 - "Schema Reference"
Cohesion: 0.10
Nodes (20): @col, Contents, Core Directives, Customizing Tables, Data Types, @default, Defining Types, Enumerations (+12 more)

### Community 51 - "SKILL.md"
Cohesion: 0.11
Nodes (11): Exploring Commands, Initialization, Refresh Android Studio Local Environment, Refresh Antigravity Local Environment, Refresh Claude Code Local Environment, Refresh Gemini CLI Local Environment, Refresh Other Local Environment, Common Issues (+3 more)

### Community 52 - "1. Vector Similarity Search (Semantic)"
Cohesion: 0.11
Nodes (17): 1. Query Formats (`queryFormat` argument), 1. Vector Similarity Search (Semantic), 2. Full-Text Search (Lexical), 2. Relevance Thresholding (`relevanceThreshold` and `_metadata.relevance`), A. Auto-Embedding Search, A. Generation on Insert, Automatic Embedding Generation (`_embed` server value), B. Custom Vector Search (+9 more)

### Community 53 - "Firestore Web SDK Usage Guide"
Cohesion: 0.12
Nodes (16): Add a Document with Auto-ID (`addDoc`), Firestore Web SDK Usage Guide, Get a Single Document (`getDoc`), Get Multiple Documents (`getDocs`), Handle Changes (Added/Modified/Removed), Initialization, Listen to a Document/Query (`onSnapshot`), Order and Limit (+8 more)

### Community 54 - "Advanced Validation for Business Logic"
Cohesion: 0.12
Nodes (16): 1. Enforce Enum Values, 2. Validate State Transitions, 3. Strict Path and Relationship Scoping, 4. Secure Counter Updates, 5. **CRITICAL** Ensure Application Validity, Advanced Validation for Business Logic, Critical Constraints, Critical Directives for Secure Generation (+8 more)

### Community 55 - "ConsumerState"
Cohesion: 0.15
Nodes (19): ConsumerState, ConsumerStatefulWidget, AcademiaScreen, _AcademiaScreenState, AdminAttendanceScreen, _AdminAttendanceScreenState, AdminMembersScreen, _AdminMembersScreenState (+11 more)

### Community 56 - "Firebase Authentication Web SDK"
Cohesion: 0.13
Nodes (15): Connect to Emulator, Email Link Authentication, Firebase Authentication Web SDK, Initialization, Observe Auth State, Sign In Anonymously, Sign In with Apple (Popup), Sign In with Facebook (Popup) (+7 more)

### Community 57 - "⛔️ CRITICAL RULE: NO INLINE INITIALIZATION ⛔️"
Cohesion: 0.13
Nodes (14): 1. Import and Initialize, 2. Type-Safe Data Models (Codable), 3. Basic CRUD Operations, 4. Pipeline Queries, 5. Realtime Listeners in SwiftUI (Lifecycle Best Practices), ⛔️ CRITICAL RULE: NO FirebaseFirestoreSwift ⛔️, ⛔️ CRITICAL RULE: NO INLINE INITIALIZATION ⛔️, Examples (+6 more)

### Community 58 - "Firestore Indexes Reference"
Cohesion: 0.13
Nodes (15): 1. High Write Rates (Sequential Values), 2. Large String/Map/Array Fields, 3. TTL Fields, Automatic vs. Manual Management, Best Practices & Exemptions, CLI Commands, Composite Indexes, Config files (+7 more)

### Community 59 - "⛔️ CRITICAL RULES & ENVIRONMENT CHECKS"
Cohesion: 0.13
Nodes (14): 1. The Anti-Ruby Mandate, 2. Modern Xcode Folder Synchronization, 3. Allowed Scripting Languages, 4. Toolchain Verification, 5. Mandatory Linker Flags for Static Frameworks (Firebase), **CRITICAL: Always Use Latest SDK Version**, ⛔️ CRITICAL RULES & ENVIRONMENT CHECKS, Empty Directory Workflow (+6 more)

### Community 60 - "Step-by-Step Migration Execution"
Cohesion: 0.14
Nodes (13): 1. Declarative IAM & APIs (Zero-Local-Overhead), 2. Global Parameter Access Restriction, 3. V2 Concurrency & Cost Parity, Core Rules & Constraints, Extension to Functions Codebase & npm Package Migration, Overview, Step 1: Inventory Extension Resources, Step 2: Configure `package.json` (+5 more)

### Community 61 - "Web SDK"
Cohesion: 0.14
Nodes (14): Best Practices for Agents, Calling Operations, Client-Side Caching, Data Type Mapping Reference, Initialization, Installation, Resilient Enum Handling, Subscriptions (Realtime) (+6 more)

### Community 62 - "Firebase SQL Connect"
Cohesion: 0.14
Nodes (14): 1. Define Data Model (`schema/schema.gql`), 2. Define Authorized Operations (`connector/queries.gql`, `connector/mutations.gql`), 3. Use type-safe SDK in your apps, Deployment & CLI, Development Workflow, Examples, Feature Capability Map, Firebase SQL Connect (+6 more)

### Community 63 - "Writing Data"
Cohesion: 0.14
Nodes (13): Add a Document with Auto-ID, Get a Single Document, Get Multiple Documents, Order and Limit, Pipeline Queries, Python SDK Usage, Queries, Reading Data (+5 more)

### Community 64 - "Cloud Functions Integration Reference"
Cohesion: 0.15
Nodes (12): Accessing User Authentication Context, Auth Context Mappings, Auth Extraction Example, Cloud Functions Integration Reference, Comprehensive Example, Core Trigger Configuration, 🚨 Critical Infinite Loop Constraint, Event Filtering (+4 more)

### Community 65 - "1. Local Prototyping: Data Seeding"
Cohesion: 0.15
Nodes (12): 1. Local Prototyping: Data Seeding, 2. Production: Admin SDK Bulk Operations, 3. Production: Bulk Operations via raw SQL, 🚨 Critical SQL Operations Constraint, Data Seeding & Bulk Operations Reference, Resetting Seed Data, SDK Bulk APIs Features:, SDK Bulk Operations Example (+4 more)

### Community 66 - "Templates"
Cohesion: 0.15
Nodes (12): Basic CRUD Schema, Client Subscribe (Web), connector.yaml Template, dataconnect.yaml Template, Event-Driven Refresh, Firebase Init Commands, Many-to-Many Relationship, Realtime Query Templates (+4 more)

### Community 67 - "Flutter & Firebase Setup Guide"
Cohesion: 0.17
Nodes (11): 1. Re-running `flutterfire configure` Upon Renaming, 2. Platform-Specific Build Requirements, 3. Web CORS Best Practices, 4. Elaborating on `WidgetsFlutterBinding.ensureInitialized()`, Flutter & Firebase Setup Guide, Prerequisites, Step 1: Create a Flutter Project, Step 2: Configure Firebase (+3 more)

### Community 68 - "Realtime Reference"
Cohesion: 0.17
Nodes (12): CEL Bindings in Conditions, Combining Multiple @refresh Directives, Common Patterns, Contents, Explicit Mutation Signals (`onMutationExecuted`), Implicit Entity Refresh signals, `mutation` — The Triggering Event, Realtime Reference (+4 more)

### Community 69 - "Flutter SDK"
Cohesion: 0.17
Nodes (12): Basic Query, Best Practices for Agents, Calling Operations, Client-Side Caching, Data Type Mapping Reference, Flutter SDK, Imports, Initialization (+4 more)

### Community 70 - "iOS SDK"
Cohesion: 0.17
Nodes (12): Basic Query, Best Practices for Agents, Calling Operations, Client-Side Caching, Data Type Mapping Reference, Dependencies (Package.swift or SPM), Initialization, iOS SDK (+4 more)

### Community 71 - "Firebase AI Logic Basics"
Cohesion: 0.18
Nodes (11): Advanced Features, Firebase AI Logic Basics, Initialization Code References, Installation, On-Device AI (Hybrid), Overview, Prerequisites, References (+3 more)

### Community 72 - "🛠️ Firebase Android Setup Guide"
Cohesion: 0.18
Nodes (10): 0. Create an Android application, 1. Create a Firebase Project, 2. Register Your Android App, 3. Download `google-services.json`, Before running these commands, ensure you are authenticated: `npx -y firebase-tools@latest login` (or `npx -y firebase-tools@latest login --no-localhost` on remote servers), Fetch the configuration file using the App ID (which is printed in the output of the previous command): `npx -y firebase-tools@latest apps:sdkconfig ANDROID <APP_ID> --project <PROJECT_ID>` *Example output extraction to file:* ` # (Output must be saved as app/google-services.json)`, 🛠️ Firebase Android Setup Guide, Manual Verification (+2 more)

### Community 73 - "Android SDK Usage (Enterprise Native Mode)"
Cohesion: 0.18
Nodes (10): 1. Initialization, 2. Decision Framework: Mandatory Pipeline Architecture, 3. Pipeline Examples, 4. Real-Time Listener & Document Operations, Add Dependencies, Android SDK Usage (Enterprise Native Mode), Full-Text Search, Initialize Firestore (+2 more)

### Community 74 - "⛔️ CRITICAL RULE: NO INLINE INITIALIZATION ⛔️"
Cohesion: 0.18
Nodes (10): 1. Import and Initialize, 2. Type-Safe Data Models (Codable), 3. Writing Data (Modern Concurrency & Codable), 4. Reading Data (Modern Concurrency & Codable), 5. Realtime Listeners in SwiftUI (Lifecycle Best Practices), ⛔️ CRITICAL RULE: NO FirebaseFirestoreSwift ⛔️, ⛔️ CRITICAL RULE: NO INLINE INITIALIZATION ⛔️, Firebase Firestore iOS Setup Guide (+2 more)

### Community 75 - "Admin Node SDK"
Cohesion: 0.20
Nodes (9): 1. Impersonating an Unauthenticated User, 2. Impersonating a Specific User (Cloud Functions), 3. Impersonating a Specific User (Plain HTTP), 4. Running with Unrestricted Access, Admin Node SDK, Best Practices for Agents, Configuration in `connector.yaml`, Generation (+1 more)

### Community 76 - "Android SDK"
Cohesion: 0.20
Nodes (10): Android SDK, Basic Query, Best Practices for Agents, Calling Operations, Client-Side Caching, Data Type Mapping Reference, Dependencies (build.gradle.kts), Initialization (+2 more)

### Community 77 - "Cloud Firestore on Android (Kotlin)"
Cohesion: 0.20
Nodes (9): 1. Add Dependencies, 2. Initialize Firestore, 3. Add Data, 4. Read Data, 5. Update Data, 6. Delete Data, Cloud Firestore on Android (Kotlin), Enable Firestore via CLI (+1 more)

### Community 78 - "main.swift"
Cohesion: 0.38
Nodes (9): addCrashlyticsRunScriptBuildPhase(), hasCrashlyticsRunScriptBuildPhase(), isUserScriptSandboxingEnabled(), main(), setDwarfWithDsymDebugInformationFormat(), Bool, PathKit, PBXProj (+1 more)

### Community 79 - "auth_provider.dart"
Cohesion: 0.08
Nodes (25): bool get, authUser, build, checkDniExists, _client, completePasswordRecovery, copyWith, errorMessage (+17 more)

### Community 80 - "Firebase Functions V1 vs V2 Signature Mapping"
Cohesion: 0.22
Nodes (8): Auth (Blocking), Cloud Firestore, Cloud Pub/Sub, Cloud Storage, Cloud Tasks, Firebase Functions V1 vs V2 Signature Mapping, HTTP / Callables, Realtime Database

### Community 81 - "SKILL.md"
Cohesion: 0.22
Nodes (5): Core Concepts, Identity Providers, Prerequisites, Tokens, Users

### Community 82 - "Firebase Authentication on Android (Kotlin)"
Cohesion: 0.22
Nodes (9): 1, Enable Authentication via CLI, 2. Add Dependencies, 3. Initialize FirebaseAuth, 4. Check Current Auth State, 5. Sign Up New Users (Email/Password), 6. Sign In Existing Users (Email/Password), 7. Sign Out, Firebase Authentication on Android (Kotlin) (+1 more)

### Community 83 - "⛔️ CRITICAL RULE: NO INLINE INITIALIZATION ⛔️"
Cohesion: 0.22
Nodes (8): 1. Import and Initialize, 2. Authentication State, 3. Email and Password Authentication (Modern Concurrency), 4. Sign Out, ⛔️ CRITICAL RULE: NO INLINE INITIALIZATION ⛔️, Firebase Auth iOS Setup Guide, Sign In, Sign Up

### Community 84 - "ios_setup.md"
Cohesion: 0.22
Nodes (8): 1. Create a Firebase Project and App (Automated), 2. Installation (Automated via Swift Package Manager CLI), 3. Initialization, AppDelegate (Traditional / UIKit), ⛔️ CRITICAL RULE: INITIALIZATION ORDER ⛔️, ⛔️ CRITICAL RULE: STATE MANAGEMENT (OBSERVATION VS COMBINE) ⛔️, Firebase iOS Setup Guide, SwiftUI (Modern - SAFE PATTERN)

### Community 85 - "Native SQL Operations"
Cohesion: 0.22
Nodes (8): Core Agent Constraints, Mutation Fields (DML), Native SQL Operations, Native SQL Root Fields, PostgreSQL Extensions, Query Fields (Read-Only), ⚠️ Security: Stored Procedures & Dynamic SQL, Syntax rules & limitations

### Community 86 - "Document Data Model"
Cohesion: 0.22
Nodes (8): Collection Group Support, Collections, Document Data Model, Documents, Examples, Firestore Data Model Reference, Subcollections, Use Cases

### Community 87 - "Firestore Indexes Reference"
Cohesion: 0.22
Nodes (9): CLI Commands, Config files, Firestore Indexes Reference, Index Density, Index Ordering, Index Structure, Management, Query Support Examples (+1 more)

### Community 88 - "Web SDK Usage (Enterprise Native Mode)"
Cohesion: 0.22
Nodes (8): 1. Initialization, 2. Decision Framework: Pipelines vs. Standard Queries, 3. Pipeline Examples, 4. Real-Time Listener & Document Operations, Full-Text Search, Relational Joins Pattern, Rules & Accountability, Web SDK Usage (Enterprise Native Mode)

### Community 89 - "Firebase AI Logic iOS Setup Guide"
Cohesion: 0.25
Nodes (7): 1. Import and Initialize, 2. SwiftUI Integration (Best Practices), 3. Safety Settings, Advanced Features, Chat Session (Multi-turn), Firebase AI Logic iOS Setup Guide, Function Calling (Tools)

### Community 90 - "Firebase AI Logic on Android (Kotlin)"
Cohesion: 0.25
Nodes (8): 0. Enable Firebase AI Logic via CLI, 1. Add Dependencies, 2. Initialize and Generate Content, 3. Multimodal Input (Text and Images), 4. Chat Session (Multi-turn), 5. Streaming Responses, Firebase AI Logic on Android (Kotlin), Jetpack Compose (Modern)

### Community 91 - "Basic Checks"
Cohesion: 0.25
Nodes (7): Authentication in Security Rules, Basic Checks, Check if user is signed in, Check if user owns the data, Check if user owns the document (field-based), Example: Email Verification Check, Token Properties

### Community 92 - "Alternative: Manual MCP Configuration (Project Scope)"
Cohesion: 0.25
Nodes (7): 1. Configure and Verify Firebase MCP Server, 1. Install and Verify Firebase Extension, 2. Restart and Verify Connection, 2. Restart and Verify Connection, Alternative: Manual MCP Configuration (Project Scope), Gemini CLI Setup, Recommended: Installing Extensions

### Community 93 - "Manual Initialization"
Cohesion: 0.25
Nodes (8): 1. Create a Firestore Enterprise Database, 2. Create `firebase.json`, 2. Create `firestore.rules`, 3. Create `firestore.indexes.json`, Deploy rules and indexes, Local Emulation, Manual Initialization, Provisioning Firestore Enterprise Native Mode

### Community 94 - "AppDelegate"
Cohesion: 0.25
Nodes (6): Any, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, AppDelegate, Bool, UIApplication

### Community 95 - "RunnerTests.swift"
Cohesion: 0.32
Nodes (5): Flutter, FlutterSceneDelegate, SceneDelegate, UIKit, XCTest

### Community 96 - "Flutter Setup for Firebase AI Logic"
Cohesion: 0.29
Nodes (6): Chat Session, Flutter Setup for Firebase AI Logic, Initialization, Installation, Text Generation, Usage

### Community 97 - "Firebase AI Logic Basics"
Cohesion: 0.29
Nodes (7): Advanced Features, Chat Session (Multi-turn), Core Capabilities, Firebase AI Logic Basics, Initialization Pattern, Multimodal (Text + Images/Audio/Video/PDF input), Streaming Responses

### Community 98 - "Core Capabilities"
Cohesion: 0.29
Nodes (7): Chat Session (Multi-turn), Core Capabilities, Generate Images with Nano Banana, Multimodal (Text + Images/Audio/Video/PDF input), Search Grounding with the built in googleSearch tool, Streaming Responses, Text-Only Generation

### Community 99 - "Firebase Auth & Google Sign-In for Flutter"
Cohesion: 0.29
Nodes (7): 1. `google_sign_in` 7.2.0 API Changes, 2. Initialization & Web Hang/Crash Pitfalls, 3. Web Logout Crashes, 4. Prototyping Workaround: Bypassing Firestore Composite Indices, 5. Robust `AuthService` Boilerplate, 6. Troubleshooting `auth/unauthorized-domain` on Flutter Web, Firebase Auth & Google Sign-In for Flutter

### Community 100 - "Cloud Firestore in Flutter"
Cohesion: 0.29
Nodes (6): 1. Setup, 2. Best Practices: Type-Safe Models, 3. The Service Layer, 4. Listening to Streams in the UI (`StreamBuilder`), Cloud Firestore in Flutter, Initialization & References

### Community 101 - "Cloud Firestore in Flutter"
Cohesion: 0.29
Nodes (6): 1. Setup, 2. Best Practices: Type-Safe Models, 3. The Service Layer, 4. Listening to Streams in the UI (`StreamBuilder`), Cloud Firestore in Flutter, Initialization & References

### Community 102 - "Manual Initialization"
Cohesion: 0.29
Nodes (7): 1. Create `firebase.json`, 2. Create `firestore.rules`, 3. Create `firestore.indexes.json`, Deploy database, rules and indexes, Local Emulation, Manual Initialization, Provisioning Cloud Firestore

### Community 103 - "1. Instance Selection and Edition Detection"
Cohesion: 0.29
Nodes (7): 1. Instance Selection and Edition Detection, 2. Specialized Guides, A. Instance Found, B. No Instance Found (or New Requested), Cloud Firestore Database and Operations, Enterprise Edition / Native Mode (`references/enterprise/`), Standard Edition (`references/standard/`)

### Community 104 - "Assessment: Security Validator (Red Team Edition)"
Cohesion: 0.29
Nodes (6): Admin Bootstrapping & Privileges:, Assessment: Security Validator (Red Team Edition), Mandatory Audit Checklist:, Overview, Scoring Criteria, Scoring Criteria (1-5):

### Community 105 - "FlutterMacOS"
Cohesion: 0.38
Nodes (4): Cocoa, FlutterMacOS, MainFlutterWindow, NSWindow

### Community 106 - "App Check Debug Tokens for Local Development & CI/CD"
Cohesion: 0.33
Nodes (6): App Check, App Check Debug Tokens for Local Development & CI/CD, CI/CD Pipelines (Pre-Provisioned), Local Development (Auto-Generated), Remote Config, Security & Production

### Community 107 - "Workflow"
Cohesion: 0.33
Nodes (6): 1. Provisioning, 2. Client Setup & Usage, 3. Security Rules, Option 1. Enabling Authentication via CLI, Option 2. Enabling Authentication in Console, Workflow

### Community 108 - "Firebase Local Environment Setup"
Cohesion: 0.33
Nodes (5): 1. Verify Node.js, 2. Verify Firebase CLI, 3. Verify Firebase Authentication, 4. Install Agent Skills and MCP Server, Firebase Local Environment Setup

### Community 109 - "Recommended: Global Setup"
Cohesion: 0.33
Nodes (5): 1. Install and Verify Firebase Skills, 2. Configure and Verify Firebase MCP Server, 3. Restart and Verify Connection, GitHub Copilot Setup, Recommended: Global Setup

### Community 110 - "Recommended: Global Setup"
Cohesion: 0.33
Nodes (5): 1. Install and Verify Firebase Skills, 2. Configure and Verify Firebase MCP Server, 3. Restart and Verify Connection, Other Agents Setup, Recommended: Global Setup

### Community 111 - "Firebase Web Setup Guide"
Cohesion: 0.33
Nodes (5): 1. Create a Firebase Project and App, 2. Installation, 3. Initialization, 4. Using Services, Firebase Web Setup Guide

### Community 113 - "AppDelegate"
Cohesion: 0.47
Nodes (4): FlutterAppDelegate, AppDelegate, Bool, NSApplication

### Community 114 - "Antigravity Setup"
Cohesion: 0.40
Nodes (4): 1. Install and Verify Firebase Skills, 2. Configure and Verify Firebase MCP Server, 3. Restart and Verify Connection, Antigravity Setup

### Community 115 - "Recommended Method: Using Plugins"
Cohesion: 0.40
Nodes (4): 1. Install and Verify Plugins, 2. Restart and Verify Connection, Claude Code Setup, Recommended Method: Using Plugins

### Community 116 - "Cursor Setup"
Cohesion: 0.40
Nodes (4): 1. Install and Verify Firebase Skills, 2. Configure and Verify Firebase MCP Server, 3. Restart and Verify Connection, Cursor Setup

### Community 118 - "RunnerTests"
Cohesion: 0.40
Nodes (3): RunnerTests, RunnerTests, XCTestCase

### Community 119 - "Android Studio Setup"
Cohesion: 0.50
Nodes (3): Android Studio Setup, MCP Setup, Skills Installation

### Community 120 - "RegisterGeneratedPlugins"
Cohesion: 0.50
Nodes (3): FlutterPluginRegistry, FlutterViewController, RegisterGeneratedPlugins()

### Community 122 - "app_constants.dart"
Cohesion: 0.14
Nodes (13): FormState, createState, dispose, _errorMessage, _formKey, _handleLogin, _identifierController, _isLoading (+5 more)

### Community 123 - "package:intl/intl.dart"
Cohesion: 0.29
Nodes (7): notificationsProvider, build, _formatRelativeTime, NotificationsSheet, _showNotificationDetail, package:flutter_riverpod/flutter_riverpod.dart, ../providers/notifications_provider.dart

### Community 124 - "_HomeScreenState"
Cohesion: 0.67
Nodes (3): AuthNotifier, AuthState, Notifier

### Community 125 - "app_constants.dart"
Cohesion: 0.13
Nodes (14): ../data/auth_provider.dart, build, _buildFormView, _buildSuccessView, _confirmPassController, createState, dispose, _errorMessage (+6 more)

### Community 126 - "supabaseClientProvider"
Cohesion: 0.11
Nodes (17): , ../constants/app_constants.dart, dart:convert, charset, class, _functionEndpoint, ResendEmailService, sendCertificateEmail (+9 more)

### Community 128 - "Movie Review App"
Cohesion: 0.07
Nodes (30): int get, build, category, clearAll, copyWith, desc, _dismissedIds, dismissNotification (+22 more)

### Community 129 - "Plantillas Oficiales de Correo Electrónico — Alianza Chaclacayo"
Cohesion: 0.40
Nodes (4): 1. Configuración de Resend (Solución al error de envío), 2. Plantilla 1: Restablecimiento de Contraseña (Password Reset), 3. Plantilla 2: Apertura de Nuevo Ciclo Académico (Academia ABC), Plantillas Oficiales de Correo Electrónico — Alianza Chaclacayo

### Community 130 - "supabaseClientProvider"
Cohesion: 0.22
Nodes (9): supabaseClientProvider, _showForgotPasswordDialog, _submitNewPassword, _fetchAnnouncementsOnly, _fetchData, HomeScreen, _HomeScreenState, _initRealtime (+1 more)

### Community 131 - "app_constants.dart"
Cohesion: 0.14
Nodes (13): AppConstants, bankAccounts, churchLocation, churchName, liveDefaultUrl, networkNames, resendApiKey, resendFromEmail (+5 more)

## Knowledge Gaps
- **1217 isolated node(s):** `PathKit`, `AppConstants`, `supabaseUrl`, `supabaseAnonKey`, `resendApiKey` (+1212 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `authStateProvider` connect `redes_screen.dart` to `Movie Review App`, `supabaseClientProvider`, `diezmos_screen.dart`, `asistencia_clase_screen.dart`, `register_screen.dart`, `oracion_screen.dart`, `admin_dashboard_screen.dart`, `login_screen.dart`, `auth_provider.dart`, `package:flutter_riverpod/flutter_riverpod.dart`, `redes_screen.dart`, `main_scaffold.dart`, `perfil_screen.dart`, `ConsumerState`, `app_constants.dart`, `admin_culto_screen.dart`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **Why does `Web SDK` connect `Web SDK` to `SKILL.md`?**
  _High betweenness centrality (0.004) - this node is a cross-community bridge._
- **Why does `Android SDK` connect `Android SDK` to `SKILL.md`?**
  _High betweenness centrality (0.004) - this node is a cross-community bridge._
- **What connects `PathKit`, `AppConstants`, `supabaseUrl` to the rest of the system?**
  _1217 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `academia_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.014285714285714285 - nodes in this community are weakly interconnected._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.0597567424643046 - nodes in this community are weakly interconnected._
- **Should `user_model.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.07142857142857142 - nodes in this community are weakly interconnected._