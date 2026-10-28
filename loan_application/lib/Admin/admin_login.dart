import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loan_application/constant.dart';
import 'admin_dashboard.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AdminLoginScreen(),
    ),
  );
}

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _rememberMe = true;

  // 🚨 Backend Logic မူရင်းအတိုင်း ထိန်းသိမ်းထားပါသည်
  Future<void> _handleLogin() async {
    final String emailInput = _emailController.text.trim();
    final String passwordInput = _passwordController.text.trim();

    if (emailInput.isEmpty || passwordInput.isEmpty) {
      setState(() {
        _errorMessage = "Email နှင့် Password ကို ရိုက်ထည့်ပါ";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = Uri.parse(ApiConfig.adminlogin);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'email': emailInput, 'password': passwordInput}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("Login အောင်မြင်ပါသည်: ${responseData['full_name']}");

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
        );
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage = errorData['error'] ?? "လော့ဂ်အင်ဝင်ရန် ပျက်ကွက်ပါသည်";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "ကွန်ရက်ချိတ်ဆက်မှု မရရှိပါ (Connection Error)";
      });
      print("Error occurred: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F3B82), Color(0xFF0D52B8), Color(0xFF0A2B66)],
          ),
        ),
        child: Stack(
          children: [
            // Background Light Circles
            // Positioned(
            //   top: 100,
            //   left: 60,
            //   child: Container(
            //     width: 120,
            //     height: 120,
            //     decoration: BoxDecoration(
            //       shape: BoxShape.circle,
            //       color: Colors.white.withOpacity(0.08),
            //       border: Border.all(color: Colors.white12, width: 1.5),
            //     ),
            //   ),
            // ),
            // Positioned(
            //   top: 180,
            //   left: 450,
            //   child: Container(
            //     width: 45,
            //     height: 45,
            //     decoration: BoxDecoration(
            //       shape: BoxShape.circle,
            //       color: Colors.white.withOpacity(0.12),
            //     ),
            //   ),
            // ),

            // Main Glassmorphism Container
            Center(
              child: SingleChildScrollView(
                child: Container(
                  width: 1100,
                  height: 620,
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // LEFT SIDE - Branding & Info
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 30,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Spacer(),
                              // Logo Image
                              Image.asset(
                                "assets/image/Logo2.PNG",
                                width: 120,
                                height: 120,
                                fit: BoxFit.contain,
                                errorBuilder:
                                    (context, error, stackTrace) => Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF16325C),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.waves,
                                        color: Colors.cyanAccent,
                                        size: 50,
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "WONDAMI",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 15),

                              // Divider Line with Text
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 50,
                                    height: 1,
                                    color: Colors.white30,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      "စီမံရန် • စောင့်ကြည့်ရန် • တိုးတက်စေရန်",
                                      style: TextStyle(
                                        color: Color(0xFF43D39E),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 50,
                                    height: 1,
                                    color: Colors.white30,
                                  ),
                                ],
                              ),
                              const Spacer(),

                              // Bottom Feature Cards (Analytics, Security, Performance)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildFeatureItem(
                                    Icons.bar_chart_rounded,
                                    "သုံးသပ်ချက်များ",
                                    "လက်ငင်း အချက်အလက်များ",
                                  ),
                                  const SizedBox(width: 12),
                                  _buildFeatureItem(
                                    Icons.shield_outlined,
                                    "လုံခြုံရေး",
                                    "ကာကွယ်ထားသော ဝင်ရောက်မှု",
                                  ),
                                  const SizedBox(width: 12),
                                  _buildFeatureItem(
                                    Icons.rocket_launch_outlined,
                                    "စွမ်းဆောင်ရည်",
                                    "တိုးတက်မှု မြှင့်တင်ရန်",
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // RIGHT SIDE - Login Form Card
                      Expanded(
                        flex: 5,
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 30,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "ပြန်လည်ကြိုဆိုပါသည်!",
                                style: TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "သင်၏ အက်မင်အကောင့်သို့ ဝင်ရောက်ပါ",
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Email Input
                              const Text(
                                "အီးမေးလ် လိပ်စာ",
                                style: TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _emailController,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: "အီးမေးလ် ရိုက်ထည့်ပါ",
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 13,
                                  ),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F4C81),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.email_outlined,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0F4C81),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Password Input
                              const Text(
                                "စကားဝှက်",
                                style: TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: "စကားဝှက် ရိုက်ထည့်ပါ",
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 13,
                                  ),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F4C81),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.lock_outline,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF64748B),
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0F4C81),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Remember Me & Forgot Password
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Row(
                                  //   children: [
                                  //     SizedBox(
                                  //       width: 24,
                                  //       height: 24,
                                  //       child: Checkbox(
                                  //         value: _rememberMe,
                                  //         onChanged: (val) {
                                  //           setState(() {
                                  //             _rememberMe = val ?? false;
                                  //           });
                                  //         },
                                  //         activeColor: const Color(0xFF0F4C81),
                                  //         shape: RoundedRectangleBorder(
                                  //           borderRadius: BorderRadius.circular(4),
                                  //         ),
                                  //       ),
                                  //     ),
                                  //     const SizedBox(width: 8),
                                  //     // const Text(
                                  //     //   "Remember me",
                                  //     //   style: TextStyle(
                                  //     //     color: Color(0xFF1E293B),
                                  //     //     fontSize: 12,
                                  //     //     fontWeight: FontWeight.w500,
                                  //     //   ),
                                  //     // ),
                                  //   ],
                                  // ),
                                  // InkWell(
                                  //   onTap: () {},
                                  //   child: const Text(
                                  //     "Forgot Password?",
                                  //     style: TextStyle(
                                  //       color: Color(0xFF1E293B),
                                  //       fontSize: 12,
                                  //       fontWeight: FontWeight.bold,
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              ),

                              // Error Message Display
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 20),

                              // Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F4C81),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 2,
                                  ),
                                  child:
                                      _isLoading
                                          ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const Text(
                                            "လော့ဂ်အင်ဝင်ရန်",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Secure Admin Access Badge
                              // Container(
                              //   width: double.infinity,
                              //   padding: const EdgeInsets.symmetric(vertical: 10),
                              //   decoration: BoxDecoration(
                              //     color: const Color(0xFFD1EBE1),
                              //     borderRadius: BorderRadius.circular(8),
                              //   ),
                              //   child: const Row(
                              //     mainAxisAlignment: MainAxisAlignment.center,
                              //     children: [
                              //       Icon(
                              //         Icons.check_circle,
                              //         color: Color(0xFF10B981),
                              //         size: 18,
                              //       ),
                              //       SizedBox(width: 8),
                              //       // Text(
                              //       //   "Secure Admin Access",
                              //       //   style: TextStyle(
                              //       //     color: Color(0xFF0F766E),
                              //       //     fontSize: 12,
                              //       //     fontWeight: FontWeight.w600,
                              //       //   ),
                              //       // ),
                              //     ],
                              //   ),
                              // ),
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

  // Feature Component Helper
  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white60, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
