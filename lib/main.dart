import 'package:flutter/material.dart';
import 'dart:async' show TimeoutException;
import 'dart:io' show File;
import 'dart:math' show sin, cos, sqrt, atan2, pi;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

const String kSupabaseUrl = 'https://lxhlodhnlmwyjjwslaln.supabase.co';
const String kSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4aGxvZGhubG13eWpqd3NsYWxuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA5OTcxMTgsImV4cCI6MjA5NjU3MzExOH0.yH-wHSiBXZqedwgEac2OYIuYo2qVa0QlJkim2f1jtUI';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);
  runApp(const ModeRentalsApp());
}

final _supabase = Supabase.instance.client;

// ─── Colours ───────────────────────────────────────────────
const Color cNavy = Color(0xFF0F172A);
const Color cNavyMid = Color(0xFF1E293B);
const Color cNavyLight = Color(0xFF334155);
const Color cIndigo = Color(0xFF4338CA);
const Color cIndigoDark = Color(0xFF1E1B4B);
const Color cPurple = Color(0xFF6366F1);
const Color cSlate = Color(0xFFF1F5F9);
const Color cSlate2 = Color(0xFFE8EEF5);
const Color cBorder = Color(0xFFE2E8F0);
const Color cMuted = Color(0xFF94A3B8);
const Color cText = Color(0xFF0F172A);
const Color cGreen = Color(0xFF16A34A);
const Color cGreenDark = Color(0xFF14532D);
const Color cGreenLight = Color(0xFFDCFCE7);
const Color cGreenBorder = Color(0xFF86EFAC);
const Color cRed = Color(0xFFDC2626);
const Color cRedDark = Color(0xFFB91C1C);
const Color cRedLight = Color(0xFFFCA5A5);
const Color cRedBg = Color(0x1FEF4444);
const Color cRedBorder = Color(0x4DEF4444);
const Color cAmberLight = Color(0xFFFEF3C7);
const Color cAmberText = Color(0xFF92400E);
const Color cAmber = Color(0xFFD97706);
const Color cVioletLight = Color(0xFFEDE9FE);
const Color cVioletText = Color(0xFF4C1D95);
const Color cGreenText = Color(0xFF166534);
const Color cBlue = Color(0xFF1D4ED8);
const Color cOrange = Color(0xFFEA580C);
const Color cOrangeDark = Color(0xFF9A3412);

// ─── Fortnight Helpers ─────────────────────────────────────
DateTime fortnightStart(DateTime d) {
  final monday = d.subtract(Duration(days: d.weekday - 1));
  final weekNum = _isoWeek(monday);
  if (weekNum % 2 == 1) return DateTime(monday.year, monday.month, monday.day);
  return DateTime(monday.year, monday.month, monday.day - 7);
}

DateTime fortnightEnd(DateTime start) => start.add(const Duration(days: 13));
int _isoWeek(DateTime d) {
  final jan4 = DateTime(d.year, 1, 4);
  final startOfWeek1 = jan4.subtract(Duration(days: jan4.weekday - 1));
  return ((d.difference(startOfWeek1).inDays) / 7).floor() + 1;
}

String fmtDate(DateTime d) {
  const m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

String fmtDateShort(DateTime d) {
  const m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${d.day} ${m[d.month - 1]}';
}

// ─── Models ────────────────────────────────────────────────
class AppUser {
  final String id;
  final String name;
  String email, password, role;
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });
  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
    id: m['id'].toString(),
    name: m['name'] ?? '',
    email: m['email'] ?? '',
    password: m['password'] ?? '',
    role: m['role'] ?? 'Staff',
  );
}

class ClockInRecord {
  final DateTime timestamp;
  final double lat, lng;
  final Branch branch;
  final File? photo;
  String? supabaseId;
  ClockInRecord({
    required this.timestamp,
    required this.lat,
    required this.lng,
    required this.branch,
    this.photo,
    this.supabaseId,
  });
}

// ─── Supabase Service ──────────────────────────────────────
class SupabaseService {
  // ── User Management ──
  static Future<List<AppUser>> getUsers() async {
    final res = await _supabase
        .from('users')
        .select()
        .order('role')
        .order('name');
    return (res as List).map((m) => AppUser.fromMap(m)).toList();
  }

  static Future<AppUser?> login(String email, String password) async {
    final res = await _supabase
        .from('users')
        .select()
        .eq('email', email.trim())
        .eq('password', password)
        .maybeSingle();
    if (res == null) return null;
    return AppUser.fromMap(res);
  }

  static Future<void> addUser(AppUser u) async {
    await _supabase.from('users').insert({
      'name': u.name,
      'email': u.email,
      'password': u.password,
      'role': u.role,
    });
  }

  static Future<void> updateUser(AppUser u) async {
    await _supabase
        .from('users')
        .update({
          'name': u.name,
          'email': u.email,
          'password': u.password,
          'role': u.role,
        })
        .eq('id', u.id);
  }

  static Future<void> deleteUser(String id) async {
    await _supabase.from('users').delete().eq('id', id);
  }

  // ── Photo Upload ──
  static Future<String> uploadPhoto({
    required File photo,
    required String userEmail,
    required DateTime timestamp,
  }) async {
    final safe = userEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final path =
        'clockin_photos/${safe}_${timestamp.millisecondsSinceEpoch}.jpg';
    final bytes = await photo.readAsBytes();
    await _supabase.storage
        .from('clockin-photos')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
    return _supabase.storage.from('clockin-photos').getPublicUrl(path);
  }

  // ── Clock In/Out ──
  static Future<String> saveClockIn({
    required AppUser user,
    required Branch branch,
    required double lat,
    required double lng,
    required DateTime clockInTime,
    required String photoUrl,
  }) async {
    final res = await _supabase
        .from('shift_records')
        .insert({
          'user_email': user.email,
          'user_name': user.name,
          'user_role': user.role,
          'branch_name': branch.name,
          'branch_address': branch.address,
          'lat': lat,
          'lng': lng,
          'clock_in_time': clockInTime.toIso8601String(),
          'photo_url': photoUrl,
          'shift_status': 'active',
        })
        .select('id')
        .single();
    return res['id'].toString();
  }

  static Future<void> saveClockOut({
    required String recordId,
    required DateTime clockOutTime,
    required String notes,
    required double shiftHours,
  }) async {
    await _supabase
        .from('shift_records')
        .update({
          'clock_out_time': clockOutTime.toIso8601String(),
          'shift_status': 'completed',
          'shift_notes': notes,
          'shift_hours': shiftHours,
        })
        .eq('id', recordId);
  }

  static Future<List<Map<String, dynamic>>> getUserRecords(String email) async {
    final res = await _supabase
        .from('shift_records')
        .select()
        .eq('user_email', email)
        .order('clock_in_time', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<List<Map<String, dynamic>>> getUserRecordsInRange(
    String email,
    DateTime from,
    DateTime to,
  ) async {
    final res = await _supabase
        .from('shift_records')
        .select()
        .eq('user_email', email)
        .gte('clock_in_time', from.toIso8601String())
        .lte('clock_in_time', to.add(const Duration(days: 1)).toIso8601String())
        .order('clock_in_time', ascending: true);
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<List<Map<String, dynamic>>> getAllRecordsInRange(
    DateTime from,
    DateTime to,
  ) async {
    final res = await _supabase
        .from('shift_records')
        .select()
        .gte('clock_in_time', from.toIso8601String())
        .lte('clock_in_time', to.add(const Duration(days: 1)).toIso8601String())
        .order('clock_in_time', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  // ── Timesheet ──
  static Future<void> submitTimesheet({
    required String userEmail,
    required String userName,
    required String branchName,
    required DateTime fnStart,
    required DateTime fnEnd,
    required double week1,
    required double week2,
    required double total,
  }) async {
    final existing = await _supabase
        .from('timesheet_submissions')
        .select('id, status')
        .eq('user_email', userEmail)
        .eq('fortnight_start', fnStart.toIso8601String().substring(0, 10));
    if ((existing as List).isNotEmpty) {
      final row = existing.first;
      if (row['status'] == 'approved')
        throw Exception('Timesheet already approved and locked.');
      await _supabase
          .from('timesheet_submissions')
          .update({
            'week1_hours': week1,
            'week2_hours': week2,
            'total_hours': total,
            'status': 'pending',
            'submitted_at': DateTime.now().toIso8601String(),
            'manager_comment': '',
            'approved_at': null,
          })
          .eq('id', row['id']);
    } else {
      await _supabase.from('timesheet_submissions').insert({
        'user_email': userEmail,
        'user_name': userName,
        'branch_name': branchName,
        'fortnight_start': fnStart.toIso8601String().substring(0, 10),
        'fortnight_end': fnEnd.toIso8601String().substring(0, 10),
        'week1_hours': week1,
        'week2_hours': week2,
        'total_hours': total,
        'status': 'pending',
        'submitted_at': DateTime.now().toIso8601String(),
      });
    }
  }

  static Future<Map<String, dynamic>?> getTimesheetStatus(
    String email,
    DateTime fnStart,
  ) async {
    final res = await _supabase
        .from('timesheet_submissions')
        .select()
        .eq('user_email', email)
        .eq('fortnight_start', fnStart.toIso8601String().substring(0, 10));
    if ((res as List).isEmpty) return null;
    return res.first as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getAllTimesheetHistory(
    String email,
  ) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 365));
    final res = await _supabase
        .from('timesheet_submissions')
        .select()
        .eq('user_email', email)
        .gte('fortnight_start', cutoff.toIso8601String().substring(0, 10))
        .order('fortnight_start', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<void> reviewTimesheet({
    required String id,
    required String status,
    required String comment,
  }) async {
    await _supabase
        .from('timesheet_submissions')
        .update({
          'status': status,
          'manager_comment': comment,
          'reviewed_at': DateTime.now().toIso8601String(),
          if (status == 'approved')
            'approved_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  static Future<List<Map<String, dynamic>>> getAllSubmissionsForFortnight(
    DateTime fnStart,
  ) async {
    final res = await _supabase
        .from('timesheet_submissions')
        .select()
        .eq('fortnight_start', fnStart.toIso8601String().substring(0, 10))
        .order('status', ascending: true);
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<void> savePayrollSummary({
    required String userEmail,
    required String userName,
    required String branchName,
    required DateTime fnStart,
    required DateTime fnEnd,
    required double totalHours,
    required String savedBy,
  }) async {
    await _supabase.from('payroll_summaries').upsert({
      'user_email': userEmail,
      'user_name': userName,
      'branch_name': branchName,
      'fortnight_start': fnStart.toIso8601String().substring(0, 10),
      'fortnight_end': fnEnd.toIso8601String().substring(0, 10),
      'total_hours': totalHours,
      'saved_at': DateTime.now().toIso8601String(),
      'saved_by': savedBy,
    });
  }
}

// ─── Branch Model ──────────────────────────────────────────
class Branch {
  final String name, address;
  final double lat, lng, radiusMeters;
  const Branch({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.radiusMeters = 1000,
  });
}

const List<Branch> kBranches = [
  Branch(
    name: 'Auckland Airport',
    address: '110 Montgomerie Rd, Airport Oaks, Mangere, Auckland 2022',
    lat: -37.00468,
    lng: 174.78486,
    radiusMeters: 1000,
  ),
  Branch(
    name: 'Auckland City',
    address: '26 Te Taou Crescent, Auckland Central, Auckland 1010',
    lat: -36.84820,
    lng: 174.76330,
    radiusMeters: 1000,
  ),
  Branch(
    name: 'Epsom',
    address: '69 Onslow Avenue, Epsom, Auckland 1023',
    lat: -36.88750,
    lng: 174.77130,
    radiusMeters: 1000,
  ),
];

double haversineDistance(double lat1, double lng1, double lat2, double lng2) {
  const R = 6371000.0;
  final dLat = (lat2 - lat1) * pi / 180, dLng = (lng2 - lng1) * pi / 180;
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLng / 2) *
          sin(dLng / 2);
  return R * 2 * atan2(sqrt(a), sqrt(1 - a));
}

// ─── App Root ──────────────────────────────────────────────
class ModeRentalsApp extends StatelessWidget {
  const ModeRentalsApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Mode Rentals',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      fontFamily: 'SF Pro Display',
      scaffoldBackgroundColor: cSlate,
      colorScheme: ColorScheme.fromSeed(seedColor: cIndigo),
    ),
    home: const _AppShell(),
  );
}

class _AppShell extends StatefulWidget {
  const _AppShell();
  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  String screen = 'login';
  AppUser? currentUser;

  void login(AppUser u) => setState(() {
    currentUser = u;
    screen = u.role.toLowerCase();
  });
  void logout() => setState(() {
    currentUser = null;
    screen = 'login';
  });
  void goForgot() => setState(() {
    screen = 'forgot';
  });
  void goLogin() => setState(() {
    screen = 'login';
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: cSlate,
    body: SafeArea(
      child: switch (screen) {
        'forgot' => ForgotScreen(onBack: goLogin),
        'staff' => StaffHome(user: currentUser!, onLogout: logout),
        'manager' => ManagerHome(user: currentUser!, onLogout: logout),
        'admin' => AdminHome(user: currentUser!, onLogout: logout),
        _ => LoginScreen(onLogin: login, onForgot: goForgot),
      },
    ),
  );
}

// ─── Helpers ───────────────────────────────────────────────
String _greeting() {
  final h = TimeOfDay.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

Widget _bgGradient({required Widget child}) => Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      colors: [cSlate, cSlate2],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ),
  child: child,
);

Widget raisedCard({required Widget child, double radius = 12}) => Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: cBorder),
    boxShadow: [
      BoxShadow(
        color: cNavy.withOpacity(0.07),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
      const BoxShadow(color: cBorder, blurRadius: 0, offset: Offset(0, 3)),
      BoxShadow(
        color: Colors.white.withOpacity(0.9),
        blurRadius: 0,
        offset: const Offset(0, 1),
      ),
    ],
  ),
  child: child,
);

String _fmtDT(String? iso) {
  if (iso == null) return '--';
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '--';
  const m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final mn = dt.minute.toString().padLeft(2, '0');
  final p = dt.hour < 12 ? 'AM' : 'PM';
  return '${dt.day} ${m[dt.month - 1]} ${dt.year}  $h:$mn $p';
}

// ─── Status Badge ──────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    final cfg =
        {
          'pending': [cAmberLight, cAmberText, '⏳ Pending'],
          'approved': [cGreenLight, cGreenText, '✓ Approved'],
          'rejected': [const Color(0xFFFDECEA), cRed, '✗ Rejected'],
          'review': [cVioletLight, cVioletText, '👁 Review'],
        }[status.toLowerCase()] ??
        [cSlate, cMuted, status];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: cfg[0] as Color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (cfg[1] as Color).withOpacity(0.3)),
      ),
      child: Text(
        cfg[2] as String,
        style: TextStyle(
          color: cfg[1] as Color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── App Header ────────────────────────────────────────────
class AppHeader extends StatelessWidget {
  final VoidCallback? onLogout;
  const AppHeader({super.key, this.onLogout});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [cNavyMid, cNavy],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 22,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFF818CF8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'mode',
          style: TextStyle(
            color: Color(0xFF818CF8),
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 2),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'TM',
            style: TextStyle(
              color: Color(0xFF818CF8),
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        if (onLogout != null)
          GestureDetector(
            onTap: onLogout,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cRedBg,
                border: Border.all(color: cRedBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout_rounded, color: cRedLight, size: 14),
                  SizedBox(width: 5),
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      color: cRedLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

// ─── Shared Widgets ────────────────────────────────────────
class RoleBadge extends StatelessWidget {
  final String role;
  const RoleBadge(this.role, {super.key});
  @override
  Widget build(BuildContext context) {
    final s =
        {
          'Admin': [cAmberLight, cAmberText],
          'Manager': [cVioletLight, cVioletText],
          'Staff': [cGreenLight, cGreenText],
        }[role] ??
        [Colors.grey.shade200, Colors.grey.shade700];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [s[0] as Color, (s[0] as Color).withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (s[1] as Color).withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        role,
        style: TextStyle(
          color: s[1] as Color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class StyledInput extends StatelessWidget {
  final String hint;
  final TextEditingController ctrl;
  final bool obscure;
  final Widget? suffix;
  final TextInputType keyboard;
  const StyledInput({
    super.key,
    required this.hint,
    required this.ctrl,
    this.obscure = false,
    this.suffix,
    this.keyboard = TextInputType.text,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: cBorder),
      boxShadow: [
        BoxShadow(
          color: cNavy.withOpacity(0.06),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 14, color: cText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: cMuted, fontSize: 14),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: InputBorder.none,
      ),
    ),
  );
}

class InputLabel extends StatelessWidget {
  final String text;
  const InputLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF475569),
      ),
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final List<Color> colors;
  final Color shadowColor;
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.colors = const [Color(0xFF312E81), cIndigo],
    this.shadowColor = cIndigoDark,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.45),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: shadowColor,
            blurRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
  );
}

class ErrorBox extends StatelessWidget {
  final String msg;
  const ErrorBox(this.msg, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFDECEA),
      border: Border.all(color: cRed.withOpacity(0.4)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.warning_amber_rounded, color: cRed, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            msg,
            style: const TextStyle(color: cRed, fontSize: 12, height: 1.5),
          ),
        ),
      ],
    ),
  );
}

class SuccessBox extends StatelessWidget {
  final String msg;
  const SuccessBox(this.msg, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: cGreenLight,
      border: Border.all(color: cGreenBorder),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.check_circle_outline, color: cGreen, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            msg,
            style: const TextStyle(color: cGreenText, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) => raisedCard(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cSlate,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cNavyMid, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: cNavyMid,
                ),
              ),
              Text(label, style: const TextStyle(fontSize: 11, color: cMuted)),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  final Color? valueColor;
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.bold,
    this.valueColor,
  });
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: bold ? cText : cMuted,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          color: valueColor ?? (bold ? cText : cNavyMid),
        ),
      ),
    ],
  );
}

// ─── LOGIN ─────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  final void Function(AppUser) onLogin;
  final VoidCallback onForgot;
  const LoginScreen({super.key, required this.onLogin, required this.onForgot});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final eCtrl = TextEditingController(), pCtrl = TextEditingController();
  bool showPw = false, loading = false;
  String err = '';

  Future<void> _login() async {
    if (eCtrl.text.trim().isEmpty) {
      setState(() => err = 'Email is required.');
      return;
    }
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(eCtrl.text.trim())) {
      setState(() => err = 'Invalid email format.');
      return;
    }
    if (pCtrl.text.isEmpty) {
      setState(() => err = 'Password is required.');
      return;
    }
    setState(() {
      loading = true;
      err = '';
    });
    try {
      final user = await SupabaseService.login(eCtrl.text.trim(), pCtrl.text);
      if (!mounted) return;
      if (user == null) {
        setState(() {
          err = 'Incorrect email or password.';
          loading = false;
        });
        return;
      }
      setState(() => loading = false);
      widget.onLogin(user);
    } catch (e) {
      if (mounted)
        setState(() {
          err = 'Login error: $e';
          loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const AppHeader(),
      Expanded(
        child: _bgGradient(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [cNavyMid, cNavyLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: cNavy.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🚗', style: TextStyle(fontSize: 38)),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Welcome to Mode',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    color: cText,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sign in to your account',
                  style: TextStyle(color: cMuted, fontSize: 14),
                ),
                const SizedBox(height: 28),
                StyledInput(
                  hint: 'Email address',
                  ctrl: eCtrl,
                  keyboard: TextInputType.emailAddress,
                ),
                StyledInput(
                  hint: 'Password',
                  ctrl: pCtrl,
                  obscure: !showPw,
                  suffix: IconButton(
                    icon: Icon(
                      showPw ? Icons.visibility_off : Icons.visibility,
                      color: cMuted,
                      size: 20,
                    ),
                    onPressed: () => setState(() => showPw = !showPw),
                  ),
                ),
                if (err.isNotEmpty) ErrorBox(err),
                loading
                    ? const CircularProgressIndicator(color: cIndigo)
                    : PrimaryButton(label: 'Sign in', onTap: _login),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: widget.onForgot,
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: cPurple,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Secured · Privacy Act 2020 compliant',
                  style: TextStyle(color: cMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

// ─── FORGOT PASSWORD ───────────────────────────────────────
class ForgotScreen extends StatefulWidget {
  final VoidCallback onBack;
  const ForgotScreen({super.key, required this.onBack});
  @override
  State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  final ctrl = TextEditingController();
  bool sent = false;
  String err = '';
  void _send() {
    final e = ctrl.text.trim();
    if (e.isEmpty) {
      setState(() => err = 'Please enter your email.');
      return;
    }
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(e)) {
      setState(() => err = 'Invalid email format.');
      return;
    }
    setState(() {
      err = '';
      sent = true;
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const AppHeader(),
      Expanded(
        child: _bgGradient(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text(
                    'Back to Sign in',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: cPurple,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [cNavyMid, cNavyLight],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: cNavy.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_reset_rounded,
                      color: Color(0xFF818CF8),
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Reset Password',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: cText,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Enter your email and we'll send you a reset link.",
                  style: TextStyle(color: cMuted, fontSize: 13),
                ),
                const SizedBox(height: 24),
                if (!sent) ...[
                  const InputLabel('Email Address'),
                  StyledInput(
                    hint: 'Your email address',
                    ctrl: ctrl,
                    keyboard: TextInputType.emailAddress,
                  ),
                  if (err.isNotEmpty) ErrorBox(err),
                  PrimaryButton(
                    label: 'Send Reset Link',
                    onTap: _send,
                    colors: [cPurple, const Color(0xFF4F46E5)],
                    shadowColor: const Color(0xFF3730A3),
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cGreenLight,
                      border: Border.all(color: cGreenBorder),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: cGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: const Icon(
                            Icons.mark_email_read_rounded,
                            color: cGreen,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Reset link sent!',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: cGreenText,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Check ${ctrl.text.trim()} for your password reset link.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: cGreenText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'Back to Sign in',
                          onTap: widget.onBack,
                          colors: [cGreen, const Color(0xFF15803D)],
                          shadowColor: cGreenDark,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

// ─── STAFF HOME ────────────────────────────────────────────
class StaffHome extends StatefulWidget {
  final AppUser user;
  final VoidCallback onLogout;
  const StaffHome({super.key, required this.user, required this.onLogout});
  @override
  State<StaffHome> createState() => _StaffHomeState();
}

class _StaffHomeState extends State<StaffHome> {
  String? subScreen;
  ClockInRecord? lastClockIn;
  @override
  Widget build(BuildContext context) {
    if (subScreen == 'clockin')
      return ClockInScreen(
        user: widget.user,
        onBack: () => setState(() => subScreen = null),
        onLogout: widget.onLogout,
        onClockedIn: (r) => setState(() {
          lastClockIn = r;
          subScreen = null;
        }),
      );
    if (subScreen == 'clockout')
      return ClockOutScreen(
        user: widget.user,
        clockInRecord: lastClockIn,
        onBack: () => setState(() => subScreen = null),
        onLogout: widget.onLogout,
        onClockedOut: () => setState(() {
          lastClockIn = null;
          subScreen = null;
        }),
      );
    if (subScreen == 'timesheet')
      return FortnightlyTimesheetScreen(
        user: widget.user,
        onBack: () => setState(() => subScreen = null),
        onLogout: widget.onLogout,
      );
    if (subScreen == 'history')
      return ShiftHistoryScreen(
        user: widget.user,
        onBack: () => setState(() => subScreen = null),
        onLogout: widget.onLogout,
      );

    return Column(
      children: [
        AppHeader(onLogout: widget.onLogout),
        Expanded(
          child: _bgGradient(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [cNavyMid, cNavy],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: cNavy.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                        const BoxShadow(
                          color: cNavy,
                          blurRadius: 0,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_greeting()}, ${widget.user.name.split(' ').first} 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Mode Rentals · New Zealand',
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'What would you like to do?',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: cNavyLight,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _NavTile(
                    icon: Icons.login_rounded,
                    label: 'Clock-In',
                    subtitle: 'Start your shift & verify location',
                    gradient: [const Color(0xFF065F46), cGreen],
                    shadowColor: const Color(0xFF064E3B),
                    onTap: () => setState(() => subScreen = 'clockin'),
                  ),
                  const SizedBox(height: 12),
                  _NavTile(
                    icon: Icons.logout_rounded,
                    label: 'Clock-Out & Shift Summary',
                    subtitle: 'End your shift & review hours',
                    gradient: [const Color(0xFF7F1D1D), cRedDark],
                    shadowColor: const Color(0xFF450A0A),
                    onTap: () => setState(() => subScreen = 'clockout'),
                  ),
                  const SizedBox(height: 12),
                  _NavTile(
                    icon: Icons.calendar_month_rounded,
                    label: 'Fortnightly Timesheet',
                    subtitle: 'View, submit & track your timesheet',
                    gradient: [const Color(0xFF1E3A8A), cBlue],
                    shadowColor: const Color(0xFF1E3A5F),
                    onTap: () => setState(() => subScreen = 'timesheet'),
                  ),
                  const SizedBox(height: 12),
                  _NavTile(
                    icon: Icons.history_rounded,
                    label: 'My Shift History',
                    subtitle: 'View your past clock-in records',
                    gradient: [const Color(0xFF4A1D96), cPurple],
                    shadowColor: const Color(0xFF2E1065),
                    onTap: () => setState(() => subScreen = 'history'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final List<Color> gradient;
  final Color shadowColor;
  final VoidCallback onTap;
  const _NavTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.shadowColor,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withOpacity(0.45),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: shadowColor,
            blurRadius: 0,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white54,
            size: 22,
          ),
        ],
      ),
    ),
  );
}

// ─── ADMIN HOME ────────────────────────────────────────────
class AdminHome extends StatefulWidget {
  final AppUser user;
  final VoidCallback onLogout;
  const AdminHome({super.key, required this.user, required this.onLogout});
  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  String? subScreen;

  @override
  Widget build(BuildContext context) {
    if (subScreen == 'users')
      return _UserManagementScreen(
        onBack: () => setState(() => subScreen = null),
        onLogout: widget.onLogout,
      );

    return Column(
      children: [
        AppHeader(onLogout: widget.onLogout),
        Expanded(
          child: _bgGradient(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [cNavyMid, cNavy],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: cNavy.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            RoleBadge(widget.user.role),
                            const SizedBox(width: 8),
                            Text(
                              widget.user.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.user.email,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Administration',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: cNavyLight,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _NavTile(
                    icon: Icons.manage_accounts_rounded,
                    label: 'User Management',
                    subtitle: 'Add, edit and delete users',
                    gradient: [const Color(0xFF4A1D96), cPurple],
                    shadowColor: const Color(0xFF2E1065),
                    onTap: () => setState(() => subScreen = 'users'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── USER MANAGEMENT SCREEN ────────────────────────────────
class _UserManagementScreen extends StatefulWidget {
  final VoidCallback onBack, onLogout;
  const _UserManagementScreen({required this.onBack, required this.onLogout});
  @override
  State<_UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<_UserManagementScreen> {
  List<AppUser> users = [];
  bool loading = true;
  String err = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      err = '';
    });
    try {
      final u = await SupabaseService.getUsers();
      if (mounted)
        setState(() {
          users = u;
          loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          err = e.toString();
          loading = false;
        });
    }
  }

  Future<void> _deleteUser(AppUser u) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete User',
          style: TextStyle(fontWeight: FontWeight.w800, color: cNavyMid),
        ),
        content: Text(
          'Are you sure you want to delete "${u.name}"?\nThis cannot be undone.',
          style: const TextStyle(color: cNavyLight, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: cRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await SupabaseService.deleteUser(u.id);
      _load();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${u.name} deleted.'),
            backgroundColor: cGreen,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: cRed),
        );
    }
  }

  void _openForm({AppUser? user}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _UserFormScreen(user: user, onSaved: _load),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppHeader(onLogout: widget.onLogout),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A1D96), cPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: widget.onBack,
              child: const Row(
                children: [
                  Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white70,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Back',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Management',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                      Text(
                        'Add, edit and delete users',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _openForm(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_add_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Add User',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      Expanded(
        child: _bgGradient(
          child: loading
              ? const Center(child: CircularProgressIndicator(color: cPurple))
              : err.isNotEmpty
              ? Center(
                  child: Text(
                    'Error: $err',
                    style: const TextStyle(color: cRed),
                  ),
                )
              : users.isEmpty
              ? const Center(
                  child: Text(
                    'No users found.',
                    style: TextStyle(color: cMuted, fontSize: 14),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: cPurple,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    itemBuilder: (_, i) {
                      final u = users[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: raisedCard(
                          radius: 12,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF312E81), cIndigo],
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: cIndigo.withOpacity(0.35),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      u.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        u.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: cText,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        u.email,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: cMuted,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      RoleBadge(u.role),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _openForm(user: u),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: cVioletLight,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.edit_rounded,
                                          color: cVioletText,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () => _deleteUser(u),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFDECEA),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.delete_rounded,
                                          color: cRed,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    ],
  );
}

// ─── USER FORM SCREEN ──────────────────────────────────────
class _UserFormScreen extends StatefulWidget {
  final AppUser? user;
  final VoidCallback onSaved;
  const _UserFormScreen({this.user, required this.onSaved});
  @override
  State<_UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<_UserFormScreen> {
  final nCtrl = TextEditingController();
  final eCtrl = TextEditingController();
  final pCtrl = TextEditingController();
  String role = 'Staff';
  bool showPw = false, saving = false;
  String err = '';

  bool get isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      nCtrl.text = widget.user!.name;
      eCtrl.text = widget.user!.email;
      pCtrl.text = widget.user!.password;
      role = widget.user!.role;
    }
  }

  Future<void> _save() async {
    if (nCtrl.text.trim().isEmpty) {
      setState(() => err = 'Name is required.');
      return;
    }
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(eCtrl.text.trim())) {
      setState(() => err = 'Valid email is required.');
      return;
    }
    if (pCtrl.text.length < 8) {
      setState(() => err = 'Password must be at least 8 characters.');
      return;
    }
    setState(() {
      saving = true;
      err = '';
    });
    try {
      final u = AppUser(
        id: isEdit ? widget.user!.id : '',
        name: nCtrl.text.trim(),
        email: eCtrl.text.trim(),
        password: pCtrl.text,
        role: role,
      );
      if (isEdit) {
        await SupabaseService.updateUser(u);
      } else {
        await SupabaseService.addUser(u);
      }
      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'User updated successfully!'
                  : 'User added successfully!',
            ),
            backgroundColor: cGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        setState(() {
          err = e.toString();
          saving = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: cSlate,
    body: SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A1D96), cPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.white70,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Back',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isEdit ? 'Edit User' : 'Add New User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                Text(
                  isEdit ? 'Update user details' : 'Create a new user account',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: _bgGradient(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    raisedCard(
                      radius: 14,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const InputLabel('Full Name'),
                            StyledInput(hint: 'Full name', ctrl: nCtrl),
                            const InputLabel('Email Address'),
                            StyledInput(
                              hint: 'Email address',
                              ctrl: eCtrl,
                              keyboard: TextInputType.emailAddress,
                            ),
                            const InputLabel('Password'),
                            StyledInput(
                              hint: 'Min 8 characters',
                              ctrl: pCtrl,
                              obscure: !showPw,
                              suffix: IconButton(
                                icon: Icon(
                                  showPw
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: cMuted,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => showPw = !showPw),
                              ),
                            ),
                            const InputLabel('Role'),
                            Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: cBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: cNavy.withOpacity(0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: role,
                                  isExpanded: true,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  items: ['Staff', 'Manager', 'Admin']
                                      .map(
                                        (r) => DropdownMenuItem(
                                          value: r,
                                          child: Row(
                                            children: [
                                              RoleBadge(r),
                                              const SizedBox(width: 8),
                                              Text(
                                                r,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(() => role = v!),
                                ),
                              ),
                            ),
                            if (err.isNotEmpty) ErrorBox(err),
                            saving
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: cPurple,
                                    ),
                                  )
                                : PrimaryButton(
                                    label: isEdit ? 'Update User' : 'Add User',
                                    onTap: _save,
                                    colors: [cPurple, const Color(0xFF4F46E5)],
                                    shadowColor: const Color(0xFF3730A3),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── MANAGER HOME ──────────────────────────────────────────
class ManagerHome extends StatefulWidget {
  final AppUser user;
  final VoidCallback onLogout;
  const ManagerHome({super.key, required this.user, required this.onLogout});
  @override
  State<ManagerHome> createState() => _ManagerHomeState();
}

class _ManagerHomeState extends State<ManagerHome> {
  String? subScreen;
  List<AppUser> users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final u = await SupabaseService.getUsers();
      if (mounted) setState(() => users = u);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (subScreen == 'staff')
      return _StaffMembersScreen(
        users: users,
        onBack: () => setState(() => subScreen = null),
        onLogout: widget.onLogout,
      );
    if (subScreen == 'timesheets')
      return _ManagerTimesheetsScreen(
        manager: widget.user,
        onBack: () => setState(() => subScreen = null),
        onLogout: widget.onLogout,
      );

    final now = DateTime.now();
    final fnStart = fortnightStart(now);
    return Column(
      children: [
        AppHeader(onLogout: widget.onLogout),
        Expanded(
          child: _bgGradient(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [cNavyMid, cNavy],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: cNavy.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                        const BoxShadow(
                          color: cNavy,
                          blurRadius: 0,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                        Text(
                          'Auckland · Fortnight ${fmtDateShort(fnStart)} – ${fmtDate(fortnightEnd(fnStart))}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Management',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: cNavyLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ManagerTile(
                    icon: Icons.people_alt_rounded,
                    label: 'Staff Members',
                    subtitle: 'View all staff profiles',
                    gradient: [const Color(0xFF065F46), cGreen],
                    shadowColor: const Color(0xFF064E3B),
                    badge: '${users.where((u) => u.role == 'Staff').length}',
                    onTap: () => setState(() => subScreen = 'staff'),
                  ),
                  const SizedBox(height: 12),
                  _ManagerTile(
                    icon: Icons.receipt_long_rounded,
                    label: 'Time Sheets',
                    subtitle: 'Review & approve fortnightly timesheets',
                    gradient: [const Color(0xFF1E3A8A), cBlue],
                    shadowColor: const Color(0xFF1E3A5F),
                    badge: null,
                    onTap: () => setState(() => subScreen = 'timesheets'),
                  ),
                  const SizedBox(height: 20),
                  StatCard(
                    icon: Icons.check_circle_rounded,
                    label: 'Checked In Today',
                    value: 0,
                  ),
                  const SizedBox(height: 10),
                  StatCard(
                    icon: Icons.pending_actions_rounded,
                    label: 'Pending Approvals',
                    value: 0,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ManagerTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final List<Color> gradient;
  final Color shadowColor;
  final String? badge;
  final VoidCallback onTap;
  const _ManagerTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.shadowColor,
    required this.badge,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withOpacity(0.45),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: shadowColor,
            blurRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white54,
            size: 22,
          ),
        ],
      ),
    ),
  );
}

// ─── STAFF MEMBERS SCREEN (Manager) ───────────────────────
class _StaffMembersScreen extends StatelessWidget {
  final List<AppUser> users;
  final VoidCallback onBack, onLogout;
  const _StaffMembersScreen({
    required this.users,
    required this.onBack,
    required this.onLogout,
  });
  @override
  Widget build(BuildContext context) {
    final staff = users.where((u) => u.role == 'Staff').toList();
    return Column(
      children: [
        AppHeader(onLogout: onLogout),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF065F46), cGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onBack,
                child: const Row(
                  children: [
                    Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.white70,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Staff Members',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              Text(
                '${staff.length} staff registered',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        Expanded(
          child: _bgGradient(
            child: staff.isEmpty
                ? const Center(
                    child: Text(
                      'No staff members yet.',
                      style: TextStyle(color: cMuted, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: staff.length,
                    itemBuilder: (_, i) {
                      final u = staff[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: raisedCard(
                          radius: 12,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF065F46), cGreen],
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: cGreen.withOpacity(0.35),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      u.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        u.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: cText,
                                        ),
                                      ),
                                      Text(
                                        u.email,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: cMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      RoleBadge(u.role),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

// ─── CLOCK IN SCREEN ───────────────────────────────────────
enum GpsState { idle, loading, granted, denied, outOfRange }

class ClockInScreen extends StatefulWidget {
  final AppUser user;
  final VoidCallback onBack, onLogout;
  final void Function(ClockInRecord) onClockedIn;
  const ClockInScreen({
    super.key,
    required this.user,
    required this.onBack,
    required this.onLogout,
    required this.onClockedIn,
  });
  @override
  State<ClockInScreen> createState() => _ClockInScreenState();
}

class _ClockInScreenState extends State<ClockInScreen> {
  Branch? selectedBranch;
  GpsState gpsState = GpsState.idle;
  Branch? detectedBranch;
  double? capturedLat, capturedLng;
  DateTime? gpsTimestamp;
  File? capturedPhoto;
  bool clockedIn = false, saving = false;
  String gpsError = '';
  final ImagePicker _picker = ImagePicker();

  String _timeStr() {
    final t = TimeOfDay.now();
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    return '${h.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  String _dateStr() {
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${days[now.weekday - 1]} ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  void _onBranchSelected(Branch? b) => setState(() {
    selectedBranch = b;
    gpsState = GpsState.idle;
    detectedBranch = null;
    capturedLat = null;
    capturedLng = null;
    gpsTimestamp = null;
    gpsError = '';
    capturedPhoto = null;
    clockedIn = false;
  });
  Future<void> _takePhoto() async {
    try {
      final XFile? x = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (x != null && mounted) setState(() => capturedPhoto = File(x.path));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e'), backgroundColor: cRed),
        );
    }
  }

  void _onVerifyTapped() {
    if (selectedBranch == null) return;
    setState(() {
      gpsState = GpsState.loading;
      gpsError = '';
      detectedBranch = null;
    });
    _requestGps();
  }

  Future<void> _requestGps() async {
    if (selectedBranch == null) {
      if (mounted) setState(() => gpsState = GpsState.idle);
      return;
    }
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        setState(() {
          gpsState = GpsState.denied;
          gpsError =
              'Location services are disabled.\nGo to Settings → Privacy → Location Services.';
        });
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();
      if (!mounted) return;
      if (perm == LocationPermission.deniedForever) {
        setState(() {
          gpsState = GpsState.denied;
          gpsError =
              'Location permanently denied.\nGo to Settings → Mode Rentals → Location.';
        });
        return;
      }
      if (perm == LocationPermission.denied) {
        setState(() {
          gpsState = GpsState.denied;
          gpsError = 'Location permission denied. Please allow and retry.';
        });
        return;
      }
      final p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );
      if (!mounted) return;
      final dist = haversineDistance(
        p.latitude,
        p.longitude,
        selectedBranch!.lat,
        selectedBranch!.lng,
      );
      if (dist <= selectedBranch!.radiusMeters) {
        setState(() {
          gpsState = GpsState.granted;
          detectedBranch = selectedBranch;
          capturedLat = p.latitude;
          capturedLng = p.longitude;
          gpsTimestamp = DateTime.now();
          gpsError = '';
        });
      } else {
        setState(() {
          gpsState = GpsState.outOfRange;
          capturedLat = p.latitude;
          capturedLng = p.longitude;
          gpsError =
              'You are ${(dist / 1000).toStringAsFixed(2)} km from "${selectedBranch!.name}".\n\n'
              'Clock-in requires you to be within 1000 m of the selected branch.\n\n'
              'Please ensure you are physically at the branch or contact your manager.';
        });
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        gpsState = GpsState.outOfRange;
        gpsError = 'GPS timed out. Move to an open area and retry.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        gpsState = GpsState.outOfRange;
        gpsError = 'Could not get GPS. Move outdoors and retry.\n\nDetail: $e';
      });
    }
  }

  Future<void> _confirmClockIn() async {
    if (detectedBranch == null || capturedLat == null || capturedPhoto == null)
      return;
    setState(() => saving = true);
    try {
      final ts = gpsTimestamp ?? DateTime.now();
      final photoUrl = await SupabaseService.uploadPhoto(
        photo: capturedPhoto!,
        userEmail: widget.user.email,
        timestamp: ts,
      );
      final id = await SupabaseService.saveClockIn(
        user: widget.user,
        branch: detectedBranch!,
        lat: capturedLat!,
        lng: capturedLng!,
        clockInTime: ts,
        photoUrl: photoUrl,
      );
      final record = ClockInRecord(
        timestamp: ts,
        lat: capturedLat!,
        lng: capturedLng!,
        branch: detectedBranch!,
        photo: capturedPhoto,
        supabaseId: id,
      );
      if (mounted) {
        setState(() {
          clockedIn = true;
          saving = false;
        });
        await Future.delayed(const Duration(milliseconds: 900));
        widget.onClockedIn(record);
      }
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: cRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppHeader(onLogout: widget.onLogout),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF065F46), cGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: widget.onBack,
              child: const Row(
                children: [
                  Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white70,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Back',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_greeting()}, ${widget.user.name.split(' ').first} 👋',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const Text(
              'Mode Rentals · New Zealand',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
      Expanded(
        child: _bgGradient(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                raisedCard(
                  radius: 16,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          _timeStr(),
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: cText,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dateStr(),
                          style: const TextStyle(color: cMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.store_rounded,
                                  color: cNavyMid,
                                  size: 15,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Select your branch',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: cNavyMid,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: cSlate,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedBranch != null
                                      ? cGreenBorder
                                      : cBorder,
                                  width: 1.5,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<Branch>(
                                  value: selectedBranch,
                                  isExpanded: true,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  hint: const Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        color: cMuted,
                                        size: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '— Choose authorised location —',
                                        style: TextStyle(
                                          color: cMuted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  items: kBranches
                                      .map(
                                        (b) => DropdownMenuItem<Branch>(
                                          value: b,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: cGreen,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      b.name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 13,
                                                        color: cText,
                                                      ),
                                                    ),
                                                    Text(
                                                      b.address,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: cMuted,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: _onBranchSelected,
                                ),
                              ),
                            ),
                            if (selectedBranch != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: cGreen,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      selectedBranch!.address,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: cGreenText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        _GpsPanel(
                          gpsState: gpsState,
                          selectedBranch: selectedBranch,
                          detectedBranch: detectedBranch,
                          gpsError: gpsError,
                          capturedLat: capturedLat,
                          capturedLng: capturedLng,
                          gpsTimestamp: gpsTimestamp,
                          onVerify: _onVerifyTapped,
                          verifyEnabled: selectedBranch != null,
                        ),
                        const SizedBox(height: 14),
                        if (gpsState == GpsState.granted) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.camera_alt_rounded,
                                    color: cNavyMid,
                                    size: 15,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Clock-in photo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: cNavyMid,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'A photo is required. Camera only — gallery upload not allowed.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cMuted,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              capturedPhoto != null
                                  ? Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.file(
                                            capturedPhoto!,
                                            width: double.infinity,
                                            height: 160,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: _takePhoto,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: cNavy.withOpacity(0.75),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.refresh_rounded,
                                                    color: Colors.white,
                                                    size: 13,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Retake',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 8,
                                          left: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: cGreen.withOpacity(0.85),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check_circle_rounded,
                                                  color: Colors.white,
                                                  size: 12,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Photo captured ✓',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : GestureDetector(
                                      onTap: _takePhoto,
                                      child: Container(
                                        width: double.infinity,
                                        height: 110,
                                        decoration: BoxDecoration(
                                          color: cSlate,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: cBorder,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    cNavyMid,
                                                    cNavyLight,
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: cNavy.withOpacity(
                                                      0.3,
                                                    ),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.camera_alt_rounded,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            const Text(
                                              'Tap to take photo',
                                              style: TextStyle(
                                                color: cNavyMid,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            const Text(
                                              'Camera only · no gallery upload',
                                              style: TextStyle(
                                                color: cMuted,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],
                        saving
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: cGreenLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: cGreenBorder),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: cGreen,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Uploading photo & saving…',
                                      style: TextStyle(
                                        color: cGreenText,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : clockedIn
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: cGreenLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: cGreenBorder),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: cGreen,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Clocked In & Saved ✓',
                                      style: TextStyle(
                                        color: cGreenText,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : _ClockInButton(
                                gpsState: gpsState,
                                photoTaken: capturedPhoto != null,
                                clockedIn: clockedIn,
                                branchSelected: selectedBranch != null,
                                onTap: _confirmClockIn,
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

// ─── GPS Panel ─────────────────────────────────────────────
class _GpsPanel extends StatelessWidget {
  final GpsState gpsState;
  final Branch? selectedBranch, detectedBranch;
  final String gpsError;
  final double? capturedLat, capturedLng;
  final DateTime? gpsTimestamp;
  final VoidCallback onVerify;
  final bool verifyEnabled;
  const _GpsPanel({
    required this.gpsState,
    required this.selectedBranch,
    required this.detectedBranch,
    required this.gpsError,
    required this.capturedLat,
    required this.capturedLng,
    required this.gpsTimestamp,
    required this.onVerify,
    required this.verifyEnabled,
  });
  String _fmtTs(DateTime? ts) {
    if (ts == null) return '';
    final h = ts.hour % 12 == 0 ? 12 : ts.hour % 12;
    final m = ts.minute.toString().padLeft(2, '0');
    final s = ts.second.toString().padLeft(2, '0');
    return '$h:$m:$s ${ts.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    if (gpsState == GpsState.idle)
      return GestureDetector(
        onTap: verifyEnabled ? onVerify : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: verifyEnabled ? cNavyMid : cSlate,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: verifyEnabled ? cNavyLight : cBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.my_location_rounded,
                color: verifyEnabled ? Colors.white : cMuted,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                verifyEnabled
                    ? 'Tap to verify location'
                    : 'Select a branch first',
                style: TextStyle(
                  color: verifyEnabled ? Colors.white : cMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    if (gpsState == GpsState.loading)
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cSlate,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cBorder),
        ),
        child: const Column(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: cGreen),
            ),
            SizedBox(height: 8),
            Text(
              'Acquiring GPS signal…',
              style: TextStyle(color: cMuted, fontSize: 12),
            ),
          ],
        ),
      );
    if (gpsState == GpsState.granted)
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cGreenLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cGreenBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_rounded, color: cGreen, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${detectedBranch!.name} · GPS verified ✓',
                    style: const TextStyle(
                      color: cGreenText,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              detectedBranch!.address,
              style: const TextStyle(
                color: cGreenText,
                fontSize: 11,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.gps_fixed, color: cGreen, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${capturedLat!.toStringAsFixed(5)}, ${capturedLng!.toStringAsFixed(5)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: cGreenText,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: cGreen,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Captured at ${_fmtTs(gpsTimestamp)}',
                        style: const TextStyle(fontSize: 10, color: cGreenText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    if (gpsState == GpsState.outOfRange)
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cOrange.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_off_rounded, color: cOrange, size: 18),
                SizedBox(width: 8),
                Text(
                  'Location Out of Range',
                  style: TextStyle(
                    color: cOrangeDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              gpsError,
              style: const TextStyle(
                color: cOrangeDark,
                fontSize: 11.5,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onVerify,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [cOrange, Color(0xFFEA580C)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: cOrange.withOpacity(0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Retry GPS Check',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cRed.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.location_disabled_rounded, color: cRed, size: 16),
              SizedBox(width: 8),
              Text(
                'Location Permission Denied',
                style: TextStyle(
                  color: cRed,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            gpsError.isNotEmpty
                ? gpsError
                : 'Please enable location access in Settings.',
            style: const TextStyle(color: cRed, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onVerify,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [cNavyMid, cNavy]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.settings_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Open Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Clock In Button ───────────────────────────────────────
class _ClockInButton extends StatelessWidget {
  final GpsState gpsState;
  final bool photoTaken, clockedIn, branchSelected;
  final Future<void> Function() onTap;
  const _ClockInButton({
    required this.gpsState,
    required this.photoTaken,
    required this.clockedIn,
    required this.branchSelected,
    required this.onTap,
  });
  bool get _enabled => gpsState == GpsState.granted && photoTaken && !clockedIn;
  @override
  Widget build(BuildContext context) {
    final label = !branchSelected
        ? 'Select a Branch First'
        : gpsState != GpsState.granted
        ? 'Verify Location First'
        : !photoTaken
        ? 'Take Photo to Enable Clock-In'
        : 'Clock In';
    return Opacity(
      opacity: _enabled ? 1.0 : 0.45,
      child: GestureDetector(
        onTap: _enabled ? onTap : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF065F46), cGreen]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _enabled
                ? [
                    BoxShadow(
                      color: cGreen.withOpacity(0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                    const BoxShadow(
                      color: Color(0xFF064E3B),
                      blurRadius: 0,
                      offset: Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── CLOCK OUT SCREEN ──────────────────────────────────────
class ClockOutScreen extends StatefulWidget {
  final AppUser user;
  final ClockInRecord? clockInRecord;
  final VoidCallback onBack, onLogout, onClockedOut;
  const ClockOutScreen({
    super.key,
    required this.user,
    required this.clockInRecord,
    required this.onBack,
    required this.onLogout,
    required this.onClockedOut,
  });
  @override
  State<ClockOutScreen> createState() => _ClockOutScreenState();
}

class _ClockOutScreenState extends State<ClockOutScreen> {
  final noteCtrl = TextEditingController();
  bool confirmed = false, saving = false;
  String _fmt(DateTime? t) {
    if (t == null) return '--:-- --';
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  double _shiftHours() {
    if (widget.clockInRecord == null) return 0;
    final diff =
        DateTime.now().difference(widget.clockInRecord!.timestamp).inMinutes -
        30;
    return (diff.clamp(0, 9999) / 60);
  }

  Future<void> _confirmOut() async {
    setState(() => saving = true);
    try {
      if (widget.clockInRecord?.supabaseId != null)
        await SupabaseService.saveClockOut(
          recordId: widget.clockInRecord!.supabaseId!,
          clockOutTime: DateTime.now(),
          notes: noteCtrl.text.trim(),
          shiftHours: _shiftHours(),
        );
      if (mounted)
        setState(() {
          confirmed = true;
          saving = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: cRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppHeader(onLogout: widget.onLogout),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7F1D1D), cRedDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: widget.onBack,
              child: const Row(
                children: [
                  Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white70,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Back',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Clock Out',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            const Text(
              'Confirm your shift end',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
      Expanded(
        child: _bgGradient(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (confirmed) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cGreenLight,
                      border: Border.all(color: cGreenBorder),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: cGreen,
                          size: 52,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Clocked Out!',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: cGreenText,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Shift total: ${_shiftHours().toStringAsFixed(1)} hrs',
                          style: const TextStyle(
                            color: cGreenText,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Saved to Supabase ✓',
                          style: TextStyle(color: cGreenText, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'Back to Home',
                          onTap: widget.onClockedOut,
                          colors: [cGreen, const Color(0xFF15803D)],
                          shadowColor: cGreenDark,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  raisedCard(
                    radius: 16,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Today's shift",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: cText,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _SummaryRow(
                            label: 'Clocked in',
                            value: _fmt(widget.clockInRecord?.timestamp),
                            bold: false,
                          ),
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'Clocking out',
                            value: _fmt(DateTime.now()),
                            bold: false,
                          ),
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'Break deducted',
                            value: '30 min',
                            bold: false,
                          ),
                          const Divider(height: 20, color: cBorder),
                          _SummaryRow(
                            label: 'Shift total',
                            value: '${_shiftHours().toStringAsFixed(1)} hrs',
                            bold: true,
                            valueColor: cBlue,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  raisedCard(
                    radius: 12,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: cGreen,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.clockInRecord?.branch.name ?? 'Unknown',
                                style: const TextStyle(
                                  color: cGreenText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                'GPS verified ✓',
                                style: TextStyle(color: cGreen, fontSize: 11),
                              ),
                            ],
                          ),
                          if (widget.clockInRecord != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              '${widget.clockInRecord!.lat.toStringAsFixed(5)}, ${widget.clockInRecord!.lng.toStringAsFixed(5)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: cMuted,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  raisedCard(
                    radius: 12,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add a note (optional)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: cText,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: noteCtrl,
                            maxLines: 3,
                            style: const TextStyle(fontSize: 13, color: cText),
                            decoration: InputDecoration(
                              hintText:
                                  'e.g. Completed vehicle drop-off at 3pm',
                              hintStyle: const TextStyle(
                                color: cMuted,
                                fontSize: 12,
                              ),
                              filled: true,
                              fillColor: cSlate,
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: cBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: cBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: cRed,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  saving
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: cSlate,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cBorder),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: cGreen,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Saving to Supabase…',
                                style: TextStyle(
                                  color: cMuted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GestureDetector(
                          onTap: _confirmOut,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7F1D1D), cRedDark],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: cRed.withOpacity(0.45),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                                const BoxShadow(
                                  color: Color(0xFF450A0A),
                                  blurRadius: 0,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Confirm Clock Out',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                ],
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

// ─── FORTNIGHTLY TIMESHEET ─────────────────────────────────
class FortnightlyTimesheetScreen extends StatefulWidget {
  final AppUser user;
  final VoidCallback onBack, onLogout;
  const FortnightlyTimesheetScreen({
    super.key,
    required this.user,
    required this.onBack,
    required this.onLogout,
  });
  @override
  State<FortnightlyTimesheetScreen> createState() =>
      _FortnightlyTimesheetScreenState();
}

class _FortnightlyTimesheetScreenState
    extends State<FortnightlyTimesheetScreen> {
  bool loading = true, viewingHistory = false;
  List<Map<String, dynamic>> shiftRecords = [];
  Map<String, dynamic>? submission;
  List<Map<String, dynamic>> history = [];
  bool historyLoading = false;
  String err = '';
  late DateTime fnStart, fnEnd;

  @override
  void initState() {
    super.initState();
    fnStart = fortnightStart(DateTime.now());
    fnEnd = fortnightEnd(fnStart);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      err = '';
    });
    try {
      final records = await SupabaseService.getUserRecordsInRange(
        widget.user.email,
        fnStart,
        fnEnd,
      );
      final sub = await SupabaseService.getTimesheetStatus(
        widget.user.email,
        fnStart,
      );
      setState(() {
        shiftRecords = records;
        submission = sub;
        loading = false;
      });
    } catch (e) {
      setState(() {
        err = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    setState(() => historyLoading = true);
    try {
      final h = await SupabaseService.getAllTimesheetHistory(widget.user.email);
      setState(() {
        history = h;
        historyLoading = false;
      });
    } catch (_) {
      setState(() => historyLoading = false);
    }
  }

  Map<String, double> _dailyHours() {
    final Map<String, double> daily = {};
    for (final r in shiftRecords) {
      if (r['shift_hours'] == null) continue;
      final dt = DateTime.tryParse(r['clock_in_time'] ?? '')?.toLocal();
      if (dt == null) continue;
      final key =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      daily[key] = (daily[key] ?? 0) + (r['shift_hours'] as num).toDouble();
    }
    return daily;
  }

  double _weekHours(int week) {
    final daily = _dailyHours();
    double total = 0;
    final weekStart = week == 1
        ? fnStart
        : fnStart.add(const Duration(days: 7));
    for (int i = 0; i < 7; i++) {
      final d = weekStart.add(Duration(days: i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      total += daily[key] ?? 0;
    }
    return total;
  }

  bool get _isApproved => submission?['status'] == 'approved';
  bool get _isSubmitted => submission != null;

  Future<void> _submit() async {
    final w1 = _weekHours(1), w2 = _weekHours(2), total = w1 + w2;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Submit Timesheet',
          style: TextStyle(fontWeight: FontWeight.w800, color: cNavyMid),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submit your fortnightly timesheet to your manager for review?',
              style: TextStyle(color: cNavyLight, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cSlate,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Week 1',
                    value: '${w1.toStringAsFixed(1)} hrs',
                    bold: false,
                  ),
                  const SizedBox(height: 4),
                  _SummaryRow(
                    label: 'Week 2',
                    value: '${w2.toStringAsFixed(1)} hrs',
                    bold: false,
                  ),
                  const Divider(height: 16, color: cBorder),
                  _SummaryRow(
                    label: 'Total',
                    value: '${total.toStringAsFixed(1)} hrs',
                    bold: true,
                    valueColor: cBlue,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: cBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Submit',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await SupabaseService.submitTimesheet(
        userEmail: widget.user.email,
        userName: widget.user.name,
        branchName: shiftRecords.isNotEmpty
            ? shiftRecords.first['branch_name'] ?? ''
            : '',
        fnStart: fnStart,
        fnEnd: fnEnd,
        week1: w1,
        week2: w2,
        total: total,
      );
      if (mounted) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timesheet submitted successfully!'),
            backgroundColor: cGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: cRed),
        );
    }
  }

  Widget _buildWeekCard(int week) {
    final daily = _dailyHours();
    final weekStart = week == 1
        ? fnStart
        : fnStart.add(const Duration(days: 7));
    double weekTotal = 0;
    final rows = <Widget>[];
    for (int i = 0; i < 7; i++) {
      final d = weekStart.add(Duration(days: i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final hrs = daily[key] ?? 0;
      weekTotal += hrs;
      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  dayNames[i],
                  style: const TextStyle(
                    fontSize: 12,
                    color: cMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                fmtDateShort(d),
                style: const TextStyle(fontSize: 12, color: cMuted),
              ),
              const Spacer(),
              hrs > 0
                  ? Text(
                      '${hrs.toStringAsFixed(1)} hrs',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hrs > 10 ? cOrange : cText,
                      ),
                    )
                  : const Text(
                      '—',
                      style: TextStyle(fontSize: 12, color: cBorder),
                    ),
            ],
          ),
        ),
      );
    }
    return raisedCard(
      radius: 14,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: cBlue,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Week $week · ${fmtDateShort(weekStart)} – ${fmtDateShort(weekStart.add(const Duration(days: 6)))}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: cText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...rows,
            const Divider(height: 16, color: cBorder),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Week $week Total',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: cText,
                  ),
                ),
                Text(
                  '${weekTotal.toStringAsFixed(1)} hrs',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: weekTotal > 45 ? cOrange : cBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w1 = _weekHours(1), w2 = _weekHours(2), total = w1 + w2;
    return Column(
      children: [
        AppHeader(onLogout: widget.onLogout),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3A8A), cBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: const Row(
                  children: [
                    Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.white70,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Timesheet',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                        Text(
                          '${fmtDateShort(fnStart)} – ${fmtDate(fnEnd)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (submission != null)
                    StatusBadge(submission!['status'] ?? 'pending'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _HeaderTab(
                    label: 'Current',
                    selected: !viewingHistory,
                    onTap: () => setState(() => viewingHistory = false),
                  ),
                  const SizedBox(width: 8),
                  _HeaderTab(
                    label: 'History',
                    selected: viewingHistory,
                    onTap: () {
                      setState(() => viewingHistory = true);
                      if (history.isEmpty) _loadHistory();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _bgGradient(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: cBlue))
                : err.isNotEmpty
                ? Center(
                    child: Text(
                      'Error: $err',
                      style: const TextStyle(color: cRed),
                    ),
                  )
                : viewingHistory
                ? (historyLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: cBlue),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadHistory,
                          color: cBlue,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (history.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(40),
                                    child: Text(
                                      'No past timesheets yet.',
                                      style: TextStyle(
                                        color: cMuted,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ...history.map(_buildHistoryCard),
                            ],
                          ),
                        ))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: cBlue,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (submission != null) ...[
                            _StatusBanner(submission: submission!),
                            const SizedBox(height: 12),
                          ],
                          _buildWeekCard(1),
                          const SizedBox(height: 12),
                          _buildWeekCard(2),
                          const SizedBox(height: 12),
                          raisedCard(
                            radius: 12,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: _SummaryRow(
                                label: 'Fortnight Grand Total',
                                value: '${total.toStringAsFixed(1)} hrs',
                                bold: true,
                                valueColor: cBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (!_isApproved)
                            GestureDetector(
                              onTap: _submit,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF1E3A8A), cBlue],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isSubmitted
                                          ? Icons.refresh_rounded
                                          : Icons.send_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isSubmitted
                                          ? 'Re-submit Timesheet'
                                          : 'Submit to Manager',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: cGreenLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: cGreenBorder),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock_rounded,
                                    color: cGreenText,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Approved & Locked',
                                    style: TextStyle(
                                      color: cGreenText,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> ts) {
    final start = DateTime.tryParse(ts['fortnight_start'] ?? '');
    final end = DateTime.tryParse(ts['fortnight_end'] ?? '');
    final status = ts['status'] ?? 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: raisedCard(
        radius: 12,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      start != null && end != null
                          ? '${fmtDateShort(start)} – ${fmtDate(end)}'
                          : '—',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: cText,
                      ),
                    ),
                  ),
                  StatusBadge(status),
                ],
              ),
              const SizedBox(height: 8),
              _SummaryRow(
                label: 'Week 1',
                value: '${(ts['week1_hours'] ?? 0).toStringAsFixed(1)} hrs',
                bold: false,
              ),
              const SizedBox(height: 3),
              _SummaryRow(
                label: 'Week 2',
                value: '${(ts['week2_hours'] ?? 0).toStringAsFixed(1)} hrs',
                bold: false,
              ),
              const Divider(height: 12, color: cBorder),
              _SummaryRow(
                label: 'Total',
                value: '${(ts['total_hours'] ?? 0).toStringAsFixed(1)} hrs',
                bold: true,
                valueColor: cBlue,
              ),
              if (status == 'rejected' &&
                  (ts['manager_comment'] ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECEA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: cRed, size: 13),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Manager: ${ts['manager_comment']}',
                          style: const TextStyle(fontSize: 11, color: cRed),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _HeaderTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected ? cBlue : Colors.white70,
        ),
      ),
    ),
  );
}

class _StatusBanner extends StatelessWidget {
  final Map<String, dynamic> submission;
  const _StatusBanner({required this.submission});
  @override
  Widget build(BuildContext context) {
    final status = submission['status'] ?? 'pending';
    Color bg, fg;
    IconData icon;
    String msg;
    switch (status) {
      case 'approved':
        bg = cGreenLight;
        fg = cGreenText;
        icon = Icons.check_circle_rounded;
        msg =
            'Approved${submission['approved_at'] != null ? ' on ${_fmtDT(submission['approved_at'])}' : ''}';
        break;
      case 'rejected':
        bg = const Color(0xFFFDECEA);
        fg = cRed;
        icon = Icons.cancel_rounded;
        msg =
            'Rejected by manager${(submission['manager_comment'] ?? '').isNotEmpty ? ': ${submission['manager_comment']}' : ''}';
        break;
      case 'review':
        bg = cVioletLight;
        fg = cVioletText;
        icon = Icons.visibility_rounded;
        msg = 'Under review by manager';
        break;
      default:
        bg = cAmberLight;
        fg = cAmberText;
        icon = Icons.hourglass_empty_rounded;
        msg = 'Submitted – awaiting manager approval';
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SHIFT HISTORY ─────────────────────────────────────────
class ShiftHistoryScreen extends StatefulWidget {
  final AppUser user;
  final VoidCallback onBack;
  final VoidCallback onLogout;

  const ShiftHistoryScreen({
    super.key,
    required this.user,
    required this.onBack,
    required this.onLogout,
  });

  @override
  State<ShiftHistoryScreen> createState() => _ShiftHistoryScreenState();
}

class _ShiftHistoryScreenState extends State<ShiftHistoryScreen> {
  List<Map<String, dynamic>> records = [];
  bool loading = true;
  String err = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await SupabaseService.getUserRecords(widget.user.email);

      if (mounted) {
        setState(() {
          records = r;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          err = e.toString();
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppHeader(onLogout: widget.onLogout),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A1D96), cPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: const Row(
                  children: [
                    Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.white70,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'My Shift History',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const Text(
                'All your clock-in records',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),

        Expanded(
          child: _bgGradient(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: cPurple))
                : err.isNotEmpty
                ? Center(
                    child: Text(
                      'Error: $err',
                      style: const TextStyle(color: cRed),
                    ),
                  )
                : records.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded, color: cMuted, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'No shift records yet.',
                          style: TextStyle(
                            color: cMuted,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    color: cPurple,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: records.length,
                      itemBuilder: (ctx, i) {
                        final d = records[i];
                        final isActive = d['shift_status'] == 'active';
                        final photoUrl = d['photo_url'] as String?;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: raisedCard(
                            radius: 14,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? cGreenLight
                                              : cSlate,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: isActive
                                                ? cGreenBorder
                                                : cBorder,
                                          ),
                                        ),
                                        child: Text(
                                          isActive ? '● Active' : '✓ Completed',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: isActive
                                                ? cGreenText
                                                : cMuted,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        d['branch_name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: cMuted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.login_rounded,
                                        color: cGreen,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'In: ${_fmtDT(d['clock_in_time'])}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: cText,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 4),

                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.logout_rounded,
                                        color: cRed,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          d['clock_out_time'] != null
                                              ? 'Out: ${_fmtDT(d['clock_out_time'])}'
                                              : 'Out: Not clocked out yet',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: d['clock_out_time'] != null
                                                ? cText
                                                : cMuted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (d['shift_hours'] != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time_rounded,
                                          color: cBlue,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Total: ${(d['shift_hours'] as num).toStringAsFixed(1)} hrs',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: cBlue,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  if (photoUrl != null) ...[
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        photoUrl,
                                        height: 100,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (_, child, progress) {
                                          if (progress == null) {
                                            return child;
                                          }

                                          return Container(
                                            height: 100,
                                            color: cSlate,
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                color: cPurple,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (_, __, ___) {
                                          return Container(
                                            height: 50,
                                            color: cSlate,
                                            child: const Center(
                                              child: Icon(
                                                Icons.broken_image_rounded,
                                                color: cMuted,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],

                                  if (d['shift_notes'] != null &&
                                      (d['shift_notes'] as String)
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: cSlate,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.notes_rounded,
                                            color: cMuted,
                                            size: 13,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              d['shift_notes'],
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: cNavyMid,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ─── MANAGER TIMESHEETS SCREEN ─────────────────────────────
class _ManagerTimesheetsScreen extends StatefulWidget {
  final AppUser manager;
  final VoidCallback onBack, onLogout;
  const _ManagerTimesheetsScreen({
    required this.manager,
    required this.onBack,
    required this.onLogout,
  });
  @override
  State<_ManagerTimesheetsScreen> createState() =>
      _ManagerTimesheetsScreenState();
}

class _ManagerTimesheetsScreenState extends State<_ManagerTimesheetsScreen> {
  bool loading = true;
  List<Map<String, dynamic>> submissions = [];
  String err = '';
  late DateTime fnStart, fnEnd;
  String? expandedId;

  @override
  void initState() {
    super.initState();
    fnStart = fortnightStart(DateTime.now());
    fnEnd = fortnightEnd(fnStart);
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final s = await SupabaseService.getAllSubmissionsForFortnight(fnStart);
      s.sort((a, b) {
        const order = {'review': 0, 'pending': 1, 'rejected': 2, 'approved': 3};
        return (order[a['status']] ?? 4).compareTo(order[b['status']] ?? 4);
      });
      setState(() {
        submissions = s;
        loading = false;
      });
    } catch (e) {
      setState(() {
        err = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _review(String id, String status, String comment) async {
    try {
      await SupabaseService.reviewTimesheet(
        id: id,
        status: status,
        comment: comment,
      );
      _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: cRed),
        );
    }
  }

  Future<void> _savePayroll(Map<String, dynamic> ts) async {
    try {
      await SupabaseService.savePayrollSummary(
        userEmail: ts['user_email'],
        userName: ts['user_name'],
        branchName: ts['branch_name'] ?? '',
        fnStart: fnStart,
        fnEnd: fnEnd,
        totalHours: (ts['total_hours'] as num).toDouble(),
        savedBy: widget.manager.name,
      );
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payroll saved for ${ts['user_name']}'),
            backgroundColor: cGreen,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: cRed),
        );
    }
  }

  void _showReviewDialog(Map<String, dynamic> ts) {
    final commentCtrl = TextEditingController(
      text: ts['manager_comment'] ?? '',
    );
    String selectedStatus = ts['status'] ?? 'pending';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Review: ${ts['user_name']}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: cNavyMid,
              fontSize: 16,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: ['approved', 'rejected', 'review']
                    .map(
                      (s) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: GestureDetector(
                            onTap: () => setDlg(() => selectedStatus = s),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selectedStatus == s ? cNavyMid : cSlate,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedStatus == s
                                      ? cNavyMid
                                      : cBorder,
                                ),
                              ),
                              child: Text(
                                s[0].toUpperCase() + s.substring(1),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: selectedStatus == s
                                      ? Colors.white
                                      : cMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Manager comment (optional)',
                  hintStyle: const TextStyle(color: cMuted, fontSize: 12),
                  filled: true,
                  fillColor: cSlate,
                  contentPadding: const EdgeInsets.all(10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: cBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: cBorder),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _review(ts['id'], selectedStatus, commentCtrl.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: cNavyMid,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppHeader(onLogout: widget.onLogout),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A8A), cBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: widget.onBack,
              child: const Row(
                children: [
                  Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white70,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Back',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Time Sheets',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            Text(
              '${fmtDateShort(fnStart)} – ${fmtDate(fnEnd)} · ${submissions.length} submitted',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
      Expanded(
        child: _bgGradient(
          child: loading
              ? const Center(child: CircularProgressIndicator(color: cBlue))
              : err.isNotEmpty
              ? Center(
                  child: Text(
                    'Error: $err',
                    style: const TextStyle(color: cRed),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: cBlue,
                  child: submissions.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inbox_rounded,
                                color: cMuted,
                                size: 48,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No timesheets submitted yet.',
                                style: TextStyle(
                                  color: cMuted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: submissions.length,
                          itemBuilder: (_, i) {
                            final ts = submissions[i];
                            final status = ts['status'] ?? 'pending';
                            final isExpanded = expandedId == ts['id'];
                            final totalHrs =
                                (ts['total_hours'] as num?)?.toDouble() ?? 0;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: raisedCard(
                                radius: 14,
                                child: Column(
                                  children: [
                                    InkWell(
                                      onTap: () => setState(
                                        () => expandedId = isExpanded
                                            ? null
                                            : ts['id'],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF1E3A8A),
                                                    cBlue,
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(22),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  (ts['user_name'] ?? '?')[0]
                                                      .toUpperCase(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    ts['user_name'] ??
                                                        'Unknown',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 14,
                                                      color: cText,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    '${totalHrs.toStringAsFixed(1)} hrs · Submitted ${_fmtDT(ts['submitted_at'])}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: cMuted,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  StatusBadge(status),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              isExpanded
                                                  ? Icons.expand_less
                                                  : Icons.expand_more,
                                              color: cMuted,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isExpanded)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          14,
                                          0,
                                          14,
                                          14,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Divider(
                                              height: 1,
                                              color: cBorder,
                                            ),
                                            const SizedBox(height: 12),
                                            raisedCard(
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Column(
                                                  children: [
                                                    _SummaryRow(
                                                      label: 'Week 1',
                                                      value:
                                                          '${(ts['week1_hours'] as num?)?.toStringAsFixed(1) ?? '0.0'} hrs',
                                                      bold: false,
                                                    ),
                                                    const SizedBox(height: 6),
                                                    _SummaryRow(
                                                      label: 'Week 2',
                                                      value:
                                                          '${(ts['week2_hours'] as num?)?.toStringAsFixed(1) ?? '0.0'} hrs',
                                                      bold: false,
                                                    ),
                                                    const Divider(
                                                      height: 16,
                                                      color: cBorder,
                                                    ),
                                                    _SummaryRow(
                                                      label: 'Total',
                                                      value:
                                                          '${totalHrs.toStringAsFixed(1)} hrs',
                                                      bold: true,
                                                      valueColor: cBlue,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: GestureDetector(
                                                    onTap: () =>
                                                        _showReviewDialog(ts),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 10,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            const LinearGradient(
                                                              colors: [
                                                                cNavyMid,
                                                                cNavy,
                                                              ],
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: const Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .rate_review_rounded,
                                                            color: Colors.white,
                                                            size: 14,
                                                          ),
                                                          SizedBox(width: 6),
                                                          Text(
                                                            'Review',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: GestureDetector(
                                                    onTap: () =>
                                                        _savePayroll(ts),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 10,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            const LinearGradient(
                                                              colors: [
                                                                Color(
                                                                  0xFF065F46,
                                                                ),
                                                                cGreen,
                                                              ],
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: const Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons.save_rounded,
                                                            color: Colors.white,
                                                            size: 14,
                                                          ),
                                                          SizedBox(width: 6),
                                                          Text(
                                                            'Save Payroll',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ),
    ],
  );
}
