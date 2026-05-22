import 'package:flutter/material.dart';

void main() => runApp(const ModeRentalsApp());

// ─── Colours ───────────────────────────────────────────────
const Color navy = Color(0xFF0F2044);
const Color navyLight = Color(0xFF1A3260);
const Color modePurple = Color(0xFF6C6CE0);
const Color inputBg = Color(0xFFF4F6FB);
const Color borderCol = Color(0xFFDDE3F0);
const Color textMuted = Color(0xFF8A94A6);
const Color dangerRed = Color(0xFFE53935);
const Color successGreen = Color(0xFF2E7D32);

// ─── User Model ────────────────────────────────────────────
class AppUser {
  final int id;
  final String name;
  String email;
  String password;
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
        scaffoldBackgroundColor: navy,
      ),
      home: Scaffold(
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

// ─── Shared Widgets ────────────────────────────────────────

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: navy,
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 6,
          decoration: BoxDecoration(
            color: modePurple,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'mode',
          style: TextStyle(
            color: modePurple,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(width: 2),
        const Text(
          '™',
          style: TextStyle(
            color: modePurple,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class RoleBadge extends StatelessWidget {
  final String role;
  const RoleBadge(this.role, {super.key});
  @override
  Widget build(BuildContext context) {
    final colors = {
      'Admin': [const Color(0xFFFFF3E0), const Color(0xFFE65100)],
      'Manager': [const Color(0xFFE8EAF6), const Color(0xFF283593)],
      'Staff': [const Color(0xFFE8F5E9), successGreen],
    };
    final c = colors[role] ?? [Colors.grey.shade200, Colors.grey];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: c[0] as Color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: c[1] as Color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
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
    child: TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        filled: true,
        fillColor: inputBg,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderCol),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderCol),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: navy, width: 1.5),
        ),
      ),
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = navy,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
  );
}

class ErrorBox extends StatelessWidget {
  final String msg;
  const ErrorBox(this.msg, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFFDECEA),
      border: Border.all(color: dangerRed),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: dangerRed, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            msg,
            style: const TextStyle(color: dangerRed, fontSize: 12),
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
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5E9),
      border: Border.all(color: successGreen),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.check_circle_outline, color: successGreen, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            msg,
            style: const TextStyle(color: successGreen, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class StatCard extends StatelessWidget {
  final String icon, label;
  final int value;
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: inputBg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: navy,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 11, color: textMuted)),
          ],
        ),
      ],
    ),
  );
}

class UserRow extends StatelessWidget {
  final AppUser u;
  final bool showRole;
  const UserRow({super.key, required this.u, this.showRole = false});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: inputBg,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: navy,
          child: Text(
            u.name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
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
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF1A1A2E),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                u.email,
                style: const TextStyle(fontSize: 11, color: textMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (showRole) RoleBadge(u.role),
      ],
    ),
  );
}

Widget logoutBtn(VoidCallback onLogout) => Container(
  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
  decoration: const BoxDecoration(
    border: Border(top: BorderSide(color: borderCol)),
  ),
  child: SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onLogout,
      style: OutlinedButton.styleFrom(
        foregroundColor: dangerRed,
        side: const BorderSide(color: borderCol),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text(
        'Sign Out',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  ),
);

// ─── LOGIN SCREEN ──────────────────────────────────────────
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
  final emailCtrl = TextEditingController();
  final pwCtrl = TextEditingController();
  bool showPw = false;
  String err = '';

  String? validate() {
    final e = emailCtrl.text.trim(), p = pwCtrl.text;
    if (e.isEmpty) return 'Email is required.';
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(e))
      return 'Invalid email format.';
    if (p.isEmpty) return 'Password is required.';
    if (p.length < 8) return 'Password must be at least 8 characters.';
    return null;
  }

  void handleLogin() {
    final e = validate();
    if (e != null) {
      setState(() => err = e);
      return;
    }
    final match = widget.users
        .where(
          (u) => u.email == emailCtrl.text.trim() && u.password == pwCtrl.text,
        )
        .firstOrNull;
    if (match == null) {
      setState(() => err = 'Incorrect email or password. Please try again.');
      return;
    }
    widget.onLogin(match);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const AppHeader(),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: navy.withOpacity(.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🚗', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome to Mode',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sign in to your account',
                style: TextStyle(color: textMuted, fontSize: 14),
              ),
              const SizedBox(height: 28),
              StyledInput(
                hint: 'Email address',
                ctrl: emailCtrl,
                keyboard: TextInputType.emailAddress,
              ),
              StyledInput(
                hint: 'Password',
                ctrl: pwCtrl,
                obscure: !showPw,
                suffix: IconButton(
                  icon: Icon(
                    showPw ? Icons.visibility_off : Icons.visibility,
                    color: textMuted,
                    size: 20,
                  ),
                  onPressed: () => setState(() => showPw = !showPw),
                ),
              ),
              if (err.isNotEmpty) ErrorBox(err),
              PrimaryButton(label: 'Sign in', onTap: handleLogin),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: widget.onForgot,
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: navyLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Secured · Privacy Act 2020 compliant',
                style: TextStyle(color: textMuted, fontSize: 11),
              ),
            ],
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

  void handle() {
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text(
                  'Back to Sign in',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: navyLight,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 20),
              const Text('🔑', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              const Text(
                'Reset Password',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Enter your email and we'll send you a reset link.",
                style: TextStyle(color: textMuted, fontSize: 13),
              ),
              const SizedBox(height: 24),
              if (!sent) ...[
                StyledInput(
                  hint: 'Email address',
                  ctrl: ctrl,
                  keyboard: TextInputType.emailAddress,
                ),
                if (err.isNotEmpty) ErrorBox(err),
                PrimaryButton(label: 'Send Reset Link', onTap: handle),
              ] else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    border: Border.all(color: successGreen),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text('📧', style: TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      const Text(
                        'Reset link sent!',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: successGreen,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Check ${ctrl.text.trim()} for your password reset link.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'Back to Sign in',
                        onTap: widget.onBack,
                        color: successGreen,
                      ),
                    ],
                  ),
                ),
            ],
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
  bool checkedIn = false;
  final List<Map<String, String>> log = [];

  String nowTime() => TimeOfDay.now().format(context);

  void toggle() {
    final action = checkedIn ? 'Check-out' : 'Check-in';
    setState(() {
      log.insert(0, {'action': action, 'time': nowTime()});
      checkedIn = !checkedIn;
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const AppHeader(),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoleBadge(widget.user.role),
              const SizedBox(height: 4),
              Text(
                'Hi, ${widget.user.name} 👋',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text(
                widget.user.email,
                style: const TextStyle(fontSize: 12, color: textMuted),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: checkedIn ? const Color(0xFFE8F5E9) : inputBg,
                  border: Border.all(
                    color: checkedIn ? successGreen : borderCol,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      checkedIn ? '✅' : '🕐',
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      checkedIn ? 'Currently Checked In' : 'Not Checked In',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: checkedIn ? successGreen : navy,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      label: checkedIn ? 'Check Out' : 'Check In',
                      onTap: toggle,
                      color: checkedIn ? const Color(0xFFC62828) : successGreen,
                    ),
                  ],
                ),
              ),
              if (log.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  "Today's Log",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 8),
                ...log.map(
                  (l) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l['action']!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l['time']!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      logoutBtn(widget.onLogout),
    ],
  );
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
        const AppHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RoleBadge(user.role),
                const SizedBox(height: 4),
                Text(
                  'Hi, ${user.name} 👋',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 12, color: textMuted),
                ),
                const SizedBox(height: 20),
                StatCard(icon: '👥', label: 'Total Staff', value: staff.length),
                const SizedBox(height: 10),
                StatCard(icon: '✅', label: 'Checked In Today', value: 0),
                const SizedBox(height: 10),
                StatCard(icon: '📋', label: 'Pending Approvals', value: 0),
                const SizedBox(height: 20),
                const Text(
                  'Staff Members',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 8),
                if (staff.isEmpty)
                  const Text(
                    'No staff members yet.',
                    style: TextStyle(color: textMuted, fontSize: 13),
                  )
                else
                  ...staff.map((s) => UserRow(u: s)),
              ],
            ),
          ),
        ),
        logoutBtn(onLogout),
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
  bool addingUser = false;
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final pwCtrl = TextEditingController();
  String role = 'Staff';
  String formErr = '';
  String successMsg = '';

  void addUser() {
    if (nameCtrl.text.trim().isEmpty) {
      setState(() => formErr = 'Name is required.');
      return;
    }
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(emailCtrl.text.trim())) {
      setState(() => formErr = 'Valid email is required.');
      return;
    }
    if (pwCtrl.text.length < 8) {
      setState(() => formErr = 'Password must be at least 8 characters.');
      return;
    }
    widget.onAddUser(
      AppUser(
        id: DateTime.now().millisecondsSinceEpoch,
        name: nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        password: pwCtrl.text,
        role: role,
      ),
    );
    nameCtrl.clear();
    emailCtrl.clear();
    pwCtrl.clear();
    setState(() {
      formErr = '';
      successMsg = 'User added successfully!';
      addingUser = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (addingUser)
      return Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() {
                      addingUser = false;
                      formErr = '';
                    }),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text(
                      'Back',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: navyLight,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Add New User',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 20),
                  StyledInput(hint: 'Full name', ctrl: nameCtrl),
                  StyledInput(
                    hint: 'Email address',
                    ctrl: emailCtrl,
                    keyboard: TextInputType.emailAddress,
                  ),
                  StyledInput(
                    hint: 'Password (min 8 chars)',
                    ctrl: pwCtrl,
                    obscure: true,
                  ),
                  const Text(
                    'Role',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: navy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: inputBg,
                      border: Border.all(color: borderCol),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: role,
                        isExpanded: true,
                        items: ['Staff', 'Manager', 'Admin']
                            .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => role = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (formErr.isNotEmpty) ErrorBox(formErr),
                  PrimaryButton(label: 'Add User', onTap: addUser),
                ],
              ),
            ),
          ),
        ],
      );

    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RoleBadge(widget.user.role),
                const SizedBox(height: 4),
                Text(
                  'Hi, ${widget.user.name} 👋',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  widget.user.email,
                  style: const TextStyle(fontSize: 12, color: textMuted),
                ),
                const SizedBox(height: 20),
                if (successMsg.isNotEmpty) SuccessBox(successMsg),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.6,
                  children: [
                    _miniStat(
                      '🛡️',
                      'Admins',
                      widget.users.where((u) => u.role == 'Admin').length,
                    ),
                    _miniStat(
                      '💼',
                      'Managers',
                      widget.users.where((u) => u.role == 'Manager').length,
                    ),
                    _miniStat(
                      '👷',
                      'Staff',
                      widget.users.where((u) => u.role == 'Staff').length,
                    ),
                    _miniStat('👥', 'Total', widget.users.length),
                  ],
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: '+ Add New User',
                  color: navyLight,
                  onTap: () => setState(() {
                    addingUser = true;
                    successMsg = '';
                  }),
                ),
                const SizedBox(height: 20),
                Text(
                  'All Users (${widget.users.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 8),
                ...widget.users.map((u) => UserRow(u: u, showRole: true)),
              ],
            ),
          ),
        ),
        logoutBtn(widget.onLogout),
      ],
    );
  }

  Widget _miniStat(String icon, String label, int value) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: inputBg,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: navy,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 10, color: textMuted)),
          ],
        ),
      ],
    ),
  );
}
