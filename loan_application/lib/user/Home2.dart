import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loan_application/constant.dart';
import 'package:loan_application/user/notification_page.dart';
import 'package:loan_application/user/payment_request_screen.dart';
import 'package:loan_application/user/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'history.dart';
import 'predict.dart';
import 'app_languages.dart';
import 'package:carousel_slider/carousel_slider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        primaryColor: const Color(0xFF1A237E),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> loanList = [];
  List<dynamic> categories = [];
  int selectedIndex = 0;
  int currentBanner = 0;
  int notificationCount = 0;
  String userName = "User";

  final List<Map<String, String>> banners = [
    {
      "image": "assets/image/loan1.jpg",
      "title": "ကိုယ်ပိုင်ချေးငွေ",
      "subtitle": "လွယ်ကူမြန်ဆန်စွာ လျှောက်ထားနိုင်ပါသည်",
    },
    {
      "image": "assets/image/loan2.jpg",
      "title": "လုပ်ငန်းချေးငွေ",
      "subtitle": "လုပ်ငန်းတိုးချဲ့ရန် ငွေကြေးအထောက်အပံ့",
    },
    {
      "image": "assets/image/loan3.jpg",
      "title": "စိုက်ပျိုးရေးချေးငွေ",
      "subtitle": "သင့်စိုက်ပျိုးရေးလုပ်ငန်းကို တိုးတက်အောင် အကူအညီပေးလိုက်ပါ",
    },
    {
      "image": "assets/image/loan4.jpg",
      "title": "လုပ်ငန်းချေးငွေ",
      "subtitle": "လုပ်ငန်းတိုးချဲ့ရန် ငွေကြေးအထောက်အပံ့",
    },
  ];

  int parseSafeInt(dynamic val) {
    if (val == null || val.toString().isEmpty || val.toString() == "null")
      return 0;
    return (double.tryParse(val.toString()) ?? 0).toInt();
  }

  String formatCurrencyMyanmar(dynamic amount) {
    int value = parseSafeInt(amount);
    String stringVal = value.toString();

    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const burmeseDigits = ['၀', '၁', '၂', '၃', '၄', '၅', '၆', '၇', '၈', '၉'];

    for (int i = 0; i < englishDigits.length; i++) {
      stringVal = stringVal.replaceAll(englishDigits[i], burmeseDigits[i]);
    }
    return stringVal;
  }

  bool isLoading = true;
  Map<String, dynamic> userData = {'photo': ''};

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.usercategory));
      if (response.statusCode == 200) {
        setState(() {
          categories = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadLoanSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("email");

    print("Email = $email");

    final response = await http.get(
      Uri.parse(ApiConfig.homesummary + "?email=$email"),
    );

    print("Status = ${response.statusCode}");
    print("Body = ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        loanList = data;
      });

      print("Loan List Updated: $loanList");
    }
  }

  Future<void> _loadNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("email");

    if (email == null || email.isEmpty) return;

    final response = await http.get(
      Uri.parse(ApiConfig.notificationcount + "?email=$email"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        notificationCount = data["count"] ?? 0;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    loadLanguage();
    _loadUser();
    _fetchCategories();
    _loadLoanSummary();
    _loadNotificationCount();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("email");

    if (email == null || email.isEmpty) return;

    final response = await http.post(
      Uri.parse(ApiConfig.userprofile),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        userName = data["user"]["full_name"] ?? "Guest";
        userData["photo"] =
            ApiConfig.baseUrl + "${data["user"]["photo"] ?? ""}";
      });
    }
  }

  Future<void> loadLanguage() async {
    await AppLanguage.load();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ===== CLEAN & MODERN HEADER =====
          Container(
            height: 350,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 164, 205, 223),
                  Color.fromARGB(255, 94, 127, 217),
                  Color.fromARGB(255, 5, 29, 79),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Stack(
              children: [
                /// Background Circle
                Positioned(
                  top: -50,
                  right: -40,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.08),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  left: -60,
                  bottom: 20,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 55, 22, 25),
                  child: Column(
                    children: [
                      /// TOP
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white,
                            backgroundImage:
                                userData['photo'] != null &&
                                        userData['photo'].isNotEmpty
                                    ? NetworkImage(userData['photo'])
                                    : null,
                            child:
                                userData['photo'] == null ||
                                        userData['photo'].isEmpty
                                    ? const Icon(Icons.person, size: 30)
                                    : null,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLanguage.text(
                                    "Welcome Back",
                                    "ပြန်လည်ကြိုဆိုပါတယ်",
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationPage(),
                                ),
                              );
                              _loadNotificationCount();
                            },
                            child: Stack(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(.12),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_none,
                                    color: Colors.white,
                                  ),
                                ),
                                if (notificationCount > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
                                      ),
                                      child: Text(
                                        notificationCount.toString(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      /// FLOATING CARD
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 33, 75, 166),
                              Color(0xFF2545A4),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(.35),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppLanguage.text("Savings", "စုငွေ"),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                const Icon(Icons.savings, color: Colors.white),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // 💡 backend မှ ရလာသော saving_amount ကို ပြသခြင်း
                            Text(
                              "ကျပ် ${formatCurrencyMyanmar(loanList.isNotEmpty ? (loanList[0]['saving_amount'] ?? 0) : 0)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 18),

                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    AppLanguage.text(
                                      "Available",
                                      "ရရှိနိုင်သည်",
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 5),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ===== BODY =====
          Expanded(
            child: Container(
              margin: EdgeInsets.zero,
              decoration: const BoxDecoration(
                color: Color(0xFFF4F8FF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Column(
                  children: [
                    const SizedBox(height: 13),

                    CarouselSlider(
                      options: CarouselOptions(
                        height: 170,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 3),
                        autoPlayAnimationDuration: const Duration(
                          milliseconds: 800,
                        ),
                        enlargeCenterPage: true,
                        viewportFraction: 1,
                        onPageChanged: (index, reason) {
                          setState(() {
                            currentBanner = index;
                          });
                        },
                      ),
                      items:
                          banners.map((banner) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(
                                    banner["image"]!,
                                    fit: BoxFit.cover,
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Colors.black.withOpacity(0.75),
                                          Colors.black.withOpacity(0.35),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          banner["title"]!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          banner["subtitle"]!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        banners.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: currentBanner == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                currentBanner == index
                                    ? const Color(0xFF1565C0)
                                    : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Categories Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLanguage.text(
                            "Categories",
                            "ချေးငွေအမျိုးအစားများ",
                          ),
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    // Categories Grid
                    isLoading
                        ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              color: Color(0xFF1A237E),
                            ),
                          ),
                        )
                        : categories.isEmpty
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              AppLanguage.text(
                                "No categories",
                                "အမျိုးအစားမရှိပါ",
                              ),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                        : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.90,
                              ),
                          itemCount:
                              categories.length > 4 ? 4 : categories.length,
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            final colors = [
                              const Color(0xFFE3EEFF),
                              const Color(0xFFFFF0E8),
                              const Color(0xFFE8F5E9),
                              const Color(0xFFFFE8EE),
                            ];
                            final accentColors = [
                              const Color(0xFF1A237E),
                              const Color(0xFFFF6B35),
                              const Color(0xFF2E7D32),
                              const Color(0xFFC62828),
                            ];

                            return GestureDetector(
                              onTap: () {
                                print(
                                  "Category from Home = ${cat['category_name']}",
                                );

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => LoanFormScreen(
                                          categoryId: cat['category_id'],
                                          selectedCategory:
                                              cat['category_name'],
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: colors[index % colors.length],
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (cat['image'] != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          ApiConfig.baseUrl + '${cat['image']}',
                                          width: 100,
                                          height: 95,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) => Icon(
                                                Icons.category,
                                                size: 30,
                                                color:
                                                    accentColors[index %
                                                        accentColors.length],
                                              ),
                                        ),
                                      )
                                    else
                                      Icon(
                                        Icons.category,
                                        size: 30,
                                        color:
                                            accentColors[index %
                                                accentColors.length],
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      cat['category_name'] ?? "Category",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF1A237E),
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 78,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (value) async {
              if (value == 0) {
                setState(() {
                  selectedIndex = 0;
                });
              } else if (value == 1) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                );
              } else if (value == 2) {
                if (loanList.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("ချေးငွေမရှိပါ")),
                  );
                  return;
                }

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => PaymentRequestScreen(
                          listId: loanList[0]["list_id"],
                        ),
                  ),
                );
              } else if (value == 3) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );

                await _loadUser();
                await AppLanguage.load();

                if (mounted) {
                  setState(() {
                    selectedIndex = 0;
                  });
                }
              }
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconSize: 28,
            selectedItemColor: const Color(0xFF1A237E),
            unselectedItemColor: Colors.grey,
            selectedFontSize: 13,
            unselectedFontSize: 12,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_rounded),
                label: AppLanguage.text("Home", "ပင်မ"),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.history_rounded),
                label: AppLanguage.text("History", "မှတ်တမ်း"),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.payment_rounded),
                label: AppLanguage.text("Payment", "ငွေပေးချေ"),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline_rounded),
                label: AppLanguage.text("Profile", "ပရိုဖိုင်"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A237E).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF1A237E), size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1A237E),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
