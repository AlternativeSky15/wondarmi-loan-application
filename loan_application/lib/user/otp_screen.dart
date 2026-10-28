import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loan_application/constant.dart';
import 'package:loan_application/user/Home2.dart';
import 'dart:convert';
import 'package:pinput/pinput.dart';



class OTPScreen extends StatefulWidget {
  final String email;
  const OTPScreen({super.key, required this.email});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  // ⏳ Timer အတွက် Variables များ
  Timer? _timer;
  int _startSeconds = 60;
  bool _isResendClickable = false;

  @override
  void initState() {
    super.initState();
    _startTimer(); // စာမျက်နှာစဖွင့်တာနဲ့ Timer စမောင်းပါမည်
  }

  // 🚀 Countdown Timer မောင်းနှင်သည့် Function
  void _startTimer() {
    setState(() {
      _startSeconds = 60;
      _isResendClickable = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startSeconds == 0) {
        setState(() {
          _isResendClickable = true;
          _timer?.cancel();
        });
      } else {
        setState(() {
          _startSeconds--;
        });
      }
    });
  }

  // 🚀 OTP ကုဒ် အသစ်ပြန်ပို့ပေးမည့် (Resend) Function
  Future<void> _resendOTP() async {
    if (!_isResendClickable) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("OTP ကုဒ်အသစ် တောင်းဆိုနေပါသည်..."), backgroundColor: Colors.blue),
    );

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.resendotp),
        headers: {"Content-Type": "application/json",
                   'ngrok-skip-browser-warning':'true'
        },
        body: jsonEncode({"email": widget.email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("OTP ကုဒ်အသစ် ပို့ပြီးပါပြီ။ Email ထပ်စစ်ပေးပါဗျာ။"), backgroundColor: Colors.orange),
          );
          _startTimer(); // အောင်မြင်လျှင် နောက်ထပ် စက္ကန့် ၆၀ တိုင်မာ ပြန်စပါမည်
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "ကုဒ်ပြန်ပို့ခြင်း မအောင်မြင်ပါ"), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ချိတ်ဆက်မှု အမှားအယွင်း: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 🚀 OTP ကုဒ် အတည်ပြုသည့် Function
  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().length < 6) return;

    setState(() => _isLoading = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xff18479D),
        ),
      ),
    );

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.verifyotp),
        headers: {"Content-Type": "application/json",
                   'ngrok-skip-browser-warning':'true'
        },
        body: jsonEncode({
          "email": widget.email,
          "otp": _otpController.text.trim(),
        }),
      );

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Loading ပိတ်ရန်
      }
      setState(() => _isLoading = false);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        String fullName = responseData['user']['full_name'] ?? "အသုံးပြုသူ";

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("မင်္ဂလာပါ $fullName၊ အကောင့်ဝင်ခြင်း အောင်မြင်ပါသည်ဗျာ။"),
              backgroundColor: Colors.green,
            ),
          );

          Future.delayed(Duration.zero, () {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomePage()),
                // (route) => false,
              );
            }
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? "OTP ကုဒ် မှားယွင်းနေပါသည်"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ချိတ်ဆက်မှု အမှားအယွင်း: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel(); // စာမျက်နှာ ပိတ်သွားလျှင် တိုင်မာကို အပြီးသတ် ဖျက်သိမ်းပါသည်
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body:SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    const Icon(
                      Icons.mark_email_read_outlined,
                      size: 100,
                      color: Color(0xff18479D),
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      "အီးမေးလ် အတည်ပြုပါ",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff18479D),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      "သင့်အီးမေးလ်သို့ ပို့ထားသော\nအတည်ပြုကုဒ်ကို ထည့်သွင်းပါ",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      widget.email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 35),


                    Pinput(
                      controller: _otpController,
                      length: 6,
                      keyboardType: TextInputType.number,

                      defaultPinTheme: PinTheme(
                        width: 50,
                        height: 60,
                        textStyle: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff18479D),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xff18479D),
                          ),
                        ),
                      ),

                      focusedPinTheme: PinTheme(
                        width: 52,
                        height: 58,
                        textStyle: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff18479D),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xff18479D),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: SizedBox(
                        width: 220,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff18479D),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            _isLoading ? "စစ်ဆေးနေသည်..." : "အတည်ပြုမည်",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    const Text(
                      "ကုဒ် မရရှိသေးပါ",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 8),

                    GestureDetector(
                      onTap: _isResendClickable ? _resendOTP : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _isResendClickable
                              ? const Color(0xff18479D).withOpacity(0.08)
                              : Colors.grey.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: _isResendClickable
                                ? const Color(0xff18479D)
                                : Colors.grey.shade400,
                          ),
                        ),
                        child: Text(
                            "ကုဒ် ပြန်ပို့ပါ",
                          style: TextStyle(
                            color: _isResendClickable
                                ? const Color(0xff18479D)
                                : Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        children: [
                          const TextSpan(
                            text: "ဤကုဒ်သည်",
                          ),
                          TextSpan(
                            text: "00:${_startSeconds.toString().padLeft(2, '0')}",
                            style: const TextStyle(
                              color: Color(0xff18479D),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(
                            text: " အတွင်းသက်တမ်းကုန်ဆုံးပါမည်။",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}