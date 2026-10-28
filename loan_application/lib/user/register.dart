import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loan_application/constant.dart';
import 'package:loan_application/user/login.dart';

class Register extends StatelessWidget {
  const Register({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Myanmar',
        scaffoldBackgroundColor: const Color(0xFF18479D),
        useMaterial3: true,
      ),
      home: const RegisterScreen(),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthController = TextEditingController();
  final _addressController = TextEditingController();

  final _emailController = TextEditingController();
  final _nrcController = TextEditingController();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool _isLoading = false;
  bool isMyanmar = true;
  String? selectedGender;

  // NRC Dropdown States
  String? selectedNrcState;
  String? selectedNrcTownship;
  String? selectedNrcType;

  Map<String, String> get text => isMyanmar ? mmText : enText;

  final enText = {
    "title": "Create Account",
    "sub": "Please fill in your information",

    "btn_next": "Next",
    "btn_back": "Back",
    "btn_register": "Register",

    "step1": "Step 1: Personal Information",
    "step2": "Step 2: Account Information",
    "step3": "Step 3: Security & Address",

    "fullname": "Full Name",
    "phone": "Phone Number",
    "dob": "Date of Birth",

    "gender": "Select Gender",
    "male": "Male",
    "female": "Female",
    "other": "Other",

    "email": "Email Address",
    "nrc": "NRC Number",

    "address": "Full Address",
    "password": "Password",
    "confirm_password": "Confirm Password",

    "err_msg": "Please fill all required fields",

    "already_account": "Already have an account?",
    "login": "Login",
  };

  final mmText = {
    "title": "အကောင့်အသစ်ဖွင့်မည်",
    "sub": "အချက်အလက်များကို မှန်ကန်စွာ ဖြည့်စွက်ပါ",

    "btn_next": "ရှေ့သို့",
    "btn_back": "နောက်သို့",
    "btn_register": "အကောင့်ဖွင့်မည်",

    "step1": "အဆင့် ၁: ကိုယ်ရေးအချက်အလက်",
    "step2": "အဆင့် ၂: အကောင့်အချက်အလက်",
    "step3": "အဆင့် ၃: လုံခြုံရေးနှင့် နေရပ်လိပ်စာ",

    "fullname": "အမည်အပြည့်အစုံ",
    "phone": "ဖုန်းနံပါတ်",
    "dob": "မွေးသက္ကရာဇ်",

    "gender": "ကျား/မ ရွေးချယ်ရန်",
    "male": "ကျား",
    "female": "မ",
    "other": "အခြား",

    "email": "အီးမေးလ်လိပ်စာ",
    "nrc": "မှတ်ပုံတင်အမှတ်",

    "address": "နေရပ်လိပ်စာ",
    "password": "လျှို့ဝှက်နံပါတ်",
    "confirm_password": "လျှို့ဝှက်နံပါတ် ထပ်မံရိုက်ထည့်ပါ",

    "err_msg": "အချက်အလက်များကို ပြည့်စုံစွာ ဖြည့်သွင်းပါ",
    "already_account": "အကောင့်ရှိပြီးသားလား?",
    "login": "အကောင့်ဝင်ရန်",
  };

  final Map<String, String> nrcStates = {
    "၁/": "ကချင်ပြည်နယ်",
    "၂/": "ကယားပြည်နယ်",
    "၃/": "ကရင်ပြည်နယ်",
    "၄/": "ချင်းပြည်နယ်",
    "၅/": "စစ်ကိုင်းတိုင်း",
    "၆/": "တနင်္သာရီတိုင်း",
    "၇/": "ပဲခူးတိုင်း",
    "၈/": "မကွေးတိုင်း",
    "၉/": "မန္တလေးတိုင်း/နေပြည်တော်",
    "၁၀/": "မွန်ပြည်နယ်",
    "၁၁/": "ရခိုင်ပြည်နယ်",
    "၁၂/": "ရန်ကုန်တိုင်း",
    "၁၃/": "ရှမ်းပြည်နယ်",
    "၁၄/": "ဧရာဝတီတိုင်း",
  };

  final List<String> nrcTypes = ["(နိုင်)", "(ပြု)", "(ဧည့်)"];

  final Map<String, List<String>> townshipData = {
    "၁/": [
      "အဂယ",
      "ဗမန",
      "ခဖန",
      "ဒဖယ",
      "ဟပန",
      "ကမန",
      "ခလဖ",
      "လဂန",
      "မခဘ",
      "မစန",
      "မညန",
      "မကတ",
      "မမန",
      "မကန",
      "နမန",
      "ဖကန",
      "ပတအ",
      "ရကန",
      "ဆဘန",
      "ဆလန",
      "ဆပဘ",
      "တနန",
      "ဝမန",
    ],
    "၂/": ["ဘလခ", "ဒမဆ", "လကန", "မဆန", "ဖဆန", "ဖရဆ", "ရတန"],
    "၃/": [
      "လဘန",
      "ကကရ",
      "ကဆက",
      "ကဒန",
      "မဝတ",
      "ဖအန",
      "ဘအန",
      "ဖပန",
      "သတန",
    ],
    "၄/": [
      "ဟခန",
      "ထတလ",
      "ကပလ",
      "မတပ",
      "မတန",
      "ဖလန",
      "ပလဝ",
      "တတန",
      "တဇန",
    ],
    "၅/": [
      "အရတ",
      "ဗမန",
      "ဘတလ",
      "ခဥန",
      "ဒပယ",
      "ဟမလ",
      "ထခန",
      "အတန",
      "ကနန",
      "ကသန",
      "ကလထ",
      "ကလဝ",
      "ကဘန",
      "ကလတ",
      "ခတန",
      "ခဥတ",
      "ကလန",
      "မလန",
      "မကန",
      "မရန",
      "မမန",
      "နယန",
      "ငဇန",
      "ပလန",
      "ဖပန",
      "ပလဘ",
      "စကန",
      "ဆလက",
      "ရဘန",
      "တမန",
      "တဆန",
      "ဝလန",
      "ဝသန",
      "ရဥန",
      "ယမပ",
      "ရသက",
    ],
    "၆/": [
      "ဘပန",
      "ထဝန",
      "ကသန",
      "ကစန",
      "လလန",
      "မမန",
      "မအရ",
      "ငရက",
      "ပလန",
      "တနသ",
      "တသရ",
      "သရခ",
      "ရဖန",
    ],
    "၇/": [
      "အဖန ",
      "အဖန",
      "အတန",
      "ဒဥန",
      "ထတပ",
      "ကတတ",
      "ကပက",
      "ကကန",
      "ကတခ",
      "ကကန",
      "မဒန",
      "မလန",
      "မညန",
      "နတလ",
      "ညလပ",
      "ပနက",
      "ပခန",
      "ပတန",
      "ပခန",
      "ပတတ",
      "ဖမန ",
      "ပမန",
      "ပတစ",
      "ရကန ",
      "ရတန",
      "တငန",
      "သနပ",
      "သကန",
      "သဝတ",
      "သဆန",
      "ဝမန",
      "ရတရ",
      "ဇကန",
    ],
    "၈/": [
      "အလန",
      "ခမန",
      "ဂဂန",
      "ဆဖန",
      "ဆပဝ",
      "ထလန",
      "ကမန",
      "မကန",
      "မဘန",
      "မလန",
      "မတန",
      "မမန",
      "မထန",
      "မသန",
      "နမန",
      "ငဖန",
      "ပခက",
      "ပမန",
      "ပဖန",
      "စလန",
      "စတရ",
      "စကန",
      "တတက",
      "သရန",
      "ဆမန",
      "ရနခ",
      "ရစက",
    ],
    "၉/": [
      "ဒခသ",
      "လဝန",
      "ဥတသ",
      "ပဗသ",
      "ပမန",
      "တကန",
      "ဇဗသ",
      "ဇယသ",
      "အမရ",
      "အမဇ",
      "ခအစ",
      "ခမစ",
      "ကပတ",
      "ကဆန",
      "မလန",
      "မဟမ",
      "မနမ",
      "မနတ",
      "မရမ",
      "မရတ",
      "မတရ",
      "မမန",
      "မထလ",
      "မကန",
      "မခန",
      "မသန",
      "နထက",
      "ငသရ",
      "ညဥန",
      "ပလန",
      "ပသက",
      "ပဖန",
      "ပကခ",
      "ပဥလ",
      "ပမန",
      "စကတ",
      "ဆကန",
      "တကန",
      "တတဥ",
      "တသန",
      "သပက",
      "သစန",
      "ဝတန",
      "ရမသ",
    ],
    "၁၀/": [
      "ဘလန",
      "ခဆန",
      "ကမရ",
      "ကထန",
      "မလမ",
      "မဒန",
      "ပမန",
      "သဖရ",
      "သထန",
      "ခဇန",
      "လမန",
      "ရမန",
    ],
    "၁၁/": [
      "အမန",
      "ဘသတ",
      "ဂမန",
      "ကဖန",
      "ကတန",
      "မအန",
      "မတန",
      "မပန",
      "မဥန",
      "မပတ",
      "ပတန",
      "ပဏက",
      "စတန",
      "တကန",
      "သတန",
      "ရဗန",
      "ရသတ",
    ],
    "၁၂/": [
      "အလန",
      "ဗဟန",
      "ဗတထ",
      "ကကက",
      "ဒဂန",
      "ဒဂရ",
      "ဒဂမ",
      "ဒဆက",
      "ဒဂတ",
      "ဒလန",
      "ဒပန",
      "လမန",
      "လသယ",
      "လကန",
      "မဘန",
      "ထတပ",
      "အစန",
      "ကမရ",
      "ကမန",
      "ခရန",
      "ကခက",
      "ကတတ",
      "ကတန",
      "ကမတ",
      "လမတ",
      "လသန",
      "မရက",
      "မဂတ",
      "မဂဒ",
      "ဥကမ",
      "ပဘတ",
      "ပဇတ",
      "စခန",
      "ဆကခ",
      "ဆကန",
      "ရပက",
      "ရပသ",
      "ဥကတ",
      "တကန",
      "တမန",
      "သကတ",
      "သလန",
      "သဃက",
      "သခန",
      "တတန",
      "ရကန",
    ],
    "၁၃/": [
      "ခရဟ",
      "ဟပတ",
      "ဟပန",
      "ကလန",
      "ကလတ",
      "ကဟန",
      "ကသန",
      "ကတတ",
      "ကတန",
      "ကမန",
      "ကခန",
      "လရန",
      "လကန",
      "လခတ",
      "လခန",
      "လလန",
      "မဘန",
      "မကန",
      "မခန",
      "မဖန",
      "မပတ",
      "မဆန",
      "မရန",
      "မရတ",
      "မတတ",
      "မမတ",
      "မနန",
      "မကန",
      "မဆတ",
      "နမတ",
      "နခန",
      "နဆန",
      "နဖန",
      "နခတ",
      "ညရန",
      "ဖခန",
      "ပလန",
      "ပတရ",
      "ဆဆန",
      "ရညန",
      "တယန",
      "တမည",
      "တခလ",
      "တလန",
      "တကန",
      "သနန",
      "သပန",
      "ရငန",
      "ရစန",
    ],
    "၁၄/": [
      "ဘကလ",
      "ဓနဖ",
      "ဒဒရ",
      "ပသရ",
      "အမန",
      "ဟကက",
      "ဟသတ",
      "အဂပ",
      "ခနန",
      "ကလန",
      "ကခန",
      "ကကန",
      "ကပန",
      "လပတ",
      "လမန",
      "မအပ",
      "မမက",
      "မအန",
      "မမန",
      "ငပတ",
      "ငသခ",
      "ညတန",
      "ပတန",
      "ဖပန",
      "သပန",
      "ဝခမ",
      "ပသန",
      "ရကန",
      "ဇလန",
      "ကကထ",
    ],
  };

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _birthController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _nrcController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // 🚨 BACKEND (DJANGO) သို့ အချက်အလက်များ လှမ်းပို့သည့် FUNCTION 🚨
  Future<void> _handleRegister() async {
    if (!_step3Key.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar("လျှို့ဝှက်နံပါတ်များ မကိုက်ညီပါ", Colors.red);
      return;
    }

    if (selectedGender == null) {
      _showSnackBar("ကျား/မ (Gender) ရွေးချယ်ပေးရန် လိုအပ်ပါသည်", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    // 💡 စက်တွင်း Emulator ဖြစ်ပါက 10.0.2.2 ကိုသုံးပါ၊ ဖုန်းအစစ်ဖြင့်စမ်းပါက ကွန်ပျူတာ IP ပြောင်းပေးပါ
    const String apiUrl =ApiConfig.register;

    // မှတ်ပုံတင်နံပါတ်အား တစ်ကြောင်းတည်းဖြစ်အောင် ပေါင်းစပ်ခြင်း
    String fullNrc = "";
    if (selectedNrcState != null &&
        selectedNrcTownship != null &&
        selectedNrcType != null) {
      fullNrc =
          "$selectedNrcState$selectedNrcTownship${selectedNrcType}${_nrcController.text.trim()}";
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json",
                   'ngrok-skip-browser-warning':'true'
        },
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "password": _passwordController.text,
          "full_name": _nameController.text.trim(),
          "phone_number": _phoneController.text.trim(),
          "nrc_number": fullNrc,
          "address": _addressController.text.trim(),
          "dob": _birthController.text.trim(),
          "gender": selectedGender,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        setState(() => _isLoading = false);
        _showSnackBar("အကောင့်ဖွင့်ခြင်း အောင်မြင်ပါသည်", Colors.green);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } else {
        setState(() => _isLoading = false);
        _showSnackBar(
          responseData['errors'] ??
              responseData['message'] ??
              "အကောင့်ဖွင့်ခြင်း မအောင်မြင်ပါ",
          Colors.red,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("ချိတ်ဆက်မှု Error တက်နေပါသည်: $e", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Myanmar')),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF18479D),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _nextPage() {
    bool valid = false;

    if (_currentPage == 0) {
      valid = _step1Key.currentState!.validate();

      if (!valid) return;

      if (selectedGender == null) {
        _showSnackBar("ကျား/မ ရွေးချယ်ပေးပါ", Colors.red);
        return;
      }
    }

    if (_currentPage == 1) {
      valid = _step2Key.currentState!.validate();

      if (!valid) return;

      if (selectedNrcState == null ||
          selectedNrcTownship == null ||
          selectedNrcType == null) {
        _showSnackBar("NRC အချက်အလက် အပြည့်အစုံရွေးပါ", Colors.red);
        return;
      }
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Header - Logo နဲ့ System Name
                        Row(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    "assets/image/Logo2.PNG",
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      "Wondarmi",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "Loan System",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Language Toggle
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isMyanmar = !isMyanmar;
                                });
                              },
                              child: Container(
                                width: 120,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Stack(
                                  children: [
                                    AnimatedAlign(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      alignment:
                                          isMyanmar
                                              ? Alignment.centerLeft
                                              : Alignment.centerRight,
                                      child: Container(
                                        width: 60,
                                        height: 45,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
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
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    isMyanmar
                                                        ? const Color(
                                                          0xFF18479D,
                                                        )
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
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    !isMyanmar
                                                        ? const Color(
                                                          0xFF18479D,
                                                        )
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
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          text["title"]!,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          text["sub"]!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // PROGRESS INDICATOR BARS
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildStepper(),
                        ),
                        const SizedBox(height: 10),
                        // PAGEVIEW FORM CONTAINER
                        SizedBox(
                          height: 520,
                          child: Card(
                            color: Colors.white,
                            elevation: 8,
                            shadowColor: Colors.black45,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: PageView(
                                controller: _pageController,
                                physics: const NeverScrollableScrollPhysics(),
                                onPageChanged:
                                    (page) =>
                                        setState(() => _currentPage = page),
                                children: [
                                  _buildStep1(),
                                  _buildStep2(),
                                  _buildStep3(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // NAVIGATION BUTTONS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_currentPage > 0)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _previousPage,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    text["btn_back"]!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            else
                              const Spacer(),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading
                                        ? null
                                        : (_currentPage == 2
                                            ? _handleRegister
                                            : _nextPage),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF18479D),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                ),
                                child:
                                    _isLoading && _currentPage == 2
                                        ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF18479D),
                                          ),
                                        )
                                        : Text(
                                          _currentPage == 2
                                              ? text["btn_register"]!
                                              : text["btn_next"]!,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${text["already_account"]!} ",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                );
                              },
                              child: Text(
                                text["login"]!,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
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
            ),
          ],
        ),
      ),
    );
  }

  // STEP 1: PERSONAL INFORMATION
  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text["step1"]!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "အမည်ဖြည့်ပါ";
                }

                String name = value.trim();

                bool hasEnglish = false;
                bool hasMyanmar = false;

                // Character validation
                for (int i = 0; i < name.length; i++) {
                  String char = name[i];
                  int code = char.codeUnitAt(0);

                  bool english =
                      (code >= 65 && code <= 90) ||
                          (code >= 97 && code <= 122);

                  bool myanmar =
                  (code >= 0x1000 && code <= 0x109F);

                  bool space = char == " ";

                  if (english) hasEnglish = true;
                  if (myanmar) hasMyanmar = true;

                  if (!english && !myanmar && !space) {
                    return "English နှင့် Myanmar စာလုံးများသာ ထည့်ပါ";
                  }
                }

                // English only -> require 2-5 words
                if (hasEnglish && !hasMyanmar) {
                  List<String> words =
                  name.split(RegExp(r'\s+'));

                  if (words.length < 2) {
                    return "English အမည် အနည်းဆုံး ၂ လုံးဖြည့်ပါ";
                  }

                  if (words.length > 5) {
                    return "English အမည် အများဆုံး ၅ လုံးသာဖြည့်ပါ";
                  }
                }

                return null;
              },
              decoration: _customInputStyle(text["fullname"]!),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "ဖုန်းနံပါတ်ဖြည့်ပါ";
                }

                String phone = value.trim();

                phone = phone.replaceAll(RegExp(r'[\s-]'), '');

                // ATOM (09 + 7 + 8 digits)
                if (RegExp(r'^097\d{8}$').hasMatch(phone)) {
                  return null;
                }

                // U9 (09 + 9 + 8 digits)
                if (RegExp(r'^099\d{8}$').hasMatch(phone)) {
                  return null;
                }

                // Mytel (09 + 6 + 8 digits)
                if (RegExp(r'^096\d{8}$').hasMatch(phone)) {
                  return null;
                }

                // MPT Mobile
                // 09 + (2/4/5/8) + 8 digits = 11 digits
                if (RegExp(r'^09(2|4|5|8)\d{8}$').hasMatch(phone)) {
                  return null;
                }

                // MPT Landline
                // 01 + 7 digits = 9 digits
                if (RegExp(r'^01\d{7}$').hasMatch(phone)) {
                  return null;
                }

                return "မြန်မာဖုန်းနံပါတ် မှန်ကန်စွာထည့်ပါ";
              },
              decoration: _customInputStyle(text["phone"]!),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _birthController,
              readOnly: true,
              onTap: () => _selectDate(context),
             validator: (value) {
                if (value == null || value.isEmpty) {
                  return "မွေးသက္ကရာဇ်ရွေးချယ်ပါ";
                }

                try {
                  DateTime dob = DateTime.parse(value);
                  DateTime today = DateTime.now();

                  int age = today.year - dob.year;

                  // ဒီနှစ် မွေးနေ့မရောက်သေးရင် ၁ နှစ်လျှော့
                  if (today.month < dob.month ||
                      (today.month == dob.month && today.day < dob.day)) {
                    age--;
                  }

                  if (age < 18) {
                    return "အသက် ၁၈ နှစ်အထက်မှ စာရင်းသွင်းနိုင်ပါသည်";
                  }

                  return null;
                } catch (e) {
                  return "မွေးသက္ကရာဇ် မမှန်ကန်ပါ";
                }
              },
              decoration: _customInputStyle(text["dob"]!).copyWith(
                suffixIcon: const Icon(
                  Icons.calendar_month,
                  color: Color(0xFF18479D),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              text["gender"]!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildGenderCard(
                  "ကျား",
                  Icons.male,
                  text["male"]!,
                  const Color(0xFF2F6BFF), // Blue
                ),

                const SizedBox(width: 8),

                _buildGenderCard(
                  "မ",
                  Icons.female,
                  text["female"]!,
                  const Color(0xFFFF5CA8), // Pink
                ),

                const SizedBox(width: 8),

                _buildGenderCard(
                  "အခြား",
                  Icons.more_horiz,
                  text["other"]!,
                  Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // STEP 2: ACCOUNT INFORMATION
  Widget _buildStep2() {
    return Form(
      key: _step2Key,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text["step2"]!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "အီးမေးလ်ဖြည့်ပါ";
                }

                String email = value.trim();

                // Gmail only + first letter lowercase + digit allowed after first character
                if (!RegExp(
                  r'^[a-z][a-z0-9._%+-]*@gmail\.com$',
                ).hasMatch(email)) {
                  return "မှန်ကန်သော Gmail ထည့်ပါ";
                }

                return null;
              },
              decoration: _customInputStyle(
                text["email"]!,
              ).copyWith(hintText: "example11@gmail.com"),
            ),
            const SizedBox(height: 18),
            const Text(
              "မှတ်ပုံတင်အမှတ် ရွေးချယ်/ဖြည့်သွင်းပါ",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedNrcState,
                  hint: const Text("ပြည်နယ်/တိုင်း"),
                  items:
                      nrcStates.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(
                            "${entry.key} ${entry.value}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedNrcState = v;
                      selectedNrcTownship = null;
                    });
                  },
                  decoration: _customDropdownStyle(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedNrcTownship,
                  hint: const Text("မြို့နယ်"),
                  items:
                      selectedNrcState == null
                          ? []
                          : townshipData[selectedNrcState]!
                              .map(
                                (township) => DropdownMenuItem(
                                  value: township,
                                  child: Text(
                                    township,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedNrcTownship = v;
                    });
                  },
                  decoration: _customDropdownStyle(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedNrcType,
                  hint: const Text("(နိုင်)"),
                  items:
                      nrcTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedNrcType = v;
                    });
                  },
                  decoration: _customDropdownStyle(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nrcController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "မှတ်ပုံတင်ဂဏန်း ၆ လုံးဖြည့်ပါ";
                }

                final nrc = value.trim();

                // 6 digits only
                if (!RegExp(r'^\d{6}$').hasMatch(nrc)) {
                  return "၆လုံးတိတိ ဂဏန်းသာထည့်ရပါမည်";
                }

                // Reject only 000000 ~ 000099
                if (int.parse(nrc) <= 99) {
                  return "ဤနံပါတ်ကို အသုံးမပြုနိုင်ပါ";
                }

                return null;
              },
              decoration: _customInputStyle(text["nrc"]!),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 3: SECURITY & ADDRESS
  Widget _buildStep3() {
    return Form(
      key: _step3Key,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text["step3"]!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return "နေရပ်လိပ်စာဖြည့်ပါ";
                }

                String address = v.trim();

                // Space , ၊ . - ( ) နဲ့ ခွဲမယ်
                List<String> parts = address.split(
                    RegExp(r'[\s,၊.\-()]+')
                ).where((e) => e.isNotEmpty).toList();

                if (parts.length < 2) {
                  return "နေရပ်လိပ်စာ အနည်းဆုံး၂လုံးသေချာဖြည့်ပေးပါါ";
                }

                return null;
              },
              decoration: _customInputStyle(
                text["address"]!,
              ).copyWith(hintText: "အိမ်အမှတ်()၊လမ်းအမည်၊ရပ်ကွက်၊မြို့"),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "လျှို့ဝှက်နံပါတ်ဖြည့်ပါ";
                }
                if (value.length < 8) {
                  return "Password အနည်းဆုံး 8 လုံးရှိရမည်";
                }
                if (!RegExp(r'[A-Z]').hasMatch(value)) {
                  return "စာလုံးအကြီး (A-Z) တစ်လုံးပါရမည်";
                }
                if (!RegExp(r'[a-z]').hasMatch(value)) {
                  return "စာလုံးအသေး (a-z) တစ်လုံးပါရမည်";
                }
                if (!RegExp(r'[0-9]').hasMatch(value)) {
                  return "ဂဏန်းတစ်လုံး ပါရမည်";
                }
                if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) {
                  return "Special Character တစ်လုံး ပါရမည်";
                }
                return null;
              },
              decoration: _customInputStyle(text["password"]!).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Password ထပ်ရိုက်ပါ";
                }
                if (value != _passwordController.text) {
                  return "Password မကိုက်ညီပါ";
                }
                return null;
              },
              decoration: _customInputStyle(text["confirm_password"]!).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepItem(0),
        Expanded(child: _stepLine(0)),
        _stepItem(1),
        Expanded(child: _stepLine(1)),
        _stepItem(2),
      ],
    );
  }

  Widget _stepItem(int index) {
    final bool active = _currentPage >= index;
    final bool completed = _currentPage > index;

    return SizedBox(
      width: 60,
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? const Color(0xFF18479D) : const Color(0xFFE6E8EF),
              border: Border.all(
                width: 2,
                color:
                    completed
                        ? Colors.green
                        : active
                        ? const Color(0xFF18479D)
                        : Colors.grey.shade300,
              ),
            ),
            child: Center(
              child:
                  completed
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text(
                        "${index + 1}",
                        style: TextStyle(
                          color: active ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Step ${index + 1}",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? Colors.black87 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepLine(int index) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      height: 2,
      color:
          _currentPage > index
              ? Colors.green
              : _currentPage >= index
              ? const Color(0xFF18479D)
              : const Color(0xFFE6E8EF),
    );
  }

  // GENDER SELECTION CARD COMPONENT
  Widget _buildGenderCard(
    String value,
    IconData icon,
    String title,
    Color accentColor,
  ) {
    final bool isSelected = selectedGender == value;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            selectedGender = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 95,
          decoration: BoxDecoration(
            color: isSelected ? accentColor.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? accentColor : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: accentColor.withOpacity(.12),
                child: Icon(icon, size: 22, color: accentColor),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? accentColor : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _customInputStyle(String label) {
    return InputDecoration(
      labelText: label,
      hintText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF18479D), width: 2),
      ),
    );
  }

  InputDecoration _customDropdownStyle() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
    );
  }
}
