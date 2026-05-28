import 'package:flutter/material.dart';

void main() => runApp(const ModeRentalsApp());

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
const Color cRedLight = Color(0xFFFCA5A5);
const Color cRedBg = Color(0x1FEF4444);
const Color cRedBorder = Color(0x4DEF4444);
const Color cAmberLight = Color(0xFFFEF3C7);
const Color cAmberText = Color(0xFF92400E);
const Color cVioletLight = Color(0xFFEDE9FE);
const Color cVioletText = Color(0xFF4C1D95);
const Color cGreenText = Color(0xFF166534);

// ─── User Model ────────────────────────────────────────────
class AppUser {
  final int id;
  final String name;
  String email, password;
  final String role;
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });
}

// ─── App Root ──────────────────────────────────────────────
class ModeRentalsApp extends StatefulWidget {
  const ModeRentalsApp({super.key});
  @override
  State<ModeRentalsApp> createState() => _ModeRentalsAppState();
}

class _ModeRentalsAppState extends State<ModeRentalsApp> {
  final List<AppUser> users = [
    AppUser(
      id: 1,
      name: 'Admin User',
      email: 'hmcsampath@hotmail.com',
      password: 'Admin@123',
      role: 'Admin',
    ),
    AppUser(
      id: 2,
      name: 'Manager User',
      email: 'hmcsampath@hotmail.com',
      password: 'Manager@123',
      role: 'Manager',
    ),
    AppUser(
      id: 3,
      name: 'Staff User',
      email: 'hmcsampath@hotmail.com',
      password: 'Staff@123',
      role: 'Staff',
    ),
  ];

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
  void addUser(AppUser u) => setState(() => users.add(u));

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mode Rentals',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: cSlate,
        colorScheme: ColorScheme.fromSeed(seedColor: cIndigo),
      ),
      home: Scaffold(
        backgroundColor: cSlate,
        body: SafeArea(
          child: switch (screen) {
            'forgot' => ForgotScreen(onBack: goLogin),
            'staff' => StaffHome(user: currentUser!, onLogout: logout),
            'manager' => ManagerHome(
              user: currentUser!,
              users: users,
              onLogout: logout,
            ),
            'admin' => AdminHome(
              user: currentUser!,
              users: users,
              onAddUser: addUser,
              onLogout: logout,
            ),
            _ => LoginScreen(users: users, onLogin: login, onForgot: goForgot),
          },
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
  Widget build(BuildContext context) {
    return Container(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cRedBg,
                  border: Border.all(color: cRedBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
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
}

// ─── Shared Widgets ────────────────────────────────────────

class RoleBadge extends StatelessWidget {
  final String role;
  const RoleBadge(this.role, {super.key});

  @override
  Widget build(BuildContext context) {
    final styles = {
      'Admin': [cAmberLight, cAmberText],
      'Manager': [cVioletLight, cVioletText],
      'Staff': [cGreenLight, cGreenText],
    };
    final s = styles[role] ?? [Colors.grey.shade200, Colors.grey.shade700];
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
  Widget build(BuildContext context) {
    return Container(
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
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 0,
            offset: const Offset(0, 1),
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
}

class InputLabel extends StatelessWidget {
  final String text;
  const InputLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
  Widget build(BuildContext context) {
    return GestureDetector(
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
}

class ErrorBox extends StatelessWidget {
  final String msg;
  const ErrorBox(this.msg, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        border: Border.all(color: cRed.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: cRed, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg, style: const TextStyle(color: cRed, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class SuccessBox extends StatelessWidget {
  final String msg;
  const SuccessBox(this.msg, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
}

Widget raisedCard({required Widget child, double radius = 12}) {
  return Container(
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
  Widget build(BuildContext context) {
    return raisedCard(
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
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: cMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class UserRow extends StatelessWidget {
  final AppUser u;
  final bool showRole;
  const UserRow({super.key, required this.u, this.showRole = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: raisedCard(
        radius: 10,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF312E81), cIndigo],
                  ),
                  borderRadius: BorderRadius.circular(18),
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
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: cText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      u.email,
                      style: const TextStyle(fontSize: 11, color: cMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (showRole) ...[const SizedBox(width: 6), RoleBadge(u.role)],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── LOGIN ─────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  final List<AppUser> users;
  final void Function(AppUser) onLogin;
  final VoidCallback onForgot;
  const LoginScreen({
    super.key,
    required this.users,
    required this.onLogin,
    required this.onForgot,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final eCtrl = TextEditingController();
  final pCtrl = TextEditingController();
  bool showPw = false;
  String err = '';

  String? _validate() {
    if (eCtrl.text.trim().isEmpty) return 'Email is required.';
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(eCtrl.text.trim()))
      return 'Invalid email format.';
    if (pCtrl.text.isEmpty) return 'Password is required.';
    if (pCtrl.text.length < 8) return 'Password must be at least 8 characters.';
    return null;
  }

  void _login() {
    final e = _validate();
    if (e != null) {
      setState(() => err = e);
      return;
    }
    final m = widget.users
        .where((u) => u.email == eCtrl.text.trim() && u.password == pCtrl.text)
        .firstOrNull;
    if (m == null) {
      setState(() => err = 'Incorrect email or password.');
      return;
    }
    widget.onLogin(m);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [cSlate, cSlate2],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
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
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          blurRadius: 0,
                          offset: const Offset(0, 1),
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
                  PrimaryButton(label: 'Sign in', onTap: _login),
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [cSlate, cSlate2],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
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
  bool checkedIn = false;
  final List<Map<String, String>> log = [];

  String _now() => TimeOfDay.now().format(context);

  void _toggle() {
    final a = checkedIn ? 'Check-out' : 'Check-in';
    setState(() {
      log.insert(0, {'action': a, 'time': _now()});
      checkedIn = !checkedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppHeader(onLogout: widget.onLogout),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [cSlate, cSlate2],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RoleBadge(widget.user.role),
                  const SizedBox(height: 6),
                  Text(
                    'Hi, ${widget.user.name} 👋',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: cText,
                    ),
                  ),
                  Text(
                    widget.user.email,
                    style: const TextStyle(fontSize: 12, color: cMuted),
                  ),
                  const SizedBox(height: 20),
                  raisedCard(
                    radius: 14,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: checkedIn ? cGreenLight : cSlate,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Icon(
                              checkedIn
                                  ? Icons.check_circle_rounded
                                  : Icons.access_time_rounded,
                              color: checkedIn ? cGreen : cMuted,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            checkedIn
                                ? 'Currently Checked In'
                                : 'Not Checked In',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: checkedIn ? cGreenText : cNavyMid,
                            ),
                          ),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: _toggle,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 32,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: checkedIn
                                      ? [const Color(0xFFC62828), cRed]
                                      : [cGreen, const Color(0xFF15803D)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: (checkedIn ? cRed : cGreen)
                                        .withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                  BoxShadow(
                                    color: checkedIn
                                        ? const Color(0xFF7F1D1D)
                                        : cGreenDark,
                                    blurRadius: 0,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                checkedIn ? 'Check Out' : 'Check In',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (log.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      "Today's Log",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: cNavyMid,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...log.map(
                      (l) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: raisedCard(
                          radius: 8,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l['action']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: cText,
                                  ),
                                ),
                                Text(
                                  l['time']!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: cMuted,
                                  ),
                                ),
                              ],
                            ),
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
}

// ─── MANAGER HOME ──────────────────────────────────────────
class ManagerHome extends StatelessWidget {
  final AppUser user;
  final List<AppUser> users;
  final VoidCallback onLogout;
  const ManagerHome({
    super.key,
    required this.user,
    required this.users,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final staff = users.where((u) => u.role == 'Staff').toList();
    return Column(
      children: [
        AppHeader(onLogout: onLogout),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [cSlate, cSlate2],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RoleBadge(user.role),
                  const SizedBox(height: 6),
                  Text(
                    'Hi, ${user.name} 👋',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: cText,
                    ),
                  ),
                  Text(
                    user.email,
                    style: const TextStyle(fontSize: 12, color: cMuted),
                  ),
                  const SizedBox(height: 20),
                  StatCard(
                    icon: Icons.group_rounded,
                    label: 'Total Staff',
                    value: staff.length,
                  ),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 20),
                  const Text(
                    'Staff Members',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: cNavyMid,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (staff.isEmpty)
                    const Text(
                      'No staff members yet.',
                      style: TextStyle(color: cMuted),
                    )
                  else
                    ...staff.map((s) => UserRow(u: s)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── ADMIN HOME ────────────────────────────────────────────
class AdminHome extends StatefulWidget {
  final AppUser user;
  final List<AppUser> users;
  final void Function(AppUser) onAddUser;
  final VoidCallback onLogout;
  const AdminHome({
    super.key,
    required this.user,
    required this.users,
    required this.onAddUser,
    required this.onLogout,
  });

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  bool adding = false;
  final nCtrl = TextEditingController();
  final eCtrl = TextEditingController();
  final pCtrl = TextEditingController();
  String role = 'Staff';
  String formErr = '';
  String successMsg = '';

  void _add() {
    if (nCtrl.text.trim().isEmpty) {
      setState(() => formErr = 'Name is required.');
      return;
    }
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(eCtrl.text.trim())) {
      setState(() => formErr = 'Valid email is required.');
      return;
    }
    if (pCtrl.text.length < 8) {
      setState(() => formErr = 'Password must be at least 8 characters.');
      return;
    }
    widget.onAddUser(
      AppUser(
        id: DateTime.now().millisecondsSinceEpoch,
        name: nCtrl.text.trim(),
        email: eCtrl.text.trim(),
        password: pCtrl.text,
        role: role,
      ),
    );
    nCtrl.clear();
    eCtrl.clear();
    pCtrl.clear();
    setState(() {
      formErr = '';
      successMsg = 'User added successfully!';
      adding = false;
    });
  }

  Widget _miniStat(IconData icon, String label, int value, Color iconColor) {
    return raisedCard(
      radius: 10,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: cNavyMid,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: cMuted),
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
    if (adding) {
      return Column(
        children: [
          AppHeader(onLogout: widget.onLogout),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [cSlate, cSlate2],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() {
                        adding = false;
                        formErr = '';
                      }),
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text(
                        'Back',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: cPurple,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Add New User',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: cText,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const InputLabel('Full Name'),
                    StyledInput(hint: 'Full name', ctrl: nCtrl),
                    const InputLabel('Email'),
                    StyledInput(
                      hint: 'Email address',
                      ctrl: eCtrl,
                      keyboard: TextInputType.emailAddress,
                    ),
                    const InputLabel('Password'),
                    StyledInput(
                      hint: 'Min 8 characters',
                      ctrl: pCtrl,
                      obscure: true,
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
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          items: ['Staff', 'Manager', 'Admin']
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(
                                    r,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => role = v!),
                        ),
                      ),
                    ),
                    if (formErr.isNotEmpty) ErrorBox(formErr),
                    PrimaryButton(
                      label: 'Add User',
                      onTap: _add,
                      colors: [cPurple, const Color(0xFF4F46E5)],
                      shadowColor: const Color(0xFF3730A3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        AppHeader(onLogout: widget.onLogout),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [cSlate, cSlate2],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RoleBadge(widget.user.role),
                  const SizedBox(height: 6),
                  Text(
                    'Hi, ${widget.user.name} 👋',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: cText,
                    ),
                  ),
                  Text(
                    widget.user.email,
                    style: const TextStyle(fontSize: 12, color: cMuted),
                  ),
                  const SizedBox(height: 16),
                  if (successMsg.isNotEmpty) SuccessBox(successMsg),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.4,
                    children: [
                      _miniStat(
                        Icons.shield_rounded,
                        'Admins',
                        widget.users.where((u) => u.role == 'Admin').length,
                        const Color(0xFFD97706),
                      ),
                      _miniStat(
                        Icons.work_rounded,
                        'Managers',
                        widget.users.where((u) => u.role == 'Manager').length,
                        cPurple,
                      ),
                      _miniStat(
                        Icons.engineering_rounded,
                        'Staff',
                        widget.users.where((u) => u.role == 'Staff').length,
                        cGreen,
                      ),
                      _miniStat(
                        Icons.people_alt_rounded,
                        'Total',
                        widget.users.length,
                        cIndigo,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => setState(() {
                      adding = true;
                      successMsg = '';
                    }),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [cPurple, Color(0xFF4F46E5)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: cPurple.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                          const BoxShadow(
                            color: Color(0xFF3730A3),
                            blurRadius: 0,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_add_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Add New User',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'All Users (${widget.users.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: cNavyMid,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.users.map((u) => UserRow(u: u, showRole: true)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
