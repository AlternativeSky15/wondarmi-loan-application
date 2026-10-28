// about_app.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'app_languages.dart';

class AboutAppPage extends StatefulWidget {
  const AboutAppPage({super.key});

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> {
  String appVersion = "1.0.0";
  String buildNumber = "1";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getAppInfo();
  }

  Future<void> _getAppInfo() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        appVersion = packageInfo.version;
        buildNumber = packageInfo.buildNumber;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xff1A237E)),
        ),
        title: Text(
          AppLanguage.text("About App", "အက်ပ်အကြောင်း"),
          style: TextStyle(
            color: Color(0xff1A237E),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),

      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xff1A237E)),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,

                  children: [
                    Container(
                      width: 120,
                      height: 120,

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),

                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff18479D).withOpacity(0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),

                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),

                        child: Image.asset(
                          "assets/image/Logo2.PNG",

                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      "ဝန္ဒာမိ",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1A237E),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      AppLanguage.text(
                        "Smart Loan System",
                        "အသေးစားချေးငွေလုပ်ငန်း",
                      ),
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),

                      decoration: BoxDecoration(
                        color: const Color(0xff18479D).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),

                      // child:Text(
                      //   AppLanguage.text(
                      //     "Version $appVersion (Build $buildNumber)",
                      //     "ဗားရှင်း $appVersion (Build $buildNumber)",
                      //   ),
                      //   style:const TextStyle(
                      //     fontSize:13,
                      //     color:Color(0xff18479D),
                      //     fontWeight:FontWeight.w600,
                      //   ),
                      // ),
                    ),

                    const SizedBox(height: 30),

                    _buildInfoCard(
                      icon: Icons.info_outline_rounded,
                      title: AppLanguage.text("About App", "အက်ပ်အကြောင်း"),

                      description: AppLanguage.text(
                        "Wondarmi is a modern loan management system that helps users apply for loans, check loan eligibility and manage financial activities easily.",
                        "ကျွန်တော်တို့ ဝန္ဒာမိ အက်ပ်ပလီကေးရှင်း သည် အသုံးပြုသူများအတွက် ချေးငွေလျှောက်ထားခြင်း၊ ချေးငွေရယူနိုင်မှု စစ်ဆေးခြင်းနှင့် ငွေကြေးဆိုင်ရာ လုပ်ဆောင်ချက်များကို လွယ်ကူစွာ စီမံနိုင်ရန် ဖန်တီးထားသော ခေတ်မီချေးငွေစီမံခန့်ခွဲမှုစနစ် ဖြစ်ပါသည်။",
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildInfoCard(
                      icon: Icons.security_rounded,
                      title: AppLanguage.text(
                        "Security & Privacy",
                        "လုံခြုံရေးနှင့် ကိုယ်ရေးအချက်အလက်",
                      ),

                      description: AppLanguage.text(
                        "Your personal information is stored securely with priority on data protection and privacy.",
                        "သင့်၏ ကိုယ်ရေးအချက်အလက်များကို လုံခြုံစွာ သိမ်းဆည်းထားပြီး အချက်အလက်လုံခြုံရေးနှင့် ကိုယ်ရေးကိုယ်တာကာကွယ်မှုကို ဦးစားပေးထားပါသည်။",
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildInfoCard(
                      icon: Icons.contact_support_rounded,
                      title: AppLanguage.text("Get Help", "အကူအညီရယူရန်"),

                      description: AppLanguage.text(
                        "If you have any questions or need help, contact us.\n\nsupport@wondarmi.com\n+95 9 123 4567",
                        "မေးခွန်းများ သို့မဟုတ် အကူအညီလိုအပ်ပါက ဆက်သွယ်နိုင်ပါသည်။\n\nsupport@wondarmi.com\n+95 9 123 4567",
                      ),
                    ),

                    const SizedBox(height: 30),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),

                      decoration: BoxDecoration(
                        color: const Color(0xffF4F1FF),
                        borderRadius: BorderRadius.circular(16),
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            AppLanguage.text(
                              " Key Features",
                              " အဓိကလုပ်ဆောင်ချက်များ",
                            ),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff1A237E),
                            ),
                          ),

                          const SizedBox(height: 12),

                          _buildFeatureItem(
                            AppLanguage.text(
                              "Loan Eligibility Check",
                              "ချေးငွေရယူနိုင်မှု စစ်ဆေးခြင်း",
                            ),
                            AppLanguage.text(
                              "Check your loan eligibility using AI Chatbot.",
                              "AI Chatbot အသုံးပြုပြီး ချေးငွေရယူနိုင်မှုကို စစ်ဆေးနိုင်ပါသည်။",
                            ),
                          ),

                          _buildFeatureItem(
                            AppLanguage.text(
                              "Multiple Loan Categories",
                              "ချေးငွေအမျိုးအစားများစွာ",
                            ),
                            AppLanguage.text(
                              "Choose from agricultural loans, Consumer loans and small businness loans.",
                              "စိုက်ပျိုးရေးချေးငွေ၊ သုံးစွဲမှုချေးငွေ၊ အသေးစားစီးပွားရေးလုပ်ငန်းချေးငွေများကို ရွေးချယ်နိုင်ပါသည်။",
                            ),
                          ),

                          _buildFeatureItem(
                            AppLanguage.text(
                              "Loan Calculation System",
                              "ချေးငွေတွက်ချက်စနစ်",
                            ),
                            AppLanguage.text(
                              "Easily calculate your loan repayment amount.",
                              "ချေးငွေပေးဆပ်ရမည့် ပမာဏများကို လွယ်ကူစွာ တွက်ချက်နိုင်ပါသည်။",
                            ),
                          ),

                          _buildFeatureItem(
                            AppLanguage.text(
                              "Application History",
                              "လျှောက်ထားမှုမှတ်တမ်း",
                            ),
                            AppLanguage.text(
                              "View all your loan applications in one place.",
                              "သင်၏ ချေးငွေလျှောက်ထားမှုများကို တစ်နေရာတည်းတွင် ကြည့်ရှုနိုင်ပါသည်။",
                            ),
                          ),

                          _buildFeatureItem(
                            AppLanguage.text(
                              "Secure Profile Management",
                              "လုံခြုံသော Profile စီမံခန့်ခွဲမှု",
                            ),
                            AppLanguage.text(
                              "Securely manage and update your personal information.",
                              "ကိုယ်ရေးအချက်အလက်များကို လုံခြုံစွာ ပြင်ဆင်စီမံနိုင်ပါသည်။",
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    Text(
                      AppLanguage.text(
                        "© 2026 Wondarmi. All rights reserved.",
                        "© 2026 Wondarmi။ မူပိုင်ခွင့်အားလုံးရှိသည်။",
                      ),
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      AppLanguage.text(
                        "Made in Myanmar",
                        "မြန်မာနိုင်ငံတွင် ဖန်တီးထားသည်",
                      ),
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: const Color(0xffF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xff18479D)),

              const SizedBox(width: 12),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1A237E),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            description,
            style: TextStyle(fontSize: 14, color: Colors.black, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            "• ",
            style: TextStyle(color: Color(0xff18479D), fontSize: 18),
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1A237E),
                  ),
                ),

                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
