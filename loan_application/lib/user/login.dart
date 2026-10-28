import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loan_application/constant.dart';
import 'package:loan_application/user/otp_screen.dart';
import 'package:loan_application/user/register.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isMyanmar = true;
  bool isLoading = false; // 🚨 API ခေါ်နေစဉ် လည်နေမည့် Indicator အတွက်

  Map<String, String> get text => isMyanmar ? mmText : enText;

  final enText = {
    "email": "Email",
    "password": "Password",
    "login": "Login",
    "register": "Create Account",
    "forgot": "Forgot Password?",
    "loading": "Connecting...",
    "error_email": "Please enter your email",
    "error_password": "Password must be at least 6 characters",
  };

  final mmText = {
    "email": "အီးမေးလ်",
    "password": "လျှို့ဝှက်နံပါတ်",
    "login": "အကောင့်သို့ဝင်မည်",
    "register": "အကောင့်အသစ်ဖွင့်မည်",
    "forgot": "လျှို့ဝှက်နံပါတ်မေ့နေပါသလား",
    "loading": "ချိတ်ဆက်နေပါသည်...",
    "error_email": "အီးမေးလ် ဖြည့်သွင်းရန် လိုအပ်ပါသည်",
    "error_password": "လျှို့ဝှက်နံပါတ်သည် အနည်းဆုံး ၆ လုံး ရှိရပါမည်",
  };

  // 🚨 BACKEND သို့ LOGIN တင်ပို့စစ်ဆေးခြင်း နှင့် Session သိမ်းဆည်းခြင်း FUNCTION
  Future<void> _loginUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);

    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    // const String apiUrl = 'http://10.49.240.134:8000/api/login/';

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {
          "Content-Type": "application/json",
          'ngrok-skip-browser-warning': 'true',
        },

        body: jsonEncode({
          "email": emailController.text.trim(),
          "password": passwordController.text,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        // Backend က ပြန်လာတဲ့ user_name ကို SharedPreferences တွင် သိမ်းဆည်းခြင်း
        final SharedPreferences prefs = await SharedPreferences.getInstance();

        // ResponseData ထဲမှာ 'user_name' ဆိုတဲ့ key နဲ့ လာတယ်ဆိုရင် ဒီအတိုင်းယူပါ
        String userName = responseData['user_name'] ?? "Guest";
        await prefs.setString('userName', userName);
        await prefs.setString('email', emailController.text.trim());

        if (mounted) {
          _showSnackBar(
            isMyanmar
                ? "OTP ကုဒ်အား အီးမေးလ်ထဲသို့ ပို့ပေးလိုက်ပါပြီ"
                : "OTP code sent to email",
            Colors.green,
          );

          // 🚀 အောင်မြင်ပါက OTPScreen သို့ Email သယ်ဆောင်ပြီး သွားမည်
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => OTPScreen(email: emailController.text.trim()),
            ),
          );
        }
      } else {
        setState(() => isLoading = false);
        _showSnackBar(
          responseData['message'] ??
              (isMyanmar
                  ? "အချက်အလက် မှားယွင်းနေပါသည်"
                  : "Invalid credentials"),
          Colors.red,
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar(
        isMyanmar ? "ချိတ်ဆက်မှု Error တက်နေပါသည်: $e" : "Connection Error: $e",
        Colors.red,
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18479D),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff2A5BEB), Color(0xff88AFFF)],
          ),
        ),
        child: Stack(
          children: [
            // Background Glow
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(.12),
                ),
              ),
            ),

            Positioned(
              left: -70,
              bottom: 120,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(.10),
                ),
              ),
            ),
            Positioned(
              right: 40,
              top: 200,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(.08),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // 🌐 ဘာသာစကားပြောင်းလဲသည့် ခလုတ်
                        Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isMyanmar = !isMyanmar;
                              });
                            },
                            child: Container(
                              width: 120,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Stack(
                                children: [
                                  AnimatedAlign(
                                    duration: const Duration(milliseconds: 250),
                                    alignment:
                                        isMyanmar
                                            ? Alignment.centerLeft
                                            : Alignment.centerRight,
                                    child: Container(
                                      width: 60,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                  ),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            "မြန်မာ",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  isMyanmar
                                                      ? const Color(0xFF18479D)
                                                      : Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),

                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            "English",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  !isMyanmar
                                                      ? const Color(0xFF18479D)
                                                      : Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // App Logo နေရာ
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 15,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              "assets/image/Logo2.PNG",
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          isMyanmar ? "အကောင့်သို့ ဝင်မည်" : "Login",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          isMyanmar
                              ? "သင့်အကောင့်သို့ ဝင်ရောက်ပါ"
                              : "Sign in to your account",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 25),

                        // အဖြူရောင် Card နှင့် Form ထည့်သွင်းခြင်းစနစ်
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 15,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Email ရိုက်သည့်ကွက်
                              TextFormField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: text["email"],
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    color: Color(0xFF18479D),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty)
                                    return text["error_email"];
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Password ရိုက်သည့်ကွက်
                              TextFormField(
                                controller: passwordController,
                                obscureText: obscurePassword,
                                decoration: InputDecoration(
                                  labelText: text["password"],
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: Color(0xFF18479D),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.grey,
                                    ),
                                    onPressed:
                                        () => setState(
                                          () =>
                                              obscurePassword =
                                                  !obscurePassword,
                                        ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty ||
                                      value.length < 6)
                                    return text["error_password"];
                                  return null;
                                },
                              ),
                              const SizedBox(height: 25),

                              // Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _loginUser,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF18479D),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child:
                                      isLoading
                                          ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : Text(
                                            text["login"]!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Register Button (အကောင့်အသစ်ဖွင့်မည်)
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const Register(),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFF18479D),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    text["register"]!,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Forgot Password TextButton
                              TextButton(
                                onPressed: () {},
                                child: Text(
                                  text["forgot"]!,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.all(15),
                          child: Text(
                            "သဘောတူချက်၊ ကန့်သတ်ချက်၊ Contact License",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
