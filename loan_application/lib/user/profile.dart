import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:loan_application/user/editProfile.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loan_application/user/AboutApp.dart';
import 'package:loan_application/user/check_loan.dart';
import 'app_languages.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String fullName = "Loading...";
  bool isLoading = true;
  String phone = "";
  String email = "";
  String nrc = "";
  String dob = "";
  String gender = "";
  String photo = "";
  String selectedLanguage = "English";

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      selectedLanguage = prefs.getString("language") ?? "English";
      final savedEmail = prefs.getString("email");

      if (savedEmail == null || savedEmail.isEmpty) {
        setState(() {
          fullName = "Guest";
          isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse("http://10.114.214.88:8000/api/user-profile/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": savedEmail}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          fullName = data["user"]["full_name"] ?? "";
          phone = data["user"]["phone_number"] ?? "";
          email = prefs.getString("email") ?? "";
          nrc = data["user"]["nrc_number"] ?? "";
          dob = data["user"]["date_of_birth"] ?? "";
          gender = data["user"]["gender"] ?? "";
          photo = data["user"]["photo"] ?? "";
          isLoading = false;
        });
      } else {
        setState(() {
          fullName = "Unknown User";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        fullName = "Error";
        isLoading = false;
      });
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isLoggedIn", false);
    await prefs.remove("email");
    await prefs.remove("userName");
    await prefs.remove("token");
    await prefs.remove("user_id");

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil("/", (route) => false);
  }

  Future<void> chooseLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 15),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLanguage.text("Language", "ဘာသာစကား"),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ListTile(
                leading: const Text("🇲🇲", style: TextStyle(fontSize: 24)),
                title: const Text("မြန်မာ"),
                trailing:
                    selectedLanguage == "Myanmar"
                        ? const Icon(
                          Icons.check,
                          color: Color(0xFF6C63FF),
                          size: 20,
                        )
                        : null,
                onTap: () => Navigator.pop(context, "Myanmar"),
              ),
              ListTile(
                leading: const Text("🇬🇧", style: TextStyle(fontSize: 24)),
                title: const Text("English"),
                trailing:
                    selectedLanguage == "English"
                        ? const Icon(
                          Icons.check,
                          color: Color(0xFF6C63FF),
                          size: 20,
                        )
                        : null,
                onTap: () => Navigator.pop(context, "English"),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (result != null) {
      await prefs.setString("language", result);
      await AppLanguage.load();
      setState(() {
        selectedLanguage = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xffF5F9FF),
              Color(0xffE8F0FE),
              Color(0xffD4E8FF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Color(0xff1E4AA8),
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLanguage.text("Profile", "ပရိုဖိုင်"),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1E4AA8),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Profile Card
              if (!isLoading)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar with border - FIXED: removed padding from decoration
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xff1E4AA8), Color(0xff6C63FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage:
                                    photo.isNotEmpty
                                        ? NetworkImage(
                                          "http://10.114.214.88:8000$photo",
                                        )
                                        : null,
                                child:
                                    photo.isEmpty
                                        ? Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.grey.shade400,
                                        )
                                        : null,
                              ),
                            ),
                          ),

                          // Edit icon on avatar
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff1E4AA8).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          email,
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xff1E4AA8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Info chips in a row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _infoChip(
                            Icons.phone_android,
                            phone.isNotEmpty ? phone : "—",
                          ),
                          Container(
                            height: 30,
                            width: 1,
                            color: Colors.grey.shade200,
                          ),
                          _infoChip(Icons.cake, dob.isNotEmpty ? dob : "—"),
                          Container(
                            height: 30,
                            width: 1,
                            color: Colors.grey.shade200,
                          ),
                          _infoChip(
                            Icons.person_outline,
                            gender.isNotEmpty ? gender : "—",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  ),
                ),

              const SizedBox(height: 16),

              // Menu items
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: [
                            _menuItem(
                              icon: Icons.person_outline,
                              title: AppLanguage.text(
                                "Edit Profile",
                                "ကိုယ်ရေးအချက်အလက်ပြင်ရန်",
                              ),
                              iconColor: const Color(0xff1E4AA8),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => EditProfilePage(
                                          fullName: fullName,
                                          phone: phone,
                                          email: email,
                                          nrc: nrc,
                                          dob: dob,
                                          gender: gender,
                                        ),
                                  ),
                                );
                                if (result == true) loadProfile();
                              },
                            ),
                            _divider(),
                            _menuItem(
                              icon: Icons.language,
                              title: AppLanguage.text("Language", "ဘာသာစကား"),
                              trailing: selectedLanguage,
                              iconColor: const Color(0xff1E4AA8),
                              onTap: chooseLanguage,
                            ),
                            _divider(),
                            _menuItem(
                              icon: Icons.fact_check_outlined,
                              title: AppLanguage.text(
                                "Check Loan",
                                "ချေးငွေစစ်ဆေး",
                              ),
                              iconColor: const Color(0xff1E4AA8),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CheckLoanPage(),
                                  ),
                                );
                              },
                            ),
                            _divider(),
                            _menuItem(
                              icon: Icons.info_outline,
                              title: AppLanguage.text(
                                "About App",
                                "App အကြောင်း",
                              ),
                              iconColor: const Color(0xff1E4AA8),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AboutAppPage(),
                                  ),
                                );
                              },
                            ),
                            _divider(),
                            _menuItem(
                              icon: Icons.logout,
                              title: AppLanguage.text("Logout", "ထွက်ရန်"),
                              textColor: Colors.red.shade600,
                              iconColor: Colors.red.shade600,
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        title: Text(
                                          AppLanguage.text("Logout", "ထွက်ရန်"),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        content: Text(
                                          AppLanguage.text(
                                            "Are you sure you want to logout?",
                                            "သေချာထွက်မှာလား?",
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  Colors.grey.shade600,
                                            ),
                                            child: Text(
                                              AppLanguage.text(
                                                "Cancel",
                                                "မလုပ်တော့ပါ",
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.red.shade600,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Text(
                                              AppLanguage.text(
                                                "Logout",
                                                "ထွက်ရန်",
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                );
                                if (confirm == true) logout();
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xff1E4AA8).withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: const Color(0xff1E4AA8)),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    String? trailing,
    Color iconColor = Colors.black54,
    Color textColor = Colors.black87,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing:
          trailing != null
              ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  trailing,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
              : Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.grey.shade400,
              ),
      onTap: onTap,
    );
  }

  Widget _divider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 1,
      color: Colors.grey.shade100,
    );
  }
}
