import 'package:flutter/material.dart';
import 'dart:async' show TimeoutException;
import 'dart:io' show File;
import 'dart:math' show sin, cos, sqrt, atan2, pi;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

// ─── Supabase credentials ──────────────────────────────────
const String kSupabaseUrl     = 'https://lxhlodhnlmwyjjwslaln.supabase.co';
const String kSupabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4aGxvZGhubG13eWpqd3NsYWxuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA5OTcxMTgsImV4cCI6MjA5NjU3MzExOH0.yH-wHSiBXZqedwgEac2OYIuYo2qVa0QlJkim2f1jtUI';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);
  runApp(const ModeRentalsApp());
}

// ─── Supabase client shorthand ─────────────────────────────
final _supabase = Supabase.instance.client;

// ─── Colours ───────────────────────────────────────────────
const Color cNavy        = Color(0xFF0F172A);
const Color cNavyMid     = Color(0xFF1E293B);
const Color cNavyLight   = Color(0xFF334155);
const Color cIndigo      = Color(0xFF4338CA);
const Color cIndigoDark  = Color(0xFF1E1B4B);
const Color cPurple      = Color(0xFF6366F1);
const Color cSlate       = Color(0xFFF1F5F9);
const Color cSlate2      = Color(0xFFE8EEF5);
const Color cBorder      = Color(0xFFE2E8F0);
const Color cMuted       = Color(0xFF94A3B8);
const Color cText        = Color(0xFF0F172A);
const Color cGreen       = Color(0xFF16A34A);
const Color cGreenDark   = Color(0xFF14532D);
const Color cGreenLight  = Color(0xFFDCFCE7);
const Color cGreenBorder = Color(0xFF86EFAC);
const Color cRed         = Color(0xFFDC2626);
const Color cRedDark     = Color(0xFFB91C1C);
const Color cRedLight    = Color(0xFFFCA5A5);
const Color cRedBg       = Color(0x1FEF4444);
const Color cRedBorder   = Color(0x4DEF4444);
const Color cAmberLight  = Color(0xFFFEF3C7);
const Color cAmberText   = Color(0xFF92400E);
const Color cVioletLight = Color(0xFFEDE9FE);
const Color cVioletText  = Color(0xFF4C1D95);
const Color cGreenText   = Color(0xFF166534);
const Color cBlue        = Color(0xFF1D4ED8);
const Color cOrange      = Color(0xFFEA580C);
const Color cOrangeDark  = Color(0xFF9A3412);

// ─── Supabase Service ──────────────────────────────────────
class SupabaseService {

  static Future<String> uploadPhoto({
    required File photo,
    required String userEmail,
    required DateTime timestamp,
  }) async {
    final safe     = userEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final fileName = '${safe}_${timestamp.millisecondsSinceEpoch}.jpg';
    final path     = 'clockin_photos/$fileName';
    final bytes    = await photo.readAsBytes();
    await _supabase.storage.from('clockin-photos').uploadBinary(
      path, bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
    );
    return _supabase.storage.from('clockin-photos').getPublicUrl(path);
  }

  static Future<int> saveClockIn({
    required AppUser user,
    required Branch branch,
    required double lat,
    required double lng,
    required DateTime clockInTime,
    required String photoUrl,
  }) async {
    final res = await _supabase.from('shift_records').insert({
      'user_email'     : user.email,
      'user_name'      : user.name,
      'user_role'      : user.role,
      'branch_name'    : branch.name,
      'branch_address' : branch.address,
      'lat'            : lat,
      'lng'            : lng,
      'clock_in_time'  : clockInTime.toIso8601String(),
      'photo_url'      : photoUrl,
      'shift_status'   : 'active',
    }).select('id').single();
    return res['id'] as int;
  }

  static Future<void> saveClockOut({
    required int recordId,
    required DateTime clockOutTime,
    required String notes,
    required double shiftHours,
  }) async {
    await _supabase.from('shift_records').update({
      'clock_out_time' : clockOutTime.toIso8601String(),
      'shift_status'   : 'completed',
      'shift_notes'    : notes,
      'shift_hours'    : shiftHours,
    }).eq('id', recordId);
  }

  static Future<List<Map<String, dynamic>>> getUserRecords(String email) async {
    final res = await _supabase
        .from('shift_records')
        .select()
        .eq('user_email', email)
        .order('clock_in_time', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<List<Map<String, dynamic>>> getAllRecords() async {
    final res = await _supabase
        .from('shift_records')
        .select()
        .order('clock_in_time', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }
}

// ─── GPS Branch Model ──────────────────────────────────────
class Branch {
  final String name, address;
  final double lat, lng, radiusMeters;
  const Branch({required this.name, required this.address,
      required this.lat, required this.lng, this.radiusMeters = 1000});
}

const List<Branch> kBranches = [
  Branch(name: 'Auckland Airport',
      address: '110 Montgomerie Rd, Airport Oaks, Mangere, Auckland 2022',
      lat: -37.00468, lng: 174.78486, radiusMeters: 1000),
  Branch(name: 'Auckland City',
      address: '26 Te Taou Crescent, Auckland Central, Auckland 1010',
      lat: -36.84820, lng: 174.76330, radiusMeters: 1000),
  Branch(name: 'Epsom',
      address: '69 Onslow Avenue, Epsom, Auckland 1023',
      lat: -36.88750, lng: 174.77130, radiusMeters: 1000),
];

double haversineDistance(double lat1, double lng1, double lat2, double lng2) {
  const R = 6371000.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLng = (lng2 - lng1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
          sin(dLng / 2) * sin(dLng / 2);
  return R * 2 * atan2(sqrt(a), sqrt(1 - a));
}

// ─── Models ────────────────────────────────────────────────
class ClockInRecord {
  final DateTime timestamp;
  final double lat, lng;
  final Branch branch;
  final File? photo;
  int? supabaseId;
  ClockInRecord({required this.timestamp, required this.lat,
      required this.lng, required this.branch, this.photo, this.supabaseId});
}

class AppUser {
  final int id;
  final String name;
  String email, password;
  final String role;
  AppUser({required this.id, required this.name,
      required this.email, required this.password, required this.role});
}

// ─── App Root ──────────────────────────────────────────────
class ModeRentalsApp extends StatefulWidget {
  const ModeRentalsApp({super.key});
  @override State<ModeRentalsApp> createState() => _ModeRentalsAppState();
}

class _ModeRentalsAppState extends State<ModeRentalsApp> {
  final List<AppUser> users = [
    AppUser(id:1, name:'Admin User',   email:'hmcsampath@hotmail.com', password:'Admin@123',   role:'Admin'),
    AppUser(id:2, name:'Manager User', email:'hmcsampath@hotmail.com', password:'Manager@123', role:'Manager'),
    AppUser(id:3, name:'Staff User',   email:'hmcsampath@hotmail.com', password:'Staff@123',   role:'Staff'),
  ];
  String screen = 'login';
  AppUser? currentUser;

  void login(AppUser u)   => setState(() { currentUser = u; screen = u.role.toLowerCase(); });
  void logout()           => setState(() { currentUser = null; screen = 'login'; });
  void goForgot()         => setState(() { screen = 'forgot'; });
  void goLogin()          => setState(() { screen = 'login'; });
  void addUser(AppUser u) => setState(() => users.add(u));

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Mode Rentals',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'SF Pro Display', scaffoldBackgroundColor: cSlate,
        colorScheme: ColorScheme.fromSeed(seedColor: cIndigo)),
    home: Scaffold(backgroundColor: cSlate, body: SafeArea(
      child: switch (screen) {
        'forgot'  => ForgotScreen(onBack: goLogin),
        'staff'   => StaffHome(user: currentUser!, onLogout: logout),
        'manager' => ManagerHome(user: currentUser!, users: users, onLogout: logout),
        'admin'   => AdminHome(user: currentUser!, users: users, onAddUser: addUser, onLogout: logout),
        _         => LoginScreen(users: users, onLogin: login, onForgot: goForgot),
      })),
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
  decoration: const BoxDecoration(gradient: LinearGradient(
      colors: [cSlate, cSlate2], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
  child: child);

Widget raisedCard({required Widget child, double radius = 12}) => Container(
  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: cBorder),
    boxShadow: [BoxShadow(color: cNavy.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 3)),
      const BoxShadow(color: cBorder, blurRadius: 0, offset: Offset(0, 3)),
      BoxShadow(color: Colors.white.withOpacity(0.9), blurRadius: 0, offset: const Offset(0, 1))]),
  child: child);

String _fmtDT(String? iso) {
  if (iso == null) return '--';
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '--';
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final m = dt.minute.toString().padLeft(2,'0');
  final p = dt.hour < 12 ? 'AM' : 'PM';
  return '${dt.day} ${months[dt.month-1]} ${dt.year}  $h:$m $p';
}

// ─── App Header ────────────────────────────────────────────
class AppHeader extends StatelessWidget {
  final VoidCallback? onLogout;
  const AppHeader({super.key, this.onLogout});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
    decoration: const BoxDecoration(gradient: LinearGradient(
        colors: [cNavyMid, cNavy], begin: Alignment.topLeft, end: Alignment.bottomRight)),
    child: Row(children: [
      Container(width: 22, height: 3, decoration: BoxDecoration(
          color: const Color(0xFF818CF8), borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 6),
      const Text('mode', style: TextStyle(color: Color(0xFF818CF8), fontSize: 22,
          fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      const SizedBox(width: 2),
      const Padding(padding: EdgeInsets.only(bottom: 8),
          child: Text('TM', style: TextStyle(color: Color(0xFF818CF8), fontSize: 8, fontWeight: FontWeight.w700))),
      const Spacer(),
      if (onLogout != null)
        GestureDetector(onTap: onLogout,
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: cRedBg, border: Border.all(color: cRedBorder),
                borderRadius: BorderRadius.circular(8)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.logout_rounded, color: cRedLight, size: 14), SizedBox(width: 5),
              Text('Sign Out', style: TextStyle(color: cRedLight, fontSize: 11, fontWeight: FontWeight.w700))]))),
    ]));
}

// ─── Shared Widgets ────────────────────────────────────────
class RoleBadge extends StatelessWidget {
  final String role;
  const RoleBadge(this.role, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = {'Admin':[cAmberLight,cAmberText],'Manager':[cVioletLight,cVioletText],
        'Staff':[cGreenLight,cGreenText]}[role] ?? [Colors.grey.shade200, Colors.grey.shade700];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [s[0] as Color, (s[0] as Color).withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: (s[1] as Color).withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 1))]),
      child: Text(role, style: TextStyle(color: s[1] as Color, fontWeight: FontWeight.w700, fontSize: 11)));
  }
}

class StyledInput extends StatelessWidget {
  final String hint; final TextEditingController ctrl;
  final bool obscure; final Widget? suffix; final TextInputType keyboard;
  const StyledInput({super.key, required this.hint, required this.ctrl,
      this.obscure=false, this.suffix, this.keyboard=TextInputType.text});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cBorder),
        boxShadow: [BoxShadow(color: cNavy.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]),
    child: TextField(controller: ctrl, obscureText: obscure, keyboardType: keyboard,
      style: const TextStyle(fontSize: 14, color: cText),
      decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: cMuted, fontSize: 14),
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none)));
}

class InputLabel extends StatelessWidget {
  final String text;
  const InputLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 5),
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))));
}

class PrimaryButton extends StatelessWidget {
  final String label; final VoidCallback onTap;
  final List<Color> colors; final Color shadowColor;
  const PrimaryButton({super.key, required this.label, required this.onTap,
      this.colors = const [Color(0xFF312E81), cIndigo], this.shadowColor = cIndigoDark});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: colors.last.withOpacity(0.45), blurRadius: 10, offset: const Offset(0, 4)),
          BoxShadow(color: shadowColor, blurRadius: 0, offset: const Offset(0, 3))]),
      child: Text(label, textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))));
}

class ErrorBox extends StatelessWidget {
  final String msg;
  const ErrorBox(this.msg, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFFDECEA),
        border: Border.all(color: cRed.withOpacity(0.4)), borderRadius: BorderRadius.circular(10)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.warning_amber_rounded, color: cRed, size: 18), const SizedBox(width: 10),
      Expanded(child: Text(msg, style: const TextStyle(color: cRed, fontSize: 12, height: 1.5)))]));
}

class SuccessBox extends StatelessWidget {
  final String msg;
  const SuccessBox(this.msg, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: cGreenLight, border: Border.all(color: cGreenBorder),
        borderRadius: BorderRadius.circular(8)),
    child: Row(children: [const Icon(Icons.check_circle_outline, color: cGreen, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(color: cGreenText, fontSize: 12)))]));
}

class StatCard extends StatelessWidget {
  final IconData icon; final String label; final int value;
  const StatCard({super.key, required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => raisedCard(child: Padding(padding: const EdgeInsets.all(14),
    child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: cSlate, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: cNavyMid, size: 22)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: cNavyMid)),
        Text(label, style: const TextStyle(fontSize: 11, color: cMuted))])])));
}

class UserRow extends StatelessWidget {
  final AppUser u; final bool showRole;
  const UserRow({super.key, required this.u, this.showRole = false});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    child: raisedCard(radius: 10, child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF312E81), cIndigo]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: cIndigo.withOpacity(0.35), blurRadius: 6, offset: const Offset(0, 2))]),
          child: Center(child: Text(u.name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: cText), overflow: TextOverflow.ellipsis),
          Text(u.email, style: const TextStyle(fontSize: 11, color: cMuted), overflow: TextOverflow.ellipsis)])),
        if (showRole) ...[const SizedBox(width: 6), RoleBadge(u.role)]]))));
}

class _SummaryRow extends StatelessWidget {
  final String label, value; final bool bold; final Color? valueColor;
  const _SummaryRow({required this.label, required this.value, required this.bold, this.valueColor});
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: TextStyle(fontSize: 13, color: bold ? cText : cMuted,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
    Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        color: valueColor ?? (bold ? cText : cNavyMid)))]);
}

// ─── LOGIN ─────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  final List<AppUser> users; final void Function(AppUser) onLogin; final VoidCallback onForgot;
  const LoginScreen({super.key, required this.users, required this.onLogin, required this.onForgot});
  @override State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final eCtrl = TextEditingController(), pCtrl = TextEditingController();
  bool showPw = false; String err = '';
  String? _validate() {
    if (eCtrl.text.trim().isEmpty) return 'Email is required.';
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(eCtrl.text.trim())) return 'Invalid email format.';
    if (pCtrl.text.isEmpty) return 'Password is required.';
    if (pCtrl.text.length < 8) return 'Password must be at least 8 characters.';
    return null;
  }
  void _login() {
    final e = _validate(); if (e != null) { setState(() => err = e); return; }
    final m = widget.users.where((u) => u.email == eCtrl.text.trim() && u.password == pCtrl.text).firstOrNull;
    if (m == null) { setState(() => err = 'Incorrect email or password.'); return; }
    widget.onLogin(m);
  }
  @override
  Widget build(BuildContext context) => Column(children: [
    const AppHeader(),
    Expanded(child: _bgGradient(child: SingleChildScrollView(padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(width: 76, height: 76,
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [cNavyMid, cNavyLight],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: cNavy.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))]),
          child: const Center(child: Text('🚗', style: TextStyle(fontSize: 38)))),
        const SizedBox(height: 22),
        const Text('Welcome to Mode', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: cText)),
        const SizedBox(height: 6),
        const Text('Sign in to your account', style: TextStyle(color: cMuted, fontSize: 14)),
        const SizedBox(height: 28),
        StyledInput(hint: 'Email address', ctrl: eCtrl, keyboard: TextInputType.emailAddress),
        StyledInput(hint: 'Password', ctrl: pCtrl, obscure: !showPw,
          suffix: IconButton(icon: Icon(showPw ? Icons.visibility_off : Icons.visibility, color: cMuted, size: 20),
              onPressed: () => setState(() => showPw = !showPw))),
        if (err.isNotEmpty) ErrorBox(err),
        PrimaryButton(label: 'Sign in', onTap: _login),
        const SizedBox(height: 16),
        GestureDetector(onTap: widget.onForgot,
          child: const Text('Forgot password?', style: TextStyle(color: cPurple, fontWeight: FontWeight.w700,
              fontSize: 13, decoration: TextDecoration.underline))),
        const SizedBox(height: 32),
        const Text('Secured · Privacy Act 2020 compliant', style: TextStyle(color: cMuted, fontSize: 11))])))]);
}

// ─── FORGOT PASSWORD ───────────────────────────────────────
class ForgotScreen extends StatefulWidget {
  final VoidCallback onBack;
  const ForgotScreen({super.key, required this.onBack});
  @override State<ForgotScreen> createState() => _ForgotScreenState();
}
class _ForgotScreenState extends State<ForgotScreen> {
  final ctrl = TextEditingController(); bool sent = false; String err = '';
  void _send() {
    final e = ctrl.text.trim();
    if (e.isEmpty) { setState(() => err = 'Please enter your email.'); return; }
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(e)) { setState(() => err = 'Invalid email format.'); return; }
    setState(() { err = ''; sent = true; });
  }
  @override
  Widget build(BuildContext context) => Column(children: [
    const AppHeader(),
    Expanded(child: _bgGradient(child: SingleChildScrollView(padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextButton.icon(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Back to Sign in', style: TextStyle(fontWeight: FontWeight.w700)),
            style: TextButton.styleFrom(foregroundColor: cPurple, padding: EdgeInsets.zero)),
        const SizedBox(height: 20),
        Container(width: 52, height: 52,
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [cNavyMid, cNavyLight]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: cNavy.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]),
          child: const Center(child: Icon(Icons.lock_reset_rounded, color: Color(0xFF818CF8), size: 26))),
        const SizedBox(height: 14),
        const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: cText)),
        const SizedBox(height: 6),
        const Text("Enter your email and we'll send you a reset link.", style: TextStyle(color: cMuted, fontSize: 13)),
        const SizedBox(height: 24),
        if (!sent) ...[
          const InputLabel('Email Address'),
          StyledInput(hint: 'Your email address', ctrl: ctrl, keyboard: TextInputType.emailAddress),
          if (err.isNotEmpty) ErrorBox(err),
          PrimaryButton(label: 'Send Reset Link', onTap: _send,
              colors: [cPurple, const Color(0xFF4F46E5)], shadowColor: const Color(0xFF3730A3)),
        ] else Container(padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: cGreenLight, border: Border.all(color: cGreenBorder), borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Container(width: 52, height: 52,
              decoration: BoxDecoration(color: cGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(26)),
              child: const Icon(Icons.mark_email_read_rounded, color: cGreen, size: 28)),
            const SizedBox(height: 12),
            const Text('Reset link sent!', style: TextStyle(fontWeight: FontWeight.w800, color: cGreenText, fontSize: 16)),
            const SizedBox(height: 6),
            Text('Check ${ctrl.text.trim()} for your password reset link.',
                style: const TextStyle(fontSize: 12, color: cGreenText), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Back to Sign in', onTap: widget.onBack,
                colors: [cGreen, const Color(0xFF15803D)], shadowColor: cGreenDark)])])))));
}

// ─── STAFF HOME ────────────────────────────────────────────
class StaffHome extends StatefulWidget {
  final AppUser user; final VoidCallback onLogout;
  const StaffHome({super.key, required this.user, required this.onLogout});
  @override State<StaffHome> createState() => _StaffHomeState();
}
class _StaffHomeState extends State<StaffHome> {
  String? subScreen;
  ClockInRecord? lastClockIn;
  @override
  Widget build(BuildContext context) {
    if (subScreen == 'clockin')
      return ClockInScreen(user: widget.user,
          onBack: () => setState(() => subScreen = null),
          onLogout: widget.onLogout,
          onClockedIn: (r) => setState(() { lastClockIn = r; subScreen = null; }));
    if (subScreen == 'clockout')
      return ClockOutScreen(user: widget.user, clockInRecord: lastClockIn,
          onBack: () => setState(() => subScreen = null),
          onLogout: widget.onLogout,
          onClockedOut: () => setState(() { lastClockIn = null; subScreen = null; }));
    if (subScreen == 'timesheet')
      return TimesheetScreen(user: widget.user,
          onBack: () => setState(() => subScreen = null), onLogout: widget.onLogout);
    if (subScreen == 'history')
      return ShiftHistoryScreen(user: widget.user,
          onBack: () => setState(() => subScreen = null), onLogout: widget.onLogout);

    return Column(children: [
      AppHeader(onLogout: widget.onLogout),
      Expanded(child: _bgGradient(child: SingleChildScrollView(padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: double.infinity, padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [cNavyMid, cNavy], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: cNavy.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4)),
                const BoxShadow(color: cNavy, blurRadius: 0, offset: Offset(0, 4))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_greeting()}, ${widget.user.name.split(' ').first} 👋',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
              const SizedBox(height: 4),
              const Text('Mode Rentals · New Zealand', style: TextStyle(color: Colors.white60, fontSize: 13))])),
          const SizedBox(height: 24),
          const Text('What would you like to do?',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: cNavyLight)),
          const SizedBox(height: 14),
          _NavTile(icon: Icons.login_rounded, label: 'Clock-In',
              subtitle: 'Start your shift & verify location',
              gradient: [const Color(0xFF065F46), cGreen], shadowColor: const Color(0xFF064E3B),
              onTap: () => setState(() => subScreen = 'clockin')),
          const SizedBox(height: 12),
          _NavTile(icon: Icons.logout_rounded, label: 'Clock-Out & Shift Summary',
              subtitle: 'End your shift & review hours',
              gradient: [const Color(0xFF7F1D1D), cRedDark], shadowColor: const Color(0xFF450A0A),
              onTap: () => setState(() => subScreen = 'clockout')),
          const SizedBox(height: 12),
          _NavTile(icon: Icons.calendar_month_rounded, label: 'Fortnightly Timesheet',
              subtitle: 'View & submit your timesheet',
              gradient: [const Color(0xFF1E3A8A), cBlue], shadowColor: const Color(0xFF1E3A5F),
              onTap: () => setState(() => subScreen = 'timesheet')),
          const SizedBox(height: 12),
          _NavTile(icon: Icons.history_rounded, label: 'My Shift History',
              subtitle: 'View your past clock-in records',
              gradient: [const Color(0xFF4A1D96), cPurple], shadowColor: const Color(0xFF2E1065),
              onTap: () => setState(() => subScreen = 'history')),
        ])))),
    ]);
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon; final String label, subtitle;
  final List<Color> gradient; final Color shadowColor; final VoidCallback onTap;
  const _NavTile({required this.icon, required this.label, required this.subtitle,
      required this.gradient, required this.shadowColor, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(width: double.infinity, padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: gradient.last.withOpacity(0.45), blurRadius: 12, offset: const Offset(0, 5)),
          BoxShadow(color: shadowColor, blurRadius: 0, offset: const Offset(0, 5)),
          BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 0, offset: const Offset(0, 1))]),
      child: Row(children: [
        Container(width: 52, height: 52,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white24)),
          child: Icon(icon, color: Colors.white, size: 26)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12))])),
        const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 22)])));
}

// ═══════════════════════════════════════════════════════════
// ─── CLOCK IN SCREEN ───────────────────────────────────────
// ═══════════════════════════════════════════════════════════
enum GpsState { idle, loading, granted, denied, outOfRange }

class ClockInScreen extends StatefulWidget {
  final AppUser user; final VoidCallback onBack, onLogout;
  final void Function(ClockInRecord) onClockedIn;
  const ClockInScreen({super.key, required this.user, required this.onBack,
      required this.onLogout, required this.onClockedIn});
  @override State<ClockInScreen> createState() => _ClockInScreenState();
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
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${days[now.weekday-1]} ${now.day} ${months[now.month-1]} ${now.year}';
  }

  void _onBranchSelected(Branch? b) => setState(() {
    selectedBranch = b; gpsState = GpsState.idle; detectedBranch = null;
    capturedLat = null; capturedLng = null; gpsTimestamp = null;
    gpsError = ''; capturedPhoto = null; clockedIn = false;
  });

  Future<void> _takePhoto() async {
    try {
      final XFile? x = await _picker.pickImage(source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front, imageQuality: 80, maxWidth: 800);
      if (x != null && mounted) setState(() => capturedPhoto = File(x.path));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e'), backgroundColor: cRed));
    }
  }

  void _onVerifyTapped() {
    if (selectedBranch == null) return;
    setState(() { gpsState = GpsState.loading; gpsError = ''; detectedBranch = null; });
    _requestGps();
  }

  Future<void> _requestGps() async {
    if (selectedBranch == null) { if (mounted) setState(() => gpsState = GpsState.idle); return; }
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        setState(() { gpsState = GpsState.denied;
          gpsError = 'Location services are disabled.\nGo to Settings → Privacy → Location Services.'; }); return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (!mounted) return;
      if (perm == LocationPermission.deniedForever) {
        setState(() { gpsState = GpsState.denied;
          gpsError = 'Location permanently denied.\nGo to Settings → Mode Rentals → Location.'; }); return;
      }
      if (perm == LocationPermission.denied) {
        setState(() { gpsState = GpsState.denied; gpsError = 'Location permission denied. Please allow and retry.'; }); return;
      }
      final p = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 20));
      if (!mounted) return;
      final dist = haversineDistance(p.latitude, p.longitude, selectedBranch!.lat, selectedBranch!.lng);
      if (dist <= selectedBranch!.radiusMeters) {
        setState(() { gpsState = GpsState.granted; detectedBranch = selectedBranch;
          capturedLat = p.latitude; capturedLng = p.longitude; gpsTimestamp = DateTime.now(); gpsError = ''; });
      } else {
        setState(() { gpsState = GpsState.outOfRange; capturedLat = p.latitude; capturedLng = p.longitude;
          gpsError = 'You are ${(dist/1000).toStringAsFixed(2)} km from "${selectedBranch!.name}".\n\n'
              'Clock-in requires you to be within 1000 m of the selected branch.\n\n'
              'Please ensure you are physically at the branch or contact your manager.'; });
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() { gpsState = GpsState.outOfRange; gpsError = 'GPS timed out. Move to an open area and retry.'; });
    } catch (e) {
      if (!mounted) return;
      setState(() { gpsState = GpsState.outOfRange; gpsError = 'Could not get GPS. Move outdoors and retry.\n\nDetail: $e'; });
    }
  }

  Future<void> _confirmClockIn() async {
    if (detectedBranch == null || capturedLat == null || capturedPhoto == null) return;
    setState(() => saving = true);
    try {
      final ts = gpsTimestamp ?? DateTime.now();
      final photoUrl = await SupabaseService.uploadPhoto(
          photo: capturedPhoto!, userEmail: widget.user.email, timestamp: ts);
      final id = await SupabaseService.saveClockIn(
          user: widget.user, branch: detectedBranch!,
          lat: capturedLat!, lng: capturedLng!,
          clockInTime: ts, photoUrl: photoUrl);
      final record = ClockInRecord(timestamp: ts, lat: capturedLat!,
          lng: capturedLng!, branch: detectedBranch!, photo: capturedPhoto, supabaseId: id);
      if (mounted) {
        setState(() { clockedIn = true; saving = false; });
        await Future.delayed(const Duration(milliseconds: 900));
        widget.onClockedIn(record);
      }
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Save failed: $e'), backgroundColor: cRed));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    AppHeader(onLogout: widget.onLogout),
    Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: const BoxDecoration(gradient: LinearGradient(
          colors: [Color(0xFF065F46), cGreen], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(onTap: widget.onBack, child: const Row(children: [
          Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 14), SizedBox(width: 4),
          Text('Back', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600))])),
        const SizedBox(height: 8),
        Text('${_greeting()}, ${widget.user.name.split(' ').first} 👋',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
        const Text('Mode Rentals · New Zealand', style: TextStyle(color: Colors.white70, fontSize: 13))])),
    Expanded(child: _bgGradient(child: SingleChildScrollView(padding: const EdgeInsets.all(16),
      child: Column(children: [
        raisedCard(radius: 16, child: Padding(padding: const EdgeInsets.all(20),
          child: Column(children: [
            Text(_timeStr(), style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: cText, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(_dateStr(), style: const TextStyle(color: cMuted, fontSize: 13)),
            const SizedBox(height: 20),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [Icon(Icons.store_rounded, color: cNavyMid, size: 15), SizedBox(width: 6),
                Text('Select your branch', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: cNavyMid))]),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: cSlate, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selectedBranch != null ? cGreenBorder : cBorder, width: 1.5)),
                child: DropdownButtonHideUnderline(child: DropdownButton<Branch>(
                  value: selectedBranch, isExpanded: true, padding: const EdgeInsets.symmetric(horizontal: 14),
                  hint: const Row(children: [Icon(Icons.location_on_outlined, color: cMuted, size: 16),
                    SizedBox(width: 8), Text('— Choose authorised location —', style: TextStyle(color: cMuted, fontSize: 13))]),
                  items: kBranches.map((b) => DropdownMenuItem<Branch>(value: b,
                    child: Row(children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: cGreen, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text(b.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: cText)),
                        Text(b.address, style: const TextStyle(fontSize: 10, color: cMuted), overflow: TextOverflow.ellipsis)]))]))).toList(),
                  onChanged: _onBranchSelected))),
              if (selectedBranch != null) ...[const SizedBox(height: 6),
                Row(children: [const Icon(Icons.check_circle_rounded, color: cGreen, size: 13), const SizedBox(width: 5),
                  Expanded(child: Text(selectedBranch!.address, style: const TextStyle(fontSize: 11, color: cGreenText)))])]]),
            const SizedBox(height: 16),
            _GpsPanel(gpsState: gpsState, selectedBranch: selectedBranch, detectedBranch: detectedBranch,
                gpsError: gpsError, capturedLat: capturedLat, capturedLng: capturedLng,
                gpsTimestamp: gpsTimestamp, onVerify: _onVerifyTapped, verifyEnabled: selectedBranch != null),
            const SizedBox(height: 14),
            if (gpsState == GpsState.granted) ...[
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [Icon(Icons.camera_alt_rounded, color: cNavyMid, size: 15), SizedBox(width: 6),
                  Text('Clock-in photo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: cNavyMid))]),
                const SizedBox(height: 4),
                const Text('A photo is required. Camera only — gallery upload not allowed.',
                    style: TextStyle(fontSize: 11, color: cMuted, height: 1.4)),
                const SizedBox(height: 10),
                capturedPhoto != null
                    ? Stack(children: [
                        ClipRRect(borderRadius: BorderRadius.circular(12),
                          child: Image.file(capturedPhoto!, width: double.infinity, height: 160, fit: BoxFit.cover)),
                        Positioned(top: 8, right: 8, child: GestureDetector(onTap: _takePhoto,
                          child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: cNavy.withOpacity(0.75), borderRadius: BorderRadius.circular(20)),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.refresh_rounded, color: Colors.white, size: 13), SizedBox(width: 4),
                              Text('Retake', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))])))),
                        Positioned(bottom: 8, left: 8, child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: cGreen.withOpacity(0.85), borderRadius: BorderRadius.circular(8)),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 12), SizedBox(width: 4),
                            Text('Photo captured ✓', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))])))])
                    : GestureDetector(onTap: _takePhoto,
                        child: Container(width: double.infinity, height: 110,
                          decoration: BoxDecoration(color: cSlate, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder, width: 1.5)),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Container(width: 48, height: 48,
                              decoration: BoxDecoration(gradient: const LinearGradient(colors: [cNavyMid, cNavyLight]),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [BoxShadow(color: cNavy.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22)),
                            const SizedBox(height: 8),
                            const Text('Tap to take photo', style: TextStyle(color: cNavyMid, fontSize: 13, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            const Text('Camera only · no gallery upload', style: TextStyle(color: cMuted, fontSize: 10))])))]),
              const SizedBox(height: 14)],
            saving
                ? Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(color: cGreenLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: cGreenBorder)),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: cGreen)),
                      SizedBox(width: 10), Text('Uploading photo & saving…', style: TextStyle(color: cGreenText, fontWeight: FontWeight.w700, fontSize: 13))]))
                : clockedIn
                    ? Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(color: cGreenLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: cGreenBorder)),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.check_circle_rounded, color: cGreen, size: 20), SizedBox(width: 8),
                          Text('Clocked In & Saved ✓', style: TextStyle(color: cGreenText, fontWeight: FontWeight.w800, fontSize: 15))]))
                    : _ClockInButton(gpsState: gpsState, photoTaken: capturedPhoto != null,
                        clockedIn: clockedIn, branchSelected: selectedBranch != null, onTap: _confirmClockIn)]))),
        const SizedBox(height: 16),
        raisedCard(radius: 16, child: Padding(padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('This fortnight', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: cText)),
            const SizedBox(height: 12),
            _SummaryRow(label: 'Last week', value: '40.0 hrs', bold: false), const SizedBox(height: 8),
            _SummaryRow(label: 'This week so far', value: '16.5 hrs', bold: false),
            const Divider(height: 20, color: cBorder),
            _SummaryRow(label: 'Total', value: '56.5 hrs', bold: true, valueColor: cBlue)]))),
        const SizedBox(height: 20)]))));
}

// ─── GPS Panel ─────────────────────────────────────────────
class _GpsPanel extends StatelessWidget {
  final GpsState gpsState; final Branch? selectedBranch, detectedBranch;
  final String gpsError; final double? capturedLat, capturedLng;
  final DateTime? gpsTimestamp; final VoidCallback onVerify; final bool verifyEnabled;
  const _GpsPanel({required this.gpsState, required this.selectedBranch, required this.detectedBranch,
      required this.gpsError, required this.capturedLat, required this.capturedLng,
      required this.gpsTimestamp, required this.onVerify, required this.verifyEnabled});

  String _fmtTs(DateTime? ts) {
    if (ts == null) return '';
    final h = ts.hour % 12 == 0 ? 12 : ts.hour % 12;
    final m = ts.minute.toString().padLeft(2,'0');
    final s = ts.second.toString().padLeft(2,'0');
    return '$h:$m:$s ${ts.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    if (gpsState == GpsState.idle) {
      return GestureDetector(onTap: verifyEnabled ? onVerify : null,
        child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(color: verifyEnabled ? cNavyMid : cSlate,
              borderRadius: BorderRadius.circular(10), border: Border.all(color: verifyEnabled ? cNavyLight : cBorder)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.my_location_rounded, color: verifyEnabled ? Colors.white : cMuted, size: 18), const SizedBox(width: 8),
            Text(verifyEnabled ? 'Tap to verify location' : 'Select a branch first',
                style: TextStyle(color: verifyEnabled ? Colors.white : cMuted, fontSize: 13, fontWeight: FontWeight.w600))])));
    }
    if (gpsState == GpsState.loading) {
      return Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: cSlate, borderRadius: BorderRadius.circular(10), border: Border.all(color: cBorder)),
        child: const Column(children: [
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: cGreen)),
          SizedBox(height: 8), Text('Acquiring GPS signal…', style: TextStyle(color: cMuted, fontSize: 12))]));
    }
    if (gpsState == GpsState.granted) {
      return Container(width: double.infinity, padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: cGreenLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: cGreenBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.location_on_rounded, color: cGreen, size: 16), const SizedBox(width: 6),
            Expanded(child: Text('${detectedBranch!.name} · GPS verified ✓',
                style: const TextStyle(color: cGreenText, fontWeight: FontWeight.w700, fontSize: 13)))]),
          const SizedBox(height: 6),
          Text(detectedBranch!.address, style: const TextStyle(color: cGreenText, fontSize: 11, height: 1.3)),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(6)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Icon(Icons.gps_fixed, color: cGreen, size: 12), const SizedBox(width: 4),
                Text('${capturedLat!.toStringAsFixed(5)}, ${capturedLng!.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 10, color: cGreenText, fontFamily: 'monospace'))]),
              const SizedBox(height: 3),
              Row(children: [const Icon(Icons.access_time_rounded, color: cGreen, size: 12), const SizedBox(width: 4),
                Text('Captured at ${_fmtTs(gpsTimestamp)}', style: const TextStyle(fontSize: 10, color: cGreenText))])]))]));
    }
    if (gpsState == GpsState.outOfRange) {
      return Container(width: double.infinity, padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cOrange.withOpacity(0.5))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.location_off_rounded, color: cOrange, size: 18), SizedBox(width: 8),
            Text('Location Out of Range', style: TextStyle(color: cOrangeDark, fontWeight: FontWeight.w800, fontSize: 13))]),
          const SizedBox(height: 8),
          Text(gpsError, style: const TextStyle(color: cOrangeDark, fontSize: 11.5, height: 1.55)),
          const SizedBox(height: 10),
          GestureDetector(onTap: onVerify,
            child: Container(padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [cOrange, Color(0xFFEA580C)]),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: cOrange.withOpacity(0.35), blurRadius: 6, offset: const Offset(0, 2))]),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.refresh_rounded, color: Colors.white, size: 16), SizedBox(width: 6),
                Text('Retry GPS Check', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))])))]));
    }
    // GpsState.denied
    return Container(padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFDECEA), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cRed.withOpacity(0.3))),
      child: Column(children: [
        const Row(children: [Icon(Icons.location_disabled_rounded, color: cRed, size: 16), SizedBox(width: 8),
          Text('Location Permission Denied', style: TextStyle(color: cRed, fontWeight: FontWeight.w700, fontSize: 12))]),
        const SizedBox(height: 6),
        Text(gpsError.isNotEmpty ? gpsError : 'Please enable location access in Settings.',
            style: const TextStyle(color: cRed, fontSize: 11, height: 1.4)),
        const SizedBox(height: 8),
        GestureDetector(onTap: onVerify,
          child: Container(padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [cNavyMid, cNavy]), borderRadius: BorderRadius.circular(8)),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.settings_rounded, color: Colors.white, size: 14), SizedBox(width: 6),
              Text('Open Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))])))]));
  }
}

// ─── Clock In Button ───────────────────────────────────────
class _ClockInButton extends StatelessWidget {
  final GpsState gpsState; final bool photoTaken, clockedIn, branchSelected;
  final Future<void> Function() onTap;
  const _ClockInButton({required this.gpsState, required this.photoTaken,
      required this.clockedIn, required this.branchSelected, required this.onTap});
  bool get _enabled => gpsState == GpsState.granted && photoTaken && !clockedIn;
  @override
  Widget build(BuildContext context) {
    final label = !branchSelected ? 'Select a Branch First'
        : gpsState != GpsState.granted ? 'Verify Location First'
        : !photoTaken ? 'Take Photo to Enable Clock-In' : 'Clock In';
    return Opacity(opacity: _enabled ? 1.0 : 0.45,
      child: GestureDetector(onTap: _enabled ? onTap : null,
        child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF065F46), cGreen]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _enabled ? [BoxShadow(color: cGreen.withOpacity(0.45), blurRadius: 10, offset: const Offset(0, 4)),
              const BoxShadow(color: Color(0xFF064E3B), blurRadius: 0, offset: Offset(0, 3))] : []),
          child: Text(label, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)))));
  }
}

// ─── SHIFT HISTORY SCREEN ──────────────────────────────────
class ShiftHistoryScreen extends StatefulWidget {
  final AppUser user; final VoidCallback onBack, onLogout;
  const ShiftHistoryScreen({super.key, required this.user, required this.onBack, required this.onLogout});
  @override State<ShiftHistoryScreen> createState() => _ShiftHistoryScreenState();
}
class _ShiftHistoryScreenState extends State<ShiftHistoryScreen> {
  List<Map<String,dynamic>> records = [];
  bool loading = true; String err = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await SupabaseService.getUserRecords(widget.user.email);
      if (mounted) setState(() { records = r; loading = false; });
    } catch (e) {
      if (mounted) setState(() { err = e.toString(); loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    AppHeader(onLogout: widget.onLogout),
    Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF4A1D96), cPurple],
          begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(onTap: widget.onBack, child: const Row(children: [
          Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 14), SizedBox(width: 4),
          Text('Back', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600))])),
        const SizedBox(height: 8),
        const Text('My Shift History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
        const Text('All your clock-in records', style: TextStyle(color: Colors.white70, fontSize: 13))])),
    Expanded(child: _bgGradient(child:
      loading ? const Center(child: CircularProgressIndicator(color: cPurple))
      : err.isNotEmpty ? Center(child: Text('Error: $err', style: const TextStyle(color: cRed)))
      : records.isEmpty
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.history_rounded, color: cMuted, size: 48), SizedBox(height: 12),
              Text('No shift records yet.', style: TextStyle(color: cMuted, fontSize: 15, fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text('Your clock-in records will appear here.', style: TextStyle(color: cMuted, fontSize: 12))]))
          : RefreshIndicator(onRefresh: _load, color: cPurple,
              child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: records.length,
                itemBuilder: (_, i) {
                  final d = records[i];
                  final isActive = d['shift_status'] == 'active';
                  final photoUrl = d['photo_url'] as String?;
                  return Container(margin: const EdgeInsets.only(bottom: 12),
                    child: raisedCard(radius: 14, child: Padding(padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: isActive ? cGreenLight : cSlate,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isActive ? cGreenBorder : cBorder)),
                            child: Text(isActive ? '● Active' : '✓ Completed',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                    color: isActive ? cGreenText : cMuted))),
                          const Spacer(),
                          Text(d['branch_name'] ?? '', style: const TextStyle(fontSize: 11, color: cMuted, fontWeight: FontWeight.w600))]),
                        const SizedBox(height: 10),
                        Row(children: [const Icon(Icons.login_rounded, color: cGreen, size: 14), const SizedBox(width: 6),
                          Text('In:  ${_fmtDT(d['clock_in_time'])}', style: const TextStyle(fontSize: 12, color: cText))]),
                        const SizedBox(height: 4),
                        Row(children: [const Icon(Icons.logout_rounded, color: cRed, size: 14), const SizedBox(width: 6),
                          Text('Out: ${d['clock_out_time'] != null ? _fmtDT(d['clock_out_time']) : 'Not clocked out yet'}',
                              style: TextStyle(fontSize: 12, color: d['clock_out_time'] != null ? cText : cMuted))]),
                        if (d['shift_hours'] != null) ...[const SizedBox(height: 4),
                          Row(children: [const Icon(Icons.access_time_rounded, color: cBlue, size: 14), const SizedBox(width: 6),
                            Text('Total: ${(d['shift_hours'] as num).toStringAsFixed(1)} hrs',
                                style: const TextStyle(fontSize: 12, color: cBlue, fontWeight: FontWeight.w600))])],
                        if (d['lat'] != null) ...[const SizedBox(height: 4),
                          Row(children: [const Icon(Icons.gps_fixed, color: cMuted, size: 12), const SizedBox(width: 6),
                            Text('${(d['lat'] as num).toStringAsFixed(5)}, ${(d['lng'] as num).toStringAsFixed(5)}',
                                style: const TextStyle(fontSize: 10, color: cMuted, fontFamily: 'monospace'))])],
                        if (photoUrl != null) ...[const SizedBox(height: 10),
                          ClipRRect(borderRadius: BorderRadius.circular(8),
                            child: Image.network(photoUrl, height: 100, width: double.infinity, fit: BoxFit.cover,
                              loadingBuilder: (_, child, prog) => prog == null ? child
                                  : Container(height: 100, color: cSlate, child: const Center(child: CircularProgressIndicator(color: cPurple, strokeWidth: 2))),
                              errorBuilder: (_, __, ___) => Container(height: 50, color: cSlate,
                                  child: const Center(child: Icon(Icons.broken_image_rounded, color: cMuted)))))],
                        if (d['shift_notes'] != null && (d['shift_notes'] as String).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: cSlate, borderRadius: BorderRadius.circular(6)),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Icon(Icons.notes_rounded, color: cMuted, size: 13), const SizedBox(width: 6),
                              Expanded(child: Text(d['shift_notes'], style: const TextStyle(fontSize: 11, color: cNavyMid)))]))])]))]);
                })))));
}

// ─── CLOCK OUT SCREEN ──────────────────────────────────────
class ClockOutScreen extends StatefulWidget {
  final AppUser user; final ClockInRecord? clockInRecord;
  final VoidCallback onBack, onLogout, onClockedOut;
  const ClockOutScreen({super.key, required this.user, required this.clockInRecord,
      required this.onBack, required this.onLogout, required this.onClockedOut});
  @override State<ClockOutScreen> createState() => _ClockOutScreenState();
}
class _ClockOutScreenState extends State<ClockOutScreen> {
  final noteCtrl = TextEditingController();
  bool confirmed = false, saving = false;

  String _fmt(DateTime? t) {
    if (t == null) return '--:-- --';
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2,'0');
    return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  double _shiftHours() {
    if (widget.clockInRecord == null) return 0;
    final diff = DateTime.now().difference(widget.clockInRecord!.timestamp).inMinutes - 30;
    return (diff.clamp(0, 9999) / 60);
  }

  Future<void> _confirmOut() async {
    setState(() => saving = true);
    try {
      if (widget.clockInRecord?.supabaseId != null) {
        await SupabaseService.saveClockOut(
            recordId: widget.clockInRecord!.supabaseId!,
            clockOutTime: DateTime.now(),
            notes: noteCtrl.text.trim(),
            shiftHours: _shiftHours());
      }
      if (mounted) setState(() { confirmed = true; saving = false; });
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save clock-out: $e'), backgroundColor: cRed));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    AppHeader(onLogout: widget.onLogout),
    Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF7F1D1D), cRedDark],
          begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(onTap: widget.onBack, child: const Row(children: [
          Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 14), SizedBox(width: 4),
          Text('Back', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600))])),
        const SizedBox(height: 8),
        const Text('Clock Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
        const Text('Confirm your shift end', style: TextStyle(color: Colors.white70, fontSize: 13))])),
    Expanded(child: _bgGradient(child: SingleChildScrollView(padding: const EdgeInsets.all(16),
      child: Column(children: [
        if (confirmed) ...[
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: cGreenLight, border: Border.all(color: cGreenBorder), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              const Icon(Icons.check_circle_rounded, color: cGreen, size: 52), const SizedBox(height: 12),
              const Text('Clocked Out!', style: TextStyle(fontWeight: FontWeight.w800, color: cGreenText, fontSize: 18)),
              const SizedBox(height: 6),
              Text('Shift total: ${_shiftHours().toStringAsFixed(1)} hrs', style: const TextStyle(color: cGreenText, fontSize: 14)),
              const SizedBox(height: 4),
              const Text('Saved to Supabase ✓', style: TextStyle(color: cGreenText, fontSize: 12)),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Back to Home', onTap: widget.onClockedOut,
                  colors: [cGreen, const Color(0xFF15803D)], shadowColor: cGreenDark)]))]
        else ...[
          raisedCard(radius: 16, child: Padding(padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Today's shift", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: cText)),
              const SizedBox(height: 14),
              _SummaryRow(label: 'Clocked in', value: _fmt(widget.clockInRecord?.timestamp), bold: false),
              const SizedBox(height: 8),
              _SummaryRow(label: 'Clocking out', value: _fmt(DateTime.now()), bold: false),
              const SizedBox(height: 8),
              _SummaryRow(label: 'Break deducted', value: '30 min', bold: false),
              const Divider(height: 20, color: cBorder),
              _SummaryRow(label: 'Shift total', value: '${_shiftHours().toStringAsFixed(1)} hrs', bold: true, valueColor: cBlue)]))),
          const SizedBox(height: 12),
          raisedCard(radius: 12, child: Padding(padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Icon(Icons.location_on_rounded, color: cGreen, size: 16), const SizedBox(width: 8),
                Text(widget.clockInRecord?.branch.name ?? 'Unknown',
                    style: const TextStyle(color: cGreenText, fontWeight: FontWeight.w700, fontSize: 13)),
                const Spacer(), const Text('GPS verified ✓', style: TextStyle(color: cGreen, fontSize: 11))]),
              if (widget.clockInRecord != null) ...[const SizedBox(height: 6),
                Text('${widget.clockInRecord!.lat.toStringAsFixed(5)}, ${widget.clockInRecord!.lng.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 10, color: cMuted, fontFamily: 'monospace'))]]))),
          const SizedBox(height: 12),
          raisedCard(radius: 12, child: Padding(padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Add a note (optional)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: cText)),
              const SizedBox(height: 10),
              TextField(controller: noteCtrl, maxLines: 3, style: const TextStyle(fontSize: 13, color: cText),
                decoration: InputDecoration(hintText: 'e.g. Completed vehicle drop-off at 3pm',
                  hintStyle: const TextStyle(color: cMuted, fontSize: 12),
                  filled: true, fillColor: cSlate, contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: cBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: cBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: cRed, width: 1.5))))]))),
          const SizedBox(height: 20),
          saving
              ? Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: cSlate, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: cGreen)),
                    SizedBox(width: 10), Text('Saving to Supabase…', style: TextStyle(color: cMuted, fontWeight: FontWeight.w600, fontSize: 14))]))
              : GestureDetector(onTap: _confirmOut,
                  child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7F1D1D), cRedDark]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: cRed.withOpacity(0.45), blurRadius: 10, offset: const Offset(0, 4)),
                        const BoxShadow(color: Color(0xFF450A0A), blurRadius: 0, offset: Offset(0, 3))]),
                    child: const Text('Confirm Clock Out', textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))))]])))));
}

// ─── TIMESHEET SCREEN ──────────────────────────────────────
class TimesheetScreen extends StatelessWidget {
  final AppUser user; final VoidCallback onBack, onLogout;
  const TimesheetScreen({super.key, required this.user, required this.onBack, required this.onLogout});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][now.month-1];
    return Column(children: [
      AppHeader(onLogout: onLogout),
      Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1E3A8A), cBlue],
            begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(onTap: onBack, child: const Row(children: [
            Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 14), SizedBox(width: 4),
            Text('Back', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600))])),
          const SizedBox(height: 8),
          const Text('My Timesheet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
          Text('1–14 $month ${now.year}', style: const TextStyle(color: Colors.white70, fontSize: 13))])),
      Expanded(child: _bgGradient(child: SingleChildScrollView(padding: const EdgeInsets.all(16),
        child: Column(children: [
          raisedCard(radius: 16, child: Padding(padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: cBlue, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 8), Text('Week 1 · 1–7 $month', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: cText))]),
              const SizedBox(height: 14),
              _SummaryRow(label: 'Mon 1 $month', value: '8.0 hrs', bold: false), const SizedBox(height: 7),
              _SummaryRow(label: 'Tue 2 $month', value: '8.5 hrs', bold: false), const SizedBox(height: 7),
              _SummaryRow(label: 'Wed 3 $month', value: '8.0 hrs', bold: false), const SizedBox(height: 7),
              _SummaryRow(label: 'Thu 4 $month', value: '7.5 hrs', bold: false), const SizedBox(height: 7),
              _SummaryRow(label: 'Fri 5 $month', value: '8.0 hrs', bold: false),
              const Divider(height: 20, color: cBorder),
              _SummaryRow(label: 'Week 1', value: '40.0 hrs', bold: true, valueColor: cBlue)]))),
          const SizedBox(height: 12),
          raisedCard(radius: 16, child: Padding(padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: cBlue, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 8), Text('Week 2 · 8–14 $month', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: cText))]),
              const SizedBox(height: 14),
              _SummaryRow(label: 'Mon–Thu', value: '32.0 hrs', bold: false),
              const Divider(height: 20, color: cBorder),
              _SummaryRow(label: 'Fortnight total', value: '72.0 hrs', bold: true, valueColor: cBlue)]))),
          const SizedBox(height: 20),
          GestureDetector(onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Timesheet submitted to manager!'), backgroundColor: cGreen)),
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), cBlue]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: cBlue.withOpacity(0.45), blurRadius: 10, offset: const Offset(0, 4)),
                  const BoxShadow(color: Color(0xFF1E3A5F), blurRadius: 0, offset: Offset(0, 3))]),
              child: const Text('Submit to Manager', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)))),
          const SizedBox(height: 20)])))]);
  }
}

// ─── MANAGER HOME ──────────────────────────────────────────
class ManagerHome extends StatelessWidget {
  final AppUser user; final List<AppUser> users; final VoidCallback onLogout;
  const ManagerHome({super.key, required this.user, required this.users, required this.onLogout});
  @override
  Widget build(BuildContext context) {
    final staff = users.where((u) => u.role == 'Staff').toList();
    return Column(children: [
      AppHeader(onLogout: onLogout),
      Expanded(child: _bgGradient(child: SingleChildScrollView(padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RoleBadge(user.role), const SizedBox(height: 6),
          Text('Hi, ${user.name} 👋', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: cText)),
          Text(user.email, style: const TextStyle(fontSize: 12, color: cMuted)),
          const SizedBox(height: 20),
          StatCard(icon: Icons.group_rounded, label: 'Total Staff', value: staff.length), const SizedBox(height: 10),
          StatCard(icon: Icons.check_circle_rounded, label: 'Checked In Today', value: 0), const SizedBox(height: 10),
          StatCard(icon: Icons.pending_actions_rounded, label: 'Pending Approvals', value: 0),
          const SizedBox(height: 20),
          const Text('Staff Members', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: cNavyMid)),
          const SizedBox(height: 8),
          if (staff.isEmpty) const Text('No staff members yet.', style: TextStyle(color: cMuted))
          else ...staff.map((s) => UserRow(u: s))])))]);
  }
}

// ─── ADMIN HOME ────────────────────────────────────────────
class AdminHome extends StatefulWidget {
  final AppUser user; final List<AppUser> users;
  final void Function(AppUser) onAddUser; final VoidCallback onLogout;
  const AdminHome({super.key, required this.user, required this.users,
      required this.onAddUser, required this.onLogout});
  @override State<AdminHome> createState() => _AdminHomeState();
}
class _AdminHomeState extends State<AdminHome> {
  bool adding = false;
  final nCtrl = TextEditingController(), eCtrl = TextEditingController(), pCtrl = TextEditingController();
  String role = 'Staff', formErr = '', successMsg = '';

  void _add() {
    if (nCtrl.text.trim().isEmpty) { setState(() => formErr = 'Name is required.'); return; }
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(eCtrl.text.trim())) { setState(() => formErr = 'Valid email is required.'); return; }
    if (pCtrl.text.length < 8) { setState(() => formErr = 'Password must be at least 8 characters.'); return; }
    widget.onAddUser(AppUser(id: DateTime.now().millisecondsSinceEpoch,
        name: nCtrl.text.trim(), email: eCtrl.text.trim(), password: pCtrl.text, role: role));
    nCtrl.clear(); eCtrl.clear(); pCtrl.clear();
    setState(() { formErr = ''; successMsg = 'User added successfully!'; adding = false; });
  }

  Widget _miniStat(IconData icon, String label, int value, Color iconColor) =>
    raisedCard(radius: 10, child: Padding(padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 18)),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: cNavyMid)),
          Text(label, style: const TextStyle(fontSize: 10, color: cMuted))])])));

  @override
  Widget build(BuildContext context) {
    if (adding) return Column(children: [
      AppHeader(onLogout: widget.onLogout),
      Expanded(child: _bgGradient(child: SingleChildScrollView(padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextButton.icon(onPressed: () => setState(() { adding = false; formErr = ''; }),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Back', style: TextStyle(fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(foregroundColor: cPurple, padding: EdgeInsets.zero)),
          const SizedBox(height: 12),
          const Text('Add New User', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: cText)),
          const SizedBox(height: 20),
          const InputLabel('Full Name'), StyledInput(hint: 'Full name', ctrl: nCtrl),
          const InputLabel('Email'), StyledInput(hint: 'Email address', ctrl: eCtrl, keyboard: TextInputType.emailAddress),
          const InputLabel('Password'), StyledInput(hint: 'Min 8 characters', ctrl: pCtrl, obscure: true),
          const InputLabel('Role'),
          Container(margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: cBorder),
                boxShadow: [BoxShadow(color: cNavy.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: role, isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                items: ['Staff','Manager','Admin'].map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: (v) => setState(() => role = v!)))),
          if (formErr.isNotEmpty) ErrorBox(formErr),
          PrimaryButton(label: 'Add User', onTap: _add, colors: [cPurple, const Color(0xFF4F46E5)], shadowColor: const Color(0xFF3730A3))])))]);

    return Column(children: [
      AppHeader(onLogout: widget.onLogout),
      Expanded(child: _bgGradient(child: SingleChildScrollView(padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RoleBadge(widget.user.role), const SizedBox(height: 6),
          Text('Hi, ${widget.user.name} 👋', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: cText)),
          Text(widget.user.email, style: const TextStyle(fontSize: 12, color: cMuted)),
          const SizedBox(height: 16),
          if (successMsg.isNotEmpty) SuccessBox(successMsg),
          GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.4,
              children: [
                _miniStat(Icons.shield_rounded, 'Admins', widget.users.where((u)=>u.role=='Admin').length, const Color(0xFFD97706)),
                _miniStat(Icons.work_rounded, 'Managers', widget.users.where((u)=>u.role=='Manager').length, cPurple),
                _miniStat(Icons.engineering_rounded, 'Staff', widget.users.where((u)=>u.role=='Staff').length, cGreen),
                _miniStat(Icons.people_alt_rounded, 'Total', widget.users.length, cIndigo)]),
          const SizedBox(height: 16),
          GestureDetector(onTap: () => setState(() { adding = true; successMsg = ''; }),
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [cPurple, Color(0xFF4F46E5)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: cPurple.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                  const BoxShadow(color: Color(0xFF3730A3), blurRadius: 0, offset: Offset(0, 3))]),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.person_add_rounded, color: Colors.white, size: 18), SizedBox(width: 8),
                Text('Add New User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))]))),
          const SizedBox(height: 20),
          Text('All Users (${widget.users.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: cNavyMid)),
          const SizedBox(height: 8),
          ...widget.users.map((u) => UserRow(u: u, showRole: true))])))]);
  }
}