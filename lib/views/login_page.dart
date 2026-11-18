
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService auth = AuthService();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool loading = false;

  void msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> login() async {
    if (emailCtrl.text.trim().isEmpty ||
        passwordCtrl.text.isEmpty) {
      msg("Please enter email and password");
      return;
    }

    setState(() => loading = true);
    try {
      final user = await auth.signInWithEmail(
        emailCtrl.text, passwordCtrl.text,
      );

      if (!mounted) return;
      if (user == null) msg("Invalid email or password");
    } catch (e) {
      if (mounted) msg(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> googleLogin() async {
    setState(() => loading = true);
    try {
      await auth.signInWithGoogle();
    } catch (e) {
      if (mounted) msg(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void forgotPassword() {
    final ctrl = TextEditingController(text: emailCtrl.text);

    showDialog(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text("Forgot Password"),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: "Email"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              try {
                await auth.resetPassword(ctrl.text);
                if (!dialog.mounted) return;
                Navigator.pop(dialog);
                if (mounted) msg("Password reset email sent");
              } catch (e) {
                if (mounted) msg(e.toString());
              }
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tacusalme, Renan Angelo")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: loading ? null : login,
                child: Text(loading ? "Loading..." : "Login with Email"),
              ),
              TextButton(
                onPressed: forgotPassword,
                child: const Text("Forgot Password?"),
              ),
              const SizedBox(height: 24),
              const Text("OR"),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: loading ? null : googleLogin,
                icon: const Icon(Icons.login),
                label: const Text("Sign in with Google"),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterPage(),
                  ),
                ),
                child: const Text("Don't have an account? Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
