import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:loan_application/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'app_languages.dart';



class EditProfilePage extends StatefulWidget {
  final String fullName;
  final String phone;
  final String email;
  final String nrc;
  final String dob;
  final String gender;

  const EditProfilePage({
    super.key,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.nrc,
    required this.dob,
    required this.gender,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  bool isPhoneEditable = false;
  bool isGenderEditable = false;
  bool isEmailEditable = false;

  Future<void> updateProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final oldEmail = prefs.getString("email");

    // Phone Validation
    if (!validatePhone()) {
      return;
    }

    // Email Validation
    if (!validateEmail()) {
      return;
    }

    if (!hasProfileChanged()) {
      showError("ပြောင်းလဲမှုမရှိပါ");
      return;
    }

    var request = http.MultipartRequest(
      "POST",
      Uri.parse(ApiConfig.updateprofile),
    );

    request.fields["old_email"] = oldEmail ?? "";
    request.fields["email"] = emailController.text.trim();
    request.fields["phone_number"] = phoneController.text.trim();
    request.fields["nrc_number"] = nrcController.text.trim();
    request.fields["date_of_birth"] = dobController.text.trim();
    request.fields["gender"] = gender;

    if (selectedImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          "photo",
          selectedImage!.path,
        ),
      );
    }

    var response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      await prefs.setString("email", emailController.text.trim());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ပရိုဖိုင်ချိန်းခြင်း အောင်မြင်ပါသည်"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } else {
      if (!mounted) return;

      String message = "Update Failed";

      try {
        final data = jsonDecode(responseBody);
        if (data["message"] != null) {
          message = data["message"];
        }
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  File? selectedImage;
  final ImagePicker picker = ImagePicker();

  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool validatePhone() {
    String phone = phoneController.text.trim();

    if (phone.isEmpty) {
      showError("ဖုန်းနံပါတ် လိုအပ်နေပါသည်");
      return false;
    }

    phone = phone.replaceAll(RegExp(r'[\s-]'), '');

    if (RegExp(r'^097\d{8}$').hasMatch(phone)) return true;
    if (RegExp(r'^099\d{8}$').hasMatch(phone)) return true;
    if (RegExp(r'^096\d{8}$').hasMatch(phone)) return true;
    if (RegExp(r'^09(2|4|5|8)\d{8}$').hasMatch(phone)) return true;
    if (RegExp(r'^01\d{7}$').hasMatch(phone)) return true;

    showError("မှန်ကန်သော ဖုန်းနံပါတ်သာထည့်ပေးပါ");
    return false;
  }

  bool validateEmail() {
    String email = emailController.text.trim();

    if (email.isEmpty) {
      showError("အီးမေးလ် လိုအပ်နေပါသည်");
      return false;
    }

    // Register နဲ့တူတဲ့ Gmail Validation
    if (!RegExp(
      r'^[a-z][a-z0-9._%+-]*@gmail\.com$',
    ).hasMatch(email)) {
      showError("မှန်ကန်သော Gmail ထည့်ပါ");
      return false;
    }

    return true;
  }

  bool hasProfileChanged() {
    if (phoneController.text.trim() != widget.phone.trim()) return true;
    if (emailController.text.trim() != widget.email.trim()) return true;
    if (nrcController.text.trim() != widget.nrc.trim()) return true;
    if (dobController.text.trim() != widget.dob.trim()) return true;
    if (gender != widget.gender) return true;
    if (selectedImage != null) return true;
    return false;
  }
  late TextEditingController phoneController;
  late TextEditingController nrcController;
  late TextEditingController emailController;
  late TextEditingController dobController;
  late String gender;

  Future<void> selectDate() async {
    DateTime initialDate = DateTime.now();

    try {
      if (dobController.text.isNotEmpty) {
        initialDate = DateTime.parse(dobController.text);
      }
    } catch (_) {}

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      dobController.text =
      "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController(text: widget.phone);
    nrcController = TextEditingController(text: widget.nrc);
    emailController = TextEditingController(text: widget.email);
    dobController = TextEditingController(text: widget.dob);
    gender = widget.gender == "Male" || widget.gender == "Female" || widget.gender == "Other"
        ? widget.gender
        : "Male";
  }

  @override
  void dispose() {
    phoneController.dispose();
    nrcController.dispose();
    emailController.dispose();
    dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, color: Color(0xff1E4AA8)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLanguage.text("Edit Profile", "ပရိုဖိုင် ပြင်ဆင်ရန်"),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1E4AA8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Profile Image Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: selectedImage != null
                            ? FileImage(selectedImage!)
                            : null,
                        child: selectedImage == null
                            ? Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey.shade400,
                        )
                            : null,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xff1E4AA8),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: GestureDetector(
                          onTap: pickImage,
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Full Name
              Text(
                widget.fullName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1E4AA8),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xff1E4AA8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  emailController.text,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Form Container
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade100,
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSectionTitle(Icons.person_outline, AppLanguage.text("Personal Information", "ကိုယ်ရေးအချက်အလက်")),
                    const SizedBox(height: 16),

                    _buildModernField(
                      label: AppLanguage.text("Phone Number", "ဖုန်းနံပါတ်"),
                      controller: phoneController,
                      icon: Icons.phone_android_outlined,
                      isEditable: isPhoneEditable,
                      onEditToggle: () {
                        setState(() {
                          isPhoneEditable = !isPhoneEditable;
                        });
                      },
                      readOnly: !isPhoneEditable,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                    ),

                    _buildModernField(
                      label: AppLanguage.text("NRC Number", "မှတ်ပုံတင်နံပါတ်"),
                      controller: nrcController,
                      icon: Icons.assignment_outlined,
                      readOnly: true,
                    ),

                    _buildModernField(
                      label: AppLanguage.text("Email", "အီးမေးလ်"),
                      controller: emailController,
                      icon: Icons.email_outlined,
                      readOnly: !isEmailEditable,
                      isEditable: isEmailEditable,
                      keyboardType: TextInputType.emailAddress,
                      onEditToggle: () {
                        setState(() {
                          isEmailEditable = !isEmailEditable;
                        });
                      },
                    ),

                    _buildModernField(
                      label: AppLanguage.text("Date of Birth", "မွေးသက္ကရာဇ်"),
                      controller: dobController,
                      icon: Icons.calendar_today_outlined,
                      readOnly: true,
                    ),

                    const SizedBox(height: 8),

                    // Gender Section
                    // Gender Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        _buildSectionTitle(
                          Icons.person_outline,
                          AppLanguage.text("Gender", "ကျား/မ"),
                        ),

                        if (!isGenderEditable)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                isGenderEditable = true;
                              });
                            },
                            icon: const Icon(
                              Icons.edit,
                              size: 16,
                            ),
                            label: Text(
                              AppLanguage.text(
                                "Edit Gender",
                                "ကျား/မ ပြင်ရန်",
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xff1E4AA8),
                              padding: EdgeInsets.zero,
                            ),
                          ),

                      ],
                    ),

                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: "Male",
                                groupValue: gender,
                                onChanged: isGenderEditable
                                    ? (value) {
                                  setState(() => gender = value!);
                                }
                                    : null,
                                activeColor: const Color(0xff1E4AA8),
                              ),
                              Text(
                                AppLanguage.text("Male", "ကျား"),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),


                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: "Female",
                                groupValue: gender,
                                onChanged: isGenderEditable
                                    ? (value) {
                                  setState(() => gender = value!);
                                }
                                    : null,
                                activeColor: const Color(0xff1E4AA8),
                              ),
                              Text(
                                AppLanguage.text("Female", "မ"),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),


                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: "Other",
                                groupValue: gender,
                                onChanged: isGenderEditable
                                    ? (value) {
                                  setState(() => gender = value!);
                                }
                                    : null,
                                activeColor: const Color(0xff1E4AA8),
                              ),
                              Text(
                                AppLanguage.text("Other", "အခြား"),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),

                        ],
                      ),
                    ),



                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff1E4AA8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xff1E4AA8).withOpacity(0.3),
                        ),
                        onPressed: updateProfile,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            Text(
                              AppLanguage.text("Save Changes", "ပြောင်းလဲမှုများ သိမ်းမည်"),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xff1E4AA8), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xff1E4AA8),
          ),
        ),
      ],
    );
  }

  Widget _buildModernField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool readOnly = false,
    bool isEditable = false,
    VoidCallback? onEditToggle,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: readOnly && !isEditable
                  ? Colors.grey.shade50
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: readOnly && !isEditable
                    ? Colors.grey.shade200
                    : const Color(0xff1E4AA8).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(
                    icon,
                    color: readOnly && !isEditable
                        ? Colors.blue
                        : const Color(0xff1E4AA8),
                    size: 20,
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    readOnly: readOnly,
                    onTap: onTap,
                    keyboardType: keyboardType ?? TextInputType.text,
                    inputFormatters: inputFormatters,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                if (onEditToggle != null)
                  IconButton(
                    onPressed: onEditToggle,
                    icon: Icon(
                      isEditable ? Icons.check_circle : Icons.edit_outlined,
                      color: isEditable
                          ? Colors.green
                          : const Color(0xff1E4AA8),
                      size: 22,
                    ),
                    padding: const EdgeInsets.all(4),
                  ),
                if (onTap != null)
                  IconButton(
                    onPressed: onTap,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xff1E4AA8),
                      size: 24,
                    ),
                    padding: const EdgeInsets.all(4),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}