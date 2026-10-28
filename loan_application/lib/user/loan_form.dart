import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:loan_application/constant.dart';
import 'package:loan_application/user/Home2.dart';
import 'package:loan_application/user/app_languages.dart';
import 'package:loan_application/user/predict.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- BACKEND CONFIGURATION ---
const String kBackendIp = '10.114.214.88';
const String kApiUrl = 'http://$kBackendIp:8000/api/v2/verify-kyc';
const String kNrcValidationUrl = 'http://$kBackendIp:8000/api/v2/validate-nrc';
const String kHouseholdValidationUrl =
    'http://$kBackendIp:8000/api/v2/validate-household';
const String kFetchLoanDetailsUrl =
    'http://$kBackendIp:8000/api/v2/loan-details';
const String kBizValidationUrl =
    'http://$kBackendIp:8000/api/v2/validate-license-ocr';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint("Camera Error: $e");
  }
  runApp(const MyApp());
}

Future<XFile?> downloadUrlToXFile(String? url, String fileName) async {
  if (url == null || url.isEmpty) return null;
  try {
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);
      return XFile(file.path);
    }
  } catch (e) {
    debugPrint("Error converting URL to XFile: $e");
  }
  return null;
}

Future<Map<String, dynamic>?> submitFullKYC({
  required XFile nrcFront,
  required XFile nrcBack,
  required XFile householdFront,
  required XFile householdBack,
  XFile? bizFront, // Nullable ပြုလုပ်ပေးထားပါသည်
  required XFile centerPhoto,
  required String userId,
  required String phoneNumber,
  required String occupation,
  required String incomeAverage,
  required String amount,
  required String month,
  required String categoryId,
}) async {
  var url = Uri.parse(kApiUrl);
  var request = http.MultipartRequest('POST', url);

  try {
    // Biz Photo ရှိမှသာ upload လုပ်မည် (Null Error မတက်စေရန်)
    if (bizFront != null) {
      request.files.add(
        await http.MultipartFile.fromPath('biz_photo', bizFront.path),
      );
    }

    request.files.add(
      await http.MultipartFile.fromPath('nrc_photo_front', nrcFront.path),
    );
    request.files.add(
      await http.MultipartFile.fromPath('nrc_photo_back', nrcBack.path),
    );
    request.files.add(
      await http.MultipartFile.fromPath(
        'household_list_photo_front',
        householdFront.path,
      ),
    );
    request.files.add(
      await http.MultipartFile.fromPath(
        'household_list_photo_back',
        householdBack.path,
      ),
    );
    request.files.add(
      await http.MultipartFile.fromPath('face_scan_photo', centerPhoto.path),
    );

    request.fields['user_id'] = userId;
    request.fields['phone_number'] = phoneNumber;
    request.fields['occupation'] = occupation;
    request.fields['income_average'] = incomeAverage;
    request.fields['amount'] = amount;
    request.fields['month'] = month;
    request.fields['category_id'] = categoryId;

    var streamedResponse = await request.send().timeout(
      const Duration(seconds: 90),
    );
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      return {
        "status": "failed",
        "error": errorData['error'] ?? "Unknown Server Error",
      };
    }
  } catch (e) {
    debugPrint("Submit Full KYC Connection Error: $e");
    return {"status": "failed", "error": "Server connection failed: $e"};
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple, useMaterial3: true),
      home: const LoanApp(),
    );
  }
}

class LoanApplicationPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final String amount;
  final String term;
  final Map<String, dynamic>? backendData;

  const LoanApplicationPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.term,
    this.backendData,
  });

  @override
  State<LoanApplicationPage> createState() => _LoanApplicationPageState();
}

class _LoanApplicationPageState extends State<LoanApplicationPage> {
  final PageController _pageController = PageController();
  int currentStep = 0;

  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;

  bool get isBusinessLoan {
    return widget.categoryName == "အသေးစားစီးပွားရေးလုပ်ငန်းချေးငွေ" ||
        widget.categoryName == "Business Loan" ||
        widget.categoryName == "Small Business Loan";
  }

  int get totalSteps => isBusinessLoan ? 5 : 4;

  final _formKey = GlobalKey<FormState>();
  String _currentUsername = "";

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController occupationController = TextEditingController();
  final TextEditingController incomeController = TextEditingController();

  late final TextEditingController amountController = TextEditingController(
    text: widget.amount,
  );
  late final TextEditingController termController = TextEditingController(
    text: widget.term,
  );

  int? savedDocumentId;
  XFile? nrcFront;
  XFile? nrcBack;
  XFile? householdFront;
  XFile? householdBack;
  XFile? bizFront;
  XFile? bizBack;
  XFile? centerPhoto;

  String? prevNrcFrontUrl;
  String? prevNrcBackUrl;
  String? prevHouseholdFrontUrl;
  String? prevHouseholdBackUrl;
  String? prevBizFrontUrl;
  String? prevFaceUrl;

  @override
  void initState() {
    super.initState();
    _loadLoggedInUser();
  }

  Future<void> _loadLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('userName');

    if (savedUsername != null && savedUsername.isNotEmpty) {
      setState(() {
        _currentUsername = savedUsername;
      });
      await fetchPreviousLoanData(_currentUsername);
    }
  }

  Future<void> fetchPreviousLoanData(String username) async {
    final url = Uri.parse(ApiConfig.userstatus + '$username/');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['is_repeated'] == true && data['previous_data'] != null) {
          final prev = data['previous_data'];

          setState(() {
            phoneController.text = prev['phone_number']?.toString() ?? '';
            occupationController.text = prev['occupation']?.toString() ?? '';
            incomeController.text = prev['income_average']?.toString() ?? '';

            prevNrcFrontUrl = prev['nrc_front_url'];
            prevNrcBackUrl = prev['nrc_back_url'];
            prevHouseholdFrontUrl = prev['household_front_url'];
            prevHouseholdBackUrl = prev['household_back_url'];
            prevBizFrontUrl = prev['biz_url'];
            prevFaceUrl = prev['face_url'];
          });
        }
      }
    } catch (e) {
      print("❌ Error fetching previous loan data: $e");
    }
  }

  void nextPage() {
    if (currentStep < totalSteps) {
      currentStep++;
      _pageController.animateToPage(
        currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {});
    }
  }

  void previousPage() {
    if (currentStep > 0) {
      currentStep--;
      _pageController.animateToPage(
        currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {});
    }
  }

  Future<void> validateBizLicenseAndNext() async {
    final hasBiz =
        bizFront != null ||
        (prevBizFrontUrl != null && prevBizFrontUrl!.isNotEmpty);

    if (!hasBiz) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ ကျေးဇူးပြု၍ လုပ်ငန်းလိုင်စင် ဓာတ်ပုံ တင်ပေးပါရန်။"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (bizFront == null) {
      nextPage();
      return;
    }

    setState(() => isLoading = true);

    try {
      final finalBiz =
          bizFront ??
          await downloadUrlToXFile(prevBizFrontUrl, 'biz_front.jpg');

      if (finalBiz == null) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ လုပ်ငန်းလိုင်စင် ပုံကို ဖတ်ရှု၍ မရပါ"),
          ),
        );
        return;
      }

      var request = http.MultipartRequest('POST', Uri.parse(kBizValidationUrl));
      request.files.add(
        await http.MultipartFile.fromPath('biz_front', finalBiz.path),
      );

      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 90),
      );
      var response = await http.Response.fromStream(streamedResponse);

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        if (result['status'] == 'valid') {
          nextPage();
        } else {
          _showErrorAlert(
            "လုပ်ငန်းလိုင်စင် မမှန်ကန်ပါ",
            result['message'] ??
                "တင်သွင်းထားသော လုပ်ငန်းလိုင်စင် ပုံစံသည် မမှန်ကန်ပါ။",
          );
        }
      } else {
        _showErrorAlert(
          "Server Error",
          "ဆာဗာမှ စစ်ဆေးမှု မအောင်မြင်ပါ။ နောက်မှ ပြန်လည်ကြိုးစားပါ။",
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "❌ Backend Server နှင့် ကွန်ရက် ချိတ်ဆက်မှု မအောင်မြင်ပါ။",
          ),
        ),
      );
    }
  }

  Future<void> _pickImage(String type, ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        if (type == 'nrc_front') nrcFront = pickedFile;
        if (type == 'nrc_back') nrcBack = pickedFile;
        if (type == 'household_front') householdFront = pickedFile;
        if (type == 'household_back') householdBack = pickedFile;
        if (type == 'biz_front') bizFront = pickedFile;
        if (type == 'biz_back') bizBack = pickedFile;
      });
    }
  }

  void _showChoiceOptions(String type, String title) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "$title Options",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xff0A4AA5),
                ),
                title: const Text("Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(type, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xff0A4AA5)),
                title: const Text("Camera"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(type, ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> validateNrcAndNext() async {
    final hasFront =
        nrcFront != null ||
        (prevNrcFrontUrl != null && prevNrcFrontUrl!.isNotEmpty);
    final hasBack =
        nrcBack != null ||
        (prevNrcBackUrl != null && prevNrcBackUrl!.isNotEmpty);

    if (!hasFront || !hasBack) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "⚠️ ကျေးဇူးပြု၍ မှတ်ပုံတင်ဓာတ်ပုံ ရှေ့/နောက်အပြည့်အစုံ တင်ပေးပါရန်။",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (nrcFront == null && nrcBack == null) {
      nextPage();
      return;
    }

    setState(() => isLoading = true);

    try {
      final finalFront =
          nrcFront ??
          await downloadUrlToXFile(prevNrcFrontUrl, 'nrc_front.jpg');
      final finalBack =
          nrcBack ?? await downloadUrlToXFile(prevNrcBackUrl, 'nrc_back.jpg');

      if (finalFront == null || finalBack == null) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ မှတ်ပုံတင် ပုံများကို ဖတ်ရှု၍ မရပါ")),
        );
        return;
      }

      var request = http.MultipartRequest('POST', Uri.parse(kNrcValidationUrl));
      request.files.add(
        await http.MultipartFile.fromPath('nrc_front', finalFront.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('nrc_back', finalBack.path),
      );

      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 90),
      );
      var response = await http.Response.fromStream(streamedResponse);

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        if (result['status'] == 'valid') {
          nextPage();
        } else {
          _showErrorAlert(
            "NRC အချက်အလက် မမှန်ကန်ပါ",
            result['message'] ??
                "တင်သွင်းထားသော မှတ်ပုံတင်ပုံစံသည် မမှန်ကန်ပါ။",
          );
        }
      } else {
        _showErrorAlert(
          "Server Error",
          "ဆာဗာမှ စစ်ဆေးမှု မအောင်မြင်ပါ။ နောက်မှ ပြန်လည်ကြိုးစားပါ။",
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "❌ Backend Server နှင့် ကွန်ရက် ချိတ်ဆက်မှု မအောင်မြင်ပါ။",
          ),
        ),
      );
    }
  }

  Future<void> validateHouseholdAndNext() async {
    final hasFront =
        householdFront != null ||
        (prevHouseholdFrontUrl != null && prevHouseholdFrontUrl!.isNotEmpty);
    final hasBack =
        householdBack != null ||
        (prevHouseholdBackUrl != null && prevHouseholdBackUrl!.isNotEmpty);

    if (!hasFront || !hasBack) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "⚠️ ကျေးဇူးပြု၍ အိမ်ထောင်စုစာရင်း ရှေ့/နောက်အပြည့်အစုံ တင်ပေးပါရန်။",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (householdFront == null && householdBack == null) {
      nextPage();
      return;
    }

    setState(() => isLoading = true);

    try {
      final finalFront =
          householdFront ??
          await downloadUrlToXFile(prevHouseholdFrontUrl, 'hh_front.jpg');
      final finalBack =
          householdBack ??
          await downloadUrlToXFile(prevHouseholdBackUrl, 'hh_back.jpg');

      if (finalFront == null || finalBack == null) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ အိမ်ထောင်စုစာရင်း ပုံများကို ဖတ်ရှု၍ မရပါ"),
          ),
        );
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(kHouseholdValidationUrl),
      );
      request.files.add(
        await http.MultipartFile.fromPath('household_front', finalFront.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('household_back', finalBack.path),
      );

      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 90),
      );
      var response = await http.Response.fromStream(streamedResponse);

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        if (result['status'] == 'valid') {
          nextPage();
        } else {
          _showErrorAlert(
            "အိမ်ထောင်စုစာရင်း မမှန်ကန်ပါ",
            result['message'] ??
                "တင်သွင်းထားသော အိမ်ထောင်စုစာရင်းပုံစံသည် မမှန်ကန်ပါ။",
          );
        }
      } else {
        _showErrorAlert(
          "Server Error",
          "ဆာဗာမှ စစ်ဆေးမှု မအောင်မြင်ပါ။ နောက်မှ ပြန်လည်ကြိုးစားပါ။",
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "❌ Backend Server နှင့် ကွန်ရက် ချိတ်ဆက်မှု မအောင်မြင်ပါ။",
          ),
        ),
      );
    }
  }

  void _showErrorAlert(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text("ပြန်လည်ပြင်ဆင်မည်"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  void _startLivenessCheck() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LivenessCameraScreen()),
    );
    if (result != null && result is XFile) {
      setState(() {
        centerPhoto = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Liveness Verification Success!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // --- NULL CHECK FIX HERE ---
  Future<void> handleUploadAndNext() async {
    if (_currentUsername.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "⚠️ User အမည် ရှာမတွေ့ပါ။ ကျေးဇူးပြု၍ Login ပြန်ဝင်ပါ။",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final finalNrcFront =
          nrcFront ??
          await downloadUrlToXFile(prevNrcFrontUrl, 'nrc_front.jpg');
      final finalNrcBack =
          nrcBack ?? await downloadUrlToXFile(prevNrcBackUrl, 'nrc_back.jpg');
      final finalHouseholdFront =
          householdFront ??
          await downloadUrlToXFile(prevHouseholdFrontUrl, 'hh_front.jpg');
      final finalHouseholdBack =
          householdBack ??
          await downloadUrlToXFile(prevHouseholdBackUrl, 'hh_back.jpg');

      // Null safety ပြန်လည်ပြင်ဆင်ထားပါသည် (Business Loan မဟုတ်ပါက null)
      XFile? finalBizFront;
      if (isBusinessLoan) {
        finalBizFront =
            bizFront ??
            await downloadUrlToXFile(prevBizFrontUrl, 'biz_front.jpg');
      }

      final finalCenterPhoto =
          centerPhoto ?? await downloadUrlToXFile(prevFaceUrl, 'face.jpg');

      if (finalNrcFront == null ||
          finalNrcBack == null ||
          finalHouseholdFront == null ||
          finalHouseholdBack == null ||
          finalCenterPhoto == null ||
          (isBusinessLoan && finalBizFront == null)) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "⚠️ Please complete NRC, Household, Business License and Face Scan.",
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final result = await submitFullKYC(
        nrcFront: finalNrcFront,
        nrcBack: finalNrcBack,
        householdFront: finalHouseholdFront,
        householdBack: finalHouseholdBack,
        bizFront: finalBizFront, // Null Safe
        centerPhoto: finalCenterPhoto,
        userId: _currentUsername,
        phoneNumber: phoneController.text,
        occupation: occupationController.text,
        incomeAverage: incomeController.text,
        amount: amountController.text,
        month: termController.text,
        categoryId: widget.categoryId.toString(),
      );

      setState(() => isLoading = false);

      if (result != null && result['status'] == 'success') {
        setState(() {
          savedDocumentId = result['document_id'];
        });
        nextPage();
      } else {
        String errorMsg = result?['error'] ?? "Backend Verification Failed.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ $errorMsg"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error handling upload: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String pageTitle() {
    switch (currentStep) {
      case 0:
        return AppLanguage.text(
          "Loan Application Form",
          "ချေးငွေလျှောက်လွှာပုံစံ",
        );
      case 1:
        return AppLanguage.text("Upload NRC Photos", "မှတ်ပုံတင်ဓာတ်ပုံတင်ပါ");
      case 2:
        return AppLanguage.text(
          "Upload Household List",
          "အိမ်ထောင်စုစာရင်းတင်ပါ",
        );
      case 3:
        return isBusinessLoan
            ? AppLanguage.text(
              "Upload Business License",
              "လုပ်ငန်းလိုင်စင်တင်ပါ",
            )
            : AppLanguage.text("Face Scan", "မျက်နှာစစ်ဆေးခြင်း");
      case 4:
        return isBusinessLoan
            ? AppLanguage.text("Face Scan", "မျက်နှာစစ်ဆေးခြင်း")
            : "";
      default:
        return "";
    }
  }

  String pageSubtitle() {
    switch (currentStep) {
      case 0:
        return AppLanguage.text(
          "Please fill the detail below",
          "အောက်ပါအချက်အလက်များကို ဖြည့်ပေးပါ",
        );
      case 1:
        return AppLanguage.text(
          "Please upload clear photos of your NRC",
          "မှတ်ပုံတင် (NRC) ရှေ့/နောက် ပုံများကို ကြည်လင်စွာ တင်ပေးပါ",
        );
      case 2:
        return AppLanguage.text(
          "Please upload your Household List",
          "အိမ်ထောင်စုစာရင်း ပုံများကို တင်ပေးပါ",
        );
      case 3:
        return isBusinessLoan
            ? AppLanguage.text(
              "Please upload your Business License",
              "လုပ်ငန်းလိုင်စင် ပုံများကို တင်ပေးပါ",
            )
            : AppLanguage.text(
              "Please complete your face scan\nfor identity verification",
              "ကိုယ်ရေးအတည်ပြုရန်\nမျက်နှာစစ်ဆေးမှု ပြီးစီးအောင်လုပ်ပါ",
            );
      case 4:
        return isBusinessLoan
            ? AppLanguage.text(
              "Please complete your face scan\nfor identity verification",
              "ကိုယ်ရေးအတည်ပြုရန်\nမျက်နှာစစ်ဆေးမှု ပြီးစီးအောင်လုပ်ပါ",
            )
            : "";
      default:
        return "";
    }
  }

  Widget stepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        bool completed = index < currentStep;
        bool current = index == currentStep;
        return Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    completed
                        ? Colors.green
                        : current
                        ? const Color(0xff0A4AA5)
                        : Colors.grey.shade300,
              ),
              child: Center(
                child:
                    completed
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : Text(
                          "${index + 1}",
                          style: TextStyle(
                            color:
                                current ? Colors.white : Colors.grey.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
            if (index != totalSteps - 1)
              Container(
                width: 28,
                height: 2,
                color:
                    index < currentStep ? Colors.green : Colors.grey.shade300,
              ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffECE8F8),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xff0A4AA5)),
                  onPressed: () {
                    if (currentStep > 0) {
                      previousPage();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              pageTitle(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xff0A4AA5),
                fontSize: 20,
              ),
            ),
            Text(
              pageSubtitle(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              maxLines: 2,
            ),
            const SizedBox(height: 15),
            if (currentStep < 5) stepIndicator(),
            const SizedBox(height: 15),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  Form(
                    key: _formKey,
                    child: LoanFormScreen(
                      formKey: _formKey,
                      onNext: nextPage,
                      onBack: previousPage,
                      phoneController: phoneController,
                      occupationController: occupationController,
                      incomeController: incomeController,
                      amountController: amountController,
                      termController: termController,
                    ),
                  ),

                  UploadScreen(
                    frontFile: nrcFront,
                    backFile: nrcBack,
                    networkFrontUrl: prevNrcFrontUrl,
                    networkBackUrl: prevNrcBackUrl,
                    isLoading: isLoading,
                    onPickFront:
                        () => _showChoiceOptions('nrc_front', 'NRC Front'),
                    onPickBack:
                        () => _showChoiceOptions('nrc_back', 'NRC Back'),
                    onNext: validateNrcAndNext,
                    onBack: previousPage,
                  ),

                  UploadScreen(
                    frontFile: householdFront,
                    backFile: householdBack,
                    networkFrontUrl: prevHouseholdFrontUrl,
                    networkBackUrl: prevHouseholdBackUrl,
                    isLoading: isLoading,
                    onPickFront:
                        () => _showChoiceOptions(
                          'household_front',
                          'Household Front',
                        ),
                    onPickBack:
                        () => _showChoiceOptions(
                          'household_back',
                          'Household Back',
                        ),
                    onNext: validateHouseholdAndNext,
                    onBack: previousPage,
                  ),

                  if (isBusinessLoan)
                    SingleUploadScreen(
                      file: bizFront,
                      networkUrl: prevBizFrontUrl,
                      isLoading: isLoading,
                      onPick:
                          () => _showChoiceOptions(
                            'biz_front',
                            'Business License',
                          ),
                      onNext: validateBizLicenseAndNext,
                      onBack: previousPage,
                    ),

                  FaceScanScreen(
                    centerPhoto: centerPhoto,
                    networkUrl: prevFaceUrl,
                    isLoading: isLoading,
                    onScanClick: _startLivenessCheck,
                    onNext: handleUploadAndNext,
                    onBack: previousPage,
                  ),

                  WaitingStageScreen(
                    documentId: savedDocumentId,
                    onNext: () {
                      Navigator.of(context).pop();
                    },
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

class LoanFormScreen extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final TextEditingController phoneController;
  final TextEditingController occupationController;
  final TextEditingController incomeController;
  final TextEditingController amountController;
  final TextEditingController termController;

  const LoanFormScreen({
    super.key,
    required this.formKey,
    required this.onNext,
    required this.onBack,
    required this.phoneController,
    required this.occupationController,
    required this.incomeController,
    required this.amountController,
    required this.termController,
  });

  Widget field(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters:
                label == AppLanguage.text("Phone Number", "ဖုန်းနံပါတ်")
                    ? [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ]
                    : null,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'ကျေးဇူးပြု၍ $label ကို ဖြည့်စွက်ပါ';
              }
              if (label == AppLanguage.text("Phone Number", "ဖုန်းနံပါတ်")) {
                String phone = value.trim().replaceAll(RegExp(r'[\s-]'), '');
                if (RegExp(r'^097\d{8}$').hasMatch(phone)) return null;
                if (RegExp(r'^099\d{8}$').hasMatch(phone)) return null;
                if (RegExp(r'^096\d{8}$').hasMatch(phone)) return null;
                if (RegExp(r'^09(2|4|5|8)\d{8}$').hasMatch(phone)) return null;
                if (RegExp(r'^01\d{7}$').hasMatch(phone)) return null;
                return "မြန်မာဖုန်းနံပါတ် မှန်ကန်စွာထည့်ပါ";
              }
              return null;
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              errorStyle: const TextStyle(
                color: Colors.redAccent,
                fontSize: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  field(
                    AppLanguage.text("Phone Number", "ဖုန်းနံပါတ်"),
                    phoneController,
                  ),
                  field(
                    AppLanguage.text("Occupation", "အလုပ်အကိုင်"),
                    occupationController,
                  ),
                  field(
                    AppLanguage.text("Income Average", "ပျမ်းမျှဝင်ငွေ"),
                    incomeController,
                  ),
                  field(
                    AppLanguage.text(
                      "Instant Loan Amount",
                      "ချက်ချင်းချေးငွေပမာဏ",
                    ),
                    amountController,
                  ),
                  field(
                    AppLanguage.text("Loan Duration", "ချေးငွေကာလ"),
                    termController,
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0A4AA5),
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      onNext();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'ကျေးဇူးပြု၍ လိုအပ်သော အချက်အလက်များ အားလုံးကို ဖြည့်စွက်ပေးပါ',
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  child: Text(
                    AppLanguage.text("Next", "ရှေ့သို့"),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UploadScreen extends StatelessWidget {
  final XFile? frontFile;
  final XFile? backFile;
  final String? networkFrontUrl;
  final String? networkBackUrl;
  final bool isLoading;
  final VoidCallback onPickFront;
  final VoidCallback onPickBack;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const UploadScreen({
    super.key,
    required this.frontFile,
    required this.backFile,
    this.networkFrontUrl,
    this.networkBackUrl,
    required this.isLoading,
    required this.onPickFront,
    required this.onPickBack,
    required this.onNext,
    required this.onBack,
  });

  Widget uploadBox(XFile? file, String? networkUrl, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 175,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xffC9C7E8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey),
        ),
        child:
            file != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(File(file.path), fit: BoxFit.cover),
                )
                : (networkUrl != null && networkUrl.isNotEmpty)
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(networkUrl, fit: BoxFit.cover),
                )
                : const Center(
                  child: Icon(
                    Icons.camera_alt,
                    size: 45,
                    color: Color(0xff0A4AA5),
                  ),
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppLanguage.text("Front Side", "ရှေ့ဘက်"),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          uploadBox(frontFile, networkFrontUrl, onPickFront),
          const SizedBox(height: 15),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(AppLanguage.text("Back Side", "နောက်ဘက်")),
          ),
          const SizedBox(height: 8),
          uploadBox(backFile, networkBackUrl, onPickBack),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0A4AA5),
                  ),
                  onPressed: onBack,
                  child: Text(
                    AppLanguage.text("Back", "နောက်သို့"),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0A4AA5),
                  ),
                  onPressed: isLoading ? null : onNext,
                  child:
                      isLoading
                          ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Text(
                            AppLanguage.text("Next", "ရှေ့သို့"),
                            style: const TextStyle(color: Colors.white),
                          ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- OVERFLOW FIX IN FACE SCAN SCREEN ---
class FaceScanScreen extends StatelessWidget {
  final XFile? centerPhoto;
  final String? networkUrl;
  final bool isLoading;
  final VoidCallback onScanClick;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const FaceScanScreen({
    super.key,
    required this.centerPhoto,
    this.networkUrl,
    required this.isLoading,
    required this.onScanClick,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: [
          const SizedBox(height: 15),
          GestureDetector(
            onTap: onScanClick,
            child:
                centerPhoto != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Image.file(
                        File(centerPhoto!.path),
                        width: 180,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    )
                    : (networkUrl != null && networkUrl!.isNotEmpty)
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Image.network(
                        networkUrl!,
                        width: 180,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    )
                    : Image.asset(
                      "assets/image/scan.png",
                      width: 180,
                      height: 180,
                      fit: BoxFit.contain,
                    ),
          ),
          const SizedBox(height: 15),
          // OVERFLOW FIX: Dynamic Container Size
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xffBFEAE4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Auto Height
              children: [
                Text(
                  AppLanguage.text("Tips", "အကြံပြုချက်များ"),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppLanguage.text(
                          "Look at the screen camera",
                          "ကင်မရာမျက်နှာပြင်ကို ကြည့်ပါ",
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.wb_sunny_outlined, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppLanguage.text(
                          "Look at the stream camera",
                          "ကင်မရာကို တည့်တည့်ကြည့်ပါ",
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.crop_free, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppLanguage.text(
                          "Keep your face within the Frame",
                          "သင့်မျက်နှာကိုဘောင်အတွင်းထားပါ",
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0A4AA5),
                    ),
                    onPressed: onBack,
                    child: Text(
                      AppLanguage.text("Back", "နောက်သို့"),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0A4AA5),
                    ),
                    onPressed: isLoading ? null : onNext,
                    child:
                        isLoading
                            ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              AppLanguage.text("Next", "ရှေ့သို့"),
                              style: const TextStyle(color: Colors.white),
                            ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class WaitingStageScreen extends StatefulWidget {
  final int? documentId;
  final VoidCallback onNext;

  const WaitingStageScreen({super.key, this.documentId, required this.onNext});

  @override
  State<WaitingStageScreen> createState() => _WaitingStageScreenState();
}

class _WaitingStageScreenState extends State<WaitingStageScreen> {
  Map<String, dynamic>? loanData;
  bool isFetching = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchDataFromDatabase();
  }

  Future<void> fetchDataFromDatabase() async {
    if (widget.documentId == null) {
      setState(() {
        isFetching = false;
        errorMessage = "Invalid Document ID Reference.";
      });
      return;
    }

    try {
      final response = await http
          .get(Uri.parse('$kFetchLoanDetailsUrl/${widget.documentId}'))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            loanData = result['data'];
            isFetching = false;
          });
        } else {
          setState(() {
            errorMessage = result['error'] ?? "Failed to query database.";
            isFetching = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Server Error: Status code ${response.statusCode}";
          isFetching = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Connection error while fetching database records: $e";
        isFetching = false;
      });
    }
  }

  Widget item(String title, String value) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: [
          const SizedBox(height: 28),
          if (isFetching)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xff0A4AA5)),
              ),
            )
          else if (errorMessage != null)
            Expanded(
              child: Center(
                child: Text(
                  "❌ $errorMessage",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  item(
                    AppLanguage.text("Amount", "ချေးငွေပမာဏ"),
                    loanData?['amount'] ?? "N/A",
                  ),
                  const Divider(),
                  item(
                    AppLanguage.text("Duration", "ချေးငွေကာလ"),
                    loanData?['duration'] ?? "N/A",
                  ),
                  const Divider(),
                  item(
                    AppLanguage.text("Total Savings", "စုဆောင်းငွေစုစုပေါင်း"),
                    loanData?['total_savings'] ?? "N/A",
                  ),
                  const Divider(),
                  item(
                    AppLanguage.text("Total Loan", "ချေးငွေစုစုပေါင်း"),
                    loanData?['total_loan'] ?? "N/A",
                  ),
                  const Divider(),
                  item(
                    AppLanguage.text(
                      "Total Repayment (Monthly)",
                      "လစဉ်ပြန်လည်ပေးဆပ်ရမည့်ပမာဏ",
                    ),
                    loanData?['monthly_repayment'] ?? "N/A",
                  ),
                  const Divider(),
                  item(
                    AppLanguage.text(
                      "Total Repayment Amount",
                      "ပြန်လည်ပေးဆပ်ရမည့် စုစုပေါင်းပမာဏ",
                    ),
                    loanData?['total_repayment'] ?? "N/A",
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLanguage.text("Status", "အခြေအနေ"),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          AppLanguage.text(
                            loanData?['loan_status'] ?? "Pending",
                            loanData?['loan_status'] == "Approved"
                                ? "အတည်ပြုပြီး"
                                : loanData?['loan_status'] == "Rejected"
                                ? "ငြင်းပယ်ထားသည်"
                                : "စောင့်ဆိုင်းနေသည်",
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xffBFEAE4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              AppLanguage.text(
                "We will notify you within 48 hours regarding your application",
                "သင့်လျှောက်လွှာအကြောင်းကို ၄၈ နာရီအတွင်း အသိပေးပါမည်",
              ),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0A4AA5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                );
              },
              child: Text(
                AppLanguage.text("Done", "ပြီးပါပြီ"),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class SingleUploadScreen extends StatelessWidget {
  final XFile? file;
  final String? networkUrl;
  final bool isLoading;
  final VoidCallback onPick;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const SingleUploadScreen({
    super.key,
    required this.file,
    this.networkUrl,
    required this.isLoading,
    required this.onPick,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppLanguage.text("Business License", "စီးပွားရေးလိုင်စင်"),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: onPick,
            child: Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xffC9C7E8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey),
              ),
              child:
                  file != null
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(File(file!.path), fit: BoxFit.cover),
                      )
                      : (networkUrl != null && networkUrl!.isNotEmpty)
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(networkUrl!, fit: BoxFit.cover),
                      )
                      : const Center(
                        child: Icon(
                          Icons.camera_alt,
                          size: 45,
                          color: Color(0xff0A4AA5),
                        ),
                      ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0A4AA5),
                  ),
                  onPressed: onBack,
                  child: Text(
                    AppLanguage.text("Back", "နောက်သို့"),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0A4AA5),
                  ),
                  onPressed: isLoading ? null : onNext,
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Text(
                            AppLanguage.text("Next", "ရှေ့သို့"),
                            style: const TextStyle(color: Colors.white),
                          ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- LIVENESS CAMERA DETECTION ENGINE ---
enum LivenessStep { left, right, center, done }

class LivenessCameraScreen extends StatefulWidget {
  const LivenessCameraScreen({super.key});

  @override
  State<LivenessCameraScreen> createState() => _LivenessCameraScreenState();
}

class _LivenessCameraScreenState extends State<LivenessCameraScreen> {
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableTracking: true,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  bool isProcessingFrame = false;
  Timer? _processingTimer;
  LivenessStep currentStep = LivenessStep.left;
  String instructionText = "Turn your face LEFT";
  Color ovalColor = Colors.deepPurpleAccent;
  bool showSuccessAlert = false;
  String alertMessage = "";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) {
      try {
        cameras = await availableCameras();
      } catch (e) {
        return;
      }
    }
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      _processingTimer = Timer.periodic(const Duration(milliseconds: 350), (
        timer,
      ) {
        if (!isProcessingFrame && currentStep != LivenessStep.done) {
          _captureAndProcessFrame();
        }
      });
    } catch (e) {
      debugPrint("Camera Init Error: $e");
    }
    if (mounted) setState(() {});
  }

  Future<void> _captureAndProcessFrame() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    setState(() => isProcessingFrame = true);

    XFile? continuousFrameFile;
    try {
      continuousFrameFile = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(continuousFrameFile.path);
      final faces = await _faceDetector.processImage(inputImage);

      try {
        final tempFile = File(continuousFrameFile.path);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}

      if (faces.isEmpty || faces.length != 1) return;

      final face = faces.first;
      final yaw = face.headEulerAngleY ?? 0.0;

      if (currentStep == LivenessStep.left && yaw > 14) {
        await _handleStepSuccess(
          AppLanguage.text("✅ LEFT OK", "✅ ဘယ်သို့ OK"),
          LivenessStep.right,
          "Turn your face RIGHT",
        );
      } else if (currentStep == LivenessStep.right && yaw < -14) {
        await _handleStepSuccess(
          "✅ RIGHT OK",
          LivenessStep.center,
          "Look STRAIGHT & STEADY",
        );
      } else if (currentStep == LivenessStep.center && yaw > -6 && yaw < 6) {
        _processingTimer?.cancel();
        setState(() {
          ovalColor = Colors.green;
          showSuccessAlert = true;
          alertMessage = "📸 Capturing Perfect Selfie...";
        });

        await Future.delayed(const Duration(milliseconds: 500));
        XFile finalSelfie = await _cameraController!.takePicture();

        if (mounted) {
          currentStep = LivenessStep.done;
          Navigator.pop(context, finalSelfie);
        }
      }
    } catch (e) {
      debugPrint("Frame loop skipped.");
    } finally {
      if (currentStep != LivenessStep.done && mounted) {
        setState(() => isProcessingFrame = false);
      }
    }
  }

  Future<void> _handleStepSuccess(
    String message,
    LivenessStep nextStep,
    String nextInstruction,
  ) async {
    setState(() {
      ovalColor = Colors.green;
      showSuccessAlert = true;
      alertMessage = message;
    });
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      currentStep = nextStep;
      nextInstruction = AppLanguage.text(
        "Turn your face LEFT",
        "သင့်မျက်နှာကို ဘယ်ဘက်သို့ လှည့်ပါ",
      );

      instructionText = nextInstruction;
      showSuccessAlert = false;
      ovalColor = Colors.deepPurpleAccent;
    });
  }

  @override
  void dispose() {
    _processingTimer?.cancel();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: CameraPreview(_cameraController!)),
          Positioned.fill(
            child: CustomPaint(
              painter: FaceHolePainter(strokeColor: ovalColor),
            ),
          ),
          if (showSuccessAlert)
            Positioned(
              top: size.height / 2 - 40,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  alertMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                instructionText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FaceHolePainter extends CustomPainter {
  final Color strokeColor;
  FaceHolePainter({required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2.5),
      width: size.width * 0.75,
      height: size.height * 0.45,
    );
    final backgroundPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.75)
          ..style = PaintingStyle.fill;
    Path backgroundPath =
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    Path holePath = Path()..addOval(ovalRect);
    Path combinedPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      holePath,
    );
    canvas.drawPath(combinedPath, backgroundPaint);
    final borderPaint =
        Paint()
          ..color = strokeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
    canvas.drawOval(ovalRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant FaceHolePainter oldDelegate) {
    return oldDelegate.strokeColor != strokeColor;
  }
}
