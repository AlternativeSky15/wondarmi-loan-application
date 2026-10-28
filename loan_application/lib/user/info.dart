import 'package:loan_application/user/Home2.dart';
import 'package:loan_application/user/chat1.dart';
import 'package:loan_application/user/login.dart';
import 'register.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: IntroScreen(nextPage: HomePage()),
    );
  }
}

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, required Widget nextPage});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

// class _IntroScreenState extends State<IntroScreen> {
//   const IntroScreen({super.key});

//   @override
//   State<IntroScreen> createState() => _IntroScreenState();
// }

class _IntroScreenState extends State<IntroScreen> {
  final PageController _controller = PageController();
  int currentPage = 0;
  bool isEnglish = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // App စဖွင့်ချင်း Login စစ်မည်
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  // အကောင့်ဝင်/မဝင် စစ်ပေးမည့် function
  Future<void> _handleLoginNavigation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      // Login Page ကို အစားထိုးပါ[cite: 3]
    }
  }

  Widget buildLogoPage() {
    return Container(
      color: const Color(0xffF3F0FC),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.55,
              child: CustomPaint(painter: WandamiPainter()),
            ),
          ),

          Center(
            child: Transform.translate(
              offset: const Offset(0, -120),
              child: Image.asset(
                "assets/image/Logo2.PNG",
                width: 190,
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    "ပုံရှာမတွေ့ပါ",
                  ); // ပုံမပေါ်ရင် Error message ပြမည်
                },
              ),
            ),
          ),

          Positioned(
            bottom: 25,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xff37C8A7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // int currentPage = 0;
  // bool isEnglish = false;

  final List<Map<String, String>> pages = [
    {
      "image": "https://cdn-icons-png.flaticon.com/512/4320/4320337.png",

      "title_en": "Finance Management",
      "title_mm": "ငွေကြေးစီမံခန့်ခွဲမှု",

      "desc_en":
          "Organize and manage your financial activities systematically.",

      "desc_mm":
          "ငွေကြေးဆိုင်ရာလုပ်ငန်းများကို\nစနစ်တကျ စီမံနိုင်စေရန် ကူညီပေးပါသည်။",
    },
    {
      "image": "https://cdn-icons-png.flaticon.com/512/2910/2910768.png",

      "title_en": "Security",
      "title_mm": "လုံခြုံမှု",

      "desc_en": "Your information is stored safely and securely.",

      "desc_mm": "သင့်အချက်အလက်များကို\nလုံခြုံစွာ သိမ်းဆည်းပေးပါသည်။",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffDCEEFF), //  BACKGROUND
      body: SafeArea(
        child: Column(
          children: [
            // TOP BAR
            if (currentPage != 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text("🇬🇧", style: TextStyle(fontSize: 30)),
                        const SizedBox(width: 10),

                        // SWITCH
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isEnglish = !isEnglish;
                            });
                          },

                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),

                            width: 60,
                            height: 32,

                            padding: const EdgeInsets.all(3),

                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),

                            alignment:
                                isEnglish
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,

                            child: Container(
                              width: 26,
                              height: 26,

                              decoration: const BoxDecoration(
                                color: const Color(0xff18479D),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        const Text("🇲🇲", style: TextStyle(fontSize: 30)),
                      ],
                    ),

                    // Text(
                    //   isEnglish ? "Version 4.0.4" : "ဗားရှင်း ၄.၀.၄",
                    //   style: TextStyle(
                    //     color: Color(0xff18479D),
                    //     fontSize: 20,
                    //     fontWeight: FontWeight.bold,
                    //   ),
                    // ),
                  ],
                ),
              ),

            // MAIN CARD
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: pages.length + 2,
                      onPageChanged: (index) {
                        setState(() {
                          currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return buildLogoPage();
                        }

                        if (index == pages.length + 1) {
                          return Padding(
                            padding: const EdgeInsets.all(20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 25,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,

                                  children: [
                                    //////////////////////////////////////////////////////
                                    // TITLE
                                    //////////////////////////////////////////////////////
                                    Text(
                                      isEnglish ? "Welcome" : "ကြိုဆိုပါသည်",

                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff18479D),
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    Text(
                                      isEnglish
                                          ? "Choose how you want to continue"
                                          : "ဆက်လက်အသုံးပြုရန် ရွေးချယ်ပါ",

                                      textAlign: TextAlign.center,

                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    const SizedBox(height: 50),

                                    //////////////////////////////////////////////////////
                                    // BOT BOX
                                    //////////////////////////////////////////////////////
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const WonderamiChatApp(),
                                          ),
                                        );
                                      },

                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(22),

                                        decoration: BoxDecoration(
                                          color: Color(0xff18479D),

                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),

                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.red.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 15,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),

                                        child: Row(
                                          children: [
                                            //////////////////////////////////////////////////
                                            // ICON
                                            //////////////////////////////////////////////////
                                            Container(
                                              width: 65,
                                              height: 65,

                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),

                                              child: const Icon(
                                                Icons.smart_toy_rounded,
                                                color: Color(0xff18479D),
                                                size: 38,
                                              ),
                                            ),

                                            const SizedBox(width: 18),

                                            //////////////////////////////////////////////////
                                            // TEXT
                                            //////////////////////////////////////////////////
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,

                                                children: [
                                                  Text(
                                                    isEnglish
                                                        ? "Talk with Bot"
                                                        : "Botနှင့်ပြောရန်",

                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),

                                                  const SizedBox(height: 6),

                                                  Text(
                                                    isEnglish
                                                        ? "Ask questions instantly."
                                                        : "မေးခွန်းများကို ချက်ချင်းမေးနိုင်ပါသည်။",

                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 25),

                                    //////////////////////////////////////////////////////
                                    // LOGIN BOX
                                    //////////////////////////////////////////////////////
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => const LoginPage(),
                                          ),
                                        );
                                      },

                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(22),

                                        decoration: BoxDecoration(
                                          color: Colors.white,

                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),

                                          border: Border.all(
                                            color: const Color(0xff18479D),
                                            width: 2,
                                          ),

                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),

                                        child: Row(
                                          children: [
                                            //////////////////////////////////////////////////
                                            // ICON
                                            //////////////////////////////////////////////////
                                            Container(
                                              width: 65,
                                              height: 65,

                                              decoration: BoxDecoration(
                                                color: const Color(0xff18479D),

                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),

                                              child: const Icon(
                                                Icons.lock_outline_rounded,
                                                color: Colors.white,
                                                size: 38,
                                              ),
                                            ),

                                            const SizedBox(width: 18),

                                            //////////////////////////////////////////////////
                                            // TEXT
                                            //////////////////////////////////////////////////
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,

                                                children: [
                                                  Text(
                                                    isEnglish
                                                        ? "Login Account"
                                                        : "အကောင့်ဝင်ရန်",

                                                    style: const TextStyle(
                                                      color: const Color(
                                                        0xff18479D,
                                                      ),
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),

                                                  const SizedBox(height: 6),

                                                  Text(
                                                    isEnglish
                                                        ? "Securely access your account."
                                                        : "သင့်အကောင့်ကို လုံခြုံစွာ ဝင်ရောက်ပါ။",

                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade700,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        if (index == 0) {
                          return buildLogoPage();
                        }

                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),

                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 25,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // IMAGE
                                  CircleAvatar(
                                    radius: 70,
                                    backgroundColor: const Color(0xffEAF1FF),
                                    child: Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Image.network(
                                        pages[index - 1]["image"]!,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 40),

                                  // TITLE
                                  Text(
                                    isEnglish
                                        ? pages[index - 1]["title_en"]!
                                        : pages[index - 1]["title_mm"]!,

                                    textAlign: TextAlign.center,

                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                      color: const Color(0xff18479D),
                                    ),
                                  ),
                                  const SizedBox(height: 25),

                                  // DESCRIPTION
                                  Text(
                                    isEnglish
                                        ? pages[index - 1]["desc_en"]!
                                        : pages[index - 1]["desc_mm"]!,

                                    textAlign: TextAlign.center,

                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      height: 1.5,
                                      letterSpacing: 0.3,
                                      color: Colors.black,
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

                  // DOTS
                  if (currentPage != 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        4,

                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: currentPage == index ? 24 : 10,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                currentPage == index
                                    ? const Color(0xff37C8A7)
                                    : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),

                  if (currentPage != 0) const SizedBox(height: 25),

                  if (currentPage != 0)
                    Text(
                      isEnglish
                          ? "Swipe to explore."
                          : "ဆွဲပြီးလေ့လာနိုင်ပါသည်။",

                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                  if (currentPage != 0) const SizedBox(height: 30),

                  // BUTTON
                  if (currentPage != 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 25, bottom: 20),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: GestureDetector(
                          onTap: _handleLoginNavigation,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isEnglish ? "Enter App" : "App စတင်ဝင်မည်",

                                style: TextStyle(
                                  color: Color(0xff18479D),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(
                                Icons.arrow_forward,
                                color: const Color(0xff18479D),
                                size: 26,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WandamiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    //////////////////////////////////////////
    // GREEN BORDER
    //////////////////////////////////////////

    final greenPaint =
        Paint()
          ..color = const Color(0xff37C8A7)
          ..style = PaintingStyle.fill;

    final greenPath = Path();

    greenPath.moveTo(0, size.height * 0.33);

    greenPath.lineTo(size.width * 0.31, size.height * 0.39);

    greenPath.lineTo(size.width * 0.49, size.height * 0.56);

    greenPath.lineTo(size.width * 0.84, size.height * 0.65);

    greenPath.lineTo(size.width, size.height * 0.95);

    greenPath.lineTo(size.width, size.height);
    greenPath.lineTo(0, size.height);

    greenPath.close();

    canvas.drawPath(greenPath, greenPaint);

    //////////////////////////////////////////
    // BLUE SHAPE
    //////////////////////////////////////////

    final bluePaint =
        Paint()
          ..color = const Color(0xff18479D)
          ..style = PaintingStyle.fill;

    final bluePath = Path();

    bluePath.moveTo(0, size.height * 0.36);

    bluePath.lineTo(size.width * 0.30, size.height * 0.42);

    bluePath.lineTo(size.width * 0.47, size.height * 0.58);

    bluePath.lineTo(size.width * 0.82, size.height * 0.67);

    bluePath.lineTo(size.width, size.height * 0.98);

    bluePath.lineTo(size.width, size.height);
    bluePath.lineTo(0, size.height);

    bluePath.close();

    canvas.drawPath(bluePath, bluePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
